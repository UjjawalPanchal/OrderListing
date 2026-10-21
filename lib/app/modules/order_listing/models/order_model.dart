class OrdersPage {
  final List<OrderModel> orders;
  final int page;
  final int total;
  final bool hasMore;

  const OrdersPage({required this.orders, required this.page, required this.total, required this.hasMore});
}

class OrderModel {
  final String id;
  final String customer;
  final String? customerEmail;
  final String city;
  final double amount;
  final String currency;
  final int itemCount;
  final String status;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.customer,
    this.customerEmail,
    required this.city,
    required this.amount,
    required this.currency,
    required this.itemCount,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      customer: map['customer'] as String,
      customerEmail: map['customerEmail'] as String?,
      city: map['city'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      itemCount: map['itemCount'] as int,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      deliveredAt: map['deliveredAt'] != null ? DateTime.parse(map['deliveredAt'] as String) : null,
    );
  }

  OrderModel copyWith({String? status, DateTime? deliveredAt}) {
    return OrderModel(
      id: id,
      customer: customer,
      customerEmail: customerEmail,
      city: city,
      amount: amount,
      currency: currency,
      itemCount: itemCount,
      status: status ?? this.status,
      createdAt: createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
