import "dart:async";
import "dart:convert";

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
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchThreads,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 16, isTablet ? 24 : 16, 12),
                child: _HeroBanner(lang: lang),
              ),
            ),

            // Threads
            if (_loading && _threads.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _ThreadSkeleton(),
                      ),
                    ),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: 20),
                  child: _ErrorCard(
                    message: _error!,
                    onRetry: _fetchThreads,
                  ),
                ),
              )
            else if (_threads.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: 20),
                  child: _EmptyState(lang: lang),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _threads.length) return null;
                    final thread = _threads[index];
                    return Padding(
                      padding:
                          EdgeInsets.fromLTRB(isTablet ? 24 : 16, 0, isTablet ? 24 : 16, 12),
                      child: _ThreadCard(thread: thread),
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

/* ---------------------------- UI COMPONENTS ---------------------------- */

class _HeroBanner extends StatelessWidget {
  final String lang;
  const _HeroBanner({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [scheme.primary.withOpacity(0.15), scheme.secondary.withOpacity(0.14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withOpacity(0.12),
              border: Border.all(color: scheme.primary.withOpacity(0.28)),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                size: 26,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t(lang, "common.tap_details"),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GlassButton(
            label: t(lang, "nav.ai_chat"),
            icon: HugeIcons.strokeRoundedAirplane02,
            onTap: () => Navigator.pushNamed(context, "/ai-chat-conversations"),
          ),
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final _ChatThread thread;
  const _ThreadCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = thread.subtitle?.trim();
    final last = thread.lastMessage?.trim();

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: navigate to chat details page
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _Avatar(initials: thread.initials, badge: thread.unreadCount > 0),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (thread.lastAt != null)
                          Text(
                            _formatShort(thread.lastAt!),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                      ],
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                    if (last != null && last.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        last,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 16,
                color: scheme.onSurface.withOpacity(0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatShort(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) {
      return DateFormat("h:mm a").format(dt);
    }
    return DateFormat("MMM d").format(dt);
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final bool badge;
  const _Avatar({required this.initials, required this.badge});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceVariant.withOpacity(0.7),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        if (badge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                border: Border.all(color: scheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final dynamic icon;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadSkeleton extends StatelessWidget {
  const _ThreadSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
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

class _EmptyState extends StatelessWidget {
  final String lang;
  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceVariant.withOpacity(0.7),
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 28,
              color: scheme.onSurface.withOpacity(0.65),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t(lang, "common.coming_soon"),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          t(lang, "auth.member_only"),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withOpacity(0.4)),
      ),
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
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text(t(currentLangSync(), "common.try_again")),
          ),
        ],
      ),
    );
  }
}

/* ---------------------------- DATA MODEL ---------------------------- */

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
