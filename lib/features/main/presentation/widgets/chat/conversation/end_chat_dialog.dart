import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../i18n/translations.dart";

// ─────────────────────────────────────────────────────────────────────────────
// EndChatDialog
//
// Premium, glassmorphism confirmation dialog used when the user wants to end
// a conversation. Returns `true` when the user confirms, `false`/`null` when
// they cancel or dismiss.
// ─────────────────────────────────────────────────────────────────────────────

class EndChatDialog {
  EndChatDialog._();

  static Future<bool> show(BuildContext context, {required String lang}) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: t(lang, "chat.end_chat_dismiss"),
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _EndChatDialogContent(lang: lang),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result == true;
  }
}

class _EndChatDialogContent extends StatelessWidget {
  final String lang;
  const _EndChatDialogContent({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: media.viewInsets.bottom > 0 ? 24 : 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: isDark ? 0.88 : 0.97),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.09)
                        : Colors.black.withValues(alpha: 0.055),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.52 : 0.16,
                      ),
                      blurRadius: 34,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 4,
                      width: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: scheme.onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _IconBadge(scheme: scheme, isDark: isDark),
                    const SizedBox(height: 16),
                    Text(
                      t(lang, "chat.end_chat_title"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t(lang, "chat.end_chat_body"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EndChatNote(lang: lang, scheme: scheme, isDark: isDark),
                    const SizedBox(height: 18),
                    _ActionsRow(lang: lang, scheme: scheme, isDark: isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;
  const _IconBadge({required this.scheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = scheme.error;
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.22 : 0.14),
            accent.withValues(alpha: isDark ? 0.10 : 0.06),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.32 : 0.22),
          width: 0.8,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedCancel01,
          size: 26,
          color: accent,
        ),
      ),
    );
  }
}

class _EndChatNote extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;
  final bool isDark;

  const _EndChatNote({
    required this.lang,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.42 : 0.62,
        ),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.055),
          width: 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: isDark ? 0.16 : 0.10),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedMessage02,
                size: 12,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              t(lang, "chat.end_chat_note"),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;
  final bool isDark;

  const _ActionsRow({
    required this.lang,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DialogButton(
          label: t(lang, "chat.end_chat_cancel"),
          icon: HugeIcons.strokeRoundedMessage02,
          onTap: () => Navigator.of(context).pop(false),
          background: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.035),
          foreground: scheme.onSurface.withValues(alpha: 0.85),
          borderColor: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.075),
        ),
        const SizedBox(height: 10),
        _DialogButton(
          label: t(lang, "chat.end_chat_confirm"),
          icon: HugeIcons.strokeRoundedCancel01,
          onTap: () => Navigator.of(context).pop(true),
          background: scheme.error,
          foreground: scheme.onError,
          borderColor: scheme.error,
          elevated: true,
        ),
      ],
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final bool elevated;

  const _DialogButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.borderColor,
    this.elevated = false,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.97 : 1.0,
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: widget.borderColor, width: 0.7),
            boxShadow: widget.elevated
                ? [
                    BoxShadow(
                      color: widget.background.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: widget.icon, size: 15, color: widget.foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: widget.foreground,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
