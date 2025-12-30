class OrderModel {
  final String id;
  final String companyId;
  final String? customerId;
  final DateTime orderDate;
  final String status; // 'open' | 'completed' | 'canceled'
  final double? totalAmount;
  final String? paymentType; // 'cash' | 'installments'
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.companyId,
    this.customerId,
    required this.orderDate,
    this.status = 'open',
    this.totalAmount,
    this.paymentType,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      customerId: json['customer_id'] as String?,
      orderDate: DateTime.parse(json['order_date'] as String),
      status: json['status'] as String? ?? 'open',
      totalAmount: json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : null,
      paymentType: json['payment_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'customer_id': customerId,
      'order_date': orderDate.toIso8601String().split('T')[0],
      'status': status,
      'total_amount': totalAmount,
      'payment_type': paymentType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'company_id': companyId,
      'customer_id': customerId,
      'order_date': orderDate.toIso8601String().split('T')[0],
      'status': status,
      'total_amount': totalAmount,
      'payment_type': paymentType,
    };
  }

  bool get isOpen => status == 'open';
  bool get isCompleted => status == 'completed';
  bool get isCanceled => status == 'canceled';
  bool get isCash => paymentType == 'cash';
  bool get isInstallments => paymentType == 'installments';
}

