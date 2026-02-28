import "package:flutter/material.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t(lang, "explore.hero_prefix"),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withOpacity(0.92),
            ),
          ),
          Text(
            t(lang, "explore.hero_rwanda"),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
