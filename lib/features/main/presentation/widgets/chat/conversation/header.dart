import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../chat_avatar.dart";

// ─────────────────────────────────────────────────────────────────────────────
// ConvHeader — glassmorphism top app bar for a chat thread
// Shows: back arrow · avatar · name. No call/video icons.
// ─────────────────────────────────────────────────────────────────────────────

class ConvHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? statusLabel; // e.g. "Online" or null
  final VoidCallback onBack;
  final bool showBackButton;

  const ConvHeader({
    super.key,
    required this.name,
    required this.onBack,
    this.avatarUrl,
    this.statusLabel,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isDark ? 0.72 : 0.90),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button
              if (showBackButton) ...[
                _BackButton(onTap: onBack),
                const SizedBox(width: 4),
              ] else
                const SizedBox(width: 12),

              // Avatar
              ChatAvatar(name: name, avatarUrl: avatarUrl, size: 38),

              const SizedBox(width: 10),

              // Name + optional status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (statusLabel != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        statusLabel!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Back button — pill-shaped glassmorphism tap target
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          size: 22,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
