enum UserRole { customer, admin, delivery }

class AppUser {
  final String username;
  final String password;
  final UserRole role;

  const AppUser({
    required this.username,
    required this.password,
    required this.role,
  });
}

/// Hardcoded users for now. Same password for everyone: "password".
const List<AppUser> kUsers = [
  AppUser(username: 'customer', password: 'password', role: UserRole.customer),
  AppUser(username: 'admin', password: 'password', role: UserRole.admin),
  AppUser(username: 'delivery', password: 'password', role: UserRole.delivery),
];
