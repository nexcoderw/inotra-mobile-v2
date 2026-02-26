import "package:flutter/material.dart";

class MainScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget child;
  final bool showAppBar;

  const MainScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title), actions: actions) : null,
      body: SafeArea(child: child),
    );
  }
}
