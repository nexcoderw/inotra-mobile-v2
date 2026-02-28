import "package:flutter/material.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ExploreHeroHeading extends StatelessWidget {
  const ExploreHeroHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    // Colors tuned to match the screenshot (muted gray + deep green).
    final muted = scheme.onSurface.withOpacity(0.42);
    final green = const Color(0xFF0B4A2A);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        // Responsive typography (keeps the same “poster” feel across screens)
        final line1Size = (w * 0.10).clamp(26.0, 72.0);
        final ofTheSize = (line1Size * 0.78).clamp(20.0, 56.0);
        final rwandaSize = (line1Size * 1.05).clamp(28.0, 84.0);

        final baseStyle = TextStyle(
          fontFamily: "DM Sans",
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
          height: 1.0,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "Discover the wonders"
            Text(
              t(lang, "explore.hero_prefix").trim(), // e.g. "Discover the wonders"
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                fontSize: line1Size,
                color: muted,
              ),
            ),

            SizedBox(height: (line1Size * 0.25).clamp(8.0, 18.0)),

            // Line 2: "of the " + "Rwanda!" (with swoosh underline)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: (line1Size * 0.10).clamp(6.0, 12.0),
              children: [
                Text(
                  t(lang, "explore.hero_suffix").trim().isNotEmpty
                      ? t(lang, "explore.hero_suffix").trim()
                      : t(lang, "explore.hero_suffix"), // if you use suffix for "of the"
                  // If your translations use:
                  // prefix = "Discover the wonders"
                  // suffix = "of the"
                  // rwanda = "Rwanda!"
                  // then this line displays suffix.
                  textAlign: TextAlign.center,
                  style: baseStyle.copyWith(
                    fontSize: ofTheSize,
                    color: muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),

                _ArcUnderlineText(
                  text: t(lang, "explore.hero_rwanda").trim(), // "Rwanda!"
                  textStyle: baseStyle.copyWith(
                    fontSize: rwandaSize,
                    color: green,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                  underlineColor: green,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ArcUnderlineText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final Color underlineColor;

  const _ArcUnderlineText({
    required this.text,
    required this.textStyle,
    required this.underlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    final textW = painter.width;
    final textH = painter.height;

    // Space reserved for the swoosh
    final thickness = (textStyle.fontSize ?? 40) * 0.09;
    final swooshH = (textStyle.fontSize ?? 40) * 0.32;

    return SizedBox(
      width: textW,
      height: textH + swooshH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Text(text, style: textStyle),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: Size(textW, swooshH),
              painter: _SwooshPainter(
                color: underlineColor,
                thickness: thickness,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwooshPainter extends CustomPainter {
  final Color color;
  final double thickness;

  _SwooshPainter({
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // Create a smooth curved “smile” arc like the screenshot
    final y = size.height * 0.45;
    final curve = size.height * 0.55;

    final path = Path()
      ..moveTo(0, y)
      ..quadraticBezierTo(size.width * 0.50, y + curve, size.width, y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SwooshPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.thickness != thickness;
  }
}