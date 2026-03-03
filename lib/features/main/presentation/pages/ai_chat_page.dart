import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    return MainScaffold(
      title: t(lang, "nav.ai_chat"),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.aiChatConversations),
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: t(lang, "ai.conversations"),
        ),
      ],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            t(lang, "ai.todo"),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
