import "package:flutter/material.dart";

import "core/config/api.dart";
import "core/constants/api/api_endpoints.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "INOTRA APP",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: "DMSans",
      ),
      home: const _HomeDebugPage(),
    );
  }
}

/// Temporary home page just to confirm the app is wired correctly.
/// We'll replace this with real routes/screens (auth -> home) next.
class _HomeDebugPage extends StatelessWidget {
  const _HomeDebugPage();

  @override
  Widget build(BuildContext context) {
    final baseUrl = Api.url("").toString(); // returns base url with trailing slash
    final loginUrl = Api.url(AuthEndpoints.login).toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("INOTRA"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Environment & API Check",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text("Base URL: $baseUrl"),
            const SizedBox(height: 8),
            Text("Auth login: $loginUrl"),
            const SizedBox(height: 20),
            const Text(
              "Next: We'll add routing + auth screens and wire the API client.",
            ),
          ],
        ),
      ),
    );
  }
}