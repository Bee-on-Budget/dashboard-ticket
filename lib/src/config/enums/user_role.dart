enum UserRole {
  admin,
  user,
  unknown;

  static UserRole fromString(String role) {
    switch (role) {
      case "admin":
        return UserRole.admin;
      case "user":
        return UserRole.user;
      default:
        return UserRole.unknown;
    }
  }

  @override
  String toString(){
    return name[0].toUpperCase().substring(1);
  }
}