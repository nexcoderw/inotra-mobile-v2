import "package:flutter/material.dart";

import "my_listing_form_workspace.dart";

class MyListingAddPage extends StatelessWidget {
  const MyListingAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyListingFormWorkspace(isEditing: false);
  }
}
