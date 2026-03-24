final class AppRoutes {
  AppRoutes._();

  // Splash
  static const splash = "/splash";

  // Auth
  static const login = "/login";
  static const register = "/register";
  static const verifyRegistrationOtp = "/verify-registration-otp";
  static const forgotPassword = "/forgot-password";
  static const resetPassword = "/reset-password";
  static const confirmPasswordReset = "/confirm-password-reset";

  // Main shell tabs
  static const home = "/home";
  static const listings = "/listings";
  static const aiChat = "/ai-chat";
  static const events = "/events";
  static const highlights = "/highlights";

  // Other pages
  static const tripPackages = "/trip-packages";
  static const tripPackageDetails = "/trip-package-details";
  static const listingDetails = "/listing-details";
  static const eventDetails = "/event-details";
  static const aiChatConversations = "/ai-chat-conversations";

  static const dashboard = "/dashboard";
  static const myEvents = "/events/my";
  static const myEventAdd = "/events/my/add";
  static const myEventEdit = "/events/my/edit";
  static const myEventDelete = "/events/my/delete";
  static const myEventSubmissions = "/events/my/submissions";
  static const myEventSubmissionDetail = "/events/my/submissions/detail";
  static const eventReview = "/events/review";
  static const eventTickets = "/events/tickets";
  static const myListings = "/listings/my";
  static const myListingAdd = "/listings/my/add";
  static const myListingEdit = "/listings/my/edit";
  static const myListingDelete = "/listings/my/delete";
  static const myListingSubmissions = "/listings/my/submissions";
  static const myListingSubmissionDetail = "/listings/my/submissions/detail";
  static const listingReviews = "/listings/reviews";
  static const listingBooking = "/listings/booking";
  static const tripReservations = "/trips/reservations";
  static const profile = "/profile";
  static const profileAccount = "/profile/account";
  static const profilePassword = "/profile/password";
  static const profileDanger = "/profile/danger";
  static const notifications = "/notifications";

  static const settings = "/settings";
  static const settingsTheme = "/settings/theme";
  static const settingsLanguage = "/settings/language";
  static const privacyPolicy = "/privacy-policy";
  static const termsConditions = "/terms-conditions";
  static const contactSupport = "/contact-support";
}
