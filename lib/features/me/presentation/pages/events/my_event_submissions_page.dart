import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/my_event_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../core/widgets/app_cached_image.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "my_event_submission_detail_page.dart";

class MyEventSubmissionsPage extends StatefulWidget {
  const MyEventSubmissionsPage({super.key});

  @override
  State<MyEventSubmissionsPage> createState() => _MyEventSubmissionsPageState();
}

class _MyEventSubmissionsPageState extends State<MyEventSubmissionsPage> {
  static const List<int> _pageSizeOptions = [10, 20, 30, 50];
  static const List<String?> _statusOptions = [
    null,
    "PENDING",
    "APPROVED",
    "REJECTED",
  ];
  static const List<String> _orderingOptions = [
    "created_at",
    "updated_at",
    "title",
    "status",
    "city",
  ];

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_SubmissionItem> _items = [];

  Timer? _debounce;
  bool _loading = false;
  bool _hasMore = true;
  bool _showBackToTop = false;
  bool _hydrated = false;
  int _page = 1;
  int _pageSize = 10;
  String _query = "";
  String? _status;
  String _ordering = "created_at";
  String _sort = "desc";
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _lang => currentLangSync();

  void _onScroll() {
    final px = _scrollCtrl.position.pixels;

    if (px >= _scrollCtrl.position.maxScrollExtent - 220 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }

    final show = px > 320;
    if (show != _showBackToTop && mounted) {
      setState(() => _showBackToTop = show);
    }
  }

  Future<void> _fetchPage({required bool reset}) async {
    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _items.clear();
        _hasMore = false;
        _error = t(_lang, "my_events.submissions_session_expired");
      });
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _items.clear();
        _hasMore = false;
        _error = t(_lang, "my_events.submissions_session_expired");
      });
      return;
    }

    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
      }
      _error = null;
    });

    final params = <String, String>{
      "page": "$_page",
      "page_size": "$_pageSize",
      "ordering": _ordering,
      "sort": _sort,
    };
    if (_query.isNotEmpty) params["search"] = _query;
    if (_status != null && _status!.isNotEmpty) params["status"] = _status!;

    try {
      final uri = Api.url(
        MyEventEndpoints.submissions,
      ).replace(queryParameters: params);
      final resp = await http
          .get(
            uri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        await AuthSession.instance.expireSession();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _hydrated = true;
          _items.clear();
          _hasMore = false;
          _error = t(_lang, "my_events.submissions_session_expired");
        });
        return;
      }

      final decoded = resp.body.isEmpty ? null : jsonDecode(resp.body);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw _ApiException(
          _extractMessage(decoded) ?? "Status ${resp.statusCode}",
        );
      }

      List<dynamic> results = const [];
      if (decoded is Map) {
        results = (decoded["results"] ?? const []) as List? ?? const [];
      } else if (decoded is List) {
        results = decoded;
      }

      final incoming = results
          .whereType<Map>()
          .map(
            (item) => _SubmissionItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      final existingIds = _items.map((e) => e.id).toSet();
      final unique = incoming
          .where((e) => !existingIds.contains(e.id))
          .toList();

      if (!mounted) return;
      setState(() {
        _items.addAll(unique);
        _hasMore = incoming.length >= _pageSize;
        if (_hasMore) _page += 1;
        _hydrated = true;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _error = t(_lang, "my_events.submissions_timeout");
      });
    } on _ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _error = t(_lang, "my_events.submissions_load_failed");
      });
    }
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map && decoded["message"] != null) {
      return decoded["message"].toString();
    }
    return null;
  }

  Future<void> _onRefresh() async => _fetchPage(reset: true);

  void _onSearchChanged(String value) {
    setState(() {});
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchPage(reset: true);
    });
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    setState(() {
      _searchCtrl.clear();
      _query = "";
    });
    _fetchPage(reset: true);
  }

  Future<void> _openFilters() async {
    HapticFeedback.selectionClick();

    String? draftStatus = _status;
    String draftOrdering = _ordering;
    String draftSort = _sort;
    int draftPageSize = _pageSize;

    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final isDark = scheme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget chip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => onTap(),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : scheme.onSurface.withValues(
                            alpha: isDark ? 0.78 : 0.72,
                          ),
                  ),
                  selectedColor: scheme.primary,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.045),
                  side: BorderSide(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.94)
                        : scheme.outline.withValues(alpha: 0.16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  24,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(
                          alpha: isDark ? 0.96 : 0.98,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.10),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t(
                                      _lang,
                                      "my_events.submissions_filters_title",
                                    ),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t(
                                _lang,
                                "my_events.submissions_filters_subtitle",
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: scheme.onSurface.withValues(alpha: 0.66),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SheetLabel(
                              text: t(
                                _lang,
                                "my_events.submissions_filter_status",
                              ),
                            ),
                            Wrap(
                              children: _statusOptions.map((value) {
                                return chip(
                                  label: _statusLabel(_lang, value),
                                  selected: draftStatus == value,
                                  onTap: () =>
                                      setModalState(() => draftStatus = value),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            _SheetLabel(
                              text: t(
                                _lang,
                                "my_events.submissions_filter_ordering",
                              ),
                            ),
                            Wrap(
                              children: _orderingOptions.map((value) {
                                return chip(
                                  label: _orderingLabel(_lang, value),
                                  selected: draftOrdering == value,
                                  onTap: () => setModalState(
                                    () => draftOrdering = value,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            _SheetLabel(
                              text: t(
                                _lang,
                                "my_events.submissions_filter_sort",
                              ),
                            ),
                            Wrap(
                              children: ["desc", "asc"].map((value) {
                                return chip(
                                  label: _sortLabel(_lang, value),
                                  selected: draftSort == value,
                                  onTap: () =>
                                      setModalState(() => draftSort = value),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            _SheetLabel(
                              text: t(
                                _lang,
                                "my_events.submissions_filter_page_size",
                              ),
                            ),
                            DropdownButtonFormField<int>(
                              initialValue: draftPageSize,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: scheme.outline.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: scheme.outline.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                ),
                              ),
                              items: _pageSizeOptions
                                  .map(
                                    (size) => DropdownMenuItem<int>(
                                      value: size,
                                      child: Text("$size"),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setModalState(() => draftPageSize = value);
                              },
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        const _FilterResult(
                                          status: null,
                                          ordering: "created_at",
                                          sort: "desc",
                                          pageSize: 10,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      t(_lang, "my_events.submissions_reset"),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        _FilterResult(
                                          status: draftStatus,
                                          ordering: draftOrdering,
                                          sort: draftSort,
                                          pageSize: draftPageSize,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      t(_lang, "my_events.submissions_apply"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _status = result.status;
      _ordering = result.ordering;
      _sort = result.sort;
      _pageSize = result.pageSize;
    });
    _fetchPage(reset: true);
  }

  bool get _hasActiveFilters {
    return _query.isNotEmpty ||
        _status != null ||
        _ordering != "created_at" ||
        _sort != "desc" ||
        _pageSize != 10;
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 700;
    final hPad = isTablet ? 24.0 : 18.0;
    final crossCount = isTablet ? 2 : 1;
    final cardAspect = isTablet ? 0.64 : 0.68;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: scheme.primary,
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(lang, "nav.my_event_submissions"),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: scheme.onSurface,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _PremiumSearchBar(
                                controller: _searchCtrl,
                                hintText: t(
                                  lang,
                                  "my_events.submissions_search_hint",
                                ),
                                onChanged: _onSearchChanged,
                                onClear: _clearSearch,
                                isDark: isDark,
                                scheme: scheme,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _FilterButton(
                              scheme: scheme,
                              isDark: isDark,
                              onTap: _openFilters,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loading && _items.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: cardAspect,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _EventCardSkeleton(index: i),
                        childCount: 4,
                      ),
                    ),
                  ),
                if (_items.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: cardAspect,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final showLoader = _loading && _items.isNotEmpty;
                          if (index >= _items.length) {
                            return showLoader
                                ? _EventCardSkeleton(index: index)
                                : const SizedBox.shrink();
                          }
                          final item = _items[index];
                          return _AnimatedGridItem(
                            index: index,
                            child: _SubmissionPosterCard(
                              item: item,
                              lang: lang,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.myEventSubmissionDetail,
                                arguments: MyEventSubmissionDetailArgs(
                                  submissionId: item.id,
                                  title: item.title,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount:
                            _items.length +
                            ((_loading && _items.isNotEmpty) ? 2 : 0),
                      ),
                    ),
                  ),
                if (_error != null && _items.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                    sliver: SliverToBoxAdapter(
                      child: _InlineErrorPanel(
                        message: _error!,
                        onRetry: () => _fetchPage(reset: false),
                        actionLabel: t(lang, "common.try_again"),
                        scheme: scheme,
                      ),
                    ),
                  ),
                if (!_loading && _items.isEmpty && _error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _LoadStatePanel(
                      icon: Icons.wifi_tethering_error_rounded,
                      title: t(lang, "my_events.submissions_error_title"),
                      description: _error!,
                      actionLabel: t(lang, "common.try_again"),
                      onAction: () => _fetchPage(reset: true),
                    ),
                  ),
                if (!_loading && _items.isEmpty && _error == null && _hydrated)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _LoadStatePanel(
                      icon: Icons.event_busy_rounded,
                      title: t(lang, "my_events.submissions_empty_title"),
                      description: _hasActiveFilters
                          ? t(lang, "my_events.submissions_empty_filtered")
                          : t(lang, "my_events.submissions_empty_default"),
                      actionLabel: _hasActiveFilters
                          ? t(lang, "my_events.submissions_reset")
                          : null,
                      onAction: _hasActiveFilters
                          ? () {
                              setState(() {
                                _query = "";
                                _searchCtrl.clear();
                                _status = null;
                                _ordering = "created_at";
                                _sort = "desc";
                                _pageSize = 10;
                              });
                              _fetchPage(reset: true);
                            }
                          : null,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            right: 18,
            bottom: _showBackToTop ? 24 : -72,
            child: FloatingActionButton.small(
              heroTag: "my-event-submissions-top",
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
              ),
              child: const Icon(Icons.arrow_upward_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionPosterCard extends StatefulWidget {
  final _SubmissionItem item;
  final String lang;
  final VoidCallback onTap;

  const _SubmissionPosterCard({
    required this.item,
    required this.lang,
    required this.onTap,
  });

  @override
  State<_SubmissionPosterCard> createState() => _SubmissionPosterCardState();
}

class _SubmissionPosterCardState extends State<_SubmissionPosterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.974,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(24);
    final statusInfo = _resolveSubmissionStatus(
      widget.item,
      widget.lang,
      scheme,
    );

    return ScaleTransition(
      scale: _pressScale,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _BannerImage(url: widget.item.bannerUrl, scheme: scheme),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.35, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.10 : 0.14,
                      ),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: _StatusBadge(info: statusInfo),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _SubmissionGlassFooter(
                  title: widget.item.title,
                  eventDateLabel: widget.item.eventDateLabel(widget.lang),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  final String? url;
  final ColorScheme scheme;

  const _BannerImage({required this.url, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.trim().isNotEmpty) {
      return AppCachedImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 1200,
        memCacheHeight: 900,
        maxWidthDiskCache: 1600,
        maxHeightDiskCache: 1200,
        errorBuilder: (_) => _ImagePlaceholder(scheme: scheme),
        placeholderBuilder: (_) => _ImagePlaceholder(scheme: scheme),
      );
    }
    return _ImagePlaceholder(scheme: scheme);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ColorScheme scheme;

  const _ImagePlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.80),
            scheme.surfaceContainerHighest.withValues(alpha: 0.50),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 44,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}

class _SubmissionGlassFooter extends StatelessWidget {
  final String title;
  final String eventDateLabel;

  const _SubmissionGlassFooter({
    required this.title,
    required this.eventDateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.14 : 0.18),
            Colors.white.withValues(alpha: isDark ? 0.07 : 0.11),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.17),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 9),
          _MetaPill(icon: Icons.event_available_rounded, label: eventDateLabel),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.90)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StatusInfo info;

  const _StatusBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: info.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        info.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: info.textColor,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _AnimatedGridItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedGridItem({required this.index, required this.child});

  @override
  State<_AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<_AnimatedGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: (widget.index * 55).clamp(0, 280));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _InlineErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String actionLabel;
  final ColorScheme scheme;

  const _InlineErrorPanel({
    required this.message,
    required this.onRetry,
    required this.actionLabel,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.error.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _LoadStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _LoadStatePanel({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.08),
              ),
              child: Icon(icon, size: 36, color: scheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterButton({
    required this.scheme,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 48,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
        child: Icon(
          Icons.tune_rounded,
          size: 18,
          color: scheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _PremiumSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;
  final ColorScheme scheme;

  const _PremiumSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          Icon(
            Icons.search_rounded,
            size: 17,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.38),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.onSurface.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;

  const _SheetLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _EventCardSkeleton extends StatefulWidget {
  final int index;

  const _EventCardSkeleton({required this.index});

  @override
  State<_EventCardSkeleton> createState() => _EventCardSkeletonState();
}

class _EventCardSkeletonState extends State<_EventCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.5 + _shimmer.value * 3, 0),
                    end: Alignment(-0.5 + _shimmer.value * 3, 0),
                    colors: [
                      scheme.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.42 : 0.56,
                      ),
                      scheme.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.22 : 0.28,
                      ),
                      scheme.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.42 : 0.56,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  width: 84,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.14 : 0.18),
                        Colors.white.withValues(alpha: isDark ? 0.07 : 0.11),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.22 : 0.10,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 160,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        width: 132,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubmissionItem {
  final String id;
  final String title;
  final String? bannerUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final String status;

  const _SubmissionItem({
    required this.id,
    required this.title,
    required this.bannerUrl,
    required this.startAt,
    required this.endAt,
    required this.status,
  });

  factory _SubmissionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    return _SubmissionItem(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? "Event submission").toString(),
      bannerUrl: (json["banner_url"] as String?)?.trim().isNotEmpty == true
          ? json["banner_url"] as String
          : null,
      startAt: parseDt(json["start_at"]?.toString()),
      endAt: parseDt(json["end_at"]?.toString()),
      status: (json["status"] ?? "PENDING").toString(),
    );
  }

  String eventDateLabel(String lang) {
    if (startAt == null && endAt == null) {
      return t(lang, "my_events.submissions_no_dates");
    }

    if (startAt != null && endAt != null) {
      final sameDay =
          startAt!.year == endAt!.year &&
          startAt!.month == endAt!.month &&
          startAt!.day == endAt!.day;

      if (sameDay) {
        return DateFormat("dd MMM · hh:mm a").format(startAt!);
      }
      return "${DateFormat("dd MMM").format(startAt!)} - ${DateFormat("dd MMM").format(endAt!)}";
    }

    return DateFormat("dd MMM · hh:mm a").format((startAt ?? endAt)!);
  }
}

class _StatusInfo {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _StatusInfo({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });
}

_StatusInfo _resolveSubmissionStatus(
  _SubmissionItem item,
  String lang,
  ColorScheme scheme,
) {
  switch (item.status.toUpperCase()) {
    case "APPROVED":
      return _StatusInfo(
        label: t(lang, "my_events.submissions_approved"),
        bgColor: Colors.green.withValues(alpha: 0.52),
        textColor: Colors.white,
        borderColor: Colors.green.withValues(alpha: 0.38),
      );
    case "REJECTED":
      return _StatusInfo(
        label: t(lang, "my_events.submissions_rejected"),
        bgColor: Colors.red.withValues(alpha: 0.52),
        textColor: Colors.white,
        borderColor: Colors.red.withValues(alpha: 0.38),
      );
    default:
      return _StatusInfo(
        label: t(lang, "my_events.submissions_pending"),
        bgColor: Colors.orange.withValues(alpha: 0.52),
        textColor: Colors.white,
        borderColor: Colors.orange.withValues(alpha: 0.38),
      );
  }
}

String _statusLabel(String lang, String? value) {
  switch (value?.toUpperCase()) {
    case "PENDING":
      return t(lang, "my_events.submissions_pending");
    case "APPROVED":
      return t(lang, "my_events.submissions_approved");
    case "REJECTED":
      return t(lang, "my_events.submissions_rejected");
    default:
      return t(lang, "common.all");
  }
}

String _orderingLabel(String lang, String value) {
  switch (value) {
    case "updated_at":
      return t(lang, "my_events.submissions_order_updated");
    case "title":
      return t(lang, "my_events.submissions_order_title");
    case "status":
      return t(lang, "my_events.submissions_order_status");
    case "city":
      return t(lang, "my_events.submissions_order_city");
    default:
      return t(lang, "my_events.submissions_order_created");
  }
}

String _sortLabel(String lang, String value) {
  return value.toLowerCase() == "asc"
      ? t(lang, "my_events.submissions_sort_asc")
      : t(lang, "my_events.submissions_sort_desc");
}

class _FilterResult {
  final String? status;
  final String ordering;
  final String sort;
  final int pageSize;

  const _FilterResult({
    required this.status,
    required this.ordering,
    required this.sort,
    required this.pageSize,
  });
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}
