import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../widgets/chat/conversation/composer.dart";
import "../widgets/chat/conversation/header.dart";
import "../widgets/chat/conversation/message_list.dart";
import "../widgets/chat/conversation/models.dart";
import "../widgets/chat/conversation/share_picker.dart";
import "../widgets/chat/conversation/skeleton.dart";

// ─────────────────────────────────────────────────────────────────────────────
// AiChatThreadPage
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

class _AiChatThreadPageState extends State<AiChatThreadPage> {
  final List<ConvMessage> _messages = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  SharedItem? _pendingShared;

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

        // API returns newest-first — reverse for chronological display
        final parsed = raw
            .whereType<Map>()
            .map((m) => ConvMessage.fromJson(Map<String, dynamic>.from(m)))
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

    final optimisticId = "__pending_${DateTime.now().millisecondsSinceEpoch}";
    final optimistic = ConvMessage(
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
      _sending = true;
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
          setState(() {
            _messages[idx] = ConvMessage.fromJson(
              Map<String, dynamic>.from(serverMsgRaw),
            );
            _sending = false;
          });
        } else {
          setState(() {
            if (idx != -1) _messages[idx] = _messages[idx].copyWith(pending: false);
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
    final result = await showModalBottomSheet<SharedItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConvSharePickerSheet(
        lang: lang,
        accessToken: token,
      ),
    );

    if (result != null && mounted) {
      setState(() => _pendingShared = result);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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
              ConvHeader(
                name: widget.title,
                avatarUrl: widget.avatarUrl,
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: _loading
                    ? const ConvSkeleton()
                    : _error != null
                        ? ConvErrorState(
                            message: _error!,
                            onRetry: _fetch,
                          )
                        : _messages.isEmpty
                            ? ConvEmptyState(lang: lang)
                            : ConvMessageList(
                                messages: _messages,
                                scrollCtrl: _scrollCtrl,
                                lang: lang,
                              ),
              ),
              ConvComposer(
                controller: _inputCtrl,
                focusNode: _focusNode,
                onSend: _send,
                onAttach: _openSharePicker,
                onClearAttach: () => setState(() => _pendingShared = null),
                pendingShared: _pendingShared,
                busy: _sending,
                lang: lang,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
