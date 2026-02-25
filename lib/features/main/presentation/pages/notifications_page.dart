import "package:flutter/material.dart";
import "../widgets/main_scaffold.dart";

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(6, (i) => "Notification ${i + 1}");

    return MainScaffold(
      title: "Notifications",
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(items[index], style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Details will be implemented later"),
            ),
          );
        },
      ),
    );
  }
}