import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../../../auth/presentation/widgets/quick_login_dialog.dart";
import "../pages/ai_chat_thread_page.dart";
import "../widgets/chat/conversation/bubble.dart";
import "../widgets/chat/conversation/header.dart";
import "../widgets/chat/conversation/models.dart";
import "../widgets/chat/conversation/skeleton.dart";

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  bool _loading = true;
  bool _authPrompted = false;
  String? _error;
  _ChatThread? _activeThread;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (!AuthSession.instance.value.isAuthenticated) {
      if (!_authPrompted) {
        _authPrompted = true;
        await QuickLoginDialog.show(context);
      }
      if (!AuthSession.instance.value.isAuthenticated) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }
    }

    await _fetchPrimaryThread();
  }

  Future<void> _fetchPrimaryThread() async {
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = "auth";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final resp = await http.get(
        Api.url(
          ChatEndpoints.threads,
        ).replace(queryParameters: const {"page": "1", "page_size": "50"}),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List raw = const [];

        if (decoded is Map) {
          raw =
              (decoded["results"] ?? decoded["data"] ?? const []) as List? ??
              const [];
        } else if (decoded is List) {
          raw = decoded;
        }

        final threads = raw
            .whereType<Map>()
            .map(
              (item) => _ChatThread.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

        setState(() {
          _activeThread = _selectAiThread(threads);
          _loading = false;
        });
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        await QuickLoginDialog.show(context);
        await _init();
      } else {
        setState(() {
          _loading = false;
          _error = "Status ${resp.statusCode}";
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  _ChatThread? _selectAiThread(List<_ChatThread> threads) {
    for (final thread in threads) {
      if (thread.isAiThread) return thread;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final assistantName = t(lang, "ai.assistant_name");
    final statusLabel = t(lang, "ai.assistant_status");
    final greeting = t(lang, "ai.chat_greeting");

    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: _loading
            ? _AiConversationLoading(
                key: const ValueKey("loading"),
                title: assistantName,
                statusLabel: statusLabel,
              )
            : _error != null
            ? _AiConversationError(
                key: const ValueKey("error"),
                lang: lang,
                title: assistantName,
                statusLabel: statusLabel,
                message: _error!,
                onRetry: _fetchPrimaryThread,
              )
            : _activeThread != null
            ? AiChatThreadPage(
                key: ValueKey(_activeThread!.id),
                threadId: _activeThread!.id,
                title: _activeThread!.displayTitle,
                embedded: true,
                showBackButton: false,
                statusLabel: statusLabel,
                introMessage: greeting,
              )
            : _AiConversationPlaceholder(
                key: const ValueKey("placeholder"),
                lang: lang,
                title: assistantName,
                statusLabel: statusLabel,
                greeting: greeting,
                onRefresh: _fetchPrimaryThread,
              ),
      ),
    );
  }
}

class _AiConversationLoading extends StatelessWidget {
  final String title;
  final String statusLabel;

  const _AiConversationLoading({
    super.key,
    required this.title,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConvHeader(
          name: title,
          statusLabel: statusLabel,
          showBackButton: false,
          onBack: () {},
        ),
        const Expanded(child: ConvSkeleton()),
        const _ComposerStatusCard(
          icon: HugeIcons.strokeRoundedSparkles,
          titleKey: "ai.preparing_title",
          subtitleKey: "ai.preparing_subtitle",
        ),
      ],
    );
  }
}

class _AiConversationError extends StatelessWidget {
  final String lang;
  final String title;
  final String statusLabel;
  final String message;
  final VoidCallback onRetry;

  const _AiConversationError({
    super.key,
    required this.lang,
    required this.title,
    required this.statusLabel,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ConvHeader(
          name: title,
          statusLabel: statusLabel,
          showBackButton: false,
          onBack: () {},
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        color: scheme.error,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t(lang, "chat.load_error"),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: scheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(t(lang, "common.try_again")),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const _ComposerStatusCard(
          icon: HugeIcons.strokeRoundedSparkles,
          titleKey: "ai.preparing_title",
          subtitleKey: "ai.preparing_subtitle",
        ),
      ],
    );
  }
}

class _AiConversationPlaceholder extends StatelessWidget {
  final String lang;
  final String title;
  final String statusLabel;
  final String greeting;
  final Future<void> Function() onRefresh;

  const _AiConversationPlaceholder({
    super.key,
    required this.lang,
    required this.title,
    required this.statusLabel,
    required this.greeting,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final introMessage = ConvMessage(
      id: "__ai_intro_placeholder__",
      text: greeting,
      createdAt: DateTime.now(),
      isMine: false,
      authorName: title,
    );

    return Column(
      children: [
        ConvHeader(
          name: title,
          statusLabel: statusLabel,
          showBackButton: false,
          onBack: () {},
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 18),
            children: [
              ConvBubble(
                message: introMessage,
                isFirstInGroup: true,
                isLastInGroup: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.10),
                        scheme.primary.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSparkles,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t(lang, "ai.chat_intro_title"),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t(lang, "ai.chat_intro_subtitle"),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.55,
                          color: scheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => onRefresh(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(t(lang, "ai.refresh_conversation")),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const _ComposerStatusCard(
          icon: HugeIcons.strokeRoundedMessage02,
          titleKey: "ai.composer_locked_title",
          subtitleKey: "ai.composer_locked_subtitle",
        ),
      ],
    );
  }
}

class _ComposerStatusCard extends StatelessWidget {
  final dynamic icon;
  final String titleKey;
  final String subtitleKey;

  const _ComposerStatusCard({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
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
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(icon: icon, size: 20, color: scheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t(lang, titleKey),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t(lang, subtitleKey),
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

class _ChatThread {
  final String id;
  final String title;
  final String? otherUserName;
  final String? currentHandler;

  const _ChatThread({
    required this.id,
    required this.title,
    required this.otherUserName,
    required this.currentHandler,
  });

  factory _ChatThread.fromJson(Map<String, dynamic> json) {
    return _ChatThread(
      id: (json["id"] ?? "").toString(),
      title: (json["topic"] ?? json["name"] ?? "Chat").toString(),
      otherUserName: (json["other_user"]?["name"] ?? "").toString().trim(),
      currentHandler: json["current_handler"]?.toString(),
    );
  }

  bool get isAiThread {
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedHandler = (currentHandler ?? "").trim().toUpperCase();
    final hasOtherUser = (otherUserName ?? "").trim().isNotEmpty;

    return normalizedHandler == "AI" ||
        normalizedTitle.contains("ai") ||
        (!hasOtherUser &&
            (normalizedTitle.isEmpty || normalizedTitle == "chat"));
  }

  String get displayTitle {
    final cleaned = title.trim();
    if (cleaned.isNotEmpty && cleaned.toLowerCase() != "chat") {
      return cleaned;
    }
    if ((otherUserName ?? "").trim().isNotEmpty) {
      return otherUserName!.trim();
    }
    return "INOTRA AI";
  }
}
