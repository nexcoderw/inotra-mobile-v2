import "package:flutter/material.dart";

import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class MyEventSubmissionDetailPage extends StatelessWidget {
  final String? title;

  const MyEventSubmissionDetailPage({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final resolvedTitle = (title ?? "").trim().isNotEmpty
        ? title!.trim()
        : t(lang, "nav.my_event_submissions");

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 34,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              resolvedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t(lang, "common.coming_soon"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
