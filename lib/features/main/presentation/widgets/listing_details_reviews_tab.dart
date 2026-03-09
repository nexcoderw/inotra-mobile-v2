import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:hugeicons/hugeicons.dart";

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

class _ListingReviewsTabState extends State<ListingReviewsTab>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<_Review> _reviews = const [];
  final _controller = TextEditingController();

  int _selectedRating = 5;

  late final AnimationController _skeletonCtrl;

  @override
  void initState() {
    super.initState();
    _skeletonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _fetch();
  }

  @override
  void dispose() {
    _controller.dispose();
    _skeletonCtrl.dispose();
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
        "rating": _selectedRating <= 0 ? 1 : _selectedRating,
      };

      final userId = AuthSession.instance.value.user?["id"];
      if (userId != null && userId.toString().isNotEmpty) {
        body["user_id"] = userId.toString();
      }

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

    return RefreshIndicator(
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _GlassSection(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCommentAdd01,
                      size: 16,
                      color: scheme.primary,
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
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.92),
                            letterSpacing: -0.1,
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
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
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
                    GestureDetector(
                      onTap: _fetch,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          size: 16,
                          color: scheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_loading) ...[
              _ReviewsSkeleton(controller: _skeletonCtrl),
            ] else if (_error != null) ...[
              _ErrorBanner(message: _error!, onRetry: _fetch),
            ] else if (_reviews.isEmpty) ...[
              _EmptyStateCard(label: t(lang, "listings.reviews_empty")),
            ] else ...[
              _ReviewsListCard(reviews: _reviews),
            ],

            const SizedBox(height: 12),

            if (authed)
              _ReviewComposer(
                controller: _controller,
                submitting: _submitting,
                rating: _selectedRating,
                onRatingChanged: (v) => setState(() => _selectedRating = v),
                onSubmit: _submit,
              )
            else
              _MutedInfoCard(
                icon: HugeIcons.strokeRoundedLockKey,
                title: t(lang, "listings.reviews_add"),
                subtitle: "Log in to write a review.",
              ),

            const SizedBox(height: 16),

            Text(
              "Tip: Pull down to refresh.",
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.40),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ========================== Glass card ========================== */

class _GlassSection extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _GlassSection({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ========================== Reviews list ========================== */

class _ReviewsListCard extends StatelessWidget {
  final List<_Review> reviews;
  const _ReviewsListCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassSection(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: reviews.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(
            height: 1,
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        itemBuilder: (_, i) => _ReviewTile(review: reviews[i]),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(initials: review.initials, imageUrl: review.avatarUrl),
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
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    review.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
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
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.82),
                  height: 1.5,
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

/* ========================== Composer ========================== */

class _ReviewComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _ReviewComposer({
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

    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCommentAdd01,
                  size: 14,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t(lang, "listings.reviews_add"),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.92),
                  letterSpacing: -0.1,
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
          const SizedBox(height: 12),

          // Rating row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Text(
                  "Rating",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.65),
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
                              horizontal: 3, vertical: 2),
                          child: Icon(
                            Icons.star_rounded,
                            size: 20,
                            color: active
                                ? Colors.amber
                                : scheme.onSurface.withValues(alpha: 0.20),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (rating != 0)
                  GestureDetector(
                    onTap: submitting ? null : () => onRatingChanged(0),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Text input
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
              border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: controller,
              maxLines: 5,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: t(lang, "listings.reviews_hint"),
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.40),
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),

          const SizedBox(height: 10),

          // Actions row
          Row(
            children: [
              Expanded(
                child: Text(
                  "Be respectful and helpful 🙂",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SendButton(
                label: submitting
                    ? t(lang, "auth.processing")
                    : t(lang, "listings.reviews_submit"),
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

class _SendButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _SendButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: disabled
              ? scheme.primary.withValues(alpha: 0.40)
              : scheme.primary,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onPrimary,
                ),
              )
            else
              HugeIcon(
                icon: HugeIcons.strokeRoundedSent,
                size: 14,
                color: scheme.onPrimary,
              ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ========================== Avatar ========================== */

class _Avatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  const _Avatar({required this.initials, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.primary.withValues(alpha: 0.10),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasImage
            ? Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(initials: initials),
                loadingBuilder: (_, child, evt) =>
                    evt == null ? child : _Initials(initials: initials),
              )
            : _Initials(initials: initials),
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
        style: TextStyle(
          fontSize: 12,
          color: scheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/* ========================== Star row ========================== */

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
            size: 14,
            color: active
                ? Colors.amber
                : scheme.onSurface.withValues(alpha: 0.20),
          ),
        );
      }),
    );
  }
}

/* ========================== Empty / Error / Muted ========================== */

class _EmptyStateCard extends StatelessWidget {
  final String label;
  const _EmptyStateCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassSection(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedBubbleChat,
              size: 16,
              color: scheme.onSurface.withValues(alpha: 0.40),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.60),
              ),
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

    return _GlassSection(
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
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: scheme.primary,
              ),
              child: Text(
                "Retry",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedInfoCard extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;

  const _MutedInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassSection(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(
              icon: icon,
              size: 16,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
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

/* ========================== Skeleton ========================== */

class _ReviewsSkeleton extends StatelessWidget {
  final AnimationController controller;
  const _ReviewsSkeleton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.30);
    final highlight = scheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final color = Color.lerp(base, highlight, controller.value)!;

        return _GlassSection(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: List.generate(3, (i) {
              return Column(
                children: [
                  _SkeletonReviewTile(color: color),
                  if (i != 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(
                        height: 1,
                        color: scheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

class _SkeletonReviewTile extends StatelessWidget {
  final Color color;
  const _SkeletonReviewTile({required this.color});

  Widget _bar(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _bar(130, 11)),
                  const SizedBox(width: 10),
                  _bar(60, 10),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _bar(double.infinity, 10),
              const SizedBox(height: 8),
              _bar(double.infinity, 10),
              const SizedBox(height: 8),
              _bar(180, 10),
            ],
          ),
        ),
      ],
    );
  }
}

/* ========================== Model ========================== */

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
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : "?";
    }
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
      author: (json["author"] ??
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
