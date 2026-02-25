final class AppRoutes {
  AppRoutes._();

  // Auth
  static const login = "/login";
  static const register = "/register";
  static const verifyRegistrationOtp = "/verify-registration-otp";
  static const forgotPassword = "/forgot-password";
  static const resetPassword = "/reset-password";
  static const confirmPasswordReset = "/confirm-password-reset";

  // Main
  static const home = "/home";
  static const tripPackages = "/trip-packages";
  static const tripPackageDetails = "/trip-package-details";
  static const listings = "/listings";
  static const listingDetails = "/listing-details";
  static const events = "/events";
  static const eventDetails = "/event-details";
  static const aiChat = "/ai-chat";
  static const aiChatConversations = "/ai-chat-conversations";
  static const highlights = "/highlights";
  static const profile = "/profile";
  static const notifications = "/notifications";
}