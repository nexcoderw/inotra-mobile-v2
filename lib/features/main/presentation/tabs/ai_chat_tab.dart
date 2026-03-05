import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/chat_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../auth/presentation/widgets/quick_login_dialog.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../pages/ai_chat_conversations_page.dart";
import "../pages/ai_chat_thread_page.dart";

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final _scrollCtrl = ScrollController();
  bool _loading = false;
  String? _error;
  bool _authPrompted = false;
  final List<_ChatThread> _threads = [];

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
      if (!AuthSession.instance.value.isAuthenticated) return;
    }
    await _fetchThreads();
  }

  Future<void> _fetchThreads() async {
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(ChatEndpoints.threads);
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
        final threads = raw
            .whereType<Map>()
            .map((m) => _ChatThread.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        if (mounted) setState(() => _threads..clear()..addAll(threads));
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        await QuickLoginDialog.show(context);
        await _init();
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;
    final hPad = isTablet ? 24.0 : 16.0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchThreads,
        color: scheme.primary,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // Hero banner
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
                child: _HeroBanner(lang: lang, isDark: isDark, scheme: scheme),
              ),
            ),

            // Section header
            if (!_loading && _error == null && _threads.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
                  child: _SectionHeader(lang: lang, scheme: scheme),
                ),
              ),

            // Content
            if (_loading && _threads.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _ThreadSkeletonList(isDark: isDark, scheme: scheme),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                  child: _ErrorCard(
                    lang: lang,
                    message: _error!,
                    onRetry: _fetchThreads,
                    isDark: isDark,
                    scheme: scheme,
                  ),
                ),
              )
            else if (_threads.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                  child: _EmptyState(lang: lang, scheme: scheme),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _threads.length) return null;
                    final thread = _threads[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
                      child: _ThreadCard(
                        thread: thread,
                        isDark: isDark,
                        scheme: scheme,
                      ),
                    );
                  },
                  childCount: _threads.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────── */
/* Hero Banner                                                             */
/* ─────────────────────────────────────────────────────────────────────── */

class _HeroBanner extends StatelessWidget {
  final String lang;
  final bool isDark;
  final ColorScheme scheme;

  const _HeroBanner({
    required this.lang,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      scheme.primary.withValues(alpha: 0.22),
                      scheme.primary.withValues(alpha: 0.10),
                    ]
                  : [
                      scheme.primary.withValues(alpha: 0.12),
                      scheme.primary.withValues(alpha: 0.06),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? scheme.primary.withValues(alpha: 0.28)
                  : scheme.primary.withValues(alpha: 0.18),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              // Icon
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.32),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSparkles,
                    size: 24,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(lang, "nav.ai_chat"),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.3,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t(lang, "chat.no_conversations_sub"),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // CTA Button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatConversationsPage()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    t(lang, "common.all"),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

/* ─────────────────────────────────────────────────────────────────────── */
/* Section header row                                                      */
/* ─────────────────────────────────────────────────────────────────────── */

class _SectionHeader extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;

  const _SectionHeader({required this.lang, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          t(lang, "chat.title"),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatConversationsPage()),
          ),
          child: Text(
            t(lang, "common.all"),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────── */
/* Thread Card — frosted glass                                             */
/* ─────────────────────────────────────────────────────────────────────── */

class _ThreadCard extends StatelessWidget {
  final _ChatThread thread;
  final bool isDark;
  final ColorScheme scheme;

  const _ThreadCard({
    required this.thread,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = thread.subtitle?.trim();
    final last = thread.lastMessage?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiChatThreadPage(
                    threadId: thread.id,
                    title: thread.title,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.07),
                  width: 0.7,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _Avatar(
                    initials: thread.initials,
                    unread: thread.unreadCount,
                    isDark: isDark,
                    scheme: scheme,
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
                                thread.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (thread.lastAt != null)
                              Text(
                                _formatShort(thread.lastAt!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                          ],
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface.withValues(alpha: 0.60),
                            ),
                          ),
                        ],
                        if (last != null && last.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            last,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.30),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatShort(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return DateFormat("h:mm a").format(dt);
    return DateFormat("MMM d").format(dt);
  }
}

/* ─────────────────────────────────────────────────────────────────────── */
/* Avatar with optional unread badge                                       */
/* ─────────────────────────────────────────────────────────────────────── */

class _Avatar extends StatelessWidget {
  final String initials;
  final int unread;
  final bool isDark;
  final ColorScheme scheme;

  const _Avatar({
    required this.initials,
    required this.unread,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: isDark ? 0.35 : 0.18),
                scheme.primary.withValues(alpha: isDark ? 0.18 : 0.09),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.28),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: scheme.primary,
              ),
            ),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  unread > 99 ? "99+" : unread.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────── */
/* Animated skeleton list                                                  */
/* ─────────────────────────────────────────────────────────────────────── */

class _ThreadSkeletonList extends StatefulWidget {
  final bool isDark;
  final ColorScheme scheme;

  const _ThreadSkeletonList({required this.isDark, required this.scheme});

  @override
  State<_ThreadSkeletonList> createState() => _ThreadSkeletonListState();
}

class _ThreadSkeletonListState extends State<_ThreadSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmerColor = widget.isDark
            ? Colors.white.withValues(alpha: 0.04 + _anim.value * 0.06)
            : Colors.black.withValues(alpha: 0.05 + _anim.value * 0.05);
        final baseColor = widget.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);

        return Column(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: shimmerColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 130,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 10,
                            width: 180,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────── */
/* Empty state                                                             */
/* ─────────────────────────────────────────────────────────────────────── */

class _EmptyState extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;

  const _EmptyState({required this.lang, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.10),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.20),
              width: 0.8,
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
        const SizedBox(height: 16),
        Text(
          t(lang, "chat.no_conversations"),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t(lang, "chat.no_conversations_sub"),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: scheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatConversationsPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              t(lang, "common.all"),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────── */
/* Error card                                                              */
/* ─────────────────────────────────────────────────────────────────────── */

class _ErrorCard extends StatelessWidget {
  final String lang;
  final String message;
  final VoidCallback onRetry;
  final bool isDark;
  final ColorScheme scheme;

  const _ErrorCard({
    required this.lang,
    required this.message,
    required this.onRetry,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: isDark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.error.withValues(alpha: 0.12),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedWifiError01,
                color: scheme.error,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t(lang, "chat.load_error"),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: scheme.error.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(t(lang, "common.try_again")),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────── */
/* Data model                                                              */
/* ─────────────────────────────────────────────────────────────────────── */

class _ChatThread {
  final String id;
  final String title;
  final String? subtitle;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unreadCount;

  const _ChatThread({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lastMessage,
    required this.lastAt,
    required this.unreadCount,
  });

  String get initials {
    final parts = title.trim().split(" ");
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : "?";
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory _ChatThread.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    return _ChatThread(
      id: (json["id"] ?? "").toString(),
      title: (json["topic"] ?? json["name"] ?? "Chat").toString(),
      subtitle: (json["other_user"]?["name"] ?? json["subtitle"] ?? "").toString(),
      lastMessage: (json["last_message_preview"] ?? "").toString(),
      lastAt: parse(json["last_message_at"]?.toString()),
      unreadCount: (json["unread_count"] as num?)?.toInt() ?? 0,
    );
  }
}
