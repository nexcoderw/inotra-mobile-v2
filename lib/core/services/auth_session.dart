import "package:flutter/foundation.dart";

import "auth_storage.dart";

/// Lightweight auth session tracker used by the mobile app header.
enum AuthStatus { checking, signedOut, signedIn }

class AuthSessionState {
  final AuthStatus status;
  final String displayName;
  final Map<String, dynamic>? user;
  final String? accessToken;
  final String? refreshToken;
  final String theme;

  const AuthSessionState({
    required this.status,
    this.displayName = "Guest",
    this.user,
    this.accessToken,
    this.refreshToken,
    this.theme = "light",
  });

  bool get isAuthenticated => status == AuthStatus.signedIn;

  AuthSessionState copyWith({
    AuthStatus? status,
    String? displayName,
    Map<String, dynamic>? user,
    String? accessToken,
    String? refreshToken,
    String? theme,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      theme: theme ?? this.theme,
    );
  }
}

class AuthSession extends ValueNotifier<AuthSessionState> {
  AuthSession._()
      : super(const AuthSessionState(status: AuthStatus.checking, displayName: "Guest"));

  static final AuthSession instance = AuthSession._();

  /// Restore persisted session (tokens, user, theme).
  Future<void> restore() async {
    final saved = await AuthStorage.loadSession();
    if (saved == null) {
      value = const AuthSessionState(status: AuthStatus.signedOut, displayName: "Guest");
      return;
    }

    value = AuthSessionState(
      status: AuthStatus.signedIn,
      displayName: saved.user?["name"] ?? saved.user?["email"] ?? "User",
      user: saved.user,
      accessToken: saved.accessToken,
      refreshToken: saved.refreshToken,
      theme: saved.theme ?? "light",
    );
  }

  void signIn({
    required Map<String, dynamic> user,
    required String accessToken,
    required String refreshToken,
    String theme = "light",
  }) {
    final safeName = (user["name"] as String?)?.trim();

    value = AuthSessionState(
      status: AuthStatus.signedIn,
      displayName: (safeName?.isNotEmpty ?? false) ? safeName! : (user["email"] ?? "User"),
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      theme: theme,
    );
  }

  Future<void> signOut() async {
    await AuthStorage.clearSession();
    value = const AuthSessionState(status: AuthStatus.signedOut, displayName: "Guest");
  }
}
