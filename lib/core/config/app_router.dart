import "package:flutter/material.dart";

import "app_routes.dart";
import "../../features/main/presentation/layouts/main_shell.dart";

// Auth pages
import "../../features/auth/presentation/pages/login_page.dart";
import "../../features/auth/presentation/pages/register_page.dart";
import "../../features/auth/presentation/pages/verify_registration_otp_page.dart";
import "../../features/auth/presentation/pages/forgot_password_page.dart";
import "../../features/auth/presentation/pages/reset_password_page.dart";
import "../../features/auth/presentation/pages/confirm_password_reset_page.dart";

// Main pages
import "../../features/main/presentation/pages/home_page.dart";
import "../../features/main/presentation/pages/trip_packages_page.dart";
import "../../features/main/presentation/pages/trip_package_details_page.dart";
import "../../features/main/presentation/pages/listings_page.dart";
import "../../features/main/presentation/pages/listing_details_page.dart";
import "../../features/main/presentation/pages/events_page.dart";
import "../../features/main/presentation/pages/event_details_page.dart";
import "../../features/main/presentation/pages/ai_chat_page.dart";
import "../../features/main/presentation/pages/ai_chat_conversations_page.dart";
import "../../features/main/presentation/pages/profile_page.dart";
import "../../features/main/presentation/pages/notifications_page.dart";

final class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case AppRoutes.verifyRegistrationOtp:
        final email = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => VerifyRegistrationOtpPage(email: email),
        );

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      case AppRoutes.resetPassword:
        final email = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => ResetPasswordPage(email: email));

      case AppRoutes.confirmPasswordReset:
        final email = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ConfirmPasswordResetPage(email: email),
        );

      // Main tab shell routes (bottom nav visible only here)
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0));

      case AppRoutes.listings:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 1));

      case AppRoutes.aiChat:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 2));

      case AppRoutes.events:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 3));

      case AppRoutes.highlights:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 4));

      case AppRoutes.tripPackages:
        return MaterialPageRoute(builder: (_) => const TripPackagesPage());

      case AppRoutes.tripPackageDetails:
        final id = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => TripPackageDetailsPage(packageId: id),
        );

      case AppRoutes.listingDetails:
        final id = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ListingDetailsPage(placeId: id),
        );

      case AppRoutes.eventDetails:
        final id = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => EventDetailsPage(eventId: id),
        );

      case AppRoutes.aiChatConversations:
        return MaterialPageRoute(builder: (_) => const AiChatConversationsPage());

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Route not found")),
          ),
        );
    }
  }
}