import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "terms.title"),
      showAppBar: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: t(lang, "terms.title")),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedFile02,
                            size: 20,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t(lang, "terms.title"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t(lang, "common.coming_soon"),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
