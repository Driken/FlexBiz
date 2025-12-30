class ItemModel {
  final String id;
  final String companyId;
  final String name;
  final String type; // 'product' | 'service'
  final double? price;
  final bool isActive;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.type,
    this.price,
    this.isActive = true,
    required this.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'type': type,
      'price': price,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'company_id': companyId,
      'name': name,
      'type': type,
      'price': price,
      'is_active': isActive,
    };
  }

  bool get isProduct => type == 'product';
  bool get isService => type == 'service';
}

