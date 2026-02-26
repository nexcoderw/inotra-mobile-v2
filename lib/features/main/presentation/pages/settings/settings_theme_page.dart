import "dart:ui";

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:hugeicons/hugeicons.dart";

import "../../widgets/main_scaffold.dart";
import "../../widgets/page_header.dart";
import "../../../../../core/services/theme_notifier.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class SettingsThemePage extends StatelessWidget {
  const SettingsThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final current = notifier.mode;
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

    return MainScaffold(
      title: t(lang, "settings.theme"),
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          PageHeader(title: t(lang, "settings.theme")),
          const SizedBox(height: 10),
          Text(
            t(lang, "theme.helper"),
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: scheme.onSurface.withOpacity(0.66),
            ),
          ),
          const SizedBox(height: 14),

          _GlassGroup(
            title: t(lang, "settings.theme"),
            children: [
              _PremiumThemeOption(
                label: t(lang, "theme.light"),
                subtitle: t(lang, "theme.light_sub"),
                icon: HugeIcons.strokeRoundedSun01,
                selected: current == ThemeMode.light,
                onTap: () => notifier.setMode(ThemeMode.light),
              ),
              _PremiumThemeOption(
                label: t(lang, "theme.dark"),
                subtitle: t(lang, "theme.dark_sub"),
                icon: HugeIcons.strokeRoundedMoon02,
                selected: current == ThemeMode.dark,
                onTap: () => notifier.setMode(ThemeMode.dark),
              ),

              // If you support system mode in ThemeNotifier, uncomment this:
              _PremiumThemeOption(
                label: t(lang, "theme.system"),
                subtitle: t(lang, "theme.system_sub"),
                icon: HugeIcons.strokeRoundedComputer,
                selected: current == ThemeMode.system,
                onTap: () => notifier.setMode(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withOpacity(0.85),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.2,
                  color: scheme.onSurface.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._withDividers(context, children),
        ],
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context, List<Widget> tiles) {
    final scheme = Theme.of(context).colorScheme;

    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i != tiles.length - 1) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 6),
            child: Divider(
              height: 14,
              thickness: 1,
              color: scheme.onSurface.withOpacity(0.06),
            ),
          ),
        );
      }
    }
    return out;
  }
}

class _PremiumThemeOption extends StatefulWidget {
  final String label;
  final String subtitle;
  final dynamic icon;
  final bool selected;
  final VoidCallback onTap;

  const _PremiumThemeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PremiumThemeOption> createState() => _PremiumThemeOptionState();
}

class _PremiumThemeOptionState extends State<_PremiumThemeOption> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _pressed || _hovered;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: active
                ? scheme.onSurface.withOpacity(0.06)
                : Colors.transparent,
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            scale: _pressed ? 0.985 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  _IconBadge(
                    icon: widget.icon,
                    selected: widget.selected,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            color: scheme.onSurface.withOpacity(0.66),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: widget.selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey("selected"),
                            color: scheme.primary,
                            size: 20,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            key: const ValueKey("unselected"),
                            color: scheme.onSurface.withOpacity(0.28),
                            size: 20,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final dynamic icon;
  final bool selected;

  const _IconBadge({
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 30,
      width: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withOpacity(selected ? 0.26 : 0.20),
            scheme.primary.withOpacity(selected ? 0.14 : 0.10),
          ],
        ),
        border: Border.all(
          color: selected
              ? scheme.primary.withOpacity(0.35)
              : scheme.onSurface.withOpacity(0.10),
          width: 1,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: scheme.primary.withOpacity(0.95),
          size: 14, // ✅ icon size 14
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: scheme.surface.withOpacity(0.55),
            border: Border.all(
              color: scheme.onSurface.withOpacity(0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
