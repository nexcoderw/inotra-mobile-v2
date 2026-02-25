final class HighlightEndpoints {
  HighlightEndpoints._();

  static const list = "api/highlights/";

  static String likeToggle(String highlightId) =>
      "api/highlight/$highlightId/like/";
  static String addComment(String highlightId) =>
      "api/highlight/$highlightId/comment/add/";
  static String comments(String highlightId) =>
      "api/highlight/$highlightId/comments/";
  static String share(String highlightId) =>
      "api/highlight/$highlightId/share/";
}