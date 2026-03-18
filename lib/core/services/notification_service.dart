import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

import "../config/api.dart";
import "../constants/api/notification_endpoints.dart";
import "../models/app_notification.dart";
import "auth_session.dart";
import "device_info_service.dart";
import "local_notification_service.dart";

/// Manages the notifications list.
/// - Persists to local [SharedPreferences] so the inbox works offline.
/// - Polls the backend API to detect new notifications and shows banners
///   via [LocalNotificationService] for any that haven't been seen before.
///
/// Expose via [ChangeNotifierProvider] so any widget can react to updates.
class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _kStorageKey = "inotra_notifications_v1";

  // ── State ─────────────────────────────────────────────────────────────────

  List<AppNotification> _notifications = [];
  bool _loading     = false;
  bool _initialized = false;

  List<AppNotification> get notifications => _notifications;
  int  get unreadCount  => _notifications.where((n) => !n.isRead).length;
  bool get loading      => _loading;
  bool get initialized  => _initialized;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Loads persisted notifications from local storage.
  /// Call once at startup so the inbox is ready before the first API fetch.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kStorageKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        _notifications = list.map(AppNotification.fromJson).toList();
        _initialized   = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetches the notification list from the server.
  /// - Notifications not yet in local storage are shown as banners.
  /// - The merged list is persisted locally so the inbox works offline.
  Future<void> fetch() async {
    if (!_isAuthed) return;
    _loading = true;
    notifyListeners();

    try {
      final res = await http
          .get(Api.url(NotificationEndpoints.list), headers: _authHeaders)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final json      = jsonDecode(res.body) as Map<String, dynamic>;
        final serverList = (json["results"] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();

        // Detect notifications we haven't stored locally yet → show banner
        final localIds = _notifications.map((n) => n.id).toSet();
        for (final notif in serverList) {
          if (!localIds.contains(notif.id)) {
            LocalNotificationService.instance.showNotification(notif);
          }
        }

        // Server is source of truth for content; preserve local read state
        // for any notification the server still considers unread but we've
        // already marked read offline.
        final localReadIds = _notifications
            .where((n) => n.isRead)
            .map((n) => n.id)
            .toSet();

        _notifications = serverList.map((n) {
          if (localReadIds.contains(n.id)) return n.copyWith(isRead: true);
          return n;
        }).toList();

        _initialized = true;
        await _persist();
      }
    } catch (_) {
      // Network errors are silently ignored — local data is still shown
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Marks one notification as read locally + on the server.
  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].isRead) return;

    // Optimistic update
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    notifyListeners();
    await _persist();

    // Sync to backend (fire-and-forget)
    try {
      await http
          .post(Api.url(NotificationEndpoints.markRead(id)), headers: _authHeaders)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Marks all notifications as read locally + on the server.
  Future<void> markAllRead() async {
    if (_notifications.every((n) => n.isRead)) return;

    // Optimistic update
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _persist();

    try {
      await http
          .post(Api.url(NotificationEndpoints.markAllRead), headers: _authHeaders)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Clears all data when the user signs out.
  void clear() {
    _notifications = [];
    _initialized   = false;
    _loading       = false;
    notifyListeners();
    _clearStorage();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  bool get _isAuthed => AuthSession.instance.hasValidToken;

  Map<String, String> get _authHeaders => {
        "Authorization": "Bearer ${AuthSession.instance.value.accessToken}",
        "Content-Type": "application/json",
        ...DeviceInfoService.instance.asHeader,
      };

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_kStorageKey, json);
    } catch (_) {}
  }

  Future<void> _clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kStorageKey);
    } catch (_) {}
  }
}
