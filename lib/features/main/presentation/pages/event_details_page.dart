import "package:flutter/material.dart";
import "../widgets/main_scaffold.dart";

class EventDetailsPage extends StatelessWidget {
  final String? eventId;
  const EventDetailsPage({super.key, this.eventId});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Event Details",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Event Details\n\nEvent ID: ${eventId ?? "N/A"}\n\nTODO: Fetch and show event details & reviews.",
              style: const TextStyle(height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}