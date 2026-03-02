import "package:flutter/material.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class AiChatTab extends StatelessWidget {
  const AiChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t(lang, "nav.ai_chat"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface.withOpacity(0.92),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t(lang, "common.coming_soon"),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
