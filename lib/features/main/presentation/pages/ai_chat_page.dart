import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../widgets/main_scaffold.dart";

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

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