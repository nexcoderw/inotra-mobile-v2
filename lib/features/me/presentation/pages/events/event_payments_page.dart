import "package:flutter/material.dart";

import "../../../../main/presentation/widgets/page_header.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class EventPaymentsPage extends StatelessWidget {
  const EventPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          PageHeader(title: t(lang, "nav.event_payments")),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: scheme.primaryContainer.withValues(alpha: 0.22),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: scheme.primary.withValues(alpha: 0.10),
                  ),
                  child: Icon(Icons.payments_outlined, color: scheme.primary),
                ),
                const SizedBox(height: 18),
                Text(
                  t(lang, "nav.event_payments"),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t(lang, "common.coming_soon"),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
