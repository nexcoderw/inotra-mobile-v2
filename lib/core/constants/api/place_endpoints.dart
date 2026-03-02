final class PlaceEndpoints {
  PlaceEndpoints._();

  static const list = "api/places/";

  static String detail(String placeId) => "api/place/$placeId/";
  static String book(String placeId) => "api/place/$placeId/book/";
  static String reviews(String placeId) => "api/place/$placeId/reviews/";
  static String addReview(String placeId) => "api/place/$placeId/add/";
  static String reportReview(String placeId, String reviewId) => "api/place/$placeId/review/$reviewId/report/";
}
