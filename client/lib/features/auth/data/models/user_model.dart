import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: _parseRole(json['role'] ?? ''),
    );
  }

  static UserRole _parseRole(String roleStr) {
    switch (roleStr.toUpperCase()) {
      case 'BUYER':
        return UserRole.buyer;
      case 'LABOR':
        return UserRole.labor;
      case 'EXPERT':
        return UserRole.expert;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.farmer;
    }
  }

  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.buyer:
        return 'BUYER';
      case UserRole.labor:
        return 'LABOR';
      case UserRole.expert:
        return 'EXPERT';
      case UserRole.admin:
        return 'ADMIN';
      default:
        return 'FARMER';
    }
  }
}
