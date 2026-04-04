import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "package:inotra/features/main/presentation/widgets/main_scaffold.dart";
import "package:inotra/features/main/presentation/widgets/page_header.dart";
import "package:inotra/core/config/app_routes.dart";
import "package:inotra/i18n/translations.dart";
import "package:inotra/core/services/auth_session.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _lang() {
    final preferred =
        AuthSession.instance.value.user?['preferred_language'] as String?;
    if (preferred == null || preferred.isEmpty) return 'en';
    final lower = preferred.toLowerCase();
    if (lower.startsWith('rw')) return 'rw';
    if (lower.startsWith('fr')) return 'fr';
    if (lower.startsWith('es')) return 'es';
    if (lower.startsWith('de')) return 'de';
    return 'en';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = _lang();

    return MainScaffold(
      title: t(lang, "settings.title"),
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          PageHeader(title: t(lang, "settings.title")),

          _GlassSection(
            title: t(lang, "settings.title"),
            children: [
              _GlassTile(
                icon: HugeIcons.strokeRoundedMoon02,
                title: t(lang, "settings.theme"),
                subtitle: t(lang, "settings.theme_subtitle"),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.settingsTheme);
                },
              ),
              _GlassTile(
                icon: HugeIcons.strokeRoundedLanguageSkill,
                title: t(lang, "settings.language"),
                subtitle: t(lang, "language.choose"),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.settingsLanguage);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GlassSection(
            title: t(lang, "settings.title"),
            children: [
              _GlassTile(
                icon: HugeIcons.strokeRoundedShield02,
                title: t(lang, "settings.privacy"),
                subtitle: t(lang, "privacy.title"),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                },
              ),
              _GlassTile(
                icon: HugeIcons.strokeRoundedFileUnlocked,
                title: t(lang, "settings.terms"),
                subtitle: t(lang, "terms.title"),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.termsConditions);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GlassSection(
            title: t(lang, "settings.support"),
            children: [
              _GlassTile(
                icon: HugeIcons.strokeRoundedCallRinging03,
                title: t(lang, "settings.support"),
                subtitle: "info@naviig8.com",
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.contactSupport);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // App version glass card
          _GlassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: _IconBadge(icon: HugeIcons.strokeRoundedDiscoverCircle),
              title: Text(
                t(lang, "settings.app_version"),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              subtitle: Text(
                "1.0.0",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                  color: scheme.primary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.2,
                  color: scheme.onSurface.withValues(alpha: 0.9),
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
              color: scheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
        );
      }
    }
    return out;
  }
}

class _GlassTile extends StatefulWidget {
  final dynamic icon; // HugeIcons.* uses custom IconData type
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GlassTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_GlassTile> createState() => _GlassTileState();
}

class _GlassTileState extends State<_GlassTile> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isActive = _pressed || _hovered;

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
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive
                ? scheme.onSurface.withValues(alpha: 0.06)
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
                  _IconBadge(icon: widget.icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
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
                            color: scheme.onSurface.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    offset: isActive ? const Offset(0.06, 0) : Offset.zero,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.55),
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

  const _IconBadge({this.icon = HugeIcons.strokeRoundedDiscoverCircle});

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
            scheme.primary.withValues(alpha: 0.22),
            scheme.primary.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: scheme.primary.withValues(alpha: 0.95),
          size: 14, // ✅ all icons 14
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
            color: scheme.surface.withValues(alpha: 0.55),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
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
