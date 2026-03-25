import "dart:async";

import "package:flutter/widgets.dart";
import "package:http/http.dart" as http;

import "../config/api.dart";
import "../constants/api/auth_endpoints.dart";
import "auth_session.dart";

/// Sends a lightweight ``POST /api/auth/heartbeat/`` every [_interval] while
/// the user is authenticated.
///
/// The server's ``AuditSessionMiddleware`` updates ``last_activity_at`` on the
/// active session whenever it receives a valid Bearer token, so the admin
/// real-time dashboard always shows an accurate count of users currently using
/// the app.
///
/// Usage:
/// ```dart
/// // Start when the user logs in:
/// SessionHeartbeatService.instance.start();
///
/// // Stop when the user logs out or the app goes to the background:
/// SessionHeartbeatService.instance.stop();
/// ```
class SessionHeartbeatService with WidgetsBindingObserver {
  SessionHeartbeatService._();

  static final SessionHeartbeatService instance = SessionHeartbeatService._();

  static const _interval = Duration(minutes: 2);

  Timer? _timer;
  bool _enabled = false;
  bool _observingLifecycle = false;

  /// Start the periodic heartbeat.  Safe to call multiple times — any existing
  /// timer is cancelled before a new one is created.
  void start() {
    _enabled = true;
    _ensureLifecycleObserver();
    _startTimerIfNeeded();
  }

  /// Stop the heartbeat (call on logout or when the app goes to background).
  void stop() {
    _enabled = false;
    _cancelTimer();
    _removeLifecycleObserver();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startTimerIfNeeded();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cancelTimer();
        break;
    }
  }

  Future<void> _ping() async {
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      stop();
      return;
    }

    try {
      await http
          .post(
            Api.url(AuthEndpoints.heartbeat),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Silently ignore — a missed heartbeat is acceptable; the session will
      // auto-expire after the configured idle threshold (30 minutes).
    }
  }

  void _startTimerIfNeeded() {
    if (!_enabled || _timer != null) return;

    // Fire immediately so the session is touched as soon as the user logs in
    // or the app returns to the foreground, then continue at a fixed interval.
    _ping();
    _timer = Timer.periodic(_interval, (_) => _ping());
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  void _removeLifecycleObserver() {
    if (!_observingLifecycle) return;
    WidgetsBinding.instance.removeObserver(this);
    _observingLifecycle = false;
  }
}
