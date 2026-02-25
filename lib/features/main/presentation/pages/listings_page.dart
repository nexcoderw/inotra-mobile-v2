import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../widgets/main_scaffold.dart";

class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final listings = List.generate(10, (i) => "PLACE-${i + 1}");

    return MainScaffold(
      title: "Listings",
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final id = listings[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text("Listing $id", style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Tap to view details"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.listingDetails,
                arguments: id,
              ),
            ),
          );
        },
      ),
    );
  }
}