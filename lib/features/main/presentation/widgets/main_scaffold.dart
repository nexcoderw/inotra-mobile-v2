import "package:flutter/material.dart";

class MainScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget child;

  const MainScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: child),
    );
  }
}