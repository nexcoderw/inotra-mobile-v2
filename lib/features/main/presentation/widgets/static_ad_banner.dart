import "dart:ui";

import "package:flutter/material.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

/// Premium glassmorphism static banner (responsive + pro CTA).
class StaticAdBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const StaticAdBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

    final hPad = isTablet ? 24.0 : 18.0;
    final vPad = isTablet ? 20.0 : 16.0;
    final height = isTablet ? 170.0 : 150.0;

    return Semantics(
      button: true,
      label: t(lang, "banner.title"),
      child: _PressableGlass(
        onTap: onTap ?? () {},
        borderRadius: 26,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              // Base gradient (premium / subtle)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              scheme.primary.withOpacity(0.26),
                              scheme.surface.withOpacity(0.10),
                              scheme.surfaceVariant.withOpacity(0.22),
                            ]
                          : [
                              scheme.primary.withOpacity(0.14),
                              scheme.surface.withOpacity(0.22),
                              scheme.surfaceVariant.withOpacity(0.30),
                            ],
                    ),
                  ),
                ),
              ),

              // Soft decorative orbs
              Positioned(
                top: -60,
                right: -40,
                child: _Orb(color: scheme.primary.withOpacity(isDark ? 0.14 : 0.10), size: 210),
              ),
              Positioned(
                bottom: -50,
                left: -45,
                child: _Orb(color: scheme.secondary.withOpacity(isDark ? 0.12 : 0.08), size: 190),
              ),

              // Light sweep highlight
              Positioned(
                top: -90,
                left: -40,
                child: Transform.rotate(
                  angle: -0.25,
                  child: Container(
                    width: 240,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(80),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(isDark ? 0.12 : 0.18),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Frosted glass layer
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: const SizedBox.expand(),
                ),
              ),

              // Border + shadow
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.16),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                child: Row(
                  children: [
                    Expanded(
                      child: _BannerCopy(
                        title: t(lang, "banner.title"),
                        subtitle: t(lang, "banner.subtitle"),
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PremiumCTA(
                      label: t(lang, "banner.cta"),
                      onTap: onTap ?? () {},
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCopy extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isTablet;

  const _BannerCopy({
    required this.title,
    required this.subtitle,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
            color: scheme.onSurface,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          maxLines: isTablet ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isTablet ? 13.5 : 13,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withOpacity(isDark ? 0.78 : 0.74),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniBadge(
              icon: Icons.flash_on_rounded,
              label: "Contact Us",
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: scheme.onSurface.withOpacity(0.86)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withOpacity(0.86),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCTA extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isTablet;

  const _PremiumCTA({
    required this.label,
    required this.onTap,
    required this.isTablet,
  });

  @override
  State<_PremiumCTA> createState() => _PremiumCTAState();
}

class _PremiumCTAState extends State<_PremiumCTA> {
  bool _pressed = false;
  bool _hover = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHover(bool v) => setState(() => _hover = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final padH = widget.isTablet ? 18.0 : 16.0;
    final padV = widget.isTablet ? 13.0 : 12.0;

    final glow = (_hover || _pressed) ? 0.38 : 0.26;

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.985 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        scheme.primary.withOpacity(0.98),
                        scheme.primary.withOpacity(0.82),
                      ]
                    : [
                        scheme.primary,
                        scheme.primary.withOpacity(0.86),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(glow),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.20 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.16),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pressable glass wrapper that feels premium with subtle scale + highlight.
class _PressableGlass extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;

  const _PressableGlass({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_PressableGlass> createState() => _PressableGlassState();
}

class _PressableGlassState extends State<_PressableGlass> {
  bool _pressed = false;

  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.992 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}