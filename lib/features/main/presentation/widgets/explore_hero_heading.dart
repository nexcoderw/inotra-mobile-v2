import "package:flutter/material.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ExploreHeroHeading extends StatelessWidget {
  const ExploreHeroHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
          height: 1.18,
          color: scheme.onSurface,
          fontFamily: "DM Sans",
        ),
        children: [
          TextSpan(text: t(lang, "explore.hero_prefix")),
          TextSpan(
            text: t(lang, "explore.hero_rwanda"),
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              fontFamily: "DM Sans",
            ),
          ),
          TextSpan(text: t(lang, "explore.hero_suffix")),
        ],
      ),
    );
  }
}
