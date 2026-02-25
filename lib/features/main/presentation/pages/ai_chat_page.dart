import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../widgets/auth_dialog.dart";
import "../widgets/main_scaffold.dart";

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAccess());
  }

  Future<void> _guardAccess() async {
    if (_dialogShown) return;
    final authed = AuthSession.instance.value.isAuthenticated;
    if (authed) return;
    _dialogShown = true;
    if (!mounted) return;
    await AuthDialog.show(
      context,
      featureLabel: "AI Chat",
      description:
          "Sign in or create an account to chat with AI and keep your conversations saved.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "AI Chat",
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.aiChatConversations),
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: "Conversations",
        ),
      ],
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "AI Chat Page\n\nTODO: Build chat UI and connect AI endpoints.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
