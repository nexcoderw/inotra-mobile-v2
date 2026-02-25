import "package:flutter/material.dart";

import "core/config/app_router.dart";
import "core/config/app_routes.dart";
import "core/constants/app_colors.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: "INOTRA APP",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: "DMSans",
        colorScheme: scheme,

        // Optional: make app bars/buttons feel branded
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          centerTitle: false,
        ),
      ),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}