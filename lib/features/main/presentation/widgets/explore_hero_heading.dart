import "package:flutter/material.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ExploreHeroHeading extends StatelessWidget {
  const ExploreHeroHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    // Screenshot look: muted gray + deep green
    final mutedGray = scheme.onSurface.withOpacity(0.40);
    const deepGreen = Color(0xFF0B4A2A);

    final prefix = t(lang, "explore.hero_prefix").trim(); // "Discover the wonders"
    final ofThe = t(lang, "explore.hero_suffix").trim().isEmpty
        ? "of the"
        : t(lang, "explore.hero_suffix").trim(); // "of the"
    final rwanda = t(lang, "explore.hero_rwanda").trim(); // "Rwanda!"

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        // Tuned to match screenshot proportions (big line1, smaller "of the", huge "Rwanda!")
        final line1 = (w * 0.095).clamp(30.0, 78.0);
        final ofTheSize = (line1 * 0.78).clamp(22.0, 58.0);
        final rwandaSize = (line1 * 1.06).clamp(32.0, 88.0);

        final base = const TextStyle(
          fontFamily: "DM Sans",
          height: 1.02,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1
            Text(
              prefix,
              textAlign: TextAlign.center,
              style: base.copyWith(
                fontSize: line1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: mutedGray,
              ),
            ),

            SizedBox(height: (line1 * 0.22).clamp(8.0, 18.0)),

            // Line 2: baseline aligned: "of the" + "Rwanda!"
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  ofThe,
                  style: base.copyWith(
                    fontSize: ofTheSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: mutedGray,
                  ),
                ),
                SizedBox(width: (line1 * 0.18).clamp(8.0, 18.0)),
                _SwooshUnderlinedText(
                  text: rwanda,
                  textStyle: base.copyWith(
                    fontSize: rwandaSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: deepGreen,
                  ),
                  color: deepGreen,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SwooshUnderlinedText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final Color color;

  const _SwooshUnderlinedText({
    required this.text,
    required this.textStyle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    final textW = tp.width;
    final textH = tp.height;

    // Underline area tuned to the screenshot:
    // thick swoosh, sitting close under the word, fairly wide.
    final swooshH = (textStyle.fontSize ?? 60) * 0.36;
    final gap = (textStyle.fontSize ?? 60) * 0.08;

    return SizedBox(
      width: textW,
      height: textH + swooshH + gap,
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
            top: textH + gap,
            child: CustomPaint(
              size: Size(textW, swooshH),
              painter: _SwooshPainter(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwooshPainter extends CustomPainter {
  final Color color;

  const _SwooshPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Two strokes to mimic that “filled swoosh” feel in the screenshot.
    final thick = Paint()
      ..color = color.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.38
      ..strokeCap = StrokeCap.round;

    final thin = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.20
      ..strokeCap = StrokeCap.round;

    // Build a smooth swoosh that dips more in the middle,
    // and rises slightly toward the end (like the image).
    final y = size.height * 0.35;
    final dip = size.height * 0.85;

    final path = Path()
      ..moveTo(0, y)
      ..cubicTo(
        size.width * 0.28,
        y + dip,
        size.width * 0.62,
        y + dip * 0.78,
        size.width,
        y + size.height * 0.06,
      );

    canvas.drawPath(path, thick);
    canvas.drawPath(path, thin);
  }

  @override
  bool shouldRepaint(covariant _SwooshPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}