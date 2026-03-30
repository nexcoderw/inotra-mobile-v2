import "package:flutter/material.dart";

import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";

class EventTicketsHeader extends StatelessWidget {
  const EventTicketsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Text(
      t(lang, "nav.event_tickets"),
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: -0.9,
        color: scheme.onSurface,
      ),
    );
  }
}
