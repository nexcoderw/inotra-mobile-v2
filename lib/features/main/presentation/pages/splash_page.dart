import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/app_colors.dart";

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isDark
                  ? "assets/branding/logo_color.png"
                  : "assets/branding/logo_color.png",
              height: 90,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              "INOTRA By Navig8",
              style: TextStyle(
                fontFamily: "DMSans",
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
