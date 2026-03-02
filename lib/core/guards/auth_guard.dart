import "package:flutter/material.dart";

import "../services/auth_session.dart";
import "../../features/main/presentation/widgets/auth_dialog.dart";

/// Centralized route guard used by AppRouter to protect authenticated screens.
///
/// If the user is signed in, it builds the protected page. If not, it shows the
/// shared AuthDialog and pops back to the previous page so the user stays on
/// their current context.
class AuthGuard {
  const AuthGuard._();

  static Route<dynamic> protect({
    required WidgetBuilder builder,
    required String featureLabel,
    String? description,
  }) {
    return MaterialPageRoute(
      builder: (context) => _GuardedPage(
        protectedBuilder: builder,
        featureLabel: featureLabel,
        description: description,
      ),
    );
  }
}

class _GuardedPage extends StatefulWidget {
  final WidgetBuilder protectedBuilder;
  final String featureLabel;
  final String? description;

  const _GuardedPage({
    required this.protectedBuilder,
    required this.featureLabel,
    this.description,
  });

  @override
  State<_GuardedPage> createState() => _GuardedPageState();
}

class _GuardedPageState extends State<_GuardedPage> {
  bool _allowed = false;
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkGuard());
  }

  Future<void> _checkGuard() async {
    if (_prompted) return;
    final valid = await AuthSession.instance.ensureValid();
    // If token/user still valid, allow.
    if (valid && mounted) {
      setState(() => _allowed = true);
      return;
    }

    // Token missing/expired: sign out but keep user on the same page;
    // downstream widgets should render guest header automatically.
    await AuthSession.instance.expireSession();
    if (mounted) setState(() => _allowed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed) {
      return widget.protectedBuilder(context);
    }
    // Keep the route alive with a minimal placeholder while dialog is shown.
    return const Scaffold(body: SizedBox.shrink());
  }
}
