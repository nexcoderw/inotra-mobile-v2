import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../../core/config/api.dart";
import "../../../../../core/constants/api/my_listing_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../../../main/presentation/widgets/listing_details_map_tab.dart";
import "../../../../main/presentation/widgets/listing_details_overview_tab.dart";
import "../../../../main/presentation/widgets/listing_details_shared.dart";
import "../../../../main/presentation/widgets/listing_details_transport_tab.dart";
import "../../../../main/presentation/widgets/listing_image_preview.dart";

class MyListingSubmissionDetailArgs {
  final String submissionId;
  final String? title;

  const MyListingSubmissionDetailArgs({required this.submissionId, this.title});
}

class MyListingSubmissionDetailPage extends StatefulWidget {
  final String? submissionId;
  final String? title;

  const MyListingSubmissionDetailPage({
    super.key,
    this.submissionId,
    this.title,
  });

  @override
  State<MyListingSubmissionDetailPage> createState() =>
      _MyListingSubmissionDetailPageState();
}

class _MyListingSubmissionDetailPageState
    extends State<MyListingSubmissionDetailPage> {
  _ListingSubmissionDetail? _detail;
  bool _loading = true;
  String? _error;

  String get _lang => currentLangSync();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  MyListingSubmissionDetailArgs? get _routeArgs {
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is MyListingSubmissionDetailArgs) return raw;
    return null;
  }

  String? get _submissionId => widget.submissionId ?? _routeArgs?.submissionId;

  Future<void> _fetch() async {
    final submissionId = _submissionId;
    if (submissionId == null || submissionId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t(_lang, "my_listing_submissions.load_failed");
      });
      return;
    }

    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t(_lang, "my_listing_submissions.session_expired");
      });
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t(_lang, "my_listing_submissions.session_expired");
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(MyListingEndpoints.submissionDetail(submissionId));
      final response = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthSession.instance.expireSession();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = t(_lang, "my_listing_submissions.session_expired");
        });
        return;
      }

      final decoded = response.body.isEmpty
          ? null
          : jsonDecode(response.body) as Object?;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _ApiException(
          _extractMessage(decoded) ??
              t(_lang, "my_listing_submissions.load_failed"),
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const _ApiException("Invalid listing submission response.");
      }

      if (!mounted) return;
      setState(() {
        _detail = _ListingSubmissionDetail.fromJson(decoded);
        _loading = false;
      });
    } on _ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t(_lang, "my_listing_submissions.load_failed");
      });
    }
  }

  String? _extractMessage(Object? decoded) {
    if (decoded is Map && decoded["message"] != null) {
      return decoded["message"].toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          top: false,
          child: _loading
              ? const _PageSkeleton()
              : _error != null
              ? _ErrorState(message: _error!, onRetry: _fetch)
              : _detail == null
              ? _ErrorState(
                  message: t(_lang, "listings.no_data"),
                  onRetry: _fetch,
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: _HeroPager(images: _detail!.place.images),
                    ),
                    Positioned(
                      left: 16,
                      top: MediaQuery.of(context).padding.top + 14,
                      child: _RoundIconButton(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        onTap: () => Navigator.maybePop(context),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _DetailsSheet(detail: _detail!, lang: _lang),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  final _ListingSubmissionDetail detail;
  final String lang;

  const _DetailsSheet({required this.detail, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);

    final maxH = media.size.height;
    final sheetMax = maxH * 0.62;
    final sheetMin = maxH * 0.52;
    final place = detail.place;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, anim, _) {
        return SizedBox(
          height: lerpDouble(sheetMin, sheetMax, 1)!,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 26,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              detail.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                height: 1.05,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusChip(status: detail.status, lang: lang),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PillTabBar(
                        labels: [
                          t(lang, "listings.tab_overview"),
                          t(lang, "listings.tab_map"),
                          t(lang, "my_listing_submissions.tab_submission"),
                          t(lang, "listings.tab_transport"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedMapsLocation02,
                            size: 18,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              place.city.isNotEmpty
                                  ? "${place.city}, ${place.country}"
                                  : place.country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withValues(alpha: 0.62),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _SubmissionMetaPill(
                            label: _formatDateShort(detail.updatedAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ThumbRow(images: place.images),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          ListingOverviewTab(place: place),
                          ListingMapTab(place: place),
                          _SubmissionReviewTab(detail: detail, lang: lang),
                          ListingTransportTab(place: place),
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

class _SubmissionReviewTab extends StatelessWidget {
  final _ListingSubmissionDetail detail;
  final String lang;

  const _SubmissionReviewTab({required this.detail, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget section({
      required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    }) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: padding,
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

    Widget header(dynamic icon, String label) {
      return Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(icon: icon, size: 14, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.92),
              letterSpacing: -0.1,
            ),
          ),
        ],
      );
    }

    Widget metaRow(dynamic icon, String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 15,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.52),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final notes = detail.reviewerNotes?.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(
                  HugeIcons.strokeRoundedShield01,
                  t(lang, "my_listing_submissions.submission_title"),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(status: detail.status, lang: lang),
                    _SubmissionMetaPill(label: detail.categoryName),
                  ],
                ),
                const SizedBox(height: 12),
                metaRow(
                  HugeIcons.strokeRoundedCalendar03,
                  t(lang, "my_listing_submissions.created_at"),
                  _formatDateTime(detail.createdAt),
                ),
                const SizedBox(height: 8),
                metaRow(
                  HugeIcons.strokeRoundedClock01,
                  t(lang, "my_listing_submissions.updated_at"),
                  _formatDateTime(detail.updatedAt),
                ),
                const SizedBox(height: 8),
                metaRow(
                  HugeIcons.strokeRoundedLayers01,
                  t(lang, "my_listing_submissions.category"),
                  detail.categoryName,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(
                  HugeIcons.strokeRoundedComment01,
                  t(lang, "my_listing_submissions.reviewer_notes"),
                ),
                const SizedBox(height: 10),
                Text(
                  (notes != null && notes.isNotEmpty)
                      ? notes
                      : t(lang, "my_listing_submissions.reviewer_notes_empty"),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.65,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
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

class _HeroPager extends StatefulWidget {
  final List<String> images;

  const _HeroPager({required this.images});

  @override
  State<_HeroPager> createState() => _HeroPagerState();
}

class _HeroPagerState extends State<_HeroPager> {
  int _index = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  void _openPreview(BuildContext context, List<String> images) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => ListingImagePreview(images: images, initialIndex: _index),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = widget.images.isNotEmpty ? widget.images : [""];
    final media = MediaQuery.of(context);
    final topPad = media.padding.top;
    final heroHeight = media.size.height * 0.52;

    return Stack(
      children: [
        Container(color: scheme.surface),
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: heroHeight,
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _openPreview(context, images),
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (_, index) {
                  final url = images[index].trim();
                  if (url.isEmpty) return _HeroPlaceholder(scheme: scheme);
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        _HeroPlaceholder(scheme: scheme),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return _HeroPlaceholder(scheme: scheme);
                    },
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: heroHeight - 180,
          height: 180,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: topPad + 64,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _index == index ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _index == index
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  final ColorScheme scheme;

  const _HeroPlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.70),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          color: scheme.onSurface.withValues(alpha: 0.35),
          size: 34,
        ),
      ),
    );
  }
}

class _PillTabBar extends StatelessWidget {
  final List<String> labels;

  const _PillTabBar({required this.labels});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.55),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        tabAlignment: TabAlignment.start,
        tabs: labels
            .map(
              (label) => Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ThumbRow extends StatelessWidget {
  final List<String> images;

  const _ThumbRow({required this.images});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = images.where((item) => item.trim().isNotEmpty).toList();
    final shown = list.take(4).toList();
    final extra = math.max(0, list.length - shown.length);

    return Row(
      children: [
        ...shown.map(
          (url) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 54,
                height: 54,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumbFallback(scheme),
                ),
              ),
            ),
          ),
        ),
        if (extra > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (shown.isNotEmpty)
                    Image.network(
                      shown.last,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.35),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (_, __, ___) => _thumbFallback(scheme),
                    )
                  else
                    _thumbFallback(scheme),
                  Center(
                    child: Text(
                      "+$extra",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _thumbFallback(ColorScheme scheme) {
    return Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedImageNotFound01,
        size: 18,
        color: scheme.onSurface.withValues(alpha: 0.35),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.black.withValues(alpha: 0.22),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String lang;

  const _StatusChip({required this.status, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = status.toUpperCase();
    final bg = switch (resolved) {
      "APPROVED" => const Color(0xFF0F7B57),
      "REJECTED" => const Color(0xFF9F1239),
      _ => const Color(0xFF8A4B0F),
    };
    final label = switch (resolved) {
      "APPROVED" => t(lang, "my_listing_submissions.status_approved"),
      "REJECTED" => t(lang, "my_listing_submissions.status_rejected"),
      _ => t(lang, "my_listing_submissions.status_pending"),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.surface.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SubmissionMetaPill extends StatelessWidget {
  final String label;

  const _SubmissionMetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 36,
              color: scheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: Text(t(currentLangSync(), "common.try_again")),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget shimmerBox({
      required double height,
      BorderRadiusGeometry radius = const BorderRadius.all(Radius.circular(18)),
    }) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: radius,
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: shimmerBox(height: double.infinity, radius: BorderRadius.zero),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.58,
              width: double.infinity,
              color: scheme.surface.withValues(alpha: 0.92),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  shimmerBox(height: 24, radius: BorderRadius.circular(12)),
                  const SizedBox(height: 12),
                  shimmerBox(height: 44, radius: BorderRadius.circular(999)),
                  const SizedBox(height: 12),
                  shimmerBox(height: 18, radius: BorderRadius.circular(10)),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: shimmerBox(
                          height: 54,
                          radius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: shimmerBox(
                      height: double.infinity,
                      radius: BorderRadius.circular(18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListingSubmissionDetail {
  final String id;
  final String name;
  final String categoryName;
  final String status;
  final String? reviewerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlaceDetails place;

  const _ListingSubmissionDetail({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.status,
    required this.reviewerNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.place,
  });

  factory _ListingSubmissionDetail.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse((json["created_at"] ?? "").toString()) ??
        DateTime.now();
    final updatedAt =
        DateTime.tryParse((json["updated_at"] ?? "").toString()) ?? createdAt;

    final placeJson = Map<String, dynamic>.from(json)
      ..putIfAbsent("avg_rating", () => 0)
      ..putIfAbsent("reviews_count", () => 0);

    return _ListingSubmissionDetail(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      categoryName: (json["category_name"] ?? "").toString(),
      status: (json["status"] ?? "").toString(),
      reviewerNotes: _stringOrNull(json["reviewer_notes"]),
      createdAt: createdAt,
      updatedAt: updatedAt,
      place: PlaceDetails.fromJson(placeJson),
    );
  }
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return "${_two(local.day)} ${_month(local.month)} ${local.year} • ${_two(local.hour)}:${_two(local.minute)}";
}

String _formatDateShort(DateTime value) {
  final local = value.toLocal();
  return "${_two(local.day)} ${_month(local.month)} ${local.year}";
}

String _two(int value) => value.toString().padLeft(2, "0");

String _month(int month) {
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  return months[(month - 1).clamp(0, 11)];
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
