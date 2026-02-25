import "package:flutter/material.dart";
import "../widgets/main_scaffold.dart";

class TripPackageDetailsPage extends StatelessWidget {
  final String? packageId;
  const TripPackageDetailsPage({super.key, this.packageId});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Package Details",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Trip Package Details\n\nPackage ID: ${packageId ?? "N/A"}\n\nTODO: Fetch and display real package data.",
              style: const TextStyle(height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}