import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../pages/ai_chat_thread_page.dart";
import "../widgets/chat/conversation/header.dart";
import "../widgets/chat/conversation/message_list.dart";
import "../widgets/chat/conversation/models.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Flow state machine
// ─────────────────────────────────────────────────────────────────────────────

enum _AiFlow { loading, languagePicker, questions, conversation }

// ─────────────────────────────────────────────────────────────────────────────
// AiChatTab
// ─────────────────────────────────────────────────────────────────────────────

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

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

  // Questions flow
  final List<ConvMessage> _messages = [];
  final _knownIds = <String>{};
  List<String> _currentChoices = [];
  bool _awaitingResponse = false;
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 3);
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
      final resp = await http.post(
        Api.url(ChatEndpoints.aiStart),
        headers: _headers,
        body: jsonEncode({}),
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
        _startPolling();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() { _apiLoading = false; _error = e.toString(); });
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
        _startPolling();
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
    _stopPolling();
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
      if (!isHandoff) _startPolling();
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

  // ── Polling ───────────────────────────────────────────────────────────────

  void _startPolling() {
    if (_pollTimer?.isActive ?? false) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollMessages());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollMessages() async {
    if (!mounted || _awaitingResponse || _threadId == null) return;
    try {
      final uri = Api.url(ChatEndpoints.messages(_threadId!))
          .replace(queryParameters: {"page": "1", "page_size": "20"});
      final resp = await http.get(
        uri,
        headers: {"Accept": "application/json", "Authorization": "Bearer $_token"},
      );
      if (!mounted || resp.statusCode != 200) return;

      final body = jsonDecode(resp.body);
      final raw = (body is Map ? (body["results"] as List?) : (body as List?)) ?? [];
      final incoming = raw
          .whereType<Map>()
          .map((m) => ConvMessage.fromJson(Map<String, dynamic>.from(m)))
          .where((m) => !_knownIds.contains(m.id))
          .toList()
          .reversed
          .toList();

      if (incoming.isEmpty) return;

      final atBottom = !_scrollCtrl.hasClients ||
          _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120;

      setState(() {
        for (final m in incoming) {
          _knownIds.add(m.id);
          _messages.add(m);
        }
        _updateCurrentChoices();
      });

      if (atBottom) _scrollToBottom();
    } catch (_) {}
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
