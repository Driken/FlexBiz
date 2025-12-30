class CustomerModel {
  final String id;
  final String companyId;
  final String name;
  final String? phone;
  final String? email;
  final String? document;
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.phone,
    this.email,
    this.document,
    required this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      document: json['document'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'phone': phone,
      'email': email,
      'document': document,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'company_id': companyId,
      'name': name,
      'phone': phone,
      'email': email,
      'document': document,
    };
  }
}

