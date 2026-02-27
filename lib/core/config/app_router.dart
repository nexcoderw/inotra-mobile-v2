import "package:flutter/material.dart";

// Auth
import "../../features/auth/presentation/pages/confirm_password_reset_page.dart";
import "../../features/auth/presentation/pages/forgot_password_page.dart";
import "../../features/auth/presentation/pages/login_page.dart";
import "../../features/auth/presentation/pages/register_page.dart";
import "../../features/auth/presentation/pages/reset_password_page.dart";
import "../../features/auth/presentation/pages/verify_registration_otp_page.dart";

// Shell and main tabs
import "../../features/main/presentation/layouts/main_shell.dart";

// AI chat
import "../../features/main/presentation/pages/ai_chat_conversations_page.dart";

// Discover & details
import "../../features/main/presentation/pages/event_details_page.dart";

// Listings details
import "../../features/main/presentation/pages/listing_details_page.dart";

// Trip packages
import "../../features/main/presentation/pages/trip_packages_page.dart";
import "../../features/main/presentation/pages/trip_package_details_page.dart";

// Me area (dashboard, profile, settings)
import "../../features/me/presentation/pages/dashboard_page.dart";
import "../../features/me/presentation/pages/events/event_review_page.dart";
import "../../features/me/presentation/pages/events/event_tickets_page.dart";
import "../../features/me/presentation/pages/events/my_event_submissions_page.dart";
import "../../features/me/presentation/pages/events/my_events_page.dart";
import "../../features/me/presentation/pages/listings/listing_booking_page.dart";
import "../../features/me/presentation/pages/listings/listing_reviews_page.dart";
import "../../features/me/presentation/pages/listings/my_listing_submissions_page.dart";
import "../../features/me/presentation/pages/listings/my_listings_page.dart";
import "../../features/me/presentation/pages/profile/profile_account_details_page.dart";
import "../../features/me/presentation/pages/profile/profile_change_password_page.dart";
import "../../features/me/presentation/pages/profile/profile_danger_zone_page.dart";
import "../../features/me/presentation/pages/profile_page.dart";
import "../../features/me/presentation/pages/settings/settings_language_page.dart";
import "../../features/me/presentation/pages/settings/settings_page.dart";
import "../../features/me/presentation/pages/settings/settings_theme_page.dart";
import "../../features/main/presentation/pages/notifications_page.dart";

// Translations
import "../../i18n/lang.dart";
import "../../i18n/translations.dart";

// Guards
import "../guards/auth_guard.dart";

// Routes
import "app_routes.dart";

final class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final lang = currentLangSync();

    switch (settings.name) {
      // -------------------
      // Auth
      // -------------------
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case AppRoutes.verifyRegistrationOtp:
        return MaterialPageRoute(builder: (_) => const ConfirmRegistrationOtpPage());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case AppRoutes.resetPassword:
        final email = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => ResetPasswordPage(email: email));
      case AppRoutes.confirmPasswordReset:
        final email = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => ConfirmPasswordResetPage(email: email));

      // -------------------
      // Main tab shell routes (bottom nav visible only here)
      // -------------------
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0));
      case AppRoutes.listings:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 1));
      case AppRoutes.aiChat:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.ai_chat"),
          description: null,
          builder: (_) => const MainShell(initialIndex: 2),
        );
      case AppRoutes.events:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 3));
      case AppRoutes.highlights:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 4));

      // -------------------
      // Discover & details
      // -------------------
      case AppRoutes.tripPackages:
        return MaterialPageRoute(builder: (_) => const TripPackagesPage());
      case AppRoutes.tripPackageDetails:
        final id = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => TripPackageDetailsPage(packageId: id));
      case AppRoutes.listingDetails:
        final id = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => ListingDetailsPage(placeId: id));
      case AppRoutes.eventDetails:
        final id = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => EventDetailsPage(eventId: id));
      case AppRoutes.aiChatConversations:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.ai_chat"),
          description: null,
          builder: (_) => const AiChatConversationsPage(),
        );

      // -------------------
      // Dashboard & profile
      // -------------------
      case AppRoutes.dashboard:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.dashboard"),
          description: null,
          builder: (_) => const DashboardPage(),
        );
      case AppRoutes.myEvents:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.my_events"),
          description: null,
          builder: (_) => const MyEventsPage(),
        );
      case AppRoutes.myEventSubmissions:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.my_event_submissions"),
          description: null,
          builder: (_) => const MyEventSubmissionsPage(),
        );
      case AppRoutes.eventReview:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.event_review"),
          description: null,
          builder: (_) => const EventReviewPage(),
        );
      case AppRoutes.eventTickets:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.event_tickets"),
          description: null,
          builder: (_) => const EventTicketsPage(),
        );
      case AppRoutes.myListings:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.my_listings"),
          description: null,
          builder: (_) => const MyListingsPage(),
        );
      case AppRoutes.myListingSubmissions:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.my_listing_submissions"),
          description: null,
          builder: (_) => const MyListingSubmissionsPage(),
        );
      case AppRoutes.listingReviews:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.listing_reviews"),
          description: null,
          builder: (_) => const ListingReviewsPage(),
        );
      case AppRoutes.listingBooking:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.listing_booking"),
          description: null,
          builder: (_) => const ListingBookingPage(),
        );
      case AppRoutes.profile:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.profile"),
          description: null,
          builder: (_) => const ProfilePage(),
        );
      case AppRoutes.profileAccount:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.profile"),
          description: null,
          builder: (_) => const ProfileAccountDetailsPage(),
        );
      case AppRoutes.profilePassword:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.profile"),
          description: null,
          builder: (_) => const ProfileChangePasswordPage(),
        );
      case AppRoutes.profileDanger:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.profile"),
          description: null,
          builder: (_) => const ProfileDangerZonePage(),
        );

      // -------------------
      // Notifications
      // -------------------
      case AppRoutes.notifications:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.notifications"),
          description: null,
          builder: (_) => const NotificationsPage(),
        );

      // -------------------
      // Settings
      // -------------------
      case AppRoutes.settings:
        return AuthGuard.protect(
          featureLabel: t(lang, "nav.settings"),
          description: null,
          builder: (_) => const SettingsPage(),
        );
      case AppRoutes.settingsTheme:
        return AuthGuard.protect(
          featureLabel: t(lang, "settings.theme"),
          description: null,
          builder: (_) => const SettingsThemePage(),
        );
      case AppRoutes.settingsLanguage:
        return AuthGuard.protect(
          featureLabel: t(lang, "settings.language"),
          description: null,
          builder: (_) => const SettingsLanguagePage(),
        );

      // -------------------
      // Fallback
      // -------------------
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text(t(lang, "common.not_found"))),
          ),
        );
    }
  }
}
