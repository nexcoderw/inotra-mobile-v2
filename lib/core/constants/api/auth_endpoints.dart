final class AuthEndpoints {
  AuthEndpoints._();

  static const googleLogin = "api/auth/google/login/";
  static const login = "api/auth/login/";
  static const logout = "api/auth/logout/";

  static const passwordResetRequest = "api/auth/password/reset/request/";
  static const passwordResetResend = "api/auth/password/reset/resend/";
  static const passwordResetConfirm = "api/auth/password/reset/confirm/";

  static const register = "api/auth/register/";
  static const registerVerify = "api/auth/register/verify/";

  static const me = "api/auth/me/";
  static const meUpdate = "api/auth/me/update/";
  static const mePasswordChange = "api/auth/me/password/change/";
  static const meDeactivate = "api/auth/me/deactivate/";
  static const meDeleteRequest = "api/auth/me/delete/request/";
  static const meLanguage = "api/auth/me/language/";

  /// Lightweight endpoint called every ~2 min to keep the session alive.
  static const heartbeat = "api/auth/heartbeat/";
}
