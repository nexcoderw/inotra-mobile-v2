import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class ImageNotFoundSvg extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;
  final double sizeFactor;

  const ImageNotFoundSvg({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.padding = const EdgeInsets.all(12),
    this.sizeFactor = 0.42,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg =
        backgroundColor ??
        scheme.surfaceContainerHighest.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.5 : 0.7,
        );
    final fg =
        iconColor ??
        scheme.onSurface.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.38 : 0.30,
        );

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Padding(
        padding: padding,
        child: FractionallySizedBox(
          widthFactor: sizeFactor,
          heightFactor: sizeFactor,
          child: SvgPicture.asset(
            "assets/images/image-not-found.svg",
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
