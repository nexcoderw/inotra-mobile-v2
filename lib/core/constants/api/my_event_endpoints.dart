final class MyEventEndpoints {
  MyEventEndpoints._();

  static const submissions = "api/me/events/submissions/";
  static const submissionsAdd = "api/me/events/submissions/add/";
  static const reviews = "api/me/events/reviews/";
  static const list = "api/me/events/";

  static String submissionDetail(String submissionId) =>
      "api/me/events/submissions/$submissionId/";
  static String submissionDelete(String submissionId) =>
      "api/me/events/submissions/$submissionId/delete/";

  static String detail(String eventId) => "api/me/events/$eventId/";
  static String update(String eventId) => "api/me/events/$eventId/update/";
  static String delete(String eventId) => "api/me/events/$eventId/delete/";
}