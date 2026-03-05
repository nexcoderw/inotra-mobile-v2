import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../i18n/translations.dart";
import "models.dart";

// ─────────────────────────────────────────────────────────────────────────────
// ConvComposer — glassmorphism bottom input bar
// ─────────────────────────────────────────────────────────────────────────────

class ConvComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onClearAttach;
  final SharedItem? pendingShared;
  final bool busy;
  final String lang;

  const ConvComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.onClearAttach,
    required this.busy,
    required this.lang,
    this.pendingShared,
  });

  @override
  State<ConvComposer> createState() => _ConvComposerState();
}

class _ConvComposerState extends State<ConvComposer> {
  bool _hasText = false;

  bool get _canSend => _hasText || widget.pendingShared != null;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isDark ? 0.78 : 0.92),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Attachment chip
                  if (widget.pendingShared != null) ...[
                    ConvAttachmentChip(
                      shared: widget.pendingShared!,
                      lang: widget.lang,
                      scheme: scheme,
                      isDark: isDark,
                      onRemove: widget.onClearAttach,
                    ),
                    const SizedBox(height: 7),
                  ],

                  // Input row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _AttachButton(
                        onTap: widget.onAttach,
                        scheme: scheme,
                        isDark: isDark,
                        active: widget.pendingShared != null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          lang: widget.lang,
                          scheme: scheme,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SendButton(
                        busy: widget.busy,
                        enabled: _canSend,
                        onTap: _canSend ? widget.onSend : null,
                        scheme: scheme,
                        isDark: isDark,
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// _AttachButton
// ─────────────────────────────────────────────────────────────────────────────

class _AttachButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isDark;
  final bool active;

  const _AttachButton({
    required this.onTap,
    required this.scheme,
    required this.isDark,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? scheme.primary.withValues(alpha: 0.16)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          border: Border.all(
            color: active
                ? scheme.primary.withValues(alpha: 0.35)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08)),
            width: 0.7,
          ),
        ),
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedAttachment02,
            size: 17,
            color: active
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.42),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TextField
// ─────────────────────────────────────────────────────────────────────────────

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String lang;
  final ColorScheme scheme;
  final bool isDark;

  const _TextField({
    required this.controller,
    required this.focusNode,
    required this.lang,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.7,
          ),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          minLines: 1,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 15.5,
            color: scheme.onSurface,
            height: 1.35,
          ),
          decoration: InputDecoration(
            hintText: t(lang, "chat.type_message"),
            hintStyle: TextStyle(
              fontSize: 15.5,
              color: scheme.onSurface.withValues(alpha: 0.32),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SendButton
// ─────────────────────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final bool busy;
  final bool enabled;
  final VoidCallback? onTap;
  final ColorScheme scheme;
  final bool isDark;

  const _SendButton({
    required this.busy,
    required this.enabled,
    required this.onTap,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: busy
          ? SizedBox(
              key: const ValueKey("busy"),
              width: 40,
              height: 40,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            )
          : GestureDetector(
              key: const ValueKey("send"),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? scheme.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.07)),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSent,
                    size: 18,
                    color: enabled
                        ? Colors.white
                        : scheme.onSurface.withValues(alpha: 0.30),
                  ),
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConvAttachmentChip — shows the pending attachment above the input
// ─────────────────────────────────────────────────────────────────────────────

class ConvAttachmentChip extends StatelessWidget {
  final SharedItem shared;
  final String lang;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onRemove;

  const ConvAttachmentChip({
    super.key,
    required this.shared,
    required this.lang,
    required this.scheme,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = shared.type == "EVENT"
        ? t(lang, "chat.shared_event")
        : shared.type == "PACKAGE"
            ? t(lang, "chat.shared_package")
            : t(lang, "chat.shared_listing");

    final accent = scheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.15 : 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAttachment02,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              shared.title != null ? "$typeLabel · ${shared.title}" : typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
              ),
              child: const Center(
                child: Icon(Icons.close_rounded, size: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
