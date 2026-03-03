import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

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
            Text(
              t(currentLangSync(), "nav.ai_chat"),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(t(currentLangSync(), "ai.placeholder")),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.aiChatConversations),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(t(currentLangSync(), "ai.open_conversations")),
            ),
          ],
        ),
      ),
    );
  }
}
