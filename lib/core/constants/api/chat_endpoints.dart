final class ChatEndpoints {
  ChatEndpoints._();

  static const threads = "api/me/chats/threads/";
  static const startThread = "api/me/chats/threads/start/";
  static const sendDirect = "api/me/chats/send/";

  static String messages(String threadId) =>
      "api/me/chats/threads/$threadId/messages/";

  static String sendMessage(String threadId) =>
      "api/me/chats/threads/$threadId/messages/send/";

  static String markRead(String threadId) =>
      "api/me/chats/threads/$threadId/read/";

  static String endThread(String threadId) =>
      "api/me/chats/threads/$threadId/end/";

  static String threadStatus(String threadId) =>
      "api/me/chats/threads/$threadId/status/";

  // ── AI onboarding ───────────────────────────────────────────────────────────
  static const aiLanguages = "api/me/chats/ai/languages/";
  static const aiStart = "api/me/chats/ai/start/";
  static String aiMessage(String threadId) =>
      "api/me/chats/ai/$threadId/message/";
}
