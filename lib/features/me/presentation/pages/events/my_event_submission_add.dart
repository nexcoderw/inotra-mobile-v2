import "package:flutter/material.dart";

import "my_event_form_workspace.dart";

class MyEventSubmissionAddPage extends StatelessWidget {
  const MyEventSubmissionAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyEventFormWorkspace(isEditing: false);
  }
}
