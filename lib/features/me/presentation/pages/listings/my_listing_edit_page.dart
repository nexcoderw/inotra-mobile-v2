import "package:flutter/material.dart";

import "my_listing_form_workspace.dart";

class MyListingEditPage extends StatelessWidget {
  final String? listingId;
  final String? title;

  const MyListingEditPage({super.key, this.listingId, this.title});

  @override
  Widget build(BuildContext context) {
    return MyListingFormWorkspace(
      isEditing: true,
      listingId: listingId,
      initialTitle: title,
    );
  }
}
