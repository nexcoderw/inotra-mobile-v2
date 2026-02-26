import "package:flutter/material.dart";

class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark ? "assets/branding/logo_color.png" : "assets/branding/logo_black.png";

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),

                  // ✅ Logo exactly like the design: centered, no container
                  Center(
                    child: Image.asset(
                      logoAsset,
                      height: 82,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 48),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
