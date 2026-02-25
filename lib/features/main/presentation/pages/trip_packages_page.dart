import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../widgets/main_scaffold.dart";

class TripPackagesPage extends StatelessWidget {
  const TripPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final packages = List.generate(8, (i) => "PKG-${i + 1}");

    return MainScaffold(
      title: "Trip Packages",
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final id = packages[index];
          return Card(
            child: ListTile(
              title: Text("Package $id", style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Tap to view details"),
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