class AccountPayableModel {
  final String id;
  final String companyId;
  final String? supplierName;
  final String? description;
  final DateTime? dueDate;
  final double amount;
  final String status; // 'open' | 'paid' | 'late'
  final DateTime? paymentDate;
  final DateTime createdAt;

  AccountPayableModel({
    required this.id,
    required this.companyId,
    this.supplierName,
    this.description,
    this.dueDate,
    required this.amount,
    this.status = 'open',
    this.paymentDate,
    required this.createdAt,
  });

  factory AccountPayableModel.fromJson(Map<String, dynamic> json) {
    return AccountPayableModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      supplierName: json['supplier_name'] as String?,
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
      'supplier_name': supplierName,
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
      'supplier_name': supplierName,
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

