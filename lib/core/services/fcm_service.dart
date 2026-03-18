import "dart:convert";
import "dart:io";

import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:http/http.dart" as http;

import "../config/api.dart";
import "../constants/api/notification_endpoints.dart";
import "auth_session.dart";
import "device_info_service.dart";
import "notification_service.dart";

// ── Background message handler (top-level, required by FCM) ──────────────────

@pragma("vm:entry-point")
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // Background messages are handled by the system notification tray.
  // No additional work needed here.
}

// ── FCM Service ───────────────────────────────────────────────────────────────

/// Handles Firebase Cloud Messaging:
/// - Requests notification permissions
/// - Gets & registers the device FCM token with the backend
/// - Displays foreground banners via flutter_local_notifications
/// - Routes notification taps to the correct detail page
class FCMService {
  FCMService._();

  static final FCMService instance = FCMService._();

  static const _channelId   = "inotra_high_importance";
  static const _channelName = "INOTRA Notifications";

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _fcm                = FirebaseMessaging.instance;

  /// Global navigator key — set once in app.dart so FCMService can navigate
  /// without a BuildContext.
  static final navigatorKey = GlobalKey<NavigatorState>();

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    // Request permissions (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS foreground presentation options
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: false, // We show our own banner via flutter_local_notifications
      badge: true,
      sound: true,
    );

    // Initialise flutter_local_notifications
    await _initLocalNotifications();

    // Register token now and whenever it refreshes
    await _registerToken();
    _fcm.onTokenRefresh.listen((_) => _registerToken());

    // Foreground FCM message → show local banner
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background/notification-tray tap while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTap);

    // App launched from a terminated state via notification tap
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onMessageTap(initial);
  }

  /// Call on logout to deactivate this device token.
  Future<void> deregisterToken() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    final accessToken = AuthSession.instance.value.accessToken;
    if (accessToken == null || accessToken.isEmpty) return;
    try {
      await http.delete(
        Api.url(NotificationEndpoints.fcmDelete),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          ...DeviceInfoService.instance.asHeader,
        },
        body: jsonEncode({"token": token}),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings("@mipmap/ic_launcher");
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: "INOTRA real-time alerts for new listings, events, and trip packages.",
        importance: Importance.max,
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _registerToken() async {
    final token       = await _fcm.getToken();
    final accessToken = AuthSession.instance.value.accessToken;
    if (token == null || accessToken == null || accessToken.isEmpty) return;

    try {
      await http.post(
        Api.url(NotificationEndpoints.fcmRegister),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          ...DeviceInfoService.instance.asHeader,
        },
        body: jsonEncode({
          "token": token,
          "device_name": DeviceInfoService.instance.deviceName,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  void _onForegroundMessage(RemoteMessage message) {
    // Bump the in-app badge immediately
    NotificationService.instance.incrementUnread();

    final notification = message.notification;
    if (notification == null) return;

    // Show a local banner since FCM suppresses foreground notifications
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: "INOTRA real-time alerts",
          importance: Importance.max,
          priority: Priority.high,
          icon: "@mipmap/ic_launcher",
          largeIcon: notification.android?.imageUrl != null
              ? DrawableResourceAndroidBitmap(notification.android!.imageUrl!)
              : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Encode deep-link data as JSON payload
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (_) {}
  }

  void _onMessageTap(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  /// Navigates to the correct detail page based on the notification payload.
  void _navigateFromData(Map<String, dynamic> data) {
    final kind     = data["kind"]      as String?;
    final entityId = data["entity_id"] as String?;
    if (kind == null || entityId == null) return;

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (kind) {
      case "PLACE":
        nav.pushNamed("/listing-details", arguments: entityId);
      case "EVENT":
        nav.pushNamed("/event-details", arguments: entityId);
      case "PACKAGE":
        nav.pushNamed("/trip-package-details", arguments: entityId);
    }
  }
}
