enum UserRole { farmer, buyer, labor, expert, admin }

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
