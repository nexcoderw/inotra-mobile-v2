import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
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

class _ListingReviewsTabState extends State<ListingReviewsTab>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<_Review> _reviews = const [];
  final _controller = TextEditingController();

  // Optional rating (UI only). If your API accepts rating, include it in body.
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
    final textTheme = Theme.of(context).textTheme;
    final authed = AuthSession.instance.value.isAuthenticated;

    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;

    // Premium minimal spacing
    const pagePad = EdgeInsets.fromLTRB(16, 16, 16, 20);

    return RefreshIndicator(
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pagePad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeaderCard(
              title: t(lang, "listings.reviews_title"),
              subtitle: _loading
                  ? t(lang, "auth.processing")
                  : _reviews.isEmpty
                      ? t(lang, "listings.reviews_empty")
                      : "${_reviews.length} ${t(lang, "listings.reviews_title")}",
              leading: Icons.rate_review_outlined,
              trailing: _loading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : _SoftIconButton(
                      tooltip: "Refresh",
                      icon: Icons.refresh_rounded,
                      onTap: _fetch,
                    ),
              isTablet: isTablet,
            ),

            const SizedBox(height: 12),

            if (_loading) ...[
              _ReviewsSkeleton(
                controller: _skeletonCtrl,
                isTablet: isTablet,
              ),
            ] else if (_error != null) ...[
              _ErrorBanner(
                message: _error!,
                onRetry: _fetch,
              ),
            ] else if (_reviews.isEmpty) ...[
              _EmptyStateCard(
                label: t(lang, "listings.reviews_empty"),
              ),
            ] else ...[
              _ReviewsListCard(
                reviews: _reviews,
                isTablet: isTablet,
              ),
            ],

            const SizedBox(height: 14),

            // Composer
            if (authed)
              _ReviewComposer(
                controller: _controller,
                submitting: _submitting,
                rating: _selectedRating,
                onRatingChanged: (v) => setState(() => _selectedRating = v),
                onSubmit: _submit,
                isTablet: isTablet,
              )
            else
              _MutedInfoCard(
                icon: Icons.lock_outline_rounded,
                title: t(lang, "listings.reviews_add"),
                subtitle: "Log in to write a review.",
              ),

            const SizedBox(height: 24),

            // Small “premium” hint at the bottom (optional)
            Text(
              "Tip: Pull down to refresh.",
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================= UI - CLEAN MINIMAL ============================= */

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.75)),
      ),
      child: child,
    );
  }
}

class _SectionHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leading;
  final Widget trailing;
  final bool isTablet;

  const _SectionHeaderCard({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.trailing,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: scheme.primary.withOpacity(0.10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Center(
              child: Icon(
                leading,
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
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isTablet ? 18 : 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _SoftIconButton({
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
            color: scheme.surfaceVariant.withOpacity(0.55),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: scheme.onSurface.withOpacity(0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewsListCard extends StatelessWidget {
  final List<_Review> reviews;
  final bool isTablet;

  const _ReviewsListCard({
    required this.reviews,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SurfaceCard(
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
            thickness: 1,
            color: scheme.outlineVariant.withOpacity(0.7),
          ),
        ),
        itemBuilder: (_, i) => _ReviewTile(review: reviews[i], isTablet: isTablet),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final _Review review;
  final bool isTablet;
  const _ReviewTile({required this.review, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          initials: review.initials,
          imageUrl: review.avatarUrl,
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

class _ReviewComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;
  final bool isTablet;

  const _ReviewComposer({
    required this.controller,
    required this.submitting,
    required this.rating,
    required this.onRatingChanged,
    required this.onSubmit,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t(lang, "listings.reviews_add"),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isTablet ? 15 : 14,
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
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                        child: Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: active ? Colors.amber : scheme.outlineVariant.withOpacity(0.75),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (rating != 0)
                _SoftIconButton(
                  tooltip: "Clear rating",
                  icon: Icons.close_rounded,
                  onTap: submitting ? () {} : () => onRatingChanged(0),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Input
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
              color: scheme.surfaceVariant.withOpacity(0.45),
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
                  borderRadius: BorderRadius.circular(14),
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
              _PrimaryButton(
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: onTap == null
              ? scheme.primary.withOpacity(0.35)
              : scheme.primary,
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

class _Avatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  const _Avatar({required this.initials, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceVariant.withOpacity(0.55),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
          color: scheme.primary,
          fontWeight: FontWeight.w900,
        ),
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
            color: active ? Colors.amber : scheme.outlineVariant.withOpacity(0.75),
          ),
        );
      }),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String label;
  const _EmptyStateCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 18,
            color: scheme.onSurface.withOpacity(0.45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withOpacity(0.75),
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

    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _PrimaryButton(
            label: "Retry",
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _MutedInfoCard extends StatelessWidget {
  final IconData icon;
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

    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: scheme.surfaceVariant.withOpacity(0.55),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.75)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.60),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

/* ============================== SKELETON LOADING ============================== */

class _ReviewsSkeleton extends StatelessWidget {
  final AnimationController controller;
  final bool isTablet;

  const _ReviewsSkeleton({
    required this.controller,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color base = scheme.surfaceVariant.withOpacity(0.55);
    Color highlight = scheme.surfaceVariant.withOpacity(0.85);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final color = Color.lerp(base, highlight, t)!;

        return Column(
          children: [
            // List container skeleton (same as reviews card)
            _SurfaceCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: List.generate(3, (i) {
                  return Column(
                    children: [
                      _SkeletonReviewTile(color: color, isTablet: isTablet),
                      if (i != 2)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: scheme.outlineVariant.withOpacity(0.7),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SkeletonReviewTile extends StatelessWidget {
  final Color color;
  final bool isTablet;

  const _SkeletonReviewTile({
    required this.color,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar skeleton
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color,
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.75)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: bar(isTablet ? 160 : 130, 12)),
                  const SizedBox(width: 10),
                  bar(70, 10),
                ],
              ),
              const SizedBox(height: 8),
              // Optional rating row space
              Row(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              bar(double.infinity, 10),
              const SizedBox(height: 8),
              bar(double.infinity, 10),
              const SizedBox(height: 8),
              bar(isTablet ? 240 : 200, 10),
            ],
          ),
        ),
      ],
    );
  }
}

/* ================================== MODEL ================================== */

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
