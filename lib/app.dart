import "package:flutter/material.dart";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "core/config/app_router.dart";
import "core/config/app_routes.dart";
import "core/constants/app_colors.dart";
import "core/services/theme_notifier.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier()..load(),
      builder: (context, _) {
        final notifier = context.watch<ThemeNotifier>();
        final mode = notifier.mode;

        final lightScheme = ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        );

        final darkScheme = ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        );

        // Keep showing while theme loads to avoid a flash
        if (!notifier.initialized) {
          return const SizedBox.shrink();
        }

        return MaterialApp(
          title: "INOTRA APP",
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: "DMSans",
            colorScheme: lightScheme,
            appBarTheme: AppBarTheme(
              backgroundColor: lightScheme.surface,
              foregroundColor: lightScheme.onSurface,
              centerTitle: false,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: "DMSans",
            colorScheme: darkScheme,
            appBarTheme: AppBarTheme(
              backgroundColor: darkScheme.surface,
              foregroundColor: darkScheme.onSurface,
              centerTitle: false,
            ),
          ),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
