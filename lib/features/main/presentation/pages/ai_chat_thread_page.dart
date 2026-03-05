import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";

class AiChatThreadPage extends StatefulWidget {
  final String threadId;
  final String title;
  const AiChatThreadPage({super.key, required this.threadId, required this.title});

  @override
  State<AiChatThreadPage> createState() => _AiChatThreadPageState();
}

class _AiChatThreadPageState extends State<AiChatThreadPage> {
  final List<_ChatMessage> _messages = [];
  final _inputCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = "Not authenticated";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(ChatEndpoints.messages(widget.threadId));
      final resp = await http.get(uri, headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List raw = const [];
        if (decoded is Map) {
          raw = (decoded["results"] ?? decoded["data"] ?? const []) as List? ?? const [];
        } else if (decoded is List) {
          raw = decoded;
        }
        final msgs = raw
            .whereType<Map>()
            .map((m) => _ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        if (mounted) setState(() => _messages..clear()..addAll(msgs));
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        setState(() => _error = "401");
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;

    setState(() => _sending = true);
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

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _inputCtrl.clear();
        await _fetch();
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        setState(() => _error = "401");
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: widget.title,
      showAppBar: false,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: PageHeader(title: widget.title),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorCard(
                          message: _error!,
                          onRetry: _fetch,
                        )
                      : _MessageList(messages: _messages),
            ),
            _Composer(
              controller: _inputCtrl,
              onSend: _send,
              busy: _sending,
              lang: lang,
              scheme: scheme,
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------- UI COMPONENTS ------------------------- */

class _MessageList extends StatelessWidget {
  final List<_ChatMessage> messages;
  const _MessageList({required this.messages});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final me = AuthSession.instance.value.user?["id"]?.toString();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      reverse: false,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final m = messages[index];
        final isMine = me != null && m.authorId == me;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isMine
                  ? scheme.primary.withOpacity(0.15)
                  : scheme.surfaceVariant.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  m.text,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(m.createdAt),
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}";
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool busy;
  final String lang;
  final ColorScheme scheme;

  const _Composer({
    required this.controller,
    required this.onSend,
    required this.busy,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: t(lang, "chat.type_message"),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: busy ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: busy
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : HugeIcon(
                      icon: HugeIcons.strokeRoundedSend03,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
              label: Text(
                t(lang, "chat.send"),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedWifiError01,
            color: scheme.error,
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(t(currentLangSync(), "common.try_again")),
          ),
        ],
      ),
    );
  }
}

/* ------------------------- DATA MODEL ------------------------- */

class _ChatMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final String? authorId;

  _ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.authorId,
  });

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    return _ChatMessage(
      id: (json["id"] ?? "").toString(),
      text: (json["text"] ?? json["message"] ?? "").toString(),
      createdAt: parse(json["created_at"]?.toString()) ?? DateTime.now(),
      authorId: (json["author"]?["id"] ?? json["user_id"] ?? "").toString(),
    );
  }
}
