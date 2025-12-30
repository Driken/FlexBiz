class AccountReceivableModel {
  final String id;
  final String companyId;
  final String? orderId;
  final String? customerId;
  final String? description;
  final DateTime? dueDate;
  final double amount;
  final String status; // 'open' | 'paid' | 'late'
  final DateTime? paymentDate;
  final DateTime createdAt;

  AccountReceivableModel({
    required this.id,
    required this.companyId,
    this.orderId,
    this.customerId,
    this.description,
    this.dueDate,
    required this.amount,
    this.status = 'open',
    this.paymentDate,
    required this.createdAt,
  });

  factory AccountReceivableModel.fromJson(Map<String, dynamic> json) {
    return AccountReceivableModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      orderId: json['order_id'] as String?,
      customerId: json['customer_id'] as String?,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'open',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'order_id': orderId,
      'customer_id': customerId,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'amount': amount,
      'status': status,
      'payment_date': paymentDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'company_id': companyId,
      'order_id': orderId,
      'customer_id': customerId,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'amount': amount,
      'status': status,
    };
  }

  bool get isOpen => status == 'open';
  bool get isPaid => status == 'paid';
  bool get isLate => status == 'late';

  bool get isOverdue {
    if (dueDate == null || isPaid) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}

