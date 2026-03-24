import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;

import "../../../../../core/config/api.dart";
import "../../../../../core/constants/api/my_event_endpoints.dart";
import "../../../../../core/constants/app_colors.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

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

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  Timer? _searchDebounce;

  List<_MyEventSubmissionItem> _items = const [];
  bool _loading = false;
  bool _hydrated = false;
  bool _showBackToTop = false;
  String? _error;

  int _page = 1;
  int _pageSize = 10;
  int _count = 0;
  bool _hasNext = false;
  bool _hasPrevious = false;

  String? _status;
  String _ordering = "created_at";
  String _sort = "desc";

  String get _lang => currentLangSync();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_handleScroll);
    unawaited(_fetchSubmissions());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldShow = _scrollCtrl.hasClients && _scrollCtrl.offset > 420;
    if (shouldShow != _showBackToTop && mounted) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  Future<void> _fetchSubmissions({bool resetPage = false}) async {
    if (resetPage) _page = 1;

    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _items = const [];
        _count = 0;
        _hasNext = false;
        _hasPrevious = false;
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
        _items = const [];
        _error = t(_lang, "my_events.submissions_session_expired");
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final query = <String, String>{
      "page": "$_page",
      "page_size": "$_pageSize",
      "ordering": _ordering,
      "sort": _sort,
    };

    final search = _searchCtrl.text.trim();
    if (search.isNotEmpty) {
      query["search"] = search;
    }
    if (_status != null && _status!.isNotEmpty) {
      query["status"] = _status!;
    }

    final uri = Api.url(
      MyEventEndpoints.submissions,
    ).replace(queryParameters: query);

    try {
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
          _items = const [];
          _error = t(_lang, "my_events.submissions_session_expired");
        });
        return;
      }

      final dynamic decoded = resp.body.isEmpty ? null : jsonDecode(resp.body);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw _ApiException(
          _extractMessage(decoded) ?? "Status ${resp.statusCode}",
        );
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      final results = (map["results"] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => _MyEventSubmissionItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _items = results;
        _count = (map["count"] as num?)?.toInt() ?? results.length;
        _hasNext = map["next"] != null;
        _hasPrevious = map["previous"] != null;
        _loading = false;
        _hydrated = true;
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

  void _onSearchChanged(String value) {
    if (mounted) setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      _page = 1;
      unawaited(_fetchSubmissions());
    });
  }

  Future<void> _openFilters() async {
    HapticFeedback.selectionClick();

    String? draftStatus = _status;
    String draftOrdering = _ordering;
    String draftSort = _sort;
    int draftPageSize = _pageSize;

    final applied = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final isDark = scheme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChoiceChip({
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
                  selectedColor: AppColors.primary,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.045),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.90)
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
                                return buildChoiceChip(
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
                                return buildChoiceChip(
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
                                return buildChoiceChip(
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
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
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

    if (applied == null || !mounted) return;

    setState(() {
      _status = applied.status;
      _ordering = applied.ordering;
      _sort = applied.sort;
      _pageSize = applied.pageSize;
      _page = 1;
    });
    unawaited(_fetchSubmissions());
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    setState(() {
      _searchCtrl.clear();
      _page = 1;
    });
    unawaited(_fetchSubmissions());
  }

  Future<void> _refresh() => _fetchSubmissions();

  int get _totalPages {
    if (_count <= 0) return 1;
    return ((_count + _pageSize - 1) / _pageSize).floor();
  }

  int get _fromItem => _count == 0 ? 0 : ((_page - 1) * _pageSize) + 1;

  int get _toItem {
    if (_count == 0) return 0;
    final raw = _page * _pageSize;
    return raw > _count ? _count : raw;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width >= 900
        ? 28.0
        : size.width >= 600
        ? 22.0
        : 16.0;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface,
                scheme.surface.withValues(alpha: isDark ? 0.96 : 0.98),
                scheme.surface,
              ],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ScrollConfiguration(
              behavior: const _NoGlowBehavior(),
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroSummaryCard(
                            lang: _lang,
                            scheme: scheme,
                            count: _count,
                            page: _page,
                            totalPages: _totalPages,
                            loading: _loading,
                            activeStatus: _status,
                            ordering: _ordering,
                            sort: _sort,
                            onRefresh: _fetchSubmissions,
                          ),
                          const SizedBox(height: 14),
                          _SearchToolbar(
                            lang: _lang,
                            controller: _searchCtrl,
                            scheme: scheme,
                            loading: _loading,
                            onChanged: _onSearchChanged,
                            onClear: _clearSearch,
                            onFilterTap: _openFilters,
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 12),
                            _ActiveFilterWrap(
                              lang: _lang,
                              scheme: scheme,
                              search: _searchCtrl.text.trim(),
                              status: _status,
                              ordering: _ordering,
                              sort: _sort,
                              pageSize: _pageSize,
                            ),
                          ],
                          if (_loading && _hydrated) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                minHeight: 3.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!_hydrated && _loading)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _SubmissionSkeletonCard(scheme: scheme),
                          ),
                          childCount: 3,
                        ),
                      ),
                    )
                  else if (_error != null && _items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _LoadStatePanel(
                        icon: Icons.wifi_tethering_error_rounded,
                        title: t(_lang, "my_events.submissions_error_title"),
                        description: _error!,
                        actionLabel: t(_lang, "common.try_again"),
                        onAction: () => _fetchSubmissions(),
                      ),
                    )
                  else if (_items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _LoadStatePanel(
                        icon: Icons.event_busy_rounded,
                        title: t(_lang, "my_events.submissions_empty_title"),
                        description: _hasActiveFilters
                            ? t(_lang, "my_events.submissions_empty_filtered")
                            : t(_lang, "my_events.submissions_empty_default"),
                        actionLabel: _hasActiveFilters
                            ? t(_lang, "my_events.submissions_reset")
                            : null,
                        onAction: _hasActiveFilters
                            ? () {
                                setState(() {
                                  _searchCtrl.clear();
                                  _status = null;
                                  _ordering = "created_at";
                                  _sort = "desc";
                                  _pageSize = 10;
                                  _page = 1;
                                });
                                _fetchSubmissions();
                              }
                            : null,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _SubmissionPremiumCard(
                              item: _items[index],
                              lang: _lang,
                              scheme: scheme,
                            ),
                          ),
                          childCount: _items.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 96),
                      child: _PaginationPanel(
                        lang: _lang,
                        scheme: scheme,
                        count: _count,
                        currentPage: _page,
                        totalPages: _totalPages,
                        fromItem: _fromItem,
                        toItem: _toItem,
                        pageSize: _pageSize,
                        loading: _loading,
                        hasPrevious: _hasPrevious,
                        hasNext: _hasNext,
                        onPrevious: _hasPrevious
                            ? () {
                                setState(() => _page -= 1);
                                _fetchSubmissions();
                              }
                            : null,
                        onNext: _hasNext
                            ? () {
                                setState(() => _page += 1);
                                _fetchSubmissions();
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          right: 18,
          bottom: _showBackToTop ? 18 : -72,
          child: FloatingActionButton.small(
            heroTag: "event-submissions-top",
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
              );
            },
            child: const Icon(Icons.arrow_upward_rounded),
          ),
        ),
      ],
    );
  }

  bool get _hasActiveFilters {
    return _searchCtrl.text.trim().isNotEmpty ||
        _status != null ||
        _ordering != "created_at" ||
        _sort != "desc" ||
        _pageSize != 10;
  }
}

class _HeroSummaryCard extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;
  final int count;
  final int page;
  final int totalPages;
  final bool loading;
  final String? activeStatus;
  final String ordering;
  final String sort;
  final Future<void> Function({bool resetPage}) onRefresh;

  const _HeroSummaryCard({
    required this.lang,
    required this.scheme,
    required this.count,
    required this.page,
    required this.totalPages,
    required this.loading,
    required this.activeStatus,
    required this.ordering,
    required this.sort,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0B331D),
                  const Color(0xFF103F2A),
                  const Color(0xFF1A5C3E),
                ]
              : [
                  const Color(0xFF072C18),
                  const Color(0xFF0E4C2C),
                  const Color(0xFF1D6F45),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -34,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(lang, "nav.my_event_submissions"),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t(lang, "my_events.submissions_subtitle"),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.74),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: loading ? null : () => onRefresh(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        loading
                            ? Icons.hourglass_top_rounded
                            : Icons.refresh_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroMetricPill(
                      icon: Icons.layers_rounded,
                      label: t(lang, "my_events.submissions_total"),
                      value: "$count",
                    ),
                    _HeroMetricPill(
                      icon: Icons.auto_awesome_mosaic_rounded,
                      label: t(lang, "my_events.submissions_page"),
                      value: "$page/$totalPages",
                    ),
                    _HeroMetricPill(
                      icon: Icons.swap_vert_rounded,
                      label: _orderingLabel(lang, ordering),
                      value: _sortLabel(lang, sort),
                    ),
                    _HeroMetricPill(
                      icon: Icons.flag_circle_rounded,
                      label: t(lang, "my_events.submissions_status"),
                      value: _statusLabel(lang, activeStatus),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchToolbar extends StatelessWidget {
  final String lang;
  final TextEditingController controller;
  final ColorScheme scheme;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const _SearchToolbar({
    required this.lang,
    required this.controller,
    required this.scheme,
    required this.loading,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: isDark ? 0.80 : 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.10),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.68),
                    ),
                    hintText: t(lang, "my_events.submissions_search_hint"),
                    hintStyle: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.48),
                      fontWeight: FontWeight.w600,
                    ),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: onClear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: loading ? null : onFilterTap,
            child: Ink(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: isDark ? 0.84 : 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.10),
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterWrap extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;
  final String search;
  final String? status;
  final String ordering;
  final String sort;
  final int pageSize;

  const _ActiveFilterWrap({
    required this.lang,
    required this.scheme,
    required this.search,
    required this.status,
    required this.ordering,
    required this.sort,
    required this.pageSize,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (search.isNotEmpty)
        '${t(lang, "my_events.submissions_search")} "$search"',
      if (status != null) _statusLabel(lang, status),
      if (ordering != "created_at") _orderingLabel(lang, ordering),
      if (sort != "desc") _sortLabel(lang, sort),
      if (pageSize != 10)
        "${t(lang, "my_events.submissions_page_size_short")}: $pageSize",
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (chip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SubmissionPremiumCard extends StatelessWidget {
  final _MyEventSubmissionItem item;
  final String lang;
  final ColorScheme scheme;

  const _SubmissionPremiumCard({
    required this.item,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(28);
    final ticket = item.firstTicket;
    final submissionStatus = _submissionStatusInfo(lang, item.status);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.92 : 0.98),
        borderRadius: radius,
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SubmissionBannerImage(url: item.bannerUrl, scheme: scheme),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.34, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.12),
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
                            Colors.black.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _SubmissionStatusBadge(info: submissionStatus),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _TopMetaGlassPill(
                      icon: Icons.schedule_rounded,
                      label: _formatShortDate(item.createdAt),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: _SubmissionGlassFooter(
                      title: item.title,
                      locationLabel: item.locationLabel,
                      ticketLabel: item.ticketLabel(lang),
                      isFree: item.isFreeTicket,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DetailChip(
                      icon: Icons.event_available_rounded,
                      label: t(lang, "my_events.submissions_dates"),
                      value: item.dateRangeLabel(lang),
                      scheme: scheme,
                    ),
                    _DetailChip(
                      icon: Icons.location_city_rounded,
                      label: t(lang, "my_events.submissions_venue"),
                      value: item.venueLabel(lang),
                      scheme: scheme,
                    ),
                    _DetailChip(
                      icon: Icons.pin_drop_rounded,
                      label: t(lang, "my_events.submissions_location"),
                      value: item.locationLabel,
                      scheme: scheme,
                    ),
                    _DetailChip(
                      icon: Icons.inventory_2_rounded,
                      label: t(lang, "my_events.submissions_ticket"),
                      value:
                          ticket?.categoryLabel(lang) ??
                          t(lang, "my_events.submissions_ticket_none"),
                      scheme: scheme,
                    ),
                  ],
                ),
                if (ticket?.consumableDescription.trim().isNotEmpty ??
                    false) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.local_bar_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t(lang, "my_events.submissions_consumable"),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ticket!.consumableDescription,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TimelineMeta(
                        icon: Icons.upload_rounded,
                        label: t(lang, "my_events.submissions_submitted_on"),
                        value: _formatLongDate(item.createdAt),
                        scheme: scheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimelineMeta(
                        icon: Icons.update_rounded,
                        label: t(lang, "my_events.submissions_updated_on"),
                        value: _formatLongDate(item.updatedAt),
                        scheme: scheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${t(lang, "my_events.submissions_id")}: ${item.shortId}",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.58),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: submissionStatus.softBackground,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: submissionStatus.borderColor),
                      ),
                      child: Text(
                        submissionStatus.helperLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: submissionStatus.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionBannerImage extends StatelessWidget {
  final String? url;
  final ColorScheme scheme;

  const _SubmissionBannerImage({required this.url, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.trim().isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _SubmissionImagePlaceholder(scheme: scheme),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : _SubmissionImagePlaceholder(scheme: scheme),
      );
    }

    return _SubmissionImagePlaceholder(scheme: scheme);
  }
}

class _SubmissionImagePlaceholder extends StatelessWidget {
  final ColorScheme scheme;

  const _SubmissionImagePlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.90),
            scheme.surfaceContainerHighest.withValues(alpha: 0.54),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_note_rounded,
          size: 42,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.26),
        ),
      ),
    );
  }
}

class _SubmissionGlassFooter extends StatelessWidget {
  final String title;
  final String locationLabel;
  final String ticketLabel;
  final bool isFree;

  const _SubmissionGlassFooter({
    required this.title,
    required this.locationLabel,
    required this.ticketLabel,
    required this.isFree,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark ? 0.09 : 0.13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.17),
            ),
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
              Row(
                children: [
                  Expanded(
                    child: _FooterMetaPill(
                      icon: Icons.place_rounded,
                      label: locationLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FooterMetaPill(
                    icon: isFree
                        ? Icons.celebration_rounded
                        : Icons.confirmation_number_outlined,
                    label: ticketLabel,
                    highlight: isFree,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _FooterMetaPill({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? Colors.green.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.26);
    final border = highlight
        ? Colors.green.withValues(alpha: 0.40)
        : Colors.white.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
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

class _TopMetaGlassPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopMetaGlassPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.92)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionStatusBadge extends StatelessWidget {
  final _SubmissionStatusInfo info;

  const _SubmissionStatusBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: info.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: info.borderColor, width: 1),
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
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.52),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.86),
                    height: 1.25,
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

class _TimelineMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;

  const _TimelineMeta({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.52),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.82),
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

class _PaginationPanel extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;
  final int count;
  final int currentPage;
  final int totalPages;
  final int fromItem;
  final int toItem;
  final int pageSize;
  final bool loading;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationPanel({
    required this.lang,
    required this.scheme,
    required this.count,
    required this.currentPage,
    required this.totalPages,
    required this.fromItem,
    required this.toItem,
    required this.pageSize,
    required this.loading,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.90 : 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoBadge(
                icon: Icons.format_list_bulleted_rounded,
                label:
                    "${t(lang, "my_events.submissions_showing")} $fromItem-$toItem ${t(lang, "my_events.submissions_of")} $count",
                scheme: scheme,
              ),
              _InfoBadge(
                icon: Icons.pages_rounded,
                label:
                    "${t(lang, "my_events.submissions_page")} $currentPage ${t(lang, "my_events.submissions_of")} $totalPages",
                scheme: scheme,
              ),
              _InfoBadge(
                icon: Icons.data_object_rounded,
                label:
                    "${t(lang, "my_events.submissions_page_size_short")}: $pageSize",
                scheme: scheme,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onPrevious,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(t(lang, "my_events.submissions_previous")),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loading ? null : onNext,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(t(lang, "my_events.submissions_next")),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.78),
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubmissionSkeletonCard extends StatelessWidget {
  final ColorScheme scheme;

  const _SubmissionSkeletonCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final soft = scheme.surfaceContainerHighest.withValues(alpha: 0.24);

    Widget line(double width, {double height = 12}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line(180, height: 14),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SkeletonChip(base: base, width: 118),
                    _SkeletonChip(base: base, width: 138),
                    _SkeletonChip(base: base, width: 126),
                    _SkeletonChip(base: base, width: 114),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonChip extends StatelessWidget {
  final Color base;
  final double width;

  const _SkeletonChip({required this.base, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(18),
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

class _MyEventSubmissionItem {
  final String id;
  final String title;
  final String? bannerUrl;
  final _SubmissionTicket? firstTicket;
  final DateTime? startAt;
  final DateTime? endAt;
  final String venueName;
  final String city;
  final String country;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const _MyEventSubmissionItem({
    required this.id,
    required this.title,
    required this.bannerUrl,
    required this.firstTicket,
    required this.startAt,
    required this.endAt,
    required this.venueName,
    required this.city,
    required this.country,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _MyEventSubmissionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic raw) {
      final value = raw?.toString();
      if (value == null || value.isEmpty) return null;
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }

    final ticketJson = json["first_ticket"];
    return _MyEventSubmissionItem(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? "Event submission").toString(),
      bannerUrl: (json["banner_url"] ?? "").toString().trim().isEmpty
          ? null
          : json["banner_url"].toString(),
      firstTicket: ticketJson is Map
          ? _SubmissionTicket.fromJson(Map<String, dynamic>.from(ticketJson))
          : null,
      startAt: parseDt(json["start_at"]),
      endAt: parseDt(json["end_at"]),
      venueName: (json["venue_name"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      status: (json["status"] ?? "PENDING").toString(),
      createdAt: parseDt(json["created_at"]),
      updatedAt: parseDt(json["updated_at"]),
    );
  }

  String get shortId => id.length <= 8 ? id : id.substring(0, 8).toUpperCase();

  bool get isFreeTicket => (firstTicket?.price ?? 0) <= 0;

  String get locationLabel {
    final parts = [
      venueName,
      city,
      country,
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? "—" : parts.join(" · ");
  }

  String ticketLabel(String lang) {
    final ticket = firstTicket;
    if (ticket == null) return t(lang, "my_events.submissions_ticket_none");
    final category = ticket.categoryLabel(lang);
    if (ticket.price == null || ticket.price! <= 0) {
      return "$category · ${t(lang, "events.free")}";
    }
    return "$category · Rwf ${_formatPrice(ticket.price!)}";
  }

  String dateRangeLabel(String lang) {
    final start = startAt;
    final end = endAt;
    if (start == null && end == null) {
      return t(lang, "my_events.submissions_no_dates");
    }
    if (start != null && end != null) {
      final sameDay =
          start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;
      if (sameDay) {
        return "${_formatShortDate(start)} · ${_formatTime(start)}-${_formatTime(end)}";
      }
      return "${_formatShortDate(start)} → ${_formatShortDate(end)}";
    }
    final fallback = start ?? end!;
    return _formatShortDate(fallback);
  }

  String venueLabel(String lang) {
    if (venueName.trim().isNotEmpty) return venueName.trim();
    return t(lang, "my_events.submissions_no_venue");
  }
}

class _SubmissionTicket {
  final String category;
  final double? price;
  final bool consumable;
  final String consumableDescription;

  const _SubmissionTicket({
    required this.category,
    required this.price,
    required this.consumable,
    required this.consumableDescription,
  });

  factory _SubmissionTicket.fromJson(Map<String, dynamic> json) {
    return _SubmissionTicket(
      category: (json["category"] ?? "").toString(),
      price: (json["price"] as num?)?.toDouble(),
      consumable: json["consumable"] == true,
      consumableDescription: (json["consumable_description"] ?? "").toString(),
    );
  }

  String categoryLabel(String lang) {
    switch (category.toUpperCase()) {
      case "FREE":
        return t(lang, "my_events.ticket_free");
      case "REGULAR":
        return t(lang, "my_events.ticket_regular");
      case "VIP":
        return t(lang, "my_events.ticket_vip");
      case "VVIP":
        return t(lang, "my_events.ticket_vvip");
      case "TABLE":
        return t(lang, "my_events.ticket_table");
      default:
        return category.isEmpty
            ? t(lang, "my_events.submissions_ticket_none")
            : category;
    }
  }
}

class _SubmissionStatusInfo {
  final String label;
  final String helperLabel;
  final Color background;
  final Color softBackground;
  final Color borderColor;
  final Color textColor;

  const _SubmissionStatusInfo({
    required this.label,
    required this.helperLabel,
    required this.background,
    required this.softBackground,
    required this.borderColor,
    required this.textColor,
  });
}

_SubmissionStatusInfo _submissionStatusInfo(String lang, String rawStatus) {
  switch (rawStatus.toUpperCase()) {
    case "APPROVED":
      return _SubmissionStatusInfo(
        label: t(lang, "my_events.submissions_approved"),
        helperLabel: t(lang, "my_events.submissions_approved_hint"),
        background: Colors.green.withValues(alpha: 0.52),
        softBackground: Colors.green.withValues(alpha: 0.10),
        borderColor: Colors.green.withValues(alpha: 0.34),
        textColor: Colors.green.shade700,
      );
    case "REJECTED":
      return _SubmissionStatusInfo(
        label: t(lang, "my_events.submissions_rejected"),
        helperLabel: t(lang, "my_events.submissions_rejected_hint"),
        background: Colors.red.withValues(alpha: 0.52),
        softBackground: Colors.red.withValues(alpha: 0.10),
        borderColor: Colors.red.withValues(alpha: 0.34),
        textColor: Colors.red.shade700,
      );
    default:
      return _SubmissionStatusInfo(
        label: t(lang, "my_events.submissions_pending"),
        helperLabel: t(lang, "my_events.submissions_pending_hint"),
        background: Colors.orange.withValues(alpha: 0.50),
        softBackground: Colors.orange.withValues(alpha: 0.10),
        borderColor: Colors.orange.withValues(alpha: 0.34),
        textColor: Colors.orange.shade800,
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
    case "created_at":
    default:
      return t(lang, "my_events.submissions_order_created");
  }
}

String _sortLabel(String lang, String value) {
  return value.toLowerCase() == "asc"
      ? t(lang, "my_events.submissions_sort_asc")
      : t(lang, "my_events.submissions_sort_desc");
}

String _formatShortDate(DateTime? date) {
  if (date == null) return "—";
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
  final month = months[(date.month - 1).clamp(0, 11)];
  return "${date.day.toString().padLeft(2, '0')} $month ${date.year}";
}

String _formatLongDate(DateTime? date) {
  if (date == null) return "—";
  return "${_formatShortDate(date)} · ${_formatTime(date)}";
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, "0");
  final suffix = date.hour >= 12 ? "PM" : "AM";
  return "$hour:$minute $suffix";
}

String _formatPrice(double value) {
  if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
  if (value >= 1000) return "${(value / 1000).toStringAsFixed(0)}k";
  return value.toStringAsFixed(0);
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
