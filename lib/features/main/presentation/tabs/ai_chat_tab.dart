import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/chat_socket_service.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../pages/ai_chat_thread_page.dart";
import "../widgets/chat/conversation/header.dart";
import "../widgets/chat/conversation/message_list.dart";
import "../widgets/chat/conversation/models.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Flow state machine
// ─────────────────────────────────────────────────────────────────────────────

enum _AiFlow { loading, languagePicker, questions, conversation, noActiveChat }

// ─────────────────────────────────────────────────────────────────────────────
// AiChatTab
// ─────────────────────────────────────────────────────────────────────────────

class AiChatTab extends StatefulWidget {
  /// Fired whenever a new incoming message arrives while the tab may be hidden.
  /// The parent (MainShell) uses this to show the unread badge on the tab icon.
  final VoidCallback? onUnreadMessage;

  const AiChatTab({super.key, this.onUnreadMessage});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  _AiFlow _flow = _AiFlow.loading;
  bool _apiLoading = false;
  String? _threadId;
  int _stage = 0;
  String? _error;

  // Language picker
  List<Map<String, dynamic>> _languages = [];

  // Chat history (shown when no active thread)
  List<Map<String, dynamic>> _historicalThreads = [];
  bool _historyLoading = false;
  bool _historyError = false;

  // Questions flow
  final List<ConvMessage> _messages = [];
  final _knownIds = <String>{};
  List<String> _currentChoices = [];
  bool _awaitingResponse = false;
  ChatSocketService? _socket;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Auth header helper ────────────────────────────────────────────────────

  Map<String, String> get _headers {
    final token = AuthSession.instance.value.accessToken ?? "";
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  String get _token => AuthSession.instance.value.accessToken ?? "";

  // ── Init flow ─────────────────────────────────────────────────────────────

  Future<void> _initFlow() async {
    if (!mounted) return;
    setState(() {
      _apiLoading = true;
      _error = null;
      _flow = _AiFlow.loading;
    });

    if (_token.isEmpty) {
      if (mounted) setState(() { _apiLoading = false; _error = "auth"; });
      return;
    }

    try {
      // Pass auto_create:false so the server never creates a thread here.
      // We only create when the user explicitly taps "Start New Chat".
      final resp = await http.post(
        Api.url(ChatEndpoints.aiStart),
        headers: _headers,
        body: jsonEncode({"auto_create": false}),
      );

      if (!mounted) return;

      if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        return;
      }
      if (resp.statusCode >= 400) {
        setState(() { _apiLoading = false; _error = "${resp.statusCode}"; });
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      // No open thread exists — show history + start-new-chat screen.
      if (data["thread_id"] == null || data["has_active_thread"] == false) {
        await _fetchHistory();
        if (mounted) setState(() { _apiLoading = false; _flow = _AiFlow.noActiveChat; });
        return;
      }

      _threadId = data["thread_id"].toString();
      _stage = (data["onboarding_stage"] as int? ?? 0);

      // Inject any welcome message the server returned on fresh thread creation.
      _injectMessages(data);

      if (_stage == 5) {
        if (mounted) setState(() { _apiLoading = false; _flow = _AiFlow.conversation; });
        return;
      }

      if (_stage == 0) {
        await _fetchLanguages();
        if (mounted) setState(() { _apiLoading = false; _flow = _AiFlow.languagePicker; });
        return;
      }

      // stages 1–4: fetch full message history to restore question context.
      await _fetchMessages();
      if (mounted) {
        setState(() {
          _apiLoading = false;
          _flow = _AiFlow.questions;
        });
        _initSocket();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() { _apiLoading = false; _error = e.toString(); });
    }
  }

  // ── Start a new chat (called from noActiveChat screen) ────────────────────

  Future<void> _startNewChat() async {
    if (_apiLoading) return;
    setState(() { _apiLoading = true; _error = null; _flow = _AiFlow.loading; });

    try {
      final resp = await http.post(
        Api.url(ChatEndpoints.aiStart),
        headers: _headers,
        body: jsonEncode({"auto_create": true}),
      );

      if (!mounted) return;

      if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        return;
      }
      if (resp.statusCode >= 400) {
        setState(() { _apiLoading = false; _error = "${resp.statusCode}"; });
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _messages.clear();
      _knownIds.clear();
      _threadId = data["thread_id"].toString();
      _stage = (data["onboarding_stage"] as int? ?? 0);
      _injectMessages(data);

      if (_stage == 5) {
        if (mounted) setState(() { _apiLoading = false; _flow = _AiFlow.conversation; });
        return;
      }

      if (_stage == 0) {
        await _fetchLanguages();
        if (mounted) setState(() { _apiLoading = false; _flow = _AiFlow.languagePicker; });
        return;
      }

      await _fetchMessages();
      if (mounted) {
        setState(() { _apiLoading = false; _flow = _AiFlow.questions; });
        _initSocket();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() { _apiLoading = false; _error = e.toString(); });
    }
  }

  // ── Called by AiChatThreadPage when user ends the chat ────────────────────

  void _onChatEnded() {
    _socket?.disconnect();
    _socket = null;
    _threadId = null;
    _messages.clear();
    _knownIds.clear();
    _fetchHistory().then((_) {
      if (mounted) setState(() { _flow = _AiFlow.noActiveChat; });
    });
  }

  // ── Fetch thread history (closed + open threads) ──────────────────────────

  Future<void> _fetchHistory() async {
    if (mounted) setState(() { _historyLoading = true; _historyError = false; });
    try {
      final uri = Api.url(ChatEndpoints.threads)
          .replace(queryParameters: {"page": "1", "page_size": "20"});
      final resp = await http.get(
        uri,
        headers: {"Accept": "application/json", "Authorization": "Bearer $_token"},
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final raw = (body is Map ? (body["results"] as List?) : (body as List?)) ?? [];
        setState(() {
          _historicalThreads = raw
              .whereType<Map>()
              .map((t) => Map<String, dynamic>.from(t))
              .toList();
          _historyLoading = false;
          _historyError = false;
        });
      } else {
        setState(() { _historyLoading = false; _historyError = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _historyLoading = false; _historyError = true; });
    }
  }

  // ── Languages ─────────────────────────────────────────────────────────────

  Future<void> _fetchLanguages() async {
    try {
      final resp = await http.get(
        Api.url(ChatEndpoints.aiLanguages),
        headers: {"Accept": "application/json", "Authorization": "Bearer $_token"},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _languages = (data["languages"] as List? ?? [])
            .whereType<Map>()
            .map((l) => Map<String, dynamic>.from(l))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _selectLanguage(String code, String name) async {
    if (_threadId == null || _apiLoading) return;
    setState(() { _apiLoading = true; });
    HapticFeedback.lightImpact();

    try {
      final resp = await http.post(
        Api.url(ChatEndpoints.aiMessage(_threadId!)),
        headers: _headers,
        body: jsonEncode({"language_code": code}),
      );

      if (!mounted) return;

      if (resp.statusCode >= 400) {
        setState(() { _apiLoading = false; });
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _stage = (data["onboarding_stage"] as int? ?? 1);
      _injectMessages(data);

      if (mounted) {
        setState(() {
          _apiLoading = false;
          _flow = _AiFlow.questions;
          _updateCurrentChoices();
        });
        _initSocket();
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() { _apiLoading = false; });
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Future<void> _fetchMessages() async {
    if (_threadId == null) return;
    try {
      final uri = Api.url(ChatEndpoints.messages(_threadId!))
          .replace(queryParameters: {"page": "1", "page_size": "50"});
      final resp = await http.get(
        uri,
        headers: {"Accept": "application/json", "Authorization": "Bearer $_token"},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final raw = (body is Map ? (body["results"] as List?) : (body as List?)) ?? [];
        final msgs = raw
            .whereType<Map>()
            .map((m) => ConvMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList()
            .reversed
            .toList();
        _messages.clear();
        _knownIds.clear();
        for (final m in msgs) {
          _knownIds.add(m.id);
          _messages.add(m);
        }
        _updateCurrentChoices();
      }
    } catch (_) {}
  }

  void _injectMessages(Map<String, dynamic> data) {
    void _add(Map raw) {
      final m = ConvMessage.fromJson(Map<String, dynamic>.from(raw));
      if (!_knownIds.contains(m.id)) {
        _knownIds.add(m.id);
        _messages.add(m);
      }
    }

    final welcome = data["welcome_message"];
    if (welcome is Map) _add(welcome);

    final userMsg = data["user_message"];
    if (userMsg is Map) _add(userMsg);

    for (final raw in (data["ai_messages"] as List? ?? [])) {
      if (raw is Map) _add(raw);
    }
  }

  void _updateCurrentChoices() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (msg.senderType == "AI" && msg.metadata["type"] == "question") {
        final choices = msg.metadata["choices"];
        if (choices is List) {
          _currentChoices = choices.map((c) => c.toString()).toList();
          return;
        }
      }
    }
    _currentChoices = [];
  }

  // ── Answer question ───────────────────────────────────────────────────────

  Future<void> _answerQuestion(int choiceIndex, String label) async {
    if (_threadId == null || _awaitingResponse) return;
    HapticFeedback.lightImpact();

    // Optimistic user message
    final optimisticId = "__pending_${DateTime.now().millisecondsSinceEpoch}";
    setState(() {
      _awaitingResponse = true;
      _knownIds.add(optimisticId);
      _messages.add(ConvMessage(
        id: optimisticId,
        text: label,
        createdAt: DateTime.now(),
        isMine: true,
        senderType: "USER",
      ));
    });
    _scrollToBottom();

    try {
      final resp = await http.post(
        Api.url(ChatEndpoints.aiMessage(_threadId!)),
        headers: _headers,
        body: jsonEncode({"choice_index": choiceIndex, "text": label}),
      );

      if (!mounted) return;

      if (resp.statusCode >= 400) {
        setState(() {
          _awaitingResponse = false;
          _knownIds.remove(optimisticId);
          _messages.removeWhere((m) => m.id == optimisticId);
        });
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final nextStage = data["onboarding_stage"] as int? ?? _stage + 1;
      final isHandoff = data["handoff"] as bool? ?? false;

      // Replace optimistic with confirmed user message.
      final userMsgRaw = data["user_message"];
      final idx = _messages.indexWhere((m) => m.id == optimisticId);
      if (userMsgRaw is Map && idx != -1) {
        final real = ConvMessage.fromJson(Map<String, dynamic>.from(userMsgRaw));
        _knownIds.remove(optimisticId);
        _knownIds.add(real.id);
        _messages[idx] = real;
      } else if (idx != -1) {
        _knownIds.remove(optimisticId);
        _messages.removeAt(idx);
      }

      // Append AI messages.
      for (final raw in (data["ai_messages"] as List? ?? [])) {
        if (raw is Map) {
          final m = ConvMessage.fromJson(Map<String, dynamic>.from(raw));
          if (!_knownIds.contains(m.id)) {
            _knownIds.add(m.id);
            _messages.add(m);
          }
        }
      }

      setState(() {
        _stage = nextStage;
        _awaitingResponse = false;
        if (isHandoff) {
          _flow = _AiFlow.conversation;
        } else {
          _updateCurrentChoices();
        }
      });

      _scrollToBottom();
      if (isHandoff) {
        _socket?.disconnect();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _awaitingResponse = false;
          final idx = _messages.indexWhere((m) => m.id == optimisticId);
          _knownIds.remove(optimisticId);
          if (idx != -1) _messages.removeAt(idx);
        });
      }
    }
  }

  // ── No active chat (ended or never started) ───────────────────────────────

  Widget _buildNoActiveChat({required String lang, required ColorScheme scheme, required Key key}) {
    final isDark = scheme.brightness == Brightness.dark;

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // ── Start new chat card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                scheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.16),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSparkles,
                    size: 26,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Plan Your Next Trip",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Our AI assistant will ask you a few questions\nto match you with the perfect experience.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: scheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _apiLoading ? null : _startNewChat,
                  icon: _apiLoading
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Start New Chat"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Previous conversations ───────────────────────────────────────────
        const SizedBox(height: 28),
        Text(
          "Previous Conversations",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),
        if (_historyLoading) ...[
          _HistoryShimmerCard(scheme: scheme, isDark: isDark),
          const SizedBox(height: 10),
          _HistoryShimmerCard(scheme: scheme, isDark: isDark),
          const SizedBox(height: 10),
          _HistoryShimmerCard(scheme: scheme, isDark: isDark),
        ] else if (_historyError)
          _HistoryErrorRow(
            scheme: scheme,
            isDark: isDark,
            onRetry: _fetchHistory,
          )
        else if (_historicalThreads.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "No previous conversations",
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
          )
        else
          ..._historicalThreads.map((thread) {
            final threadId = thread["id"]?.toString() ?? "";
            final topic = thread["topic"]?.toString() ?? "Trip Planning";
            final preview = thread["last_message_preview"]?.toString();
            final isOpen = thread["is_open"] as bool? ?? false;
            final rawDate = thread["last_message_at"] ?? thread["updated_at"] ?? thread["created_at"];
            DateTime? date;
            if (rawDate is String) date = DateTime.tryParse(rawDate);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryThreadCard(
                topic: topic,
                preview: preview,
                isOpen: isOpen,
                date: date,
                scheme: scheme,
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AiChatThreadPage(
                        threadId: threadId,
                        title: topic,
                        showBackButton: true,
                        checkTyping: isOpen,
                        statusLabel: isOpen ? null : "Ended",
                      ),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  // ── WebSocket ──────────────────────────────────────────────────────────────

  void _initSocket() {
    _socket?.disconnect();
    if (_threadId == null || _token.isEmpty) return;
    _socket = ChatSocketService(
      threadId: _threadId!,
      accessToken: _token,
      onNewMessage: _onSocketMessage,
    );
    _socket!.connect();
  }

  void _onSocketMessage(Map<String, dynamic> raw) {
    if (!mounted || _flow != _AiFlow.questions) return;
    final msg = ConvMessage.fromJson(raw);
    if (_knownIds.contains(msg.id)) return;

    final atBottom = !_scrollCtrl.hasClients ||
        _scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 120;

    setState(() {
      _knownIds.add(msg.id);
      _messages.add(msg);
      _updateCurrentChoices();
    });
    widget.onUnreadMessage?.call();

    if (atBottom) _scrollToBottom();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    // Stage-5 conversation fills the tab completely — AiChatThreadPage owns its header.
    if (_flow == _AiFlow.conversation && _threadId != null) {
      return SafeArea(
        child: AiChatThreadPage(
          key: ValueKey(_threadId),
          threadId: _threadId!,
          title: t(lang, "ai.assistant_name"),
          embedded: true,
          showHeader: true,
          showBackButton: false,
          checkTyping: true,
          onChatEnded: _onChatEnded,
          onNewMessage: widget.onUnreadMessage,
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          ConvHeader(
            name: t(lang, "ai.assistant_name"),
            statusLabel: t(lang, "ai.assistant_status"),
            showBackButton: false,
            onBack: () {},
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              child: _buildFlowBody(lang: lang, scheme: scheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowBody({required String lang, required ColorScheme scheme}) {
    switch (_flow) {
      case _AiFlow.loading:
        return _buildLoading(lang: lang, scheme: scheme, key: const ValueKey("loading"));
      case _AiFlow.languagePicker:
        return _buildLanguagePicker(lang: lang, scheme: scheme, key: const ValueKey("lang-picker"));
      case _AiFlow.questions:
        return _buildQuestions(lang: lang, scheme: scheme, key: const ValueKey("questions"));
      case _AiFlow.conversation:
        return const SizedBox.shrink(key: ValueKey("conversation-placeholder"));
      case _AiFlow.noActiveChat:
        return _buildNoActiveChat(lang: lang, scheme: scheme, key: const ValueKey("no-active-chat"));
    }
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading({required String lang, required ColorScheme scheme, required Key key}) {
    if (_error != null) {
      return Center(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.error, size: 44),
              const SizedBox(height: 14),
              Text(
                t(lang, "common.error"),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface),
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: _initFlow,
                child: Text(t(lang, "common.try_again")),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      key: key,
      children: [
        Expanded(child: _AiThinkingStage(lang: lang)),
        _ThinkingFooter(lang: lang),
      ],
    );
  }

  // ── Language picker ───────────────────────────────────────────────────────

  Widget _buildLanguagePicker({required String lang, required ColorScheme scheme, required Key key}) {
    final isDark = scheme.brightness == Brightness.dark;

    return Column(
      key: key,
      children: [
        Expanded(
          child: _languages.isEmpty
              ? const Center(child: CircularProgressIndicator.adaptive())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome bubble (from API welcome message, if any)
                      if (_messages.isNotEmpty)
                        _WelcomeBubble(
                          text: _messages.first.text,
                          scheme: scheme,
                          isDark: isDark,
                        ),
                      if (_messages.isNotEmpty) const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _languages.map((l) {
                          final code = l["code"]?.toString() ?? "";
                          final name = l["name"]?.toString() ?? code;
                          return _LanguageChip(
                            name: name,
                            disabled: _apiLoading,
                            scheme: scheme,
                            isDark: isDark,
                            onTap: () => _selectLanguage(code, name),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
        ),
        if (_apiLoading) _ThinkingFooter(lang: lang),
      ],
    );
  }

  // ── Questions ─────────────────────────────────────────────────────────────

  Widget _buildQuestions({required String lang, required ColorScheme scheme, required Key key}) {
    return Column(
      key: key,
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ConvMessageList(
                  messages: _messages,
                  scrollCtrl: _scrollCtrl,
                  lang: lang,
                ),
        ),
        if (_awaitingResponse)
          _ThinkingFooter(lang: lang)
        else if (_currentChoices.isNotEmpty)
          _ChoicesFooter(
            choices: _currentChoices,
            scheme: scheme,
            onTap: _answerQuestion,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WelcomeBubble — renders the first AI message as a styled bubble
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBubble extends StatelessWidget {
  final String text;
  final ColorScheme scheme;
  final bool isDark;

  const _WelcomeBubble({
    required this.text,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: isDark ? 0.30 : 0.18),
                scheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.14),
              width: 0.8,
            ),
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSparkles,
              size: 16,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: scheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LanguageChip — tappable language selection chip
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageChip extends StatelessWidget {
  final String name;
  final bool disabled;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.name,
    required this.disabled,
    required this.scheme,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                scheme.primary.withValues(alpha: isDark ? 0.10 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18),
              width: 0.8,
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChoicesFooter — 4 multiple-choice answer buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ChoicesFooter extends StatelessWidget {
  final List<String> choices;
  final ColorScheme scheme;
  final void Function(int index, String label) onTap;

  const _ChoicesFooter({
    required this.choices,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < choices.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ChoiceButton(
              label: choices[i],
              scheme: scheme,
              isDark: isDark,
              onTap: () => onTap(i, choices[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.scheme,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.7)
                : scheme.surfaceContainerHigh.withValues(alpha: 0.6),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.07),
              width: 0.7,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AiThinkingStage — full-screen loading card shown while initialising
// ─────────────────────────────────────────────────────────────────────────────

class _AiThinkingStage extends StatelessWidget {
  final String lang;

  const _AiThinkingStage({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                scheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.16),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSparkles,
                    size: 30,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                t(lang, "ai.thinking"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(lang, "ai.thinking_subtitle"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ThinkingDot(delay: 0),
                  SizedBox(width: 8),
                  _ThinkingDot(delay: 180),
                  SizedBox(width: 8),
                  _ThinkingDot(delay: 360),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ThinkingFooter — compact footer shown while waiting for an API response
// ─────────────────────────────────────────────────────────────────────────────

class _ThinkingFooter extends StatelessWidget {
  final String lang;

  const _ThinkingFooter({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.86 : 0.96),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.10),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedMessage02,
                size: 20,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t(lang, "ai.thinking"),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t(lang, "ai.thinking_subtitle"),
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ThinkingDot — animated bouncing dot used in loading indicators
// ─────────────────────────────────────────────────────────────────────────────

class _ThinkingDot extends StatefulWidget {
  final int delay;

  const _ThinkingDot({required this.delay});

  @override
  State<_ThinkingDot> createState() => _ThinkingDotState();
}

class _ThinkingDotState extends State<_ThinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _delayTimer = Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        height: 10,
        width: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HistoryThreadCard — single row in the previous conversations list
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryThreadCard extends StatelessWidget {
  final String topic;
  final String? preview;
  final bool isOpen;
  final DateTime? date;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onTap;

  const _HistoryThreadCard({
    required this.topic,
    required this.isOpen,
    required this.scheme,
    required this.isDark,
    required this.onTap,
    this.preview,
    this.date,
  });

  String _formatDate() {
    if (date == null) return "";
    final now = DateTime.now();
    final diff = now.difference(date!);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inHours < 1) return "${diff.inMinutes}m ago";
    if (diff.inDays < 1) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${date!.day}/${date!.month}/${date!.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : scheme.surfaceContainerHigh.withValues(alpha: 0.4),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.7,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMessage02,
                    size: 17,
                    color: scheme.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (preview != null && preview!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        preview!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isOpen
                      ? scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10)
                      : scheme.onSurface.withValues(alpha: 0.06),
                ),
                child: Text(
                  isOpen ? "Active" : "Ended",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isOpen
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.4),
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
// _HistoryShimmerCard — pulsing placeholder while history is loading
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryShimmerCard extends StatefulWidget {
  final ColorScheme scheme;
  final bool isDark;

  const _HistoryShimmerCard({required this.scheme, required this.isDark});

  @override
  State<_HistoryShimmerCard> createState() => _HistoryShimmerCardState();
}

class _HistoryShimmerCardState extends State<_HistoryShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 0.7).animate(
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
    final isDark = widget.isDark;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final v = _pulse.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : scheme.surfaceContainerHigh.withValues(alpha: 0.4),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.7,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.onSurface.withValues(alpha: v * 0.12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: scheme.onSurface.withValues(alpha: v * 0.12),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: scheme.onSurface.withValues(alpha: v * 0.08),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 20,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: scheme.onSurface.withValues(alpha: v * 0.08),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HistoryErrorRow — inline error + retry for the history section
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryErrorRow extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onRetry;

  const _HistoryErrorRow({
    required this.scheme,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.errorContainer.withValues(alpha: isDark ? 0.18 : 0.10),
        border: Border.all(
          color: scheme.error.withValues(alpha: isDark ? 0.22 : 0.14),
          width: 0.7,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: scheme.error.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn't load history",
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              "Retry",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
