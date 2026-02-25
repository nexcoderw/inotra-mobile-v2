import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../widgets/auth_dialog.dart";

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI Chat",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("Chat UI will be implemented next (static page for now)."),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.aiChatConversations),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Open Conversations"),
            ),
          ],
        ),
      ),
    );
  }
}
