import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: "Settings",
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          PageHeader(title: "Settings"),

          _GlassSection(
            title: "Personalization",
            children: [
              _GlassTile(
                icon: HugeIcons.strokeRoundedMoon02,
                title: "Theme",
                subtitle: "Light / Dark / System",
                onTap: () {
                  _toast(context, "Theme picker coming soon");
                },
              ),
              _GlassTile(
                icon: HugeIcons.strokeRoundedLanguageSkill,
                title: "Language",
                subtitle: "Change display language",
                onTap: () {
                  _toast(context, "Language selector coming soon");
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GlassSection(
            title: "Account & Privacy",
            children: [
              _GlassTile(
                icon: HugeIcons.strokeRoundedShield02,
                title: "Privacy Policy",
                subtitle: "How we handle your data",
                onTap: () {
                  _toast(context, "Privacy policy view coming soon");
                },
              ),
              _GlassTile(
                icon: HugeIcons.strokeRoundedFileUnlocked,
                title: "Terms of Service",
                subtitle: "Review the terms",
                onTap: () {
                  _toast(context, "Terms of service view coming soon");
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GlassSection(
            title: "Support",
            children: [
              _GlassTile(
                icon: HugeIcons.strokeRoundedMessageQuestion,
                title: "Help Center",
                subtitle: "FAQs and guides",
                onTap: () {
                  _toast(context, "Help Center coming soon");
                },
              ),
              _GlassTile(
                icon: HugeIcons.strokeRoundedCallRinging03,
                title: "Contact Support",
                subtitle: "Chat or email us",
                onTap: () {
                  _toast(context, "Support contact coming soon");
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // App version glass card
          _GlassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: _IconBadge(
                icon: HugeIcons.strokeRoundedDiscoverCircle,
              ),
              title: const Text(
                "App version",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              subtitle: Text(
                "1.0.0",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.68),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassSection({
    required this.title,
    required this.children,
  });

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
                            color: scheme.onSurface.withOpacity(0.68),
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
                      color: scheme.onSurface.withOpacity(0.55),
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

  const _IconBadge({
    this.icon = HugeIcons.strokeRoundedDiscoverCircle,
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
            scheme.primary.withOpacity(0.22),
            scheme.primary.withOpacity(0.10),
          ],
        ),
        border: Border.all(
          color: scheme.onSurface.withOpacity(0.10),
          width: 1,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: scheme.primary.withOpacity(0.95),
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
