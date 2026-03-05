import "package:flutter/material.dart";

import "../../../../../../i18n/translations.dart";
import "bubble.dart";
import "models.dart";

// ─────────────────────────────────────────────────────────────────────────────
// ConvMessageList — scrollable list of bubbles with date separators
// ─────────────────────────────────────────────────────────────────────────────

class ConvMessageList extends StatelessWidget {
  final List<ConvMessage> messages;
  final ScrollController scrollCtrl;
  final String lang;

  const ConvMessageList({
    super.key,
    required this.messages,
    required this.scrollCtrl,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    // Interleave date separators
    final items = <dynamic>[];
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final prev = i > 0 ? messages[i - 1] : null;
      if (prev == null || !_sameDay(prev.createdAt, msg.createdAt)) {
        items.add(_DateLabel(date: msg.createdAt, lang: lang));
      }
      items.add(msg);
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is _DateLabel) {
          return _DateSeparator(label: item);
        }

        final msg = item as ConvMessage;

        final nextItem = index + 1 < items.length ? items[index + 1] : null;
        final nextMsg = nextItem is ConvMessage ? nextItem : null;
        final prevItem = index > 0 ? items[index - 1] : null;
        final prevMsg = prevItem is ConvMessage ? prevItem : null;

        final isFirst = prevMsg == null ||
            prevMsg.isMine != msg.isMine ||
            msg.createdAt.difference(prevMsg.createdAt).inMinutes >= 3;

        final isLast = nextMsg == null ||
            nextMsg.isMine != msg.isMine ||
            nextMsg.createdAt.difference(msg.createdAt).inMinutes >= 3;

        return ConvBubble(
          message: msg,
          isFirstInGroup: isFirst,
          isLastInGroup: isLast,
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// Date label & separator
// ─────────────────────────────────────────────────────────────────────────────

class _DateLabel {
  final DateTime date;
  final String lang;
  const _DateLabel({required this.date, required this.lang});
}

class _DateSeparator extends StatelessWidget {
  final _DateLabel label;
  const _DateSeparator({required this.label});

  String _text() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(label.date.year, label.date.month, label.date.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return t(label.lang, "chat.today");
    if (diff == 1) return t(label.lang, "chat.yesterday");
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return "${months[label.date.month - 1]} ${label.date.day}, ${label.date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSurface.withValues(alpha: 0.32);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, height: 1, thickness: 0.4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _text(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(child: Divider(color: color, height: 1, thickness: 0.4)),
        ],
      ),
    );
  }
}
