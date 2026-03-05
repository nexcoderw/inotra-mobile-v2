import "package:flutter/material.dart";

import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "chat_avatar.dart";

/// iMessage-style conversation row.
///
/// Layout:
///   [Avatar] | [Name + Preview] | [Timestamp + Unread badge]
///
/// Unread state: name is bold, preview is slightly bolder, blue badge shown.
/// Separator: thin 0.5 px line anchored after the avatar (iOS-style).
class ChatThreadTile extends StatelessWidget {
  final String threadId;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool lastMessageIsFromMe;
  final bool isLast;
  final VoidCallback onTap;

  const ChatThreadTile({
    super.key,
    required this.threadId,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.lastMessageIsFromMe,
    required this.isLast,
    required this.onTap,
  });

  static const _blue = Color(0xFF007AFF);

  String _formatTime(String lang) {
    if (lastMessageAt == null) return "";
    final now = DateTime.now();
    final dt = lastMessageAt!.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) {
      // Today — show time HH:MM
      final h = dt.hour.toString().padLeft(2, "0");
      final m = dt.minute.toString().padLeft(2, "0");
      return "$h:$m";
    }
    if (diff == 1) {
      return t(lang, "chat.yesterday");
    }
    if (diff < 7) {
      const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      return days[dt.weekday - 1];
    }
    // Older: MM/DD/YY
    final mm = dt.month.toString().padLeft(2, "0");
    final dd = dt.day.toString().padLeft(2, "0");
    final yy = dt.year.toString().substring(2);
    return "$mm/$dd/$yy";
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final hasUnread = unreadCount > 0;
    final timeStr = _formatTime(lang);

    String preview = lastMessage.trim();
    if (lastMessageIsFromMe) {
      preview = "${t(lang, "chat.you")}: $preview";
    }

    return InkWell(
      onTap: onTap,
      splashColor: scheme.primary.withOpacity(0.06),
      highlightColor: scheme.primary.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ChatAvatar(name: name, avatarUrl: avatarUrl, size: 50),
            ),

            const SizedBox(width: 12),

            // ── Right section (separator + content) ─────────────────────
            Expanded(
              child: Container(
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.09),
                            width: 0.5,
                          ),
                        ),
                      ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Name + preview
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Name
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: scheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Message preview
                            Text(
                              preview.isEmpty ? "…" : preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: hasUnread
                                    ? scheme.onSurface.withOpacity(0.80)
                                    : scheme.onSurface.withOpacity(0.45),
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Timestamp + badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: hasUnread
                                    ? _blue
                                    : scheme.onSurface.withOpacity(0.40),
                                letterSpacing: 0,
                              ),
                            ),
                          if (hasUnread) ...[
                            const SizedBox(height: 5),
                            _UnreadBadge(count: unreadCount),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? "99+" : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      constraints: const BoxConstraints(minWidth: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
