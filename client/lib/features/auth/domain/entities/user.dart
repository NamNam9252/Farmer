enum UserRole {
  farmer('FARMER'),
  buyer('BUYER'),
  labor('LABOR'),
  expert('EXPERT'),
  admin('ADMIN');

  final String value;
  const UserRole(this.value);
}

class User {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final String status;
  final bool isEmailVerified;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.status,
    required this.isEmailVerified,
  });
}
