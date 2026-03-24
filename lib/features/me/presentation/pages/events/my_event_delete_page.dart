import "package:flutter/material.dart";

import "../../../../main/presentation/widgets/page_header.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class MyEventDeletePage extends StatelessWidget {
  final String? eventId;
  final String? title;

  const MyEventDeletePage({super.key, this.eventId, this.title});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final eventTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : "Event";

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          PageHeader(title: t(lang, "my_events.delete_event")),
          _DeleteWorkspaceCard(
            title: t(lang, "my_events.delete_event"),
            eventTitle: eventTitle,
            eventId: eventId,
            scheme: scheme,
          ),
        ],
      ),
    );
  }
}

class _DeleteWorkspaceCard extends StatelessWidget {
  final String title;
  final String eventTitle;
  final String? eventId;
  final ColorScheme scheme;

  const _DeleteWorkspaceCard({
    required this.title,
    required this.eventTitle,
    required this.eventId,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.errorContainer.withValues(alpha: 0.22),
        border: Border.all(color: scheme.error.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.error.withValues(alpha: 0.10),
            ),
            child: Icon(Icons.delete_outline_rounded, color: scheme.error),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            eventTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
          if (eventId != null && eventId!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              eventId!,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurface.withValues(alpha: 0.52),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            t(currentLangSync(), "common.coming_soon"),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}
