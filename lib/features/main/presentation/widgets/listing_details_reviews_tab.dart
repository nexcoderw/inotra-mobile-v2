import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../../../auth/presentation/widgets/quick_login_dialog.dart";

class ListingReviewsTab extends StatefulWidget {
  final String placeId;
  const ListingReviewsTab({super.key, required this.placeId});

  @override
  State<ListingReviewsTab> createState() => _ListingReviewsTabState();
}

class _ListingReviewsTabState extends State<ListingReviewsTab> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<_Review> _reviews = const [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Api.url(PlaceEndpoints.reviews(widget.placeId));
      final resp = await http.get(uri, headers: {"Accept": "application/json"});
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final results = (decoded is Map
                ? (decoded["results"] ?? decoded["data"] ?? const [])
                : decoded as List?) ??
            const [];
        final items = results.whereType<Map>().map(_Review.fromJson).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        setState(() => _reviews = items);
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!AuthSession.instance.value.isAuthenticated) {
      await QuickLoginDialog.show(context);
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = AuthSession.instance.value.accessToken;
      final uri = Api.url(PlaceEndpoints.addReview(widget.placeId));
      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: jsonEncode({"comment": text}),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _controller.clear();
        await _fetch();
      } else if (resp.statusCode == 401) {
        await AuthSession.instance.expireSession();
        await QuickLoginDialog.show(context);
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final authed = AuthSession.instance.value.isAuthenticated;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t(lang, "listings.reviews_title"),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_loading)
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            _ErrorBanner(message: _error!, onRetry: _fetch)
          else if (_reviews.isEmpty && !_loading)
            _EmptyState(label: t(lang, "listings.reviews_empty")),
          if (_reviews.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _reviews.length,
                separatorBuilder: (_, __) => Divider(
                  height: 14,
                  thickness: 1,
                  color: scheme.onSurface.withOpacity(0.08),
                ),
                itemBuilder: (_, i) => _ReviewTile(review: _reviews[i]),
              ),
            ),
          const SizedBox(height: 14),
          authed
              ? _ReviewComposer(
                  controller: _controller,
                  submitting: _submitting,
                  onSubmit: _submit,
                )
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLogin03,
                      size: 16,
                      color: scheme.primary,
                    ),
                    label: Text(
                      t(lang, "listings.login_to_proceed"),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: scheme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => QuickLoginDialog.show(context),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final _Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary.withOpacity(0.12),
              child: Text(
                review.initials,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.author,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review.formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          review.comment,
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.85),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ReviewComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  const _ReviewComposer({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t(lang, "listings.reviews_add"),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          minLines: 3,
          decoration: InputDecoration(
            hintText: t(lang, "listings.reviews_hint"),
            filled: true,
            fillColor: scheme.surfaceVariant.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: submitting
                ? SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : HugeIcon(
                    icon: HugeIcons.strokeRoundedSend02,
                    size: 14,
                    color: scheme.onPrimary,
                  ),
            label: Text(
              submitting ? t(lang, "auth.processing") : t(lang, "listings.reviews_submit"),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: submitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedMessage02,
            size: 18,
            color: scheme.onSurface.withOpacity(0.45),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedWifiError01,
            size: 18,
            color: scheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}

class _Review {
  final String id;
  final String author;
  final String comment;
  final DateTime createdAt;

  _Review({
    required this.id,
    required this.author,
    required this.comment,
    required this.createdAt,
  });

  String get initials {
    final parts = author.trim().split(" ");
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : "?";
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get formattedDate {
    final month = createdAt.month.toString().padLeft(2, "0");
    final day = createdAt.day.toString().padLeft(2, "0");
    return "$day/$month/${createdAt.year}";
  }

  factory _Review.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    return _Review(
      id: (json["id"] ?? "").toString(),
      author: (json["author"] ?? json["user_name"] ?? "Anonymous").toString(),
      comment: (json["comment"] ?? json["text"] ?? "").toString(),
      createdAt: parseDate(json["created_at"]?.toString()),
    );
  }
}
