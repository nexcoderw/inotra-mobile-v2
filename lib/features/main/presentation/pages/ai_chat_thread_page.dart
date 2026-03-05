import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/chat/chat_avatar.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AiChatThreadPage extends StatefulWidget {
  final String threadId;
  final String title;
  final String? avatarUrl;

  const AiChatThreadPage({
    super.key,
    required this.threadId,
    required this.title,
    this.avatarUrl,
  });

  @override
  State<AiChatThreadPage> createState() => _AiChatThreadPageState();
}

class _AiChatThreadPageState extends State<AiChatThreadPage>
    with TickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  bool _loading = true;
  bool _sending = false;
  String? _error;

  // My user ID for bubble alignment
  String? _myId;

  @override
  void initState() {
    super.initState();
    _myId = AuthSession.instance.value.user?["id"]?.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Fetch ────────────────────────────────────────────────────────────────

  Future<void> _fetch() async {
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (mounted) setState(() { _loading = false; _error = "auth"; });
      return;
    }

    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      final uri = Api.url(ChatEndpoints.messages(widget.threadId));
      final resp = await http.get(uri, headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final parsed = _parseMessages(resp.body);
        parsed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        setState(() {
          _messages
            ..clear()
            ..addAll(parsed);
          _loading = false;
        });
        _scrollToBottom();
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        if (mounted) setState(() { _loading = false; _error = "401"; });
      } else {
        setState(() { _loading = false; _error = "${resp.statusCode}"; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  /// Robustly parses multiple possible API response shapes.
  List<_ChatMessage> _parseMessages(String body) {
    try {
      final decoded = jsonDecode(body);
      List raw = const [];
      if (decoded is Map) {
        // Try every common DRF / custom key
        raw = (decoded["results"] as List?)
            ?? (decoded["messages"] as List?)
            ?? (decoded["data"] as List?)
            ?? (decoded["items"] as List?)
            ?? (decoded["chat_messages"] as List?)
            ?? const [];
      } else if (decoded is List) {
        raw = decoded;
      }
      return raw
          .whereType<Map>()
          .map((m) => _ChatMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ── Send ─────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _sending = true);

    // Optimistic local insert
    final optimistic = _ChatMessage(
      id: "__pending_${DateTime.now().millisecondsSinceEpoch}",
      text: text,
      createdAt: DateTime.now(),
      authorId: _myId,
      authorName: null,
      pending: true,
    );
    setState(() {
      _messages.add(optimistic);
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      final uri = Api.url(ChatEndpoints.sendMessage(widget.threadId));
      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"text": text}),
      );

      if (!mounted) return;

      // Remove the optimistic message regardless of outcome
      setState(() {
        _messages.removeWhere((m) => m.id == optimistic.id);
        _sending = false;
      });

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await _fetch();
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
      } else {
        _showSnack("${resp.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == optimistic.id);
          _sending = false;
        });
        _showSnack(e.toString());
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: scheme.surface,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _ChatHeader(
                name: widget.title,
                avatarUrl: widget.avatarUrl,
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: _loading
                    ? _LoadingShimmer(scheme: scheme)
                    : _error != null
                        ? _ErrorState(
                            message: _error!,
                            lang: lang,
                            onRetry: _fetch,
                          )
                        : _messages.isEmpty
                            ? _EmptyState(lang: lang)
                            : _MessageList(
                                messages: _messages,
                                myId: _myId,
                                scrollCtrl: _scrollCtrl,
                                lang: lang,
                              ),
              ),
              _Composer(
                controller: _inputCtrl,
                focusNode: _focusNode,
                onSend: _send,
                busy: _sending,
                lang: lang,
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final VoidCallback onBack;

  const _ChatHeader({
    required this.name,
    required this.avatarUrl,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 22,
              color: const Color(0xFF007AFF),
            ),
            splashRadius: 20,
          ),

          // Avatar + name
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChatAvatar(name: name, avatarUrl: avatarUrl, size: 36),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCall,
                  size: 20,
                  color: const Color(0xFF007AFF),
                ),
                splashRadius: 20,
              ),
              IconButton(
                onPressed: () {},
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedVideo01,
                  size: 20,
                  color: const Color(0xFF007AFF),
                ),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message list
// ─────────────────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<_ChatMessage> messages;
  final String? myId;
  final ScrollController scrollCtrl;
  final String lang;

  const _MessageList({
    required this.messages,
    required this.myId,
    required this.scrollCtrl,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    // Build flat item list: messages with date separators interleaved
    final items = <dynamic>[];
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final prev = i > 0 ? messages[i - 1] : null;
      final sameDay = prev != null &&
          _sameDay(prev.createdAt, msg.createdAt);
      if (!sameDay) {
        items.add(_DateLabel(date: msg.createdAt, lang: lang));
      }
      items.add(msg);
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _DateLabel) {
          return _DateSeparator(label: item);
        }

        final msg = item as _ChatMessage;
        final isMine = myId != null && msg.authorId == myId;

        // Grouping: is this the last in a consecutive run from same author?
        final nextItem = index + 1 < items.length ? items[index + 1] : null;
        final nextMsg = nextItem is _ChatMessage ? nextItem : null;
        final isLastInGroup = nextMsg == null ||
            nextMsg.authorId != msg.authorId ||
            nextMsg.createdAt.difference(msg.createdAt).inMinutes >= 3;

        final prevItem = index > 0 ? items[index - 1] : null;
        final prevMsg = prevItem is _ChatMessage ? prevItem : null;
        final isFirstInGroup = prevMsg == null ||
            prevMsg.authorId != msg.authorId ||
            msg.createdAt.difference(prevMsg.createdAt).inMinutes >= 3;

        return _ChatBubble(
          message: msg,
          isMine: isMine,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat bubble
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isMine;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  static const _blue = Color(0xFF007AFF);
  static const _bubbleRadius = 18.0;
  static const _tailRadius = 4.0;

  BorderRadius _radius() {
    if (isMine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(_bubbleRadius),
        topRight: Radius.circular(isFirstInGroup ? _bubbleRadius : _tailRadius),
        bottomLeft: const Radius.circular(_bubbleRadius),
        bottomRight: Radius.circular(isLastInGroup ? _tailRadius : _bubbleRadius),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(isFirstInGroup ? _bubbleRadius : _tailRadius),
        topRight: const Radius.circular(_bubbleRadius),
        bottomLeft: Radius.circular(isLastInGroup ? _tailRadius : _bubbleRadius),
        bottomRight: const Radius.circular(_bubbleRadius),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    final bubbleBg = isMine
        ? _blue
        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8ED));
    final textColor = isMine
        ? Colors.white
        : scheme.onSurface;
    final timeColor = isMine
        ? Colors.white.withValues(alpha: 0.65)
        : scheme.onSurface.withValues(alpha: 0.40);

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 64 : 12,
        right: isMine ? 12 : 64,
        top: isFirstInGroup ? 4 : 1.5,
        bottom: isLastInGroup ? 4 : 1.5,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Sender name for theirs (first in group only)
              if (!isMine && isFirstInGroup && message.authorName != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.authorName!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

              // Bubble
              Container(
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: _radius(),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.35,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              // Timestamp (last in group only)
              if (isLastInGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: timeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMine && message.pending) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.access_time_rounded,
                          size: 10,
                          color: timeColor,
                        ),
                      ] else if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_rounded,
                          size: 11,
                          color: timeColor,
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, "0");
    final m = dt.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date separator
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
    // Older: Month Day, Year
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[label.date.month - 1]} ${label.date.day}, ${label.date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: scheme.onSurface.withValues(alpha: 0.12),
              height: 1,
              thickness: 0.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _text(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.38),
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: scheme.onSurface.withValues(alpha: 0.12),
              height: 1,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Composer
// ─────────────────────────────────────────────────────────────────────────────

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool busy;
  final String lang;
  final ColorScheme scheme;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.busy,
    required this.lang,
    required this.scheme,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: widget.scheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text field
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.10),
                        width: 0.7,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: widget.scheme.onSurface,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: t(widget.lang, "chat.type_message"),
                        hintStyle: TextStyle(
                          color: widget.scheme.onSurface.withValues(alpha: 0.35),
                          fontSize: 15.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: widget.busy
                    ? const SizedBox(
                        key: ValueKey("loading"),
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      )
                    : GestureDetector(
                        key: const ValueKey("send"),
                        onTap: _hasText ? widget.onSend : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hasText
                                ? const Color(0xFF007AFF)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.08)),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSent,
                              size: 18,
                              color: _hasText
                                  ? Colors.white
                                  : widget.scheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error / Loading states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String lang;
  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withValues(alpha: 0.10),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMessage01,
                  size: 32,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t(lang, "chat.no_messages"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t(lang, "chat.no_messages_sub"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.45),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String lang;
  final VoidCallback onRetry;
  const _ErrorState({
    required this.message,
    required this.lang,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 38, color: scheme.error),
            const SizedBox(height: 14),
            Text(
              t(lang, "chat.load_error"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                t(lang, "common.try_again"),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatefulWidget {
  final ColorScheme scheme;
  const _LoadingShimmer({required this.scheme});

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.scheme.brightness == Brightness.dark;
    final base = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);
    final highlight = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final shimmer = LinearGradient(
          begin: Alignment(-1.5 + _anim.value * 3, 0),
          end: Alignment(-0.5 + _anim.value * 3, 0),
          colors: [base, highlight, base],
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              _ShimmerRow(shimmer: shimmer, isMine: false),
              _ShimmerRow(shimmer: shimmer, isMine: false, wide: false),
              _ShimmerRow(shimmer: shimmer, isMine: true),
              _ShimmerRow(shimmer: shimmer, isMine: false),
              _ShimmerRow(shimmer: shimmer, isMine: true, wide: false),
              _ShimmerRow(shimmer: shimmer, isMine: true),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final Gradient shimmer;
  final bool isMine;
  final bool wide;
  const _ShimmerRow({
    required this.shimmer,
    required this.isMine,
    this.wide = true,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? w * 0.28 : 0,
        right: isMine ? 0 : w * 0.28,
        bottom: 10,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: shimmer,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              height: 40,
              width: wide ? w * 0.48 : w * 0.30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: shimmer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final String? authorId;
  final String? authorName;
  final bool pending;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.pending = false,
  });

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? tryParse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try { return DateTime.parse(raw).toLocal(); } catch (_) { return null; }
    }

    // Robust author extraction — handle nested map or flat id field
    String? authorId;
    String? authorName;
    final author = json["author"] ?? json["sender"];
    if (author is Map) {
      authorId = author["id"]?.toString();
      authorName = (author["name"]
              ?? author["full_name"]
              ?? author["username"])
          ?.toString();
    } else if (author != null) {
      authorId = author.toString();
    } else {
      authorId = (json["author_id"] ?? json["user_id"])?.toString();
    }

    return _ChatMessage(
      id: (json["id"] ?? "").toString(),
      text: (json["text"]
              ?? json["content"]
              ?? json["body"]
              ?? json["message"]
              ?? "")
          .toString(),
      createdAt: tryParse(
            (json["created_at"] ?? json["timestamp"] ?? json["sent_at"])
                ?.toString(),
          ) ??
          DateTime.now(),
      authorId: authorId,
      authorName: authorName,
    );
  }
}
