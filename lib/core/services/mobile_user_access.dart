final class MobileUserAccess {
  MobileUserAccess._();

  static const allowedRole = "USER";

  static bool isAllowed(Map<String, dynamic>? user) {
    return normalizedRole(user) == allowedRole;
  }

  static String normalizedRole(Map<String, dynamic>? user) {
    return (user?["role"] ?? "").toString().trim().toUpperCase();
  }
}
