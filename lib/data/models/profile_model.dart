class ProfileModel {
  final String id;
  final String companyId;
  final String? name;
  final String role;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.companyId,
    this.name,
    required this.role,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'owner',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || isOwner;
  bool get isSuperAdmin => role == 'super_admin';
}

