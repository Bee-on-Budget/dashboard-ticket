enum UserRole {
  admin,
  user,
  accountent,
  unknown;

  static UserRole fromString(String? role) {
    switch (role?.trim().toLowerCase()) {
      case "admin":
        return UserRole.admin;
      case "user":
        return UserRole.user;
      case "accountent":
      case "accountant":
        return UserRole.accountent;
      default:
        return UserRole.unknown;
    }
  }

  String get storageValue => name;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.user:
        return 'User';
      case UserRole.accountent:
        return 'Accountent';
      case UserRole.unknown:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return displayName;
  }
}
