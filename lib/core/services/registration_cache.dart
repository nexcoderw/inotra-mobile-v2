/// Lightweight in-memory cache to hand off data between auth screens.
class RegistrationCache {
  RegistrationCache._();

  static final RegistrationCache instance = RegistrationCache._();

  String? _email;

  String? get email => _email;

  void setEmail(String? value) {
    final trimmed = value?.trim();
    _email = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  void clear() => _email = null;
}
