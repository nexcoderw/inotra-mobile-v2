import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/chat/chat_avatar.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _SharedItem {
  final String type; // "EVENT" | "PACKAGE" | "LISTING"
  final String id;
  final String? title;

  const _SharedItem({required this.type, required this.id, this.title});

  factory _SharedItem.fromJson(Map<String, dynamic> json) => _SharedItem(
        type: (json["type"] ?? "").toString().toUpperCase(),
        id: (json["id"] ?? "").toString(),
        title: json["title"]?.toString(),
      );

  Map<String, String?> toSendBody() => {
        if (type == "EVENT") "shared_event_id": id,
        if (type == "LISTING") "shared_listing_id": id,
        if (type == "PACKAGE") "shared_package_id": id,
      };
}

class _ChatMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isMine;
  final String? authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final _SharedItem? shared;
  final bool pending;
  final bool failed;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isMine,
    this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    this.shared,
    this.pending = false,
    this.failed = false,
  });

  _ChatMessage copyWith({bool? pending, bool? failed}) => _ChatMessage(
        id: id,
        text: text,
        createdAt: createdAt,
        isMine: isMine,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        shared: shared,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? tryParse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    String? authorId;
    String? authorName;
    String? authorAvatarUrl;
    final sender = json["sender"];
    if (sender is Map) {
      authorId = sender["id"]?.toString();
      authorName = (sender["name"] ?? sender["full_name"] ?? sender["username"])?.toString();
      authorAvatarUrl = sender["avatar_url"]?.toString();
    }

    _SharedItem? shared;
    final sharedRaw = json["shared"];
    if (sharedRaw is Map) {
      shared = _SharedItem.fromJson(Map<String, dynamic>.from(sharedRaw));
    }

    return _ChatMessage(
      id: (json["id"] ?? "").toString(),
      text: (json["source_text"] ?? json["text"] ?? json["content"] ?? json["body"] ?? "").toString(),
      createdAt: tryParse(
            (json["created_at"] ?? json["timestamp"] ?? json["sent_at"])?.toString(),
          ) ??
          DateTime.now(),
      isMine: json["is_mine"] as bool? ?? false,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      shared: shared,
    );
  }
}

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
  _SharedItem? _pendingShared;

  @override
  void initState() {
    super.initState();
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
      final uri = Api.url(ChatEndpoints.messages(widget.threadId))
          .replace(queryParameters: {"page": "1", "page_size": "50"});
      final resp = await http.get(uri, headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List raw = const [];
        if (decoded is Map) {
          raw = (decoded["results"] as List?) ?? const [];
        } else if (decoded is List) {
          raw = decoded;
        }
        // API returns newest first — reverse for chronological display
        final parsed = raw
            .whereType<Map>()
            .map((m) => _ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList()
            .reversed
            .toList();

        setState(() {
          _messages
            ..clear()
            ..addAll(parsed);
          _loading = false;
        });
        _scrollToBottom();
        _markRead(token);
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

  void _markRead(String token) {
    http
        .post(
          Api.url(ChatEndpoints.markRead(widget.threadId)),
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .ignore();
  }

  // ── Send ─────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    final shared = _pendingShared;
    if (text.isEmpty && shared == null) return;

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _sending = true);

    final optimisticId = "__pending_${DateTime.now().millisecondsSinceEpoch}";
    final optimistic = _ChatMessage(
      id: optimisticId,
      text: text,
      createdAt: DateTime.now(),
      isMine: true,
      shared: shared,
      pending: true,
    );

    setState(() {
      _messages.add(optimistic);
      _inputCtrl.clear();
      _pendingShared = null;
    });
    _scrollToBottom();

    try {
      final uri = Api.url(ChatEndpoints.sendMessage(widget.threadId));
      final body = <String, dynamic>{
        "text": text,
        "source_language": "",
        if (shared != null) ...shared.toSendBody(),
      };

      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final serverMsgRaw = decoded["chat_message"];
        final idx = _messages.indexWhere((m) => m.id == optimisticId);
        if (serverMsgRaw is Map && idx != -1) {
          final serverMsg = _ChatMessage.fromJson(
            Map<String, dynamic>.from(serverMsgRaw),
          );
          setState(() {
            _messages[idx] = serverMsg;
            _sending = false;
          });
        } else {
          setState(() {
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(pending: false);
            }
            _sending = false;
          });
        }
        _scrollToBottom();
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        setState(() => _sending = false);
      } else {
        final idx = _messages.indexWhere((m) => m.id == optimisticId);
        setState(() {
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(pending: false, failed: true);
          }
          _sending = false;
        });
        _showSnack("${resp.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        final idx = _messages.indexWhere((m) => m.id == optimisticId);
        setState(() {
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(pending: false, failed: true);
          }
          _sending = false;
        });
        _showSnack(e.toString());
      }
    }
  }

  // ── Share picker ─────────────────────────────────────────────────────────

  Future<void> _openSharePicker() async {
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;

    final lang = currentLangSync();
    final result = await showModalBottomSheet<_SharedItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatSharePickerSheet(
        lang: lang,
        accessToken: token,
      ),
    );

    if (result != null && mounted) {
      setState(() => _pendingShared = result);
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
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                                scrollCtrl: _scrollCtrl,
                                lang: lang,
                              ),
              ),
              _Composer(
                controller: _inputCtrl,
                focusNode: _focusNode,
                onSend: _send,
                onAttach: _openSharePicker,
                onClearAttach: () => setState(() => _pendingShared = null),
                pendingShared: _pendingShared,
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
          IconButton(
            onPressed: onBack,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 22,
              color: const Color(0xFF007AFF),
            ),
            splashRadius: 20,
          ),
          Expanded(
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
  final ScrollController scrollCtrl;
  final String lang;

  const _MessageList({
    required this.messages,
    required this.scrollCtrl,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final items = <dynamic>[];
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final prev = i > 0 ? messages[i - 1] : null;
      final sameDay = prev != null && _sameDay(prev.createdAt, msg.createdAt);
      if (!sameDay) items.add(_DateLabel(date: msg.createdAt, lang: lang));
      items.add(msg);
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _DateLabel) return _DateSeparator(label: item);

        final msg = item as _ChatMessage;

        final nextItem = index + 1 < items.length ? items[index + 1] : null;
        final nextMsg = nextItem is _ChatMessage ? nextItem : null;
        final isLastInGroup = nextMsg == null ||
            nextMsg.isMine != msg.isMine ||
            nextMsg.createdAt.difference(msg.createdAt).inMinutes >= 3;

        final prevItem = index > 0 ? items[index - 1] : null;
        final prevMsg = prevItem is _ChatMessage ? prevItem : null;
        final isFirstInGroup = prevMsg == null ||
            prevMsg.isMine != msg.isMine ||
            msg.createdAt.difference(prevMsg.createdAt).inMinutes >= 3;

        return _ChatBubble(
          message: msg,
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
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _ChatBubble({
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  static const _blue = Color(0xFF007AFF);
  static const _bubbleRadius = 18.0;
  static const _tailRadius = 4.0;

  BorderRadius _radius(bool isMine) {
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
    final isMine = message.isMine;
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    final bubbleBg = isMine
        ? _blue
        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8ED));
    final textColor = isMine ? Colors.white : scheme.onSurface;
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
                  color: message.failed
                      ? (isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFE5E5))
                      : bubbleBg,
                  borderRadius: _radius(isMine),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.shared != null)
                      _SharedCard(
                        shared: message.shared!,
                        isMine: isMine,
                        radius: _radius(isMine),
                      ),
                    if (message.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 9),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.35,
                            color: message.failed
                                ? (isDark ? Colors.red[200]! : Colors.red[700]!)
                                : textColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    if (message.shared != null && message.text.isEmpty)
                      const SizedBox(height: 4),
                  ],
                ),
              ),

              // Timestamp
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
                        Icon(Icons.access_time_rounded, size: 10, color: timeColor),
                      ] else if (isMine && message.failed) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.error_outline_rounded,
                            size: 11,
                            color: isDark ? Colors.red[300] : Colors.red[700]),
                      ] else if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_rounded, size: 11, color: timeColor),
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
// Shared card (inside bubble)
// ─────────────────────────────────────────────────────────────────────────────

class _SharedCard extends StatelessWidget {
  final _SharedItem shared;
  final bool isMine;
  final BorderRadius radius;

  const _SharedCard({
    required this.shared,
    required this.isMine,
    required this.radius,
  });

  dynamic _icon() {
    switch (shared.type) {
      case "EVENT":
        return HugeIcons.strokeRoundedCalendar03;
      case "PACKAGE":
        return HugeIcons.strokeRoundedLuggage01;
      default: // LISTING
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
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.06);
    final iconColor = isMine ? Colors.white : const Color(0xFF007AFF);
    final labelColor = isMine
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.45);
    final titleColor = isMine ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final dividerColor = isMine
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.10);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: radius.topLeft,
        topRight: radius.topRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                HugeIcon(icon: _icon(), size: 18, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (shared.title != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          shared.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
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
      ),
    );
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
  final VoidCallback onAttach;
  final VoidCallback onClearAttach;
  final _SharedItem? pendingShared;
  final bool busy;
  final String lang;
  final ColorScheme scheme;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.onClearAttach,
    required this.pendingShared,
    required this.busy,
    required this.lang,
    required this.scheme,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  bool get _canSend => _hasText || widget.pendingShared != null;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Attachment chip
              if (widget.pendingShared != null) ...[
                _AttachmentChip(
                  shared: widget.pendingShared!,
                  lang: widget.lang,
                  scheme: widget.scheme,
                  onRemove: widget.onClearAttach,
                ),
                const SizedBox(height: 6),
              ],

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach button
                  _AttachButton(
                    onTap: widget.onAttach,
                    scheme: widget.scheme,
                    isDark: isDark,
                    hasAttachment: widget.pendingShared != null,
                  ),
                  const SizedBox(width: 6),

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
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
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
                            onTap: _canSend ? widget.onSend : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _canSend
                                    ? const Color(0xFF007AFF)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.08)),
                              ),
                              child: Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedSent,
                                  size: 18,
                                  color: _canSend
                                      ? Colors.white
                                      : widget.scheme.onSurface
                                          .withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isDark;
  final bool hasAttachment;

  const _AttachButton({
    required this.onTap,
    required this.scheme,
    required this.isDark,
    required this.hasAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasAttachment
              ? const Color(0xFF007AFF).withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedAttachment02,
            size: 18,
            color: hasAttachment
                ? const Color(0xFF007AFF)
                : scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final _SharedItem shared;
  final String lang;
  final ColorScheme scheme;
  final VoidCallback onRemove;

  const _AttachmentChip({
    required this.shared,
    required this.lang,
    required this.scheme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    final typeLabel = shared.type == "EVENT"
        ? t(lang, "chat.shared_event")
        : shared.type == "PACKAGE"
            ? t(lang, "chat.shared_package")
            : t(lang, "chat.shared_listing");

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF007AFF).withValues(alpha: 0.30),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAttachment02,
            size: 14,
            color: Color(0xFF007AFF),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              shared.title != null
                  ? "$typeLabel · ${shared.title}"
                  : typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF007AFF),
              ),
              child: const Center(
                child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share picker sheet
// ─────────────────────────────────────────────────────────────────────────────

enum _ShareTab { events, listings, packages }

class _ShareOption {
  final String id;
  final String title;
  final String? subtitle;
  final _ShareTab tab;

  const _ShareOption({
    required this.id,
    required this.title,
    this.subtitle,
    required this.tab,
  });
}

class _ChatSharePickerSheet extends StatefulWidget {
  final String lang;
  final String accessToken;

  const _ChatSharePickerSheet({
    required this.lang,
    required this.accessToken,
  });

  @override
  State<_ChatSharePickerSheet> createState() => _ChatSharePickerSheetState();
}

class _ChatSharePickerSheetState extends State<_ChatSharePickerSheet> {
  _ShareTab _tab = _ShareTab.events;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<_ShareOption> _options = [];
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadOptions("");
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadOptions(_searchCtrl.text.trim());
    });
  }

  Future<void> _loadOptions(String query) async {
    if (!mounted) return;
    setState(() { _fetching = true; _options = []; });

    try {
      final String endpoint;
      switch (_tab) {
        case _ShareTab.events:
          endpoint = EventEndpoints.list;
          break;
        case _ShareTab.listings:
          endpoint = PlaceEndpoints.list;
          break;
        case _ShareTab.packages:
          endpoint = PackageEndpoints.list;
          break;
      }

      final params = {
        "page": "1",
        "page_size": "12",
        "ordering": "created_at",
        "sort": "desc",
        if (query.isNotEmpty) "search": query,
      };

      final uri = Api.url(endpoint).replace(queryParameters: params);
      final resp = await http.get(uri, headers: {
        "Accept": "application/json",
        "Authorization": "Bearer ${widget.accessToken}",
      });

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List raw = const [];
        if (decoded is Map) {
          raw = (decoded["results"] as List?) ?? const [];
        } else if (decoded is List) {
          raw = decoded;
        }

        final opts = raw.whereType<Map>().map((item) {
          final map = Map<String, dynamic>.from(item);
          final id = (map["id"] ?? "").toString();
          final title = (map["name"] ?? map["title"] ?? map["id"] ?? "").toString();
          final subtitle = (map["location"] ?? map["address"] ?? map["description"])?.toString();
          return _ShareOption(id: id, title: title, subtitle: subtitle, tab: _tab);
        }).toList();

        setState(() { _options = opts; _fetching = false; });
      } else {
        setState(() => _fetching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _switchTab(_ShareTab tab) {
    if (_tab == tab) return;
    _searchCtrl.clear();
    setState(() {
      _tab = tab;
      _options = [];
    });
    _loadOptions("");
  }

  String get _sharedType {
    switch (_tab) {
      case _ShareTab.events: return "EVENT";
      case _ShareTab.listings: return "LISTING";
      case _ShareTab.packages: return "PACKAGE";
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final lang = widget.lang;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.65, 0.92],
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      t(lang, "chat.share_title"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.07),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _TabChip(
                      label: t(lang, "chat.share_events"),
                      active: _tab == _ShareTab.events,
                      onTap: () => _switchTab(_ShareTab.events),
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      label: t(lang, "chat.share_listings"),
                      active: _tab == _ShareTab.listings,
                      onTap: () => _switchTab(_ShareTab.listings),
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      label: t(lang, "chat.share_packages"),
                      active: _tab == _ShareTab.packages,
                      onTap: () => _switchTab(_ShareTab.packages),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.10),
                      width: 0.7,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(fontSize: 14.5, color: scheme.onSurface),
                    decoration: InputDecoration(
                      hintText: t(lang, "chat.share_search_hint"),
                      hintStyle: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.35),
                        fontSize: 14.5,
                      ),
                      prefixIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 16,
                        color: scheme.onSurface.withValues(alpha: 0.40),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Results
              Expanded(
                child: _fetching
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF007AFF),
                        ),
                      )
                    : _options.isEmpty
                        ? Center(
                            child: Text(
                              t(lang, "chat.share_no_results"),
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurface.withValues(alpha: 0.40),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: _options.length,
                            itemBuilder: (context, index) {
                              final opt = _options[index];
                              return _ShareOptionTile(
                                option: opt,
                                onTap: () {
                                  Navigator.of(context).pop(
                                    _SharedItem(
                                      type: _sharedType,
                                      id: opt.id,
                                      title: opt.title,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF007AFF)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF007AFF)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.10)),
            width: 0.7,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? Colors.white
                : scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final _ShareOption option;
  final VoidCallback onTap;

  const _ShareOptionTile({required this.option, required this.onTap});

  dynamic _icon() {
    switch (option.tab) {
      case _ShareTab.events:
        return HugeIcons.strokeRoundedCalendar03;
      case _ShareTab.packages:
        return HugeIcons.strokeRoundedLuggage01;
      default:
        return HugeIcons.strokeRoundedLocation01;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(
                  icon: _icon(),
                  size: 20,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 16,
              color: scheme.onSurface.withValues(alpha: 0.30),
            ),
          ],
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
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);

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
