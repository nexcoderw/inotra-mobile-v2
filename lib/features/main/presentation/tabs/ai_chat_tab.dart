import "dart:async";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/chat/conversation/composer.dart";
import "../widgets/chat/conversation/header.dart";
import "../widgets/chat/conversation/message_list.dart";
import "../widgets/chat/conversation/models.dart";

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  static const Duration _thinkingDelay = Duration(seconds: 3);

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Timer? _introTimer;
  bool _thinking = true;
  final List<ConvMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _startIntroSequence();
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startIntroSequence() {
    _introTimer?.cancel();
    _introTimer = Timer(_thinkingDelay, _revealGreeting);
  }

  void _revealGreeting() {
    if (!mounted) return;

    final lang = currentLangSync();
    final assistantName = t(lang, "ai.assistant_name");
    final greeting = t(lang, "ai.chat_greeting");

    setState(() {
      _thinking = false;
      _messages
        ..clear()
        ..add(
          ConvMessage(
            id: "__ai_intro__",
            text: greeting,
            createdAt: DateTime.now(),
            isMine: false,
            authorName: assistantName,
          ),
        );
    });

    _scrollToBottom();
  }

  void _sendLocalMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ConvMessage(
          id: "__local_${DateTime.now().microsecondsSinceEpoch}",
          text: text,
          createdAt: DateTime.now(),
          isMine: true,
        ),
      );
      _inputCtrl.clear();
    });

    _scrollToBottom();
  }

  void _showStaticNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final assistantName = t(lang, "ai.assistant_name");
    final statusLabel = t(lang, "ai.assistant_status");

    return SafeArea(
      child: Column(
        children: [
          ConvHeader(
            name: assistantName,
            statusLabel: statusLabel,
            showBackButton: false,
            onBack: () {},
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: _thinking
                  ? _AiThinkingStage(
                      key: const ValueKey("thinking"),
                      lang: lang,
                    )
                  : ConvMessageList(
                      key: const ValueKey("conversation"),
                      messages: _messages,
                      scrollCtrl: _scrollCtrl,
                      lang: lang,
                    ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: _thinking
                ? _ThinkingFooter(
                    key: const ValueKey("thinking-footer"),
                    lang: lang,
                  )
                : ConvComposer(
                    key: const ValueKey("composer"),
                    controller: _inputCtrl,
                    focusNode: _focusNode,
                    onSend: _sendLocalMessage,
                    onAttach: () =>
                        _showStaticNotice(t(lang, "common.coming_soon")),
                    onClearAttach: () {},
                    pendingShared: null,
                    busy: false,
                    lang: lang,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AiThinkingStage extends StatelessWidget {
  final String lang;

  const _AiThinkingStage({super.key, required this.lang});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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

class _ThinkingFooter extends StatelessWidget {
  final String lang;

  const _ThinkingFooter({super.key, required this.lang});

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
    _scale = Tween<double>(
      begin: 0.82,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _delayTimer = Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
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
