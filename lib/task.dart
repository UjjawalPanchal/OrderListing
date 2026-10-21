/*
* Created by ujjawal on 21/10/26.
*/
// lib/mock/mock_order_repository.dart
//
// Mock of the Orders API (AWS Lambda + PostgreSQL) for the Flutter Round 2 assessment.
// Pure Dart, no dependencies. Treat it like a remote API: slow, fallible, changing.
// Candidates must NOT modify this file. Wrap it behind your own repository.

import 'dart:async';
import 'dart:math';

// ---------------------------------------------------------------------------
// Exceptions (mirror what an HTTP client such as Dio would surface)
// ---------------------------------------------------------------------------

/// Connection-level failure: offline or timed out. No HTTP status.
class MockNetworkException implements Exception {
  const MockNetworkException(this.message, {this.isTimeout = false});
  final String message;
  final bool isTimeout;

  @override
  String toString() => 'MockNetworkException: $message';
}

/// The server answered with an error status (400, 401, 404, 409, 500, 503).
class MockApiException implements Exception {
  const MockApiException(this.statusCode, this.code, this.message);
  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'MockApiException($statusCode $code): $message';
}

enum MockFailureType { network, timeout, server, serviceUnavailable, unauthorized }

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

class MockApiConfig {
  const MockApiConfig({
    this.seed = 42,
    this.totalOrders = 237,
    this.minLatency = const Duration(milliseconds: 300),
    this.maxLatency = const Duration(milliseconds: 1500),
    this.failureRate = 0.10,
    this.requireAuth = false,
  });

  /// Zero latency, zero random failures. Use in unit tests.
  const MockApiConfig.testing({this.requireAuth = false})
    : seed = 42,
      totalOrders = 237,
      minLatency = Duration.zero,
      maxLatency = Duration.zero,
      failureRate = 0;

  final int seed;
  final int totalOrders;
  final Duration minLatency;
  final Duration maxLatency;

  /// Probability (0.0 to 1.0) that any request fails with a 500 or a timeout.
  final double failureRate;

  /// When true, every data call needs a valid `authToken` (see [MockOrderRepository.login]).
  final bool requireAuth;
}

// ---------------------------------------------------------------------------
// The mock API
// ---------------------------------------------------------------------------

class MockOrderRepository {
  MockOrderRepository({MockApiConfig config = const MockApiConfig()})
    : _config = config,
      _dataRandom = Random(config.seed),
      _chaosRandom = Random(config.seed + 1) {
    _orders = _generateOrders(config.totalOrders);
    _nextId = 1001 + config.totalOrders;
  }

  static const List<String> statuses = ['PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED'];
  static const List<String> sortFields = ['createdAt', 'amount', 'customer'];
  static const int maxLimit = 50;

  static const Map<String, List<String>> _allowedTransitions = {
    'PENDING': ['CONFIRMED', 'CANCELLED'],
    'CONFIRMED': ['SHIPPED', 'CANCELLED'],
    'SHIPPED': ['DELIVERED'],
    'DELIVERED': ['REFUNDED'],
    'CANCELLED': [],
    'REFUNDED': [],
  };

  final MockApiConfig _config;
  final Random _dataRandom;
  final Random _chaosRandom;
  late final List<Map<String, dynamic>> _orders;
  late int _nextId;

  bool _offline = false;
  final List<MockFailureType> _forcedFailures = [];
  int _tokenVersion = 1;
  String _validToken = 'mock-token-v1';
  int _requestCount = 0;
  int _refreshCallCount = 0;

  // =========================================================================
  // PUBLIC API (what the candidate calls)
  // =========================================================================

  /// GET /orders
  ///
  /// Returns:
  /// {
  ///   "data": [ {order}, ... ],
  ///   "page": 1, "limit": 20, "total": 237, "hasMore": true,
  ///   "serverTime": "2026-10-21T05:40:00.000Z"
  /// }
  ///
  /// Order shape:
  /// {
  ///   "id": "ORD-1237", "customer": "Ananya Iyer",
  ///   "customerEmail": "ananya.iyer@example.com" | null,
  ///   "city": "Bengaluru", "amount": 1499.5 | 2300 (int!), "currency": "INR",
  ///   "itemCount": 3, "status": "DELIVERED",
  ///   "createdAt": "2026-10-18T09:12:00.000Z",
  ///   "deliveredAt": "2026-10-20T11:00:00.000Z" | null
  /// }
  ///
  /// Throws [MockNetworkException] or [MockApiException].
  Future<Map<String, dynamic>> fetchOrders({
    int page = 1,
    int limit = 20,
    String? search,
    List<String>? statuses,
    double? minAmount,
    double? maxAmount,
    DateTime? fromDate,
    DateTime? toDate,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    String? authToken,
  }) async {
    await _simulateNetwork();
    _checkAuth(authToken);

    if (page < 1) {
      throw const MockApiException(400, 'INVALID_PAGE', 'page must be >= 1');
    }
    if (limit < 1 || limit > maxLimit) {
      throw const MockApiException(400, 'INVALID_LIMIT', 'limit must be between 1 and $maxLimit');
    }
    if (!sortFields.contains(sortBy)) {
      throw MockApiException(400, 'INVALID_SORT', 'sortBy must be one of $sortFields');
    }
    if (sortOrder != 'asc' && sortOrder != 'desc') {
      throw const MockApiException(400, 'INVALID_SORT_ORDER', "sortOrder must be 'asc' or 'desc'");
    }
    final unknown = (statuses ?? const <String>[]).where((s) => !MockOrderRepository.statuses.contains(s)).toList();
    if (unknown.isNotEmpty) {
      throw MockApiException(400, 'INVALID_STATUS', 'Unknown status: $unknown');
    }
    if (minAmount != null && maxAmount != null && minAmount > maxAmount) {
      throw const MockApiException(400, 'INVALID_RANGE', 'minAmount must be <= maxAmount');
    }
    if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
      throw const MockApiException(400, 'INVALID_RANGE', 'fromDate must be before toDate');
    }

    final statusSet = statuses?.toSet();
    final results =
        _orders
            .where(
              (o) => _matches(
                o,
                search: search,
                statuses: statusSet,
                minAmount: minAmount,
                maxAmount: maxAmount,
                fromDate: fromDate,
                toDate: toDate,
              ),
            )
            .toList()
          ..sort((a, b) {
            final cmp = _compare(a, b, sortBy);
            return sortOrder == 'asc' ? cmp : -cmp;
          });

    final total = results.length;
    final start = (page - 1) * limit;
    final pageItems = start >= total ? <Map<String, dynamic>>[] : results.sublist(start, min(start + limit, total));

    return {
      'data': pageItems.map(_copy).toList(),
      'page': page,
      'limit': limit,
      'total': total,
      'hasMore': start + limit < total,
      'serverTime': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// GET /orders/{id}. Throws 404 if not found.
  Future<Map<String, dynamic>> getOrderById(String id, {String? authToken}) async {
    await _simulateNetwork();
    _checkAuth(authToken);
    return _copy(_findOrThrow(id));
  }

  /// PATCH /orders/{id}/status. Allowed transitions:
  /// PENDING -> CONFIRMED | CANCELLED, CONFIRMED -> SHIPPED | CANCELLED,
  /// SHIPPED -> DELIVERED, DELIVERED -> REFUNDED. Anything else -> 409.
  Future<Map<String, dynamic>> updateOrderStatus(String id, String newStatus, {String? authToken}) async {
    await _simulateNetwork();
    _checkAuth(authToken);
    if (!statuses.contains(newStatus)) {
      throw MockApiException(400, 'INVALID_STATUS', 'Unknown status: $newStatus');
    }
    final order = _findOrThrow(id);
    final current = order['status'] as String;
    if (!_allowedTransitions[current]!.contains(newStatus)) {
      throw MockApiException(409, 'INVALID_TRANSITION', 'Cannot move $id from $current to $newStatus');
    }
    order['status'] = newStatus;
    if (newStatus == 'DELIVERED') {
      order['deliveredAt'] = DateTime.now().toUtc().toIso8601String();
    }
    return _copy(order);
  }

  /// POST /auth/login. Returns an access token (only matters when requireAuth = true).
  Future<String> login() async {
    await _delay();
    if (_offline) throw const MockNetworkException('No internet connection');
    return _validToken;
  }

  /// POST /auth/refresh. Each call invalidates the previous token, so parallel
  /// refresh calls make earlier tokens fail again. Check [refreshCallCount].
  Future<String> refreshToken() async {
    _refreshCallCount++;
    await _delay();
    if (_offline) throw const MockNetworkException('No internet connection');
    _rotateToken();
    return _validToken;
  }

  // =========================================================================
  // INTERVIEWER CONTROLS (use during twists; candidates should not need these)
  // =========================================================================

  /// Every request fails with MockNetworkException until [goOnline].
  void goOffline() => _offline = true;
  void goOnline() => _offline = false;
  bool get isOffline => _offline;

  /// The next [times] requests fail with [type], regardless of failureRate.
  void failNext(MockFailureType type, {int times = 1}) {
    for (var i = 0; i < times; i++) {
      _forcedFailures.add(type);
    }
  }

  /// Invalidates the current token. The next authenticated call returns 401 TOKEN_EXPIRED.
  void expireToken() => _rotateToken();

  /// Adds [count] brand-new orders (newest first in default sort). Use this while the
  /// candidate is on page 2+ to expose duplicate items from offset pagination.
  void insertNewOrders(int count) {
    for (var i = 0; i < count; i++) {
      _orders.add(_buildOrder(_nextId++, DateTime.now().toUtc()));
    }
  }

  /// Total data requests made. Reveals missing debounce or duplicate page loads.
  int get requestCount => _requestCount;

  /// Total refreshToken() calls. More than 1 per expiry = no refresh lock.
  int get refreshCallCount => _refreshCallCount;

  // =========================================================================
  // INTERNALS
  // =========================================================================

  Future<void> _delay() async {
    final minMs = _config.minLatency.inMilliseconds;
    final range = _config.maxLatency.inMilliseconds - minMs;
    final ms = minMs + (range > 0 ? _chaosRandom.nextInt(range + 1) : 0);
    await Future<void>.delayed(Duration(milliseconds: ms));
  }

  Future<void> _simulateNetwork() async {
    _requestCount++;
    await _delay();
    if (_offline) {
      throw const MockNetworkException('No internet connection');
    }
    if (_forcedFailures.isNotEmpty) {
      await _fail(_forcedFailures.removeAt(0));
    }
    if (_chaosRandom.nextDouble() < _config.failureRate) {
      await _fail(_chaosRandom.nextBool() ? MockFailureType.server : MockFailureType.timeout);
    }
  }

  Future<Never> _fail(MockFailureType type) async {
    switch (type) {
      case MockFailureType.network:
        throw const MockNetworkException('No internet connection');
      case MockFailureType.timeout:
        await Future<void>.delayed(const Duration(seconds: 2));
        throw const MockNetworkException('Request timed out', isTimeout: true);
      case MockFailureType.server:
        throw const MockApiException(500, 'INTERNAL_ERROR', 'Something went wrong');
      case MockFailureType.serviceUnavailable:
        throw const MockApiException(503, 'SERVICE_UNAVAILABLE', 'Service temporarily unavailable');
      case MockFailureType.unauthorized:
        throw const MockApiException(401, 'TOKEN_EXPIRED', 'Access token has expired');
    }
  }

  void _checkAuth(String? token) {
    if (!_config.requireAuth) return;
    if (token == null || token.isEmpty) {
      throw const MockApiException(401, 'UNAUTHORIZED', 'Missing auth token');
    }
    if (token != _validToken) {
      throw const MockApiException(401, 'TOKEN_EXPIRED', 'Access token has expired');
    }
  }

  void _rotateToken() {
    _tokenVersion++;
    _validToken = 'mock-token-v$_tokenVersion';
  }

  Map<String, dynamic> _findOrThrow(String id) {
    for (final o in _orders) {
      if (o['id'] == id) return o;
    }
    throw MockApiException(404, 'NOT_FOUND', 'Order $id not found');
  }

  Map<String, dynamic> _copy(Map<String, dynamic> o) => Map<String, dynamic>.from(o);

  bool _matches(
    Map<String, dynamic> o, {
    String? search,
    Set<String>? statuses,
    double? minAmount,
    double? maxAmount,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final q = search?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      final hit = (o['customer'] as String).toLowerCase().contains(q) || (o['id'] as String).toLowerCase().contains(q);
      if (!hit) return false;
    }
    if (statuses != null && statuses.isNotEmpty && !statuses.contains(o['status'])) {
      return false;
    }
    final amount = (o['amount'] as num).toDouble();
    if (minAmount != null && amount < minAmount) return false;
    if (maxAmount != null && amount > maxAmount) return false;
    final created = DateTime.parse(o['createdAt'] as String);
    if (fromDate != null && created.isBefore(fromDate)) return false;
    if (toDate != null && created.isAfter(toDate)) return false;
    return true;
  }

  int _compare(Map<String, dynamic> a, Map<String, dynamic> b, String sortBy) {
    final int cmp;
    switch (sortBy) {
      case 'amount':
        cmp = (a['amount'] as num).compareTo(b['amount'] as num);
      case 'customer':
        cmp = (a['customer'] as String).compareTo(b['customer'] as String);
      default:
        cmp = DateTime.parse(a['createdAt'] as String).compareTo(DateTime.parse(b['createdAt'] as String));
    }
    // Tie-break on numeric id so pagination order is stable.
    return cmp != 0 ? cmp : _idNum(a).compareTo(_idNum(b));
  }

  int _idNum(Map<String, dynamic> o) => int.parse((o['id'] as String).substring(4));

  // ---- Seed data ----------------------------------------------------------

  static const _firstNames = [
    'Aarav',
    'Vivaan',
    'Aditya',
    'Ananya',
    'Diya',
    'Ishaan',
    'Kavya',
    'Rohan',
    'Priya',
    'Arjun',
    'Sneha',
    'Rahul',
    'Neha',
    'Vikram',
    'Pooja',
    'Karthik',
    'Meera',
    'Siddharth',
    'Lakshmi',
    'Farhan',
  ];
  static const _lastNames = [
    'Sharma',
    'Verma',
    'Reddy',
    'Iyer',
    'Nair',
    'Gupta',
    'Patel',
    'Khan',
    'Singh',
    'Rao',
    'Mehta',
    'Das',
    'Joshi',
    'Menon',
    'Kulkarni',
  ];
  static const _cities = ['Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad', 'Chennai', 'Pune', 'Kolkata', 'Jaipur', 'Lucknow', 'Kochi'];
  // Weighted: DELIVERED 40%, SHIPPED 15%, CONFIRMED 15%, PENDING 15%, CANCELLED 10%, REFUNDED 5%.
  static const _statusWeights = {'DELIVERED': 40, 'SHIPPED': 15, 'CONFIRMED': 15, 'PENDING': 15, 'CANCELLED': 10, 'REFUNDED': 5};

  List<Map<String, dynamic>> _generateOrders(int count) {
    final base = DateTime.utc(2026, 10, 20, 18);
    final createdDates = List.generate(count, (_) => base.subtract(Duration(minutes: _dataRandom.nextInt(60 * 24 * 120))))..sort();
    // Ids increase with createdAt, like a real auto-increment.
    return [for (var i = 0; i < count; i++) _buildOrder(1001 + i, createdDates[i])];
  }

  Map<String, dynamic> _buildOrder(int idNum, DateTime createdAt) {
    final first = _firstNames[_dataRandom.nextInt(_firstNames.length)];
    final last = _lastNames[_dataRandom.nextInt(_lastNames.length)];
    final status = _weightedStatus();

    // Trap 1: ~25% of amounts are whole rupees and arrive as int, not double.
    final raw = (_dataRandom.nextInt(4980001) + 19900) / 100; // 199.00 to 49999.00
    final Object amount = _dataRandom.nextInt(4) == 0 ? raw.round() : raw;

    // Trap 2: ~10% of customers have no email.
    final String? email = _dataRandom.nextInt(10) == 0 ? null : '${first.toLowerCase()}.${last.toLowerCase()}@example.com';

    String? deliveredAt;
    if (status == 'DELIVERED') {
      final now = DateTime.now().toUtc();
      var d = createdAt.add(Duration(hours: 24 + _dataRandom.nextInt(24 * 6)));
      if (d.isAfter(now)) d = now;
      deliveredAt = d.toIso8601String();
    }

    return {
      'id': 'ORD-$idNum',
      'customer': '$first $last',
      'customerEmail': email,
      'city': _cities[_dataRandom.nextInt(_cities.length)],
      'amount': amount,
      'currency': 'INR',
      'itemCount': _dataRandom.nextInt(8) + 1,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt,
    };
  }

  String _weightedStatus() {
    final total = _statusWeights.values.fold<int>(0, (a, b) => a + b);
    var roll = _dataRandom.nextInt(total);
    for (final entry in _statusWeights.entries) {
      if (roll < entry.value) return entry.key;
      roll -= entry.value;
    }
    return 'PENDING';
  }
}
