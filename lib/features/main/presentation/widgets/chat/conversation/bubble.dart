import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "models.dart";

// ─────────────────────────────────────────────────────────────────────────────
// ConvBubble — a single chat message bubble
// ─────────────────────────────────────────────────────────────────────────────

class ConvBubble extends StatelessWidget {
  final ConvMessage message;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const ConvBubble({
    super.key,
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  static const _r = 18.0;
  static const _tail = 4.0;

  BorderRadius _radius(bool isMine) {
    if (isMine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(_r),
        topRight: Radius.circular(isFirstInGroup ? _r : _tail),
        bottomLeft: const Radius.circular(_r),
        bottomRight: Radius.circular(isLastInGroup ? _tail : _r),
      );
    }
    return BorderRadius.only(
      topLeft: Radius.circular(isFirstInGroup ? _r : _tail),
      topRight: const Radius.circular(_r),
      bottomLeft: Radius.circular(isLastInGroup ? _tail : _r),
      bottomRight: const Radius.circular(_r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final isMine = message.isMine;
    final maxW = MediaQuery.of(context).size.width * 0.74;

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 56 : 14,
        right: isMine ? 14 : 56,
        top: isFirstInGroup ? 5 : 2,
        bottom: isLastInGroup ? 5 : 2,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Bubble
              _BubbleBody(
                message: message,
                isMine: isMine,
                isDark: isDark,
                scheme: scheme,
                radius: _radius(isMine),
                senderType: message.senderType,
              ),

              // Timestamp row
              if (isLastInGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
                  child: _TimeRow(
                    message: message,
                    isMine: isMine,
                    isDark: isDark,
                    scheme: scheme,
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
// _BubbleBody — the colored / frosted container
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleBody extends StatelessWidget {
  final ConvMessage message;
  final bool isMine;
  final bool isDark;
  final ColorScheme scheme;
  final BorderRadius radius;
  final String senderType;

  const _BubbleBody({
    required this.message,
    required this.isMine,
    required this.isDark,
    required this.scheme,
    required this.radius,
    this.senderType = "",
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isMine ? Colors.white : scheme.onSurface;
    final failedTextColor = isDark ? Colors.red[200]! : Colors.red[800]!;

    // Outgoing: solid primary. Incoming: glassmorphism frosted pill with
    // optional tint based on sender type (violet=AI, teal=human rep).
    Color? tint;
    if (!isMine) {
      if (senderType == "AI") {
        tint = const Color(0xFF7C3AED); // violet
      } else if (senderType == "HUMAN") {
        tint = const Color(0xFF0D9488); // teal
      }
    }

    Widget body = isMine
        ? _solidBubble(textColor, failedTextColor)
        : _frostedBubble(textColor, tint: tint);

    return body;
  }

  Widget _solidBubble(Color textColor, Color failedTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: message.failed ? (isDark ? const Color(0xFF3D1515) : const Color(0xFFFFE5E5)) : scheme.primary,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: message.failed
                ? Colors.red.withValues(alpha: 0.18)
                : scheme.primary.withValues(alpha: isDark ? 0.25 : 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _bubbleContent(
        message.failed ? failedTextColor : textColor,
      ),
    );
  }

  Widget _frostedBubble(Color textColor, {Color? tint}) {
    final bubbleColor = tint != null
        ? tint.withValues(alpha: isDark ? 0.14 : 0.08)
        : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.80));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.07),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _bubbleContent(textColor),
        ),
      ),
    );
  }

  Widget _bubbleContent(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.shared != null)
          ConvSharedCard(shared: message.shared!, isMine: isMine, isDark: isDark, scheme: scheme),
        if (message.text.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              13,
              message.shared != null ? 8 : 9,
              13,
              9,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 12,
                height: 1.38,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          )
        else if (message.shared != null)
          const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConvSharedCard — shared event / listing / package preview inside a bubble
// ─────────────────────────────────────────────────────────────────────────────

class ConvSharedCard extends StatelessWidget {
  final SharedItem shared;
  final bool isMine;
  final bool isDark;
  final ColorScheme scheme;

  const ConvSharedCard({
    super.key,
    required this.shared,
    required this.isMine,
    required this.isDark,
    required this.scheme,
  });

  dynamic _icon() {
    switch (shared.type) {
      case "EVENT":
        return HugeIcons.strokeRoundedCalendar03;
      case "PACKAGE":
        return HugeIcons.strokeRoundedLuggage01;
      default:
        return HugeIcons.strokeRoundedLocation01;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final typeLabel = shared.type == "EVENT"
        ? t(lang, "chat.shared_event")
        : shared.type == "PACKAGE"
            ? t(lang, "chat.shared_package")
            : t(lang, "chat.shared_listing");

    final cardBg = isMine
        ? Colors.white.withValues(alpha: 0.14)
        : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.04));
    final iconColor = isMine ? Colors.white : scheme.primary;
    final labelColor = isMine
        ? Colors.white.withValues(alpha: 0.65)
        : scheme.onSurface.withValues(alpha: 0.42);
    final titleColor = isMine ? Colors.white : scheme.onSurface;
    final dividerColor = isMine
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: cardBg,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: HugeIcon(icon: _icon(), size: 16, color: iconColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                        letterSpacing: 0.9,
                      ),
                    ),
                    if (shared.title != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        shared.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 0.5, thickness: 0.5, color: dividerColor),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TimeRow — timestamp + delivery indicator
// ─────────────────────────────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final ConvMessage message;
  final bool isMine;
  final bool isDark;
  final ColorScheme scheme;

  const _TimeRow({
    required this.message,
    required this.isMine,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final timeColor = scheme.onSurface.withValues(alpha: 0.38);
    final h = message.createdAt.hour.toString().padLeft(2, "0");
    final m = message.createdAt.minute.toString().padLeft(2, "0");

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$h:$m",
          style: TextStyle(
            fontSize: 10.5,
            color: timeColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 3),
          Icon(
            message.pending
                ? Icons.access_time_rounded
                : message.failed
                    ? Icons.error_outline_rounded
                    : Icons.done_rounded,
            size: 11,
            color: message.failed
                ? (isDark ? Colors.red[300] : Colors.red[700])
                : timeColor,
          ),
        ],
      ],
    );
  }
}

