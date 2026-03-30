import "package:flutter/material.dart";

import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";

class MyListingBookingHeader extends StatelessWidget {
  const MyListingBookingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      t(currentLangSync(), "nav.listing_booking"),
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: -0.9,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
