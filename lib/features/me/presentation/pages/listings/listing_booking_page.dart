import "package:flutter/material.dart";
import "package:inotra/i18n/lang.dart";
import "package:inotra/i18n/translations.dart";
import "package:inotra/features/main/presentation/widgets/main_scaffold.dart";

class ListingBookingPage extends StatelessWidget {
  const ListingBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "nav.listing_booking"),
      child: Center(
        child: Text(
          t(lang, "common.coming_soon"),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
