class CompanyModel {
  final String id;
  final String name;
  final String? document;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    this.document,
    required this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      document: json['document'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'document': document,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

