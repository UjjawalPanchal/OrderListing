/*
* Created by ujjawal on 21/10/26.
*/
import 'package:demo_test_project/app/modules/order_listing/models/order_model.dart';
import 'package:demo_test_project/task.dart';

class OrderRepository {
  OrderRepository({MockOrderRepository? mockRepo}) : _repo = mockRepo ?? MockOrderRepository();

  final MockOrderRepository _repo;

  Future<OrdersPage> fetchOrders({
    int page = 1,
    int limit = 20,
    String? search,
    List<String>? statuses,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final raw = await _repo.fetchOrders(
      page: page,
      limit: limit,
      search: search?.isEmpty == true ? null : search,
      statuses: statuses?.isEmpty == true ? null : statuses,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    final data = (raw['data'] as List<dynamic>).map((e) => OrderModel.fromMap(e as Map<String, dynamic>)).toList();

    return OrdersPage(orders: data, page: raw['page'] as int, total: raw['total'] as int, hasMore: raw['hasMore'] as bool);
  }

  Future<OrderModel> getOrderById(String id) async {
    final raw = await _repo.getOrderById(id);
    return OrderModel.fromMap(raw);
  }

  Future<OrderModel> updateOrderStatus(String id, String newStatus) async {
    final raw = await _repo.updateOrderStatus(id, newStatus);
    return OrderModel.fromMap(raw);
  }
}
