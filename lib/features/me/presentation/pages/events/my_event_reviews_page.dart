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
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class MyEventReviewsPage extends StatefulWidget {
  const MyEventReviewsPage({super.key});

  @override
  State<MyEventReviewsPage> createState() => _MyEventReviewsPageState();
}

class _MyEventReviewsPageState extends State<MyEventReviewsPage>
    with TickerProviderStateMixin {
  static const List<int> _pageSizeOptions = [10, 20, 30, 50];
  static const List<int?> _ratingOptions = [null, 5, 4, 3, 2, 1];
  static const List<String> _orderingOptions = [
    "created_at",
    "rating",
    "event_title",
  ];

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final List<_EventReviewItem> _reviews = [];

  Timer? _debounce;
  bool _loading = false;
  bool _hydrated = false;
  bool _hasMore = true;
  bool _showBackToTop = false;
  int _page = 1;
  int _pageSize = 10;
  int? _rating;
  bool? _published;
  bool? _isReported;
  String _query = "";
  String _ordering = "created_at";
  String _sort = "desc";
  String? _error;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  String get _lang => currentLangSync();

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    _scrollCtrl.addListener(_onScroll);
    _fetchPage(reset: true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entranceCtrl.forward(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

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
        _reviews.clear();
        _hasMore = false;
        _error = t(_lang, "my_event_reviews.session_expired");
      });
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _reviews.clear();
        _hasMore = false;
        _error = t(_lang, "my_event_reviews.session_expired");
      });
      return;
    }

    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _reviews.clear();
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
    if (_rating != null) params["rating"] = "$_rating";
    if (_published != null) params["published"] = "$_published";
    if (_isReported != null) params["is_reported"] = "$_isReported";

    try {
      final uri = Api.url(
        MyEventEndpoints.reviews,
      ).replace(queryParameters: params);
      final response = await http
          .get(
            uri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthSession.instance.expireSession();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _hydrated = true;
          _reviews.clear();
          _hasMore = false;
          _error = t(_lang, "my_event_reviews.session_expired");
        });
        return;
      }

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _ApiException(
          _extractMessage(decoded) ?? "Status ${response.statusCode}",
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
            (item) =>
                _EventReviewItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      final existingIds = _reviews.map((review) => review.id).toSet();
      final unique = incoming
          .where((review) => !existingIds.contains(review.id))
          .toList();

      if (!mounted) return;
      setState(() {
        _reviews.addAll(unique);
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
        _error = t(_lang, "my_event_reviews.timeout");
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
        _error = t(_lang, "my_event_reviews.load_failed");
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

    int? draftRating = _rating;
    bool? draftPublished = _published;
    bool? draftReported = _isReported;
    String draftOrdering = _ordering;
    String draftSort = _sort;
    int draftPageSize = _pageSize;

    final result = await showModalBottomSheet<_ReviewFilterResult>(
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
                                    t(_lang, "my_event_reviews.filters_title"),
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
                              t(_lang, "my_event_reviews.filters_subtitle"),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: scheme.onSurface.withValues(alpha: 0.66),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SheetLabel(
                              text: t(_lang, "my_event_reviews.filter_rating"),
                            ),
                            Wrap(
                              children: _ratingOptions.map((value) {
                                return chip(
                                  label: _ratingLabel(_lang, value),
                                  selected: draftRating == value,
                                  onTap: () =>
                                      setModalState(() => draftRating = value),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            _SheetLabel(
                              text: t(
                                _lang,
                                "my_event_reviews.filter_published",
                              ),
                            ),
                            Wrap(
                              children: [null, true, false].map((value) {
                                return chip(
                                  label: _publishedLabel(_lang, value),
                                  selected: draftPublished == value,
                                  onTap: () => setModalState(
                                    () => draftPublished = value,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            _SheetLabel(
                              text: t(
                                _lang,
                                "my_event_reviews.filter_reported",
                              ),
                            ),
                            Wrap(
                              children: [null, true, false].map((value) {
                                return chip(
                                  label: _reportedFilterLabel(_lang, value),
                                  selected: draftReported == value,
                                  onTap: () => setModalState(
                                    () => draftReported = value,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            _SheetLabel(
                              text: t(
                                _lang,
                                "my_event_reviews.filter_ordering",
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
                              text: t(_lang, "my_event_reviews.filter_sort"),
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
                                "my_event_reviews.filter_page_size",
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
                                        const _ReviewFilterResult(
                                          rating: null,
                                          published: null,
                                          reported: null,
                                          ordering: "created_at",
                                          sort: "desc",
                                          pageSize: 10,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      t(_lang, "my_event_reviews.reset"),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        _ReviewFilterResult(
                                          rating: draftRating,
                                          published: draftPublished,
                                          reported: draftReported,
                                          ordering: draftOrdering,
                                          sort: draftSort,
                                          pageSize: draftPageSize,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      t(_lang, "my_event_reviews.apply"),
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
      _rating = result.rating;
      _published = result.published;
      _isReported = result.reported;
      _ordering = result.ordering;
      _sort = result.sort;
      _pageSize = result.pageSize;
    });
    _fetchPage(reset: true);
  }

  bool get _hasActiveFilters {
    return _query.isNotEmpty ||
        _rating != null ||
        _published != null ||
        _isReported != null ||
        _ordering != "created_at" ||
        _sort != "desc" ||
        _pageSize != 10;
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final hPad = MediaQuery.sizeOf(context).width >= 700 ? 24.0 : 18.0;

    return SafeArea(
      child: FadeTransition(
        opacity: _entranceFade,
        child: SlideTransition(
          position: _entranceSlide,
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
                              t(lang, "my_event_reviews.title"),
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
                                  child: _ReviewSearchBar(
                                    controller: _searchCtrl,
                                    hintText: t(
                                      lang,
                                      "my_event_reviews.search_hint",
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
                    if (_loading && _reviews.isEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverList.builder(
                          itemCount: 4,
                          itemBuilder: (_, index) =>
                              const _ReviewCardSkeleton(),
                        ),
                      ),
                    if (_reviews.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverList.builder(
                          itemCount:
                              _reviews.length +
                              ((_loading && _reviews.isNotEmpty) ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _reviews.length) {
                              return const _ReviewCardSkeleton();
                            }
                            final item = _reviews[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ReviewCard(
                                item: item,
                                lang: lang,
                                onTap: item.eventId == null
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.eventDetails,
                                        arguments: item.eventId,
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (_error != null && _reviews.isNotEmpty)
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
                    if (!_loading && _reviews.isEmpty && _error != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _LoadStatePanel(
                          icon: Icons.rate_review_outlined,
                          title: t(lang, "my_event_reviews.error_title"),
                          description: _error!,
                          actionLabel: t(lang, "common.try_again"),
                          onAction: () => _fetchPage(reset: true),
                        ),
                      ),
                    if (!_loading &&
                        _reviews.isEmpty &&
                        _error == null &&
                        _hydrated)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _LoadStatePanel(
                          icon: Icons.reviews_outlined,
                          title: t(lang, "my_event_reviews.empty_title"),
                          description: _hasActiveFilters
                              ? t(lang, "my_event_reviews.empty_filtered")
                              : t(lang, "my_event_reviews.empty_default"),
                          actionLabel: _hasActiveFilters
                              ? t(lang, "my_event_reviews.reset")
                              : null,
                          onAction: _hasActiveFilters
                              ? () {
                                  setState(() {
                                    _query = "";
                                    _searchCtrl.clear();
                                    _rating = null;
                                    _published = null;
                                    _isReported = null;
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
                  heroTag: "my-event-reviews-top",
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
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _EventReviewItem item;
  final String lang;
  final VoidCallback? onTap;

  const _ReviewCard({required this.item, required this.lang, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surface.withValues(alpha: 0.98),
                scheme.surfaceContainerHighest.withValues(alpha: 0.22),
              ],
            ),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Stars(rating: item.rating),
                    const Spacer(),
                    Text(
                      item.createdLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: scheme.primary.withValues(alpha: 0.10),
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.eventTitle ??
                                t(lang, "my_event_reviews.no_event"),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.comment?.trim().isNotEmpty == true
                                ? item.comment!.trim()
                                : t(lang, "my_event_reviews.comment_empty"),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: scheme.onSurface.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ReviewPill(
                      label: item.published
                          ? t(lang, "my_event_reviews.published")
                          : t(lang, "my_event_reviews.unpublished"),
                      color: item.published
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    _ReviewPill(
                      label: item.isReported
                          ? t(lang, "my_event_reviews.reported")
                          : t(lang, "my_event_reviews.not_reported"),
                      color: item.isReported ? scheme.error : scheme.tertiary,
                    ),
                    _ReviewPill(
                      label:
                          "${t(lang, "my_event_reviews.rating")} ${item.rating}/5",
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ReviewPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;

  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: const Color(0xFFF59E0B),
          ),
        );
      }),
    );
  }
}

class _ReviewCardSkeleton extends StatefulWidget {
  const _ReviewCardSkeleton();

  @override
  State<_ReviewCardSkeleton> createState() => _ReviewCardSkeletonState();
}

class _ReviewCardSkeletonState extends State<_ReviewCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) {
          return Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
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
          );
        },
      ),
    );
  }
}

class _ReviewSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;
  final ColorScheme scheme;

  const _ReviewSearchBar({
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
                    size: 12,
                    color: scheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ),
            ),
        ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
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
          child: Icon(Icons.tune_rounded, color: scheme.onSurface),
        ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.errorContainer.withValues(alpha: 0.30),
        border: Border.all(color: scheme.error.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.error, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: scheme.error.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: scheme.onSurface.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 14),
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
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.65),
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

class _EventReviewItem {
  final String id;
  final String? eventId;
  final String? eventTitle;
  final int rating;
  final String? comment;
  final bool published;
  final bool isReported;
  final DateTime? createdAt;

  const _EventReviewItem({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.rating,
    required this.comment,
    required this.published,
    required this.isReported,
    required this.createdAt,
  });

  factory _EventReviewItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    return _EventReviewItem(
      id: (json["id"] ?? "").toString(),
      eventId: json["event_id"]?.toString(),
      eventTitle: json["event_title"]?.toString(),
      rating: json["rating"] is num ? (json["rating"] as num).toInt() : 0,
      comment: json["comment"]?.toString(),
      published: json["published"] == true,
      isReported: json["is_reported"] == true,
      createdAt: parseDate(json["created_at"]?.toString()),
    );
  }

  String get createdLabel {
    if (createdAt == null) return "";
    return DateFormat("dd MMM yyyy").format(createdAt!);
  }
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}

String _ratingLabel(String lang, int? rating) {
  if (rating == null) return t(lang, "my_event_reviews.all_ratings");
  return "$rating★";
}

String _publishedLabel(String lang, bool? value) {
  if (value == null) return t(lang, "my_event_reviews.published_all");
  return value
      ? t(lang, "my_event_reviews.published_only")
      : t(lang, "my_event_reviews.unpublished_only");
}

String _reportedFilterLabel(String lang, bool? value) {
  if (value == null) return t(lang, "my_event_reviews.reported_all");
  return value
      ? t(lang, "my_event_reviews.reported_only")
      : t(lang, "my_event_reviews.clean_only");
}

String _orderingLabel(String lang, String value) {
  switch (value) {
    case "rating":
      return t(lang, "my_event_reviews.ordering_rating");
    case "event_title":
      return t(lang, "my_event_reviews.ordering_event_title");
    case "created_at":
    default:
      return t(lang, "my_event_reviews.ordering_created");
  }
}

String _sortLabel(String lang, String value) {
  return value == "asc"
      ? t(lang, "my_event_reviews.sort_asc")
      : t(lang, "my_event_reviews.sort_desc");
}

class _ReviewFilterResult {
  final int? rating;
  final bool? published;
  final bool? reported;
  final String ordering;
  final String sort;
  final int pageSize;

  const _ReviewFilterResult({
    required this.rating,
    required this.published,
    required this.reported,
    required this.ordering,
    required this.sort,
    required this.pageSize,
  });
}
