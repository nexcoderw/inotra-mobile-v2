import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class ExploreHeroHeading extends StatelessWidget {
  const ExploreHeroHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset =
        isDark ? "assets/images/welcome-dark.svg" : "assets/images/welcome-light.svg";

    return Center(
      child: SvgPicture.asset(
        asset,
        width: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }
}
