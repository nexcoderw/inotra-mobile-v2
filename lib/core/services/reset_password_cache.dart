/// Simple cache to hand off password reset data between screens.
class ResetPasswordCache {
  ResetPasswordCache._();

  static final ResetPasswordCache instance = ResetPasswordCache._();

  String? _email;
  String? _otp;

  String? get email => _email;
  String? get otp => _otp;

  void setEmail(String? value) {
    final trimmed = value?.trim();
    _email = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  void setOtp(String? value) {
    final trimmed = value?.trim();
    _otp = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  void clear() {
    _email = null;
    _otp = null;
  }
}
