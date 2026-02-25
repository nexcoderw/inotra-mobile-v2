import "package:flutter/material.dart";
import "../widgets/main_scaffold.dart";

class AiChatConversationsPage extends StatelessWidget {
  const AiChatConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(8, (i) => "Conversation ${i + 1}");

    return MainScaffold(
      title: "AI Conversations",
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(items[index], style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Tap to open (coming next)"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}