import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserModel {
  final String email;
  final bool active;
  final String role;

  const AdminUserModel({
    required this.email,
    required this.active,
    required this.role,
  });

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminUserModel(
      email: doc.id.toLowerCase(),
      active: data['active'] as bool? ?? false,
      role: data['role'] as String? ?? 'admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'active': active,
      'role': role,
    };
  }
}
