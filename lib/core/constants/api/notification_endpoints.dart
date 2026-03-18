final class NotificationEndpoints {
  NotificationEndpoints._();

  static const list         = "api/me/notifications/";
  static const unreadCount  = "api/me/notifications/unread-count/";
  static const markAllRead  = "api/me/notifications/read-all/";
  static String markRead(String id) => "api/me/notifications/$id/read/";

  static const fcmRegister  = "api/me/fcm-token/";
  static const fcmDelete    = "api/me/fcm-token/delete/";
}
