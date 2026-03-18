import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;

import "../config/api.dart";
import "../constants/api/auth_endpoints.dart";
import "auth_storage.dart";
import "session_heartbeat_service.dart";

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

    // Keep the server session alive while the user is active.
    SessionHeartbeatService.instance.start();
  }

  Future<void> signOut() async {
    SessionHeartbeatService.instance.stop();
    await AuthStorage.clearSession();
    value = const AuthSessionState(status: AuthStatus.signedOut, displayName: "Guest");
  }

  /// Returns true when the current session is authenticated and has a non-empty access token.
  bool get hasValidToken =>
      value.isAuthenticated && (value.accessToken != null && value.accessToken!.isNotEmpty);

  /// If the token is missing/empty, clears the session and returns false.
  Future<bool> ensureValid() async {
    if (hasValidToken) return true;
    await expireSession();
    return false;
  }

  // ── Token refresh ─────────────────────────────────────────────────────────

  /// Coalesces concurrent refresh calls so only one request is in-flight at a time.
  Future<bool>? _pendingRefresh;

  /// Silently exchanges the stored refresh token for a new access token.
  /// Returns true and updates the session on success; returns false on failure.
  /// Never calls [expireSession] — callers are responsible for that.
  Future<bool> tryRefresh() {
    _pendingRefresh ??= _doRefresh().whenComplete(() => _pendingRefresh = null);
    return _pendingRefresh!;
  }

  Future<bool> _doRefresh() async {
    final refresh = value.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final res = await http
          .post(
            Api.url(AuthEndpoints.tokenRefresh),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"refresh": refresh}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess = json["access"] as String?;
        final newRefresh = (json["refresh"] as String?) ?? refresh;

        if (newAccess != null && newAccess.isNotEmpty) {
          value = value.copyWith(accessToken: newAccess, refreshToken: newRefresh);
          await AuthStorage.updateTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // ── Session expiry ────────────────────────────────────────────────────────

  /// Attempts a silent token refresh before signing out.
  /// If the refresh succeeds the session stays alive; if it fails [signOut] is called.
  /// This prevents aggressive logout caused by a 30-minute access-token expiry
  /// when the user still has a valid long-lived refresh token.
  Future<void> expireSession() async {
    if (value.isAuthenticated &&
        value.refreshToken != null &&
        value.refreshToken!.isNotEmpty) {
      if (await tryRefresh()) return;
    }
    await signOut();
  }
}
