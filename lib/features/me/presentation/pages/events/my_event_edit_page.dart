import "package:flutter/material.dart";

import "../../../../main/presentation/widgets/page_header.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class MyEventEditPage extends StatelessWidget {
  final String? eventId;
  final String? title;

  const MyEventEditPage({super.key, this.eventId, this.title});

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
          PageHeader(title: t(lang, "my_events.edit_event")),
          _ManageWorkspaceCard(
            icon: Icons.edit_outlined,
            title: t(lang, "my_events.edit_event"),
            eventTitle: eventTitle,
            eventId: eventId,
            scheme: scheme,
          ),
        ],
      ),
    );
  }
}

class _ManageWorkspaceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String eventTitle;
  final String? eventId;
  final ColorScheme scheme;

  const _ManageWorkspaceCard({
    required this.icon,
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
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: scheme.primary),
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
