import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/highlight_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class HighlightsTab extends StatefulWidget {
  const HighlightsTab({super.key});

  @override
  State<HighlightsTab> createState() => _HighlightsTabState();
}

class _HighlightsTabState extends State<HighlightsTab> {
  List<_Highlight> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() {
          _items[index] = item.copyWith(shares: item.shares + 1);
        });
      }
    } catch (_) {}
  }

  Future<void> _addComment(int index, String text) async {
    if (text.trim().isEmpty) return;
    final item = _items[index];
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;
    final uri = Api.url(HighlightEndpoints.addComment(item.id));
    try {
      final resp = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"comment": text.trim()}),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() {
          _items[index] = item.copyWith(comments: item.comments + 1);
        });
      }
    } catch (_) {}
  }

  Future<List<_Comment>> _fetchComments(String highlightId) async {
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
    return results.whereType<Map<String, dynamic>>().map(_Comment.fromJson).toList();
  }

  void _openCommentSheet(int index) {
    final controller = TextEditingController();
    final item = _items[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        final lang = currentLangSync();
        return FutureBuilder<List<_Comment>>(
          future: _fetchComments(item.id),
          builder: (context, snapshot) {
            final comments = snapshot.data ?? [];
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(lang, "highlights.title"),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LinearProgressIndicator(),
                  if (comments.isNotEmpty) ...[
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            comments[i].author ?? t(lang, "auth.anonymous"),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(comments[i].text ?? ""),
                        ),
                      ),
                    ),
                  ] else if (snapshot.connectionState == ConnectionState.done)
                    Text(
                      t(lang, "common.empty"),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: t(lang, "highlights.static"),
                      filled: true,
                      fillColor: Theme.of(ctx).colorScheme.surfaceVariant.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addComment(index, controller.text);
                      },
                      child: const Text(
                        "Send",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                child: Image.network(
                  item.coverUrl ?? "",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: scheme.surfaceVariant,
                    child: Center(
                      child: Icon(Icons.image_not_supported,
                          color: scheme.onSurface.withOpacity(0.6)),
                    ),
                  ),
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes == null
                            ? null
                            : progress.cumulativeBytesLoaded /
                                (progress.expectedTotalBytes ?? 1),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 28,
              right: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.caption ?? t(lang, "highlights.title"),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${item.likes} likes • ${item.comments} comments • ${item.shares} shares",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: item.liked ? Icons.favorite : Icons.favorite_border,
                    color: item.liked ? Colors.redAccent : Colors.white,
                    label: "${item.likes}",
                    onTap: () => _toggleLike(index),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: "${item.comments}",
                    onTap: () => _openCommentSheet(index),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.send_rounded,
                    label: "${item.shares}",
                    onTap: () => _share(index),
                  ),
                ],
              ),
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
    );
  }
}

class _Highlight {
  final String id;
  final String? caption;
  final String? coverUrl;
  final int likes;
  final int comments;
  final int shares;
  final bool liked;

  _Highlight({
    required this.id,
    required this.caption,
    required this.coverUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.liked,
  });

  _Highlight copyWith({
    String? caption,
    String? coverUrl,
    int? likes,
    int? comments,
    int? shares,
    bool? liked,
  }) {
    return _Highlight(
      id: id,
      caption: caption ?? this.caption,
      coverUrl: coverUrl ?? this.coverUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      liked: liked ?? this.liked,
    );
  }

  static _Highlight fromJson(Map<String, dynamic> json) {
    final media = (json["media"] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    String? cover;
    if (media.isNotEmpty) {
      cover = (media.first["image_url"] ?? media.first["video_url"]) as String?;
    }
    return _Highlight(
      id: json["id"] as String? ?? "",
      caption: json["caption"] as String?,
      coverUrl: cover,
      likes: (json["likes_count"] as num?)?.toInt() ?? 0,
      comments: (json["comments_count"] as num?)?.toInt() ?? 0,
      shares: (json["shares_count"] as num?)?.toInt() ?? 0,
      liked: json["liked"] == true,
    );
  }
}

class _Comment {
  final String? author;
  final String? text;

  _Comment({this.author, this.text});

  static _Comment fromJson(Map<String, dynamic> json) => _Comment(
        author: json["user"] as String? ?? json["author"] as String?,
        text: json["comment"] as String? ?? json["text"] as String?,
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
