import "package:flutter/foundation.dart";

/// Lightweight auth session tracker used by the mobile app header.
///
/// Mirrors the web navbar's idea of checking the local session first, then
/// flipping between signed-out and signed-in states. Storage of real tokens
/// can be wired in later without changing the widgets that listen to it.
enum AuthStatus { checking, signedOut, signedIn }

class AuthSessionState {
  final AuthStatus status;
  final String displayName;

  const AuthSessionState({
    required this.status,
    this.displayName = "Guest",
  });

  bool get isAuthenticated => status == AuthStatus.signedIn;

  AuthSessionState copyWith({
    AuthStatus? status,
    String? displayName,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
    );
  }
}

class AuthSession extends ValueNotifier<AuthSessionState> {
  AuthSession._()
      : super(const AuthSessionState(status: AuthStatus.checking, displayName: "Guest"));

  static final AuthSession instance = AuthSession._();

  /// Placeholder restore hook; will load persisted session once available.
  Future<void> restore() async {
    value = const AuthSessionState(status: AuthStatus.signedOut, displayName: "Guest");
  }

  void signIn({String? displayName}) {
    final safeName = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : "User";

    value = AuthSessionState(
      status: AuthStatus.signedIn,
      displayName: safeName,
    );
  }

  void signOut() {
    value = const AuthSessionState(status: AuthStatus.signedOut, displayName: "Guest");
  }
}
