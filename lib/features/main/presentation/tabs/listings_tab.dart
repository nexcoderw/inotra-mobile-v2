import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingsTab extends StatelessWidget {
  const ListingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final listings = List.generate(10, (i) => "PLACE-${i + 1}");
    final lang = currentLangSync();

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: listings.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              t(lang, "nav.listings"),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            );
          }

          final id = listings[index - 1];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text("${t(lang, "nav.listings")} $id",
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(t(lang, "common.tap_details")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.listingDetails, arguments: id),
            ),
          );
        },
      ),
    );
  }
}
