import "package:flutter/material.dart";

import "my_event_form_workspace.dart";

class MyEventEditPage extends StatelessWidget {
  final String? eventId;
  final String? title;

  const MyEventEditPage({super.key, this.eventId, this.title});

  @override
  Widget build(BuildContext context) {
    return MyEventFormWorkspace(
      isEditing: true,
      eventId: eventId,
      initialTitle: title,
    );
  }
}
