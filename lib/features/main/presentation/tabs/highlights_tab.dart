import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:share_plus/share_plus.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/highlight_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/highlights/highlight_card.dart";
import "../widgets/highlights/highlight_comments_sheet.dart";
import "../widgets/highlights/highlight_comment.dart";

class HighlightsTab extends StatefulWidget {
  const HighlightsTab({super.key});

  @override
  State<HighlightsTab> createState() => _HighlightsTabState();
}

class _HighlightsTabState extends State<HighlightsTab> {
  List<_Highlight> _items = [];
  bool _loading = true;
  String? _error;
  final Map<String, List<HighlightComment>> _commentsCache = {};
  final Set<String> _expandedCaptions = {};
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _handleUnauthorized(int status) async {
    if (status == 401) {
      await AuthSession.instance.expireSession();
      // stay on the page; UI will fall back to guest header/state
      return true;
    }
    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Api.url(HighlightEndpoints.list);
      final token = AuthSession.instance.value.accessToken;
      final resp = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );
      if (await _handleUnauthorized(resp.statusCode)) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = (decoded["results"] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(_Highlight.fromJson)
            .toList();
        setState(() {
          _items = results;
        });
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(int index) async {
    final item = _items[index];
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;
    final uri = Api.url(HighlightEndpoints.likeToggle(item.id));
    try {
      final resp = await http.post(uri, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });
      if (await _handleUnauthorized(resp.statusCode)) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() {
          final liked = !item.liked;
          _items[index] = item.copyWith(
            liked: liked,
            likes: liked ? item.likes + 1 : (item.likes - 1).clamp(0, 1 << 31),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _share(int index) async {
    final item = _items[index];
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;
    final uri = Api.url(HighlightEndpoints.share(item.id));
    try {
      final resp = await http.post(uri, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });
      if (await _handleUnauthorized(resp.statusCode)) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() {
          _items[index] = item.copyWith(shares: item.shares + 1);
        });
        final shareText =
            item.caption?.isNotEmpty == true ? item.caption! : "Check this highlight on Inotra";
        await Share.share(shareText);
      }
    } catch (_) {}
  }

  Future<bool> _postComment(String highlightId, String text) async {
    if (text.trim().isEmpty) return false;
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return false;
    final uri = Api.url(HighlightEndpoints.addComment(highlightId));
    final resp = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"comment": text.trim()}),
    );
    if (await _handleUnauthorized(resp.statusCode)) return false;
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<void> _addComment(int index, String text) async {
    if (text.trim().isEmpty) return;
    final item = _items[index];
    try {
      final ok = await _postComment(item.id, text);
      if (ok) {
        setState(() {
          _items[index] = item.copyWith(comments: item.comments + 1);
          final list = _commentsCache[item.id] ?? [];
          _commentsCache[item.id] = [
            HighlightComment(author: AuthSession.instance.value.displayName, text: text.trim()),
            ...list,
          ];
        });
      }
    } catch (_) {}
  }

  Future<List<HighlightComment>> _fetchComments(String highlightId) async {
    final token = AuthSession.instance.value.accessToken;
    final uri = Api.url(HighlightEndpoints.comments(highlightId));
    final resp = await http.get(
      uri,
      headers: {
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) return [];
    final decoded = jsonDecode(resp.body);
    final results = (decoded is Map ? decoded["results"] : decoded) as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map(_commentFromJson).toList();
  }

  void _openCommentSheet(int index) {
    final item = _items[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return HighlightCommentsSheet(
          loadComments: () async {
            final cached = _commentsCache[item.id];
            if (cached != null) return cached;
            final fetched = await _fetchComments(item.id);
            _commentsCache[item.id] = fetched;
            return fetched;
          },
          onSend: (text) async => _addComment(index, text),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const _HighlightsSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: Text(t(lang, "common.try_again")),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          t(lang, "highlights.title"),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels <= 0 && n is OverscrollNotification && !_loading) {
          _load();
        }
        return false;
      },
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Stack(
            children: [
              HighlightCard(
                imageUrl: item.coverUrl,
                mediaItems: item.mediaItems
                    .map((m) => HighlightMediaItem(url: m.url, isVideo: m.isVideo))
                    .toList(),
                title: item.caption ?? t(lang, "highlights.title"),
                meta: null,
                entityName: _entityName(item),
                liked: item.liked,
                likes: item.likes,
                comments: item.comments,
                shares: item.shares,
                expandedCaption: _expandedCaptions.contains(item.id),
                onCaptionTap: () {
                  setState(() {
                    if (_expandedCaptions.contains(item.id)) {
                      _expandedCaptions.remove(item.id);
                    } else {
                      _expandedCaptions.add(item.id);
                    }
                  });
                },
                onLike: () => _toggleLike(index),
                onComment: () => _openCommentSheet(index),
                onShare: () => _share(index),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: Text(
                  t(lang, "highlights.title"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MediaItem {
  final String url;
  final bool isVideo;
  const _MediaItem({required this.url, required this.isVideo});
}

class _Highlight {
  final String id;
  final String? caption;
  final String? coverUrl;
  final List<_MediaItem> mediaItems;
  final int likes;
  final int comments;
  final int shares;
  final bool liked;
  final String? placeName;
  final String? eventName;

  _Highlight({
    required this.id,
    required this.caption,
    required this.coverUrl,
    required this.mediaItems,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.liked,
    this.placeName,
    this.eventName,
  });

  _Highlight copyWith({
    String? caption,
    String? coverUrl,
    List<_MediaItem>? mediaItems,
    int? likes,
    int? comments,
    int? shares,
    bool? liked,
    String? placeName,
    String? eventName,
  }) {
    return _Highlight(
      id: id,
      caption: caption ?? this.caption,
      coverUrl: coverUrl ?? this.coverUrl,
      mediaItems: mediaItems ?? this.mediaItems,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      liked: liked ?? this.liked,
      placeName: placeName ?? this.placeName,
      eventName: eventName ?? this.eventName,
    );
  }

  static _Highlight fromJson(Map<String, dynamic> json) {
    final media = (json["media"] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    String? cover;
    final items = <_MediaItem>[];
    for (final m in media) {
      final imageUrl = m["image_url"] as String?;
      final videoUrl = m["video_url"] as String?;
      if (imageUrl != null && imageUrl.trim().isNotEmpty) {
        items.add(_MediaItem(url: imageUrl.trim(), isVideo: false));
      } else if (videoUrl != null && videoUrl.trim().isNotEmpty) {
        items.add(_MediaItem(url: videoUrl.trim(), isVideo: true));
      }
    }
    if (items.isNotEmpty) {
      cover = items.first.url;
    }
    return _Highlight(
      id: json["id"] as String? ?? "",
      caption: json["caption"] as String?,
      coverUrl: cover,
      mediaItems: items,
      likes: (json["likes_count"] as num?)?.toInt() ?? 0,
      comments: (json["comments_count"] as num?)?.toInt() ?? 0,
      shares: (json["shares_count"] as num?)?.toInt() ?? 0,
      liked: json["liked"] == true,
      placeName: json["place_name"] as String?,
      eventName: json["event_name"] as String?,
    );
  }
}

HighlightComment _commentFromJson(Map<String, dynamic> json) {
  return HighlightComment(
    author: json["user"] as String? ?? json["author"] as String?,
    text: json["comment"] as String? ?? json["text"] as String?,
  );
}

String? _entityName(_Highlight h) {
  if (h.placeName != null && h.placeName!.isNotEmpty) return h.placeName;
  if (h.eventName != null && h.eventName!.isNotEmpty) return h.eventName;
  return null;
}

/* ----------------------------- Skeleton Loading ----------------------------- */

class _HighlightsSkeleton extends StatefulWidget {
  const _HighlightsSkeleton();

  @override
  State<_HighlightsSkeleton> createState() => _HighlightsSkeletonState();
}

class _HighlightsSkeletonState extends State<_HighlightsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final base = isDark
            ? Colors.white.withOpacity(0.06)
            : scheme.surfaceVariant.withOpacity(0.30);
        final hi = isDark
            ? Colors.white.withOpacity(0.12)
            : scheme.surfaceVariant.withOpacity(0.55);
        final c = Color.lerp(base, hi, t)!;

        return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          child: Container(
            color: isDark ? const Color(0xFF121212) : scheme.surfaceVariant.withOpacity(0.20),
            child: Stack(
              children: [
                // Full background shimmer
                Positioned.fill(child: Container(color: c.withOpacity(0.3))),

                // Title skeleton (top left)
                Positioned(
                  top: 42,
                  left: 16,
                  child: Container(
                    width: 120,
                    height: 18,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Counter pill skeleton (top right)
                Positioned(
                  top: 52,
                  right: 14,
                  child: Container(
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Right action buttons skeleton
                Positioned(
                  right: 14,
                  bottom: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 20,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                // Dots skeleton (center bottom)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 100,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (i) {
                          return Container(
                            width: i == 0 ? 16 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // Bottom info card skeleton
                Positioned(
                  left: 14,
                  right: 78,
                  bottom: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Entity name skeleton
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 100,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: c,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Caption lines
                            Container(
                              width: double.infinity,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 160,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
