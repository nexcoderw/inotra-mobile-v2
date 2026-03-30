import "package:flutter/material.dart";

import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";

class MyListingBookingHeader extends StatelessWidget {
  const MyListingBookingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF142A22), const Color(0xFF08130F)]
              : [const Color(0xFF163629), const Color(0xFF09150F)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1F16).withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Text(
        t(currentLangSync(), "nav.listing_booking"),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: -0.9,
          color: Colors.white,
        ),
      ),
    );
  }
}
