import "dart:async";
import "dart:convert";

import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;

import "../config/api.dart";
import "../constants/api/notification_endpoints.dart";
import "auth_session.dart";
import "local_notification_service.dart";

// ── Background message handler (must be top-level) ────────────────────────────

/// Called by FCM when a data-only message arrives while the app is terminated
/// or in the background.  Firebase is already initialised by main.dart before
/// this runs — we just need the handler registered; navigation happens via
/// [FirebaseMessaging.onMessageOpenedApp] when the user taps the notification.
@pragma("vm:entry-point")
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

// ── FcmService ────────────────────────────────────────────────────────────────

/// Manages Firebase Cloud Messaging for the app.
///
/// Responsibilities:
/// - Request notification permission on first launch.
/// - Obtain the FCM token and register it with the backend.
/// - Refresh the token whenever Firebase rotates it.
/// - Show a local notification banner for foreground messages.
/// - Navigate to the relevant screen when the user taps a notification.
/// - Deregister the token on logout so this device stops receiving pushes.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call once after the user is authenticated and Firebase is initialised.
  Future<void> initialize() async {
    if (kIsWeb) return;

    // Register the background handler.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Request permission (iOS shows a dialog; Android 13+ also needs this).
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get the current token and register it with the backend.
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);

    // Keep the token fresh — FCM may rotate it at any time.
    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Show a local notification banner while the app is in the foreground
    // (FCM does not display a system notification in this state by default).
    _foregroundSub =
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle tap when the app was in the background (notification was visible).
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Handle tap that launched the app from the terminated state.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);
  }

  /// Call when the user signs out to stop push notifications on this device.
  Future<void> deregister() async {
    if (kIsWeb) return;
    _foregroundSub?.cancel();
    _foregroundSub = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _deleteToken(token);
    } catch (_) {}
  }

  // ── Message handlers ───────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ??
        (message.data["kind"] == "CHAT" ? "New message" : "INOTRA");
    final body = message.notification?.body ?? "";
    LocalNotificationService.instance.showRawNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  static void _onNotificationTap(RemoteMessage message) {
    LocalNotificationService.navigate(jsonEncode(message.data));
  }

  // ── API ────────────────────────────────────────────────────────────────────

  Future<void> _registerToken(String token) async {
    try {
      final accessToken = AuthSession.instance.value.accessToken;
      if (accessToken == null || accessToken.isEmpty) return;
      await http
          .post(
            Api.url(NotificationEndpoints.fcmRegister),
            headers: {
              "Authorization": "Bearer $accessToken",
              "Content-Type": "application/json",
            },
            body: jsonEncode({"token": token}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> _deleteToken(String token) async {
    try {
      final accessToken = AuthSession.instance.value.accessToken;
      if (accessToken == null || accessToken.isEmpty) return;
      await http
          .delete(
            Api.url(NotificationEndpoints.fcmDelete),
            headers: {
              "Authorization": "Bearer $accessToken",
              "Content-Type": "application/json",
            },
            body: jsonEncode({"token": token}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
