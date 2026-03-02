import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../auth/presentation/widgets/quick_login_dialog.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

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

  // Optional rating (UI only). If your API accepts rating, include it in body.
  int _selectedRating = 0;

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

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        setState(() => _error = "Status ${resp.statusCode}");
        return;
      }

      final decoded = jsonDecode(resp.body);

      List<dynamic> rawList = const [];
      if (decoded is Map<String, dynamic>) {
        final v = decoded["results"] ?? decoded["data"];
        if (v is List) rawList = v;
      } else if (decoded is List) {
        rawList = decoded;
      }

      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map<_Review>((m) => _Review.fromJson(m))
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() => _reviews = items);
    } catch (e) {
      if (!mounted) return;
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

    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final token = AuthSession.instance.value.accessToken;
      final uri = Api.url(PlaceEndpoints.addReview(widget.placeId));

      final body = <String, dynamic>{
        "comment": text,
        // If your backend supports rating, uncomment:
        // "rating": _selectedRating == 0 ? null : _selectedRating,
      };

      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _controller.clear();
        setState(() => _selectedRating = 0);
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
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (glass)
          _GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.primary.withOpacity(0.12),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMessage02,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(lang, "listings.reviews_title"),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _loading
                            ? t(lang, "auth.processing")
                            : _reviews.isEmpty
                            ? t(lang, "listings.reviews_empty")
                            : "${_reviews.length} ${t(lang, "listings.reviews_title")}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.62),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                else
                  _GlassIconButton(
                    tooltip: "Refresh",
                    icon: Icons.refresh_rounded,
                    onTap: _fetch,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (_error != null)
            _ErrorGlassBanner(message: _error!, onRetry: _fetch)
          else if (_reviews.isEmpty && !_loading)
            _EmptyGlassState(label: t(lang, "listings.reviews_empty")),

          if (_reviews.isNotEmpty) ...[
            _GlassCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _reviews.length,
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.onSurface.withOpacity(0.08),
                  ),
                ),
                itemBuilder: (_, i) => _ReviewTile(review: _reviews[i]),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Composer
          if (authed)
            _ReviewComposerGlass(
              controller: _controller,
              submitting: _submitting,
              rating: _selectedRating,
              onRatingChanged: (v) => setState(() => _selectedRating = v),
              onSubmit: _submit,
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
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarGlass(initials: review.initials, imageUrl: review.avatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isTablet ? 14 : 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    review.formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (review.rating != null) ...[
                const SizedBox(height: 6),
                _StarRow(rating: review.rating!.clamp(0, 5)),
              ],
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.88),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewComposerGlass extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _ReviewComposerGlass({
    required this.controller,
    required this.submitting,
    required this.rating,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t(lang, "listings.reviews_add"),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (submitting)
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
          const SizedBox(height: 10),

          // Rating (optional)
          Row(
            children: [
              Text(
                "Rating",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withOpacity(0.70),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: List.generate(5, (i) {
                    final v = i + 1;
                    final active = rating >= v;
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: submitting ? null : () => onRatingChanged(v),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 2,
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: active
                              ? Colors.amber
                              : Colors.grey.withOpacity(0.35),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (rating != 0)
                _GlassIconButton(
                  tooltip: "Clear rating",
                  icon: Icons.close_rounded,
                  onTap: submitting ? () {} : () => onRatingChanged(0),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Input
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              color: scheme.surfaceVariant.withOpacity(0.35),
            ),
            child: TextField(
              controller: controller,
              maxLines: 5,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.92),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: t(lang, "listings.reviews_hint"),
                hintStyle: TextStyle(
                  color: scheme.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: Text(
                  "Be respectful and helpful 🙂",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PrimaryGlassButton(
                label: submitting
                    ? t(lang, "auth.processing")
                    : t(lang, "listings.reviews_submit"),
                icon: Icons.send_rounded,
                loading: submitting,
                onTap: submitting ? null : onSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- GLASS UI PARTS ----------------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: scheme.surface.withOpacity(0.14),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: scheme.onSurface.withOpacity(0.90),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryGlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryGlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: scheme.primary.withOpacity(onTap == null ? 0.35 : 0.85),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 8),
              color: scheme.primary.withOpacity(0.18),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onPrimary,
                ),
              )
            else
              Icon(icon, size: 16, color: scheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarGlass extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  const _AvatarGlass({required this.initials, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl!.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Initials(initials: initials),
                    loadingBuilder: (_, child, evt) =>
                        evt == null ? child : _Initials(initials: initials),
                  ),
                )
              : _Initials(initials: initials),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  const _Initials({required this.initials});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        initials,
        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(5, (i) {
        final active = i < rating;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            Icons.star_rounded,
            size: 16,
            color: active ? Colors.amber : scheme.onSurface.withOpacity(0.20),
          ),
        );
      }),
    );
  }
}

class _EmptyGlassState extends StatelessWidget {
  final String label;
  const _EmptyGlassState({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedMessage02,
            size: 18,
            color: scheme.onSurface.withOpacity(0.45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withOpacity(0.70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorGlassBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorGlassBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedWifiError01,
            size: 18,
            color: scheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _PrimaryGlassButton(
            label: "Retry",
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

/* ---------------------------------- MODEL -------------------------------- */

class _Review {
  final String id;
  final String author;
  final String comment;
  final DateTime createdAt;
  final int? rating;
  final String? avatarUrl;

  _Review({
    required this.id,
    required this.author,
    required this.comment,
    required this.createdAt,
    this.rating,
    this.avatarUrl,
  });

  String get initials {
    final parts = author.trim().split(" ").where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length == 1)
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : "?";
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

    final avatar =
        (json["user_avatar_url"] ?? json["avatar"] ?? json["avatar_url"] ?? "")
            .toString()
            .trim();

    return _Review(
      id: (json["id"] ?? "").toString(),
      author:
          (json["author"] ??
                  json["user_name"] ??
                  json["username"] ??
                  "Anonymous")
              .toString(),
      comment: (json["comment"] ?? json["text"] ?? "").toString(),
      createdAt: parseDate(json["created_at"]?.toString()),
      rating: _toNullableInt(json["rating"]),
      avatarUrl: avatar.isEmpty ? null : avatar,
    );
  }
}

int? _toNullableInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}
