import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";

class AiChatTab extends StatelessWidget {
  const AiChatTab({super.key});

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
