import "package:flutter/material.dart";
import "../widgets/main_scaffold.dart";

class ListingDetailsPage extends StatelessWidget {
  final String? placeId;
  const ListingDetailsPage({super.key, this.placeId});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Listing Details",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Listing Details\n\nPlace ID: ${placeId ?? "N/A"}\n\nTODO: Fetch and show listing details, reviews, booking.",
              style: const TextStyle(height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}