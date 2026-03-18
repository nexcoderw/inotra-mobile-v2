final class NotificationEndpoints {
  NotificationEndpoints._();

  static const list        = "api/me/notifications/";
  static const markAllRead = "api/me/notifications/read-all/";
  static String markRead(String id) => "api/me/notifications/$id/read/";
}
