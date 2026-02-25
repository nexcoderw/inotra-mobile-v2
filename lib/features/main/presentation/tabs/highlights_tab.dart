import "package:flutter/material.dart";

class HighlightsTab extends StatelessWidget {
  const HighlightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(8, (i) => "Highlight ${i + 1}");

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Text(
              "Highlights",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            );
          }
          final title = items[index - 1];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text("Static for now"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}