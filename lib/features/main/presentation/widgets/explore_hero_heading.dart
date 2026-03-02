import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class ExploreHeroHeading extends StatelessWidget {
  const ExploreHeroHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset =
        isDark ? "assets/images/welcome-dark.svg" : "assets/images/welcome-light.svg";

    final width = MediaQuery.sizeOf(context).width;
    final height = width * 0.24; // reduced height (~50%) to trim top/bottom space

    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
      ),
    );
  }
}
