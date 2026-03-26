import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/observers/audit_route_observer.dart";
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
  final bool embedded;
  final bool showHeader;
  final bool showBackButton;
  final String? statusLabel;
  final String? introMessage;
  /// When true, polls the thread status endpoint to show a rep-typing indicator.
  final bool checkTyping;

  const AiChatThreadPage({
    super.key,
    required this.threadId,
    required this.title,
    this.avatarUrl,
    this.embedded = false,
    this.showHeader = true,
    this.showBackButton = true,
    this.statusLabel,
    this.introMessage,
    this.checkTyping = false,
  });

  @override
  State<AiChatThreadPage> createState() => _AiChatThreadPageState();
}

class _AiChatThreadPageState extends State<AiChatThreadPage>
    with WidgetsBindingObserver, RouteAware {
  final List<ConvMessage> _messages = [];
  final _knownIds = <String>{};
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  bool _loading = true;
  bool _sending = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 50;
  static const Duration _pollInterval = Duration(seconds: 3);
  String? _error;
  SharedItem? _pendingShared;
  Timer? _pollTimer;
  ModalRoute<dynamic>? _route;
  bool _isAppInForeground = true;
  bool _isRouteVisible = true;
  bool _isRepTyping = false;

  bool get _canPoll =>
      _isAppInForeground && _isRouteVisible && !_loading && mounted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || identical(route, _route)) return;

    AuditRouteObserver.instance.unsubscribe(this);
    _route = route;
    AuditRouteObserver.instance.subscribe(this, route as dynamic);
    _isRouteVisible = route.isCurrent;
    _syncPollingState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuditRouteObserver.instance.unsubscribe(this);
    _stopPolling();
    _scrollCtrl.removeListener(_onScroll);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Pause polling when app goes to background; resume when it comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    _syncPollingState(immediate: _isAppInForeground);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels <= 80 &&
        !_loadingMore &&
        _hasMore &&
        !_loading) {
      _loadMore();
    }
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  void _startPolling() {
    final token = AuthSession.instance.value.accessToken;
    if (!_canPoll || token == null || token.isEmpty) return;
    if (_pollTimer?.isActive ?? false) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollNewMessages());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _syncPollingState({bool immediate = false}) {
    if (!_canPoll) {
      _stopPolling();
      return;
    }
    if (immediate) {
      _pollNewMessages();
    }
    _startPolling();
  }

  @override
  void didPush() {
    _isRouteVisible = true;
    _syncPollingState(immediate: true);
  }

  @override
  void didPopNext() {
    _isRouteVisible = true;
    _syncPollingState(immediate: true);
  }

  @override
  void didPushNext() {
    _isRouteVisible = false;
    _syncPollingState();
  }

  @override
  void didPop() {
    _isRouteVisible = false;
    _syncPollingState();
  }

  /// Silently fetches the latest page of messages and appends any that are new.
  /// Never triggers a loading spinner — runs completely in the background.
  Future<void> _pollNewMessages() async {
    if (!mounted || _loading) return;
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;

    // Poll typing status in parallel when requested.
    if (widget.checkTyping) _pollTypingStatus(token).ignore();

    try {
      final uri = Api.url(
        ChatEndpoints.messages(widget.threadId),
      ).replace(queryParameters: {"page": "1", "page_size": "20"});
      final resp = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted || resp.statusCode != 200) return;

      final decoded = jsonDecode(resp.body);
      List raw = const [];
      if (decoded is Map) {
        raw = (decoded["results"] as List?) ?? const [];
      } else if (decoded is List) {
        raw = decoded;
      }

      // API returns newest-first. Filter out already-known messages, then
      // reverse to chronological order before appending.
      final incoming = raw
          .whereType<Map>()
          .map((m) => ConvMessage.fromJson(Map<String, dynamic>.from(m)))
          .where((m) => !_knownIds.contains(m.id))
          .toList()
          .reversed
          .toList();

      if (incoming.isEmpty) return;

      // Only auto-scroll if the user is already near the bottom (≤120 px away).
      final atBottom =
          !_scrollCtrl.hasClients ||
          _scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 120;

      setState(() {
        for (final msg in incoming) {
          _knownIds.add(msg.id);
          _messages.add(msg);
        }
      });

      if (atBottom) _scrollToBottom();
      _markRead(token);
    } catch (_) {
      // Silent — polling errors are non-fatal.
    }
  }

  Future<void> _pollTypingStatus(String token) async {
    try {
      final resp = await http.get(
        Api.url(ChatEndpoints.threadStatus(widget.threadId)),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (!mounted || resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final isTyping = data["is_rep_typing"] as bool? ?? false;
      if (_isRepTyping != isTyping) {
        setState(() => _isRepTyping = isTyping);
      }
    } catch (_) {
      // Silent — non-fatal.
    }
  }

  // ── Fetch (initial / refresh) ─────────────────────────────────────────────

  Future<void> _fetch() async {
    _stopPolling();
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = "auth";
        });
      return;
    }

    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });

    try {
      final uri = Api.url(
        ChatEndpoints.messages(widget.threadId),
      ).replace(queryParameters: {"page": "1", "page_size": "$_pageSize"});
      final resp = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List raw = const [];
        bool hasNext = false;
        if (decoded is Map) {
          raw = (decoded["results"] as List?) ?? const [];
          hasNext = decoded["next"] != null;
        } else if (decoded is List) {
          raw = decoded;
        }

        // API returns newest-first — reverse for chronological display.
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
          _knownIds
            ..clear()
            ..addAll(parsed.map((m) => m.id));
          _loading = false;
          _hasMore = hasNext;
          _page = 1;
        });
        _scrollToBottom();
        _markRead(token);
        _syncPollingState();
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        if (mounted)
          setState(() {
            _loading = false;
            _error = "401";
          });
      } else {
        setState(() {
          _loading = false;
          _error = "${resp.statusCode}";
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  // ── Load more (older messages on scroll to top) ───────────────────────────

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;

    setState(() => _loadingMore = true);

    final nextPage = _page + 1;
    try {
      final uri = Api.url(ChatEndpoints.messages(widget.threadId)).replace(
        queryParameters: {"page": "$nextPage", "page_size": "$_pageSize"},
      );
      final resp = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List raw = const [];
        bool hasNext = false;
        if (decoded is Map) {
          raw = (decoded["results"] as List?) ?? const [];
          hasNext = decoded["next"] != null;
        } else if (decoded is List) {
          raw = decoded;
        }

        final older = raw
            .whereType<Map>()
            .map((m) => ConvMessage.fromJson(Map<String, dynamic>.from(m)))
            .where((m) => !_knownIds.contains(m.id))
            .toList()
            .reversed
            .toList();

        if (older.isEmpty) {
          setState(() {
            _loadingMore = false;
            _hasMore = false;
          });
          return;
        }

        // Save scroll offset so we don't jump after prepending.
        final prevExtent = _scrollCtrl.hasClients
            ? _scrollCtrl.position.maxScrollExtent
            : 0.0;

        setState(() {
          for (final m in older) _knownIds.add(m.id);
          _messages.insertAll(0, older);
          _page = nextPage;
          _hasMore = hasNext;
          _loadingMore = false;
        });

        // Restore position after layout so the view doesn't jump.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            final newExtent = _scrollCtrl.position.maxScrollExtent;
            _scrollCtrl.jumpTo(newExtent - prevExtent);
          }
        });
      } else {
        if (mounted) setState(() => _loadingMore = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
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
      _knownIds.add(optimisticId);
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
          final serverMsg = ConvMessage.fromJson(
            Map<String, dynamic>.from(serverMsgRaw),
          );
          setState(() {
            // Replace optimistic ID with real server ID.
            _knownIds.remove(optimisticId);
            _knownIds.add(serverMsg.id);
            _messages[idx] = serverMsg;
            _sending = false;
          });
        } else {
          setState(() {
            if (idx != -1)
              _messages[idx] = _messages[idx].copyWith(pending: false);
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
            _messages[idx] = _messages[idx].copyWith(
              pending: false,
              failed: true,
            );
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
            _messages[idx] = _messages[idx].copyWith(
              pending: false,
              failed: true,
            );
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
      builder: (_) => ConvSharePickerSheet(lang: lang, accessToken: token),
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

  List<ConvMessage> _buildDisplayMessages() {
    final intro = (widget.introMessage ?? "").trim();
    if (intro.isEmpty) {
      return _messages;
    }

    final alreadyPresent = _messages.any(
      (message) => !message.isMine && message.text.trim() == intro,
    );
    if (alreadyPresent) {
      return _messages;
    }

    final introCreatedAt = _messages.isNotEmpty
        ? _messages.first.createdAt.subtract(const Duration(minutes: 1))
        : DateTime.now();

    return [
      ConvMessage(
        id: "__intro__${widget.threadId}",
        text: intro,
        createdAt: introCreatedAt,
        isMine: false,
        authorName: widget.title,
      ),
      ..._messages,
    ];
  }

  Widget _buildConversationBody({
    required String lang,
    required ColorScheme scheme,
  }) {
    final displayMessages = _buildDisplayMessages();

    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surface),
      child: Column(
        children: [
          if (widget.showHeader)
            ConvHeader(
              name: widget.title,
              avatarUrl: widget.avatarUrl,
              statusLabel: widget.statusLabel,
              showBackButton: widget.showBackButton,
              onBack: () => Navigator.maybePop(context),
            ),
          Expanded(
            child: _loading
                ? const ConvSkeleton()
                : _error != null
                ? ConvErrorState(message: _error!, onRetry: _fetch)
                : displayMessages.isEmpty
                ? ConvEmptyState(lang: lang)
                : Column(
                    children: [
                      if (_loadingMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      Expanded(
                        child: ConvMessageList(
                          messages: displayMessages,
                          scrollCtrl: _scrollCtrl,
                          lang: lang,
                        ),
                      ),
                    ],
                  ),
          ),
          if (_isRepTyping) _RepTypingBubble(scheme: scheme),
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
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final conversationBody = _buildConversationBody(lang: lang, scheme: scheme);

    if (widget.embedded) {
      return conversationBody;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: scheme.surface,
        resizeToAvoidBottomInset: true,
        body: SafeArea(child: conversationBody),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rep typing indicator bubble (shown when the assigned rep is composing a reply)
// ─────────────────────────────────────────────────────────────────────────────

class _RepTypingBubble extends StatefulWidget {
  final ColorScheme scheme;

  const _RepTypingBubble({required this.scheme});

  @override
  State<_RepTypingBubble> createState() => _RepTypingBubbleState();
}

class _RepTypingBubbleState extends State<_RepTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            ),
            child: Center(
              child: Icon(
                Icons.support_agent_rounded,
                size: 15,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FadeTransition(
            opacity: _fade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surfaceContainerHighest
                    : scheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _TypingDot(delay: 0),
                  SizedBox(width: 5),
                  _TypingDot(delay: 180),
                  SizedBox(width: 5),
                  _TypingDot(delay: 360),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _delayTimer = Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        height: 7,
        width: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
