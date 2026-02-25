import "package:flutter/material.dart";

import "../services/auth_session.dart";
import "../../features/main/presentation/widgets/auth_dialog.dart";

/// Centralized route guard used by AppRouter to protect authenticated screens.
///
/// If the user is signed in, it returns a normal MaterialPageRoute that builds
/// the requested page. If the user is not signed in, it returns a DialogRoute
/// that shows the shared AuthDialog, leaving the current page visible beneath.
class AuthGuard {
  const AuthGuard._();

  static Route<dynamic> protect({
    required BuildContext context,
    required WidgetBuilder builder,
    required String featureLabel,
    String? description,
  }) {
    final authed = AuthSession.instance.value.isAuthenticated;
    if (authed) {
      return MaterialPageRoute(builder: builder);
    }

    final copy = description ??
        "Sign in or create an account to access $featureLabel and keep your experience in sync.";

    return DialogRoute(
      context: context,
      barrierDismissible: true,
      builder: (_) => AuthDialog(
        featureLabel: featureLabel,
        description: copy,
      ),
    );
  }
}
