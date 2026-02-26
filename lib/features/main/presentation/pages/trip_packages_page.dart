import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";

class TripPackagesPage extends StatelessWidget {
  const TripPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final packages = List.generate(8, (i) => "PKG-${i + 1}");
    final lang = currentLangSync();

    return MainScaffold(
      title: t(lang, "trips.title"),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final id = packages[index];
          return Card(
            child: ListTile(
              title: Text("${t(lang, "trips.details_title")} $id",
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(t(lang, "common.tap_details")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.tripPackageDetails,
                arguments: id,
              ),
            ),
          );
        },
      ),
    );
  }
}
