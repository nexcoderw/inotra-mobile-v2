import "package:flutter/material.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/trip_packages_preview.dart";

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
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
            ),
            const SizedBox(height: 36),
            const TripPackagesPreview(),
          ],
        ),
      ),
    );
  }
}
