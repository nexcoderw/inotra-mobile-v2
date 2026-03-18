import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;

import "../config/api.dart";
import "../constants/api/notification_endpoints.dart";
import "../models/app_notification.dart";
import "auth_session.dart";
import "device_info_service.dart";

/// Manages the notifications list and unread badge count.
/// Expose via [ChangeNotifierProvider] so any widget can react to updates.
class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  // ── State ────────────────────────────────────────────────────────────────

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;
  bool _initialized = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  bool get initialized => _initialized;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetches the notification list from the server.
  /// Safe to call multiple times; skips if not authenticated.
  Future<void> fetch() async {
    if (!_isAuthed) return;
    _loading = true;
    notifyListeners();

    try {
      final res = await http
          .get(
            Api.url(NotificationEndpoints.list),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (json["results"] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();

        _notifications = results;
        _unreadCount   = json["unread_count"] as int? ?? _countUnread(results);
        _initialized   = true;
      }
    } catch (_) {
      // Network errors are silently ignored — stale data is fine
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetches only the unread count (lightweight, for badge refresh).
  Future<void> refreshUnreadCount() async {
    if (!_isAuthed) return;
    try {
      final res = await http
          .get(
            Api.url(NotificationEndpoints.unreadCount),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final count = json["unread_count"] as int? ?? _unreadCount;
        if (count != _unreadCount) {
          _unreadCount = count;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Marks one notification as read locally + on the server.
  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    if (_notifications[idx].isRead) return;

    // Optimistic update
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    // Persist on server (fire-and-forget)
    try {
      await http
          .post(
            Api.url(NotificationEndpoints.markRead(id)),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Marks all notifications as read locally + on the server.
  Future<void> markAllRead() async {
    final hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    // Optimistic update
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount   = 0;
    notifyListeners();

    try {
      await http
          .post(
            Api.url(NotificationEndpoints.markAllRead),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Bumps the unread badge by 1 (called by FCMService on foreground push).
  void incrementUnread() {
    _unreadCount++;
    notifyListeners();
  }

  /// Clears all data when the user signs out.
  void clear() {
    _notifications  = [];
    _unreadCount    = 0;
    _initialized    = false;
    _loading        = false;
    notifyListeners();
  }

  // ── Internals ────────────────────────────────────────────────────────────

  bool get _isAuthed => AuthSession.instance.hasValidToken;

  Map<String, String> get _authHeaders => {
        "Authorization": "Bearer ${AuthSession.instance.value.accessToken}",
        "Content-Type": "application/json",
        ...DeviceInfoService.instance.asHeader,
      };

  int _countUnread(List<AppNotification> list) =>
      list.where((n) => !n.isRead).length;
}
