import "package:flutter/material.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "package:inotra/features/main/presentation/widgets/trip_packages_preview.dart";
import "package:inotra/features/main/presentation/widgets/static_ad_banner.dart";
import "package:inotra/features/main/presentation/widgets/explore_hero_heading.dart";

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
            const ExploreHeroHeading(),
            const SizedBox(height: 36),
            TripPackagesPreview(),
            const SizedBox(height: 24),
            const StaticAdBanner(),
          ],
        ),
      ),
    );
  }
}
