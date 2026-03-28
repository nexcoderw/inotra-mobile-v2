import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";

import "../config/app_routes.dart";
import "../models/app_notification.dart";

// ── Background tap handler (top-level, required by flutter_local_notifications) ─

@pragma("vm:entry-point")
void _onBackgroundNotificationTap(NotificationResponse response) {
  LocalNotificationService.navigate(response.payload);
}

// ── Local Notification Service ────────────────────────────────────────────────

/// Wraps flutter_local_notifications.
/// Shows banners with sound + vibration on both Android and iOS.
/// Routes taps to the correct detail page via [navigatorKey].
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const _channelId = "inotra_high_importance";
  static const _channelName = "INOTRA Notifications";

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Attached to [MaterialApp.navigatorKey] so we can navigate from tap
  /// callbacks that have no BuildContext.
  static final navigatorKey = GlobalKey<NavigatorState>();

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (kIsWeb) return;

    const android = AndroidInitializationSettings("@mipmap/ic_launcher");
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onForegroundTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    if (Platform.isAndroid) {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Create the high-importance channel (idempotent — safe to call every launch)
      await impl?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description:
              "INOTRA real-time alerts for new listings, events, and trip packages.",
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
        ),
      );

      // Request POST_NOTIFICATIONS permission on Android 13+
      await impl?.requestNotificationsPermission();
    }
  }

  // ── Show a banner ──────────────────────────────────────────────────────────

  /// Shows a notification banner with arbitrary title/body and a raw payload
  /// map (encoded as JSON).  Used by [FcmService] for foreground FCM messages.
  Future<void> showRawNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      payload.hashCode.abs(),
      title,
      body.isNotEmpty ? body : null,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: "INOTRA real-time alerts",
          importance: Importance.max,
          priority: Priority.high,
          icon: "@mipmap/ic_launcher",
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showNotification(AppNotification notif) async {
    if (kIsWeb) return;

    await _plugin.show(
      // Stable int ID derived from the UUID — same notification won't appear twice
      notif.id.hashCode.abs(),
      notif.title,
      notif.body.isNotEmpty ? notif.body : null,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: "INOTRA real-time alerts",
          importance: Importance.max,
          priority: Priority.high,
          icon: "@mipmap/ic_launcher",
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Deep-link payload so taps can navigate to the right page
      payload: jsonEncode({"kind": notif.kind, "entity_id": notif.entityId}),
    );
  }

  // ── Tap handlers ───────────────────────────────────────────────────────────

  static void _onForegroundTap(NotificationResponse response) {
    navigate(response.payload);
  }

  /// Navigates to the screen indicated by [payload] (JSON-encoded data map).
  /// Public so [FcmService] can reuse it for FCM notification taps.
  static void navigate(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final kind = data["kind"] as String?;
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
        case "CHAT":
          if (entityId.isEmpty) {
            nav.pushNamed(AppRoutes.aiChat);
          } else {
            nav.pushNamed(
              AppRoutes.aiChatThread,
              arguments: {"threadId": entityId, "title": "Chat"},
            );
          }
      }
    } catch (_) {}
  }
}
