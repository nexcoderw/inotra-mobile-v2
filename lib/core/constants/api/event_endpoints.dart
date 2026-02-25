final class EventEndpoints {
  EventEndpoints._();

  static const list = "api/events/";

  static String detail(String eventId) => "api/event/$eventId/";
  static String reviews(String eventId) => "api/event/$eventId/reviews/";
  static String addReview(String eventId) => "api/event/$eventId/review/add/";
}