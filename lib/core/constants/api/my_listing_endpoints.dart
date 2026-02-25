final class MyListingEndpoints {
  MyListingEndpoints._();

  static const list = "api/me/listings/";
  static const submissions = "api/me/listings/submissions/";
  static const submissionsAdd = "api/me/listings/submissions/add/";
  static const reviews = "api/me/listings/reviews/";
  static const bookings = "api/me/listings/bookings/";

  static String detail(String placeId) => "api/me/listings/$placeId/";
  static String update(String placeId) => "api/me/listings/$placeId/update/";
  static String delete(String placeId) => "api/me/listings/$placeId/delete/";

  static String submissionDetail(String submissionId) =>
      "api/me/listings/submissions/$submissionId/";
  static String submissionDelete(String submissionId) =>
      "api/me/listings/submissions/$submissionId/delete/";

  static String bookingCancel(String bookingId) =>
      "api/me/listings/bookings/$bookingId/cancel/";
}