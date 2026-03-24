import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:toastification/toastification.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/my_listing_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "my_listing_submission_detail_page.dart";

class MyListingSubmissionsPage extends StatefulWidget {
  const MyListingSubmissionsPage({super.key});

  @override
  State<MyListingSubmissionsPage> createState() =>
      _MyListingSubmissionsPageState();
}

class _MyListingSubmissionsPageState extends State<MyListingSubmissionsPage>
    with TickerProviderStateMixin {
  static const int _pageSize = 10;
  static const List<_SubmissionStatusFilter> _statusFilters = [
    _SubmissionStatusFilter(labelKey: "common.all", value: null),
    _SubmissionStatusFilter(
      labelKey: "my_listing_submissions.status_pending",
      value: "PENDING",
    ),
    _SubmissionStatusFilter(
      labelKey: "my_listing_submissions.status_approved",
      value: "APPROVED",
    ),
    _SubmissionStatusFilter(
      labelKey: "my_listing_submissions.status_rejected",
      value: "REJECTED",
    ),
  ];

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final List<_ListingSubmission> _items = [];
  final Set<String> _deletingIds = <String>{};

  Timer? _debounce;
  bool _loading = false;
  bool _hasMore = true;
  bool _hydrated = false;
  bool _showBackToTop = false;
  int _page = 1;
  String _query = "";
  String? _selectedStatus;
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
      duration: const Duration(milliseconds: 600),
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
    if (!_scrollCtrl.hasClients) return;

    final px = _scrollCtrl.position.pixels;
    if (px >= _scrollCtrl.position.maxScrollExtent - 240 &&
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
        _hasMore = false;
        if (reset) _items.clear();
        _error = t(_lang, "my_listing_submissions.session_expired");
      });
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _hasMore = false;
        if (reset) _items.clear();
        _error = t(_lang, "my_listing_submissions.session_expired");
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
    };
    if (_query.isNotEmpty) params["search"] = _query;
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      params["status"] = _selectedStatus!;
    }

    try {
      final uri = Api.url(
        MyListingEndpoints.submissions,
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
          _hasMore = false;
          if (reset) _items.clear();
          _error = t(_lang, "my_listing_submissions.session_expired");
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
      int? count;
      if (decoded is Map) {
        count = (decoded["count"] as num?)?.toInt();
        results = (decoded["results"] ?? const []) as List? ?? const [];
      } else if (decoded is List) {
        results = decoded;
      }

      final incoming = results
          .whereType<Map>()
          .map(
            (item) =>
                _ListingSubmission.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      final existingIds = _items.map((item) => item.id).toSet();
      final unique = incoming.where((item) => !existingIds.contains(item.id));

      if (!mounted) return;
      setState(() {
        _items.addAll(unique);
        final hasMoreByLength = incoming.length >= _pageSize;
        _hasMore = hasMoreByLength;
        if (_hasMore) _page += 1;
        if (count != null && _items.length >= count) _hasMore = false;
        _hydrated = true;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _error = t(_lang, "my_listing_submissions.timeout");
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
        _error = t(_lang, "my_listing_submissions.load_failed");
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
      if (_query.isEmpty) {
        _fetchPage(reset: true);
        return;
      }
      if (_query.length < 3) {
        if (!mounted) return;
        setState(() {
          _items.clear();
          _hasMore = false;
          _loading = false;
          _error = null;
          _hydrated = true;
        });
        return;
      }
      _fetchPage(reset: true);
    });
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchCtrl.clear();
    _onSearchChanged("");
  }

  void _onStatusChanged(String? value) {
    HapticFeedback.selectionClick();
    if (value == _selectedStatus) return;
    setState(() => _selectedStatus = value);
    _fetchPage(reset: true);
  }

  bool _canDeleteSubmission(_ListingSubmission submission) {
    return submission.status.toUpperCase() != "APPROVED";
  }

  Future<void> _confirmDeleteSubmission(_ListingSubmission submission) async {
    if (_deletingIds.contains(submission.id) ||
        !_canDeleteSubmission(submission)) {
      return;
    }

    final lang = _lang;
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.error.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: scheme.error.withValues(alpha: 0.12),
                      border: Border.all(
                        color: scheme.error.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t(lang, "my_listing_submissions.delete_title"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(lang, "my_listing_submissions.delete_message"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.name.trim().isEmpty
                              ? t(lang, "my_listing_submissions.fallback_title")
                              : submission.name.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _compactLocation(submission.city, submission.country),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.56),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogGhostButton(
                          label: t(lang, "common.cancel"),
                          onTap: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DialogDangerButton(
                          label: t(
                            lang,
                            "my_listing_submissions.delete_action",
                          ),
                          tone: scheme.error,
                          onTap: () => Navigator.of(context).pop(true),
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
    );

    if (confirmed == true) {
      await _deleteSubmission(submission);
    }
  }

  Future<void> _deleteSubmission(_ListingSubmission submission) async {
    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      if (!mounted) return;
      setState(
        () => _error = t(_lang, "my_listing_submissions.session_expired"),
      );
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(
        () => _error = t(_lang, "my_listing_submissions.session_expired"),
      );
      return;
    }

    setState(() => _deletingIds.add(submission.id));

    try {
      final uri = Api.url(MyListingEndpoints.submissionDelete(submission.id));
      final response = await http
          .delete(
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
          _deletingIds.remove(submission.id);
          _error = t(_lang, "my_listing_submissions.session_expired");
        });
        return;
      }

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _ApiException(
          _extractMessage(decoded) ??
              t(_lang, "my_listing_submissions.delete_failed"),
        );
      }

      if (!mounted) return;
      setState(() {
        _deletingIds.remove(submission.id);
        _items.removeWhere((item) => item.id == submission.id);
      });

      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        title: Text(t(_lang, "my_listing_submissions.delete_success")),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 2),
      );

      if (_items.isEmpty && _hasMore) {
        _fetchPage(reset: false);
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _deletingIds.remove(submission.id));
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(t(_lang, "my_listing_submissions.timeout")),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
    } on _ApiException catch (error) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(submission.id));
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(error.message),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(submission.id));
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(t(_lang, "my_listing_submissions.delete_failed")),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final hPad = isTablet ? 24.0 : 16.0;

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
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ListingSubmissionsHeaderDelegate(
                        isTablet: isTablet,
                        isDark: isDark,
                        scheme: scheme,
                        lang: lang,
                        searchCtrl: _searchCtrl,
                        onSearchChanged: _onSearchChanged,
                        onClear: _clearSearch,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SubmissionStatusRailDelegate(
                        statuses: _statusFilters,
                        selectedStatus: _selectedStatus,
                        onSelect: _onStatusChanged,
                        isTablet: isTablet,
                        isDark: isDark,
                        scheme: scheme,
                        lang: lang,
                      ),
                    ),
                    if (_loading && _items.isEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ListingSubmissionCardSkeleton(
                                index: index,
                              ),
                            ),
                            childCount: 4,
                          ),
                        ),
                      ),
                    if (_items.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final showLoader = _loading && _items.isNotEmpty;
                              if (index >= _items.length) {
                                return showLoader
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: _ListingSubmissionCardSkeleton(
                                          index: index,
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }

                              final submission = _items[index];
                              return _AnimatedListItem(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _ListingSubmissionCard(
                                    submission: submission,
                                    isTablet: isTablet,
                                    lang: lang,
                                    isDeleting: _deletingIds.contains(
                                      submission.id,
                                    ),
                                    onOpen: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.myListingSubmissionDetail,
                                      arguments: MyListingSubmissionDetailArgs(
                                        submissionId: submission.id,
                                        title: submission.name,
                                      ),
                                    ),
                                    onDelete: _canDeleteSubmission(submission)
                                        ? () => _confirmDeleteSubmission(
                                            submission,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                            childCount:
                                _items.length +
                                ((_loading && _items.isNotEmpty) ? 1 : 0),
                          ),
                        ),
                      ),
                    if (_error != null && _items.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.all(hPad),
                        sliver: SliverToBoxAdapter(
                          child: _ErrorPanel(
                            message: _error!,
                            onRetry: () => _fetchPage(reset: true),
                            retryText: t(lang, "common.try_again"),
                          ),
                        ),
                      ),
                    if (!_loading && _items.isEmpty && _error != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ListingSubmissionsStateView(
                          icon: Icons.cloud_off_rounded,
                          title: t(lang, "my_listing_submissions.error_title"),
                          description: _error!,
                          actionLabel: t(lang, "common.try_again"),
                          onAction: () => _fetchPage(reset: true),
                        ),
                      ),
                    if (!_loading &&
                        _items.isEmpty &&
                        _error == null &&
                        _hydrated)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ListingSubmissionsStateView(
                          icon: Icons.storefront_outlined,
                          title: t(lang, "my_listing_submissions.empty_title"),
                          description:
                              _query.isNotEmpty || _selectedStatus != null
                              ? t(lang, "my_listing_submissions.empty_filtered")
                              : t(lang, "my_listing_submissions.empty_default"),
                          actionLabel:
                              (_query.isNotEmpty || _selectedStatus != null)
                              ? t(lang, "my_listing_submissions.reset")
                              : null,
                          onAction:
                              (_query.isNotEmpty || _selectedStatus != null)
                              ? () {
                                  setState(() {
                                    _selectedStatus = null;
                                    _query = "";
                                    _searchCtrl.clear();
                                  });
                                  _fetchPage(reset: true);
                                }
                              : null,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: 18,
                bottom: _showBackToTop ? 24 : -72,
                child: _BackToTopButton(
                  onTap: () => _scrollCtrl.animateTo(
                    0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingSubmissionsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isTablet;
  final bool isDark;
  final ColorScheme scheme;
  final String lang;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _ListingSubmissionsHeaderDelegate({
    required this.isTablet,
    required this.isDark,
    required this.scheme,
    required this.lang,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  double get minExtent => 68.0;

  @override
  double get maxExtent => 132.0;

  @override
  bool shouldRebuild(_ListingSubmissionsHeaderDelegate oldDelegate) =>
      isTablet != oldDelegate.isTablet ||
      isDark != oldDelegate.isDark ||
      lang != oldDelegate.lang ||
      searchCtrl.text != oldDelegate.searchCtrl.text;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final shrinkT = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 1.0;
    final hPad = isTablet ? 24.0 : 16.0;

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: scheme.surface.withValues(alpha: isDark ? 0.85 : 0.92),
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: (28.0 * (1.0 - shrinkT)).clamp(0.0, 28.0),
                  child: AnimatedOpacity(
                    opacity: (1.0 - shrinkT * 1.6).clamp(0.0, 1.0),
                    duration: Duration.zero,
                    child: Transform.translate(
                      offset: Offset(0, -shrinkT * 14),
                      child: Text(
                        t(lang, "nav.my_listing_submissions"),
                        style: TextStyle(
                          fontSize: (28 - shrinkT * 6).clamp(22.0, 28.0),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.0,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (10.0 * (1.0 - shrinkT)).clamp(0.0, 10.0)),
                _PremiumSearchBar(
                  controller: searchCtrl,
                  hintText: t(lang, "my_listing_submissions.search_hint"),
                  onChanged: onSearchChanged,
                  onClear: onClear,
                  isDark: isDark,
                  scheme: scheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionStatusRailDelegate extends SliverPersistentHeaderDelegate {
  final List<_SubmissionStatusFilter> statuses;
  final String? selectedStatus;
  final ValueChanged<String?> onSelect;
  final bool isTablet;
  final bool isDark;
  final ColorScheme scheme;
  final String lang;

  const _SubmissionStatusRailDelegate({
    required this.statuses,
    required this.selectedStatus,
    required this.onSelect,
    required this.isTablet,
    required this.isDark,
    required this.scheme,
    required this.lang,
  });

  @override
  double get minExtent => 54.0;

  @override
  double get maxExtent => 54.0;

  @override
  bool shouldRebuild(_SubmissionStatusRailDelegate oldDelegate) =>
      selectedStatus != oldDelegate.selectedStatus ||
      statuses.length != oldDelegate.statuses.length ||
      lang != oldDelegate.lang;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final hPad = isTablet ? 24.0 : 16.0;

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: scheme.surface.withValues(alpha: isDark ? 0.82 : 0.90),
            padding: EdgeInsets.only(left: hPad, right: hPad, bottom: 8),
            child: ScrollConfiguration(
              behavior: _NoGlowBehavior(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(statuses.length, (index) {
                    final status = statuses[index];
                    final selected = selectedStatus == status.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < statuses.length - 1 ? 8 : 0,
                      ),
                      child: _FilterPill(
                        label: t(lang, status.labelKey),
                        selected: selected,
                        isDark: isDark,
                        scheme: scheme,
                        onTap: () => onSelect(status.value),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 280));
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

class _FilterPill extends StatefulWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.scheme,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.scheme.primary
                : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.055)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.selected
                  ? widget.scheme.primary
                  : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.08)),
              width: 1.2,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: widget.selected
                  ? Colors.white
                  : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.70)
                        : Colors.black.withValues(alpha: 0.60)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingSubmissionCard extends StatelessWidget {
  final _ListingSubmission submission;
  final bool isTablet;
  final String lang;
  final bool isDeleting;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  const _ListingSubmissionCard({
    required this.submission,
    required this.isTablet,
    required this.lang,
    required this.isDeleting,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(isTablet ? 28 : 24);
    final height = isTablet ? 260.0 : 242.0;
    final title = submission.name.trim().isEmpty
        ? t(lang, "my_listing_submissions.fallback_title")
        : submission.name.trim();
    final location = _compactLocation(submission.city, submission.country);
    final category = submission.categoryName.trim();

    return GestureDetector(
      onTap: onOpen,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: _CardImage(
                  url: submission.firstImageUrl,
                  scheme: scheme,
                ),
              ),
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
                        Colors.black.withValues(alpha: 0.72),
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
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(child: _SpecularHighlight(radius: radius)),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.10 : 0.14,
                      ),
                    ),
                  ),
                ),
              ),
              if (category.isNotEmpty)
                Positioned(
                  top: 14,
                  left: 14,
                  child: _GlassBadge(label: category),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SubmissionStatusBadge(
                      status: submission.status,
                      lang: lang,
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      _SubmissionDeleteButton(
                        busy: isDeleting,
                        onTap: onDelete!,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _GlassFooter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isTablet ? 16.5 : 15,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: Icons.photo_library_outlined,
                            label:
                                "${submission.imagesCount} ${t(lang, "my_listing_submissions.images_short")}",
                          ),
                          _InfoPill(
                            icon: Icons.room_service_outlined,
                            label:
                                "${submission.servicesCount} ${t(lang, "my_listing_submissions.services_short")}",
                          ),
                          _InfoPill(
                            icon: Icons.schedule_rounded,
                            label: _formatDate(
                              submission.updatedAt ?? submission.createdAt,
                            ),
                          ),
                          if (submission.hasReviewerNotes)
                            _InfoPill(
                              icon: Icons.sticky_note_2_outlined,
                              label: t(
                                lang,
                                "my_listing_submissions.note_available",
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? url;
  final ColorScheme scheme;

  const _CardImage({required this.url, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Placeholder(scheme: scheme),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _Placeholder(scheme: scheme);
        },
      );
    }
    return _Placeholder(scheme: scheme);
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme scheme;

  const _Placeholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.8),
            scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final String label;

  const _GlassBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionStatusBadge extends StatelessWidget {
  final String status;
  final String lang;

  const _SubmissionStatusBadge({required this.status, required this.lang});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: style.border),
          ),
          child: Text(
            _statusLabel(lang, status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: style.foreground,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionDeleteButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const _SubmissionDeleteButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.error.withValues(alpha: 0.88),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              boxShadow: [
                BoxShadow(
                  color: scheme.error.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.96),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassFooter extends StatelessWidget {
  final Widget child;

  const _GlassFooter({required this.child});

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
          child: child,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

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
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _DialogGhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogDangerButton extends StatelessWidget {
  final String label;
  final Color tone;
  final VoidCallback? onTap;

  const _DialogDangerButton({
    required this.label,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackToTopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ListingSubmissionCardSkeleton extends StatefulWidget {
  final int index;

  const _ListingSubmissionCardSkeleton({required this.index});

  @override
  State<_ListingSubmissionCardSkeleton> createState() =>
      _ListingSubmissionCardSkeletonState();
}

class _ListingSubmissionCardSkeletonState
    extends State<_ListingSubmissionCardSkeleton>
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
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final radius = BorderRadius.circular(isTablet ? 28 : 24);
    final height = isTablet ? 260.0 : 242.0;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final value = _shimmer.value;
        return ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.5 + value * 3, 0),
                        end: Alignment(-0.5 + value * 3, 0),
                        colors: [
                          scheme.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
                          scheme.surfaceContainerHighest.withValues(
                            alpha: 0.78,
                          ),
                          scheme.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.16),
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
                        color: scheme.onSurface.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 14,
                  left: 14,
                  child: _SkeletonPill(width: 96, height: 30),
                ),
                const Positioned(
                  top: 12,
                  right: 12,
                  child: _SkeletonPill(width: 92, height: 30),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            _SkeletonLine(width: 210, height: 14),
                            SizedBox(height: 8),
                            _SkeletonLine(width: 150, height: 11),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _SkeletonPill(width: 88, height: 26),
                                _SkeletonPill(width: 96, height: 26),
                                _SkeletonPill(width: 110, height: 26),
                              ],
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

class _SpecularHighlight extends StatelessWidget {
  final BorderRadius radius;

  const _SpecularHighlight({required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -30,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 200,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 17,
            color: scheme.onSurface.withValues(alpha: 0.42),
          ),
          const SizedBox(width: 8),
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
                  color: scheme.onSurface.withValues(alpha: 0.36),
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
                    color: scheme.onSurface.withValues(alpha: 0.14),
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

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryText;

  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.errorContainer.withValues(alpha: 0.3),
        border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
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
              retryText,
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

class _ListingSubmissionsStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ListingSubmissionsStateView({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              ),
              child: Icon(
                icon,
                size: 34,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
              ),
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
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SkeletonPill extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonPill({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _ListingSubmission {
  final String id;
  final String name;
  final String categoryName;
  final String city;
  final String country;
  final String status;
  final String? reviewerNotes;
  final int imagesCount;
  final int servicesCount;
  final String? firstImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const _ListingSubmission({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.city,
    required this.country,
    required this.status,
    required this.reviewerNotes,
    required this.imagesCount,
    required this.servicesCount,
    required this.firstImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasReviewerNotes =>
      reviewerNotes != null && reviewerNotes!.trim().isNotEmpty;

  factory _ListingSubmission.fromJson(Map<String, dynamic> json) {
    return _ListingSubmission(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      categoryName: (json["category_name"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      status: (json["status"] ?? "").toString(),
      reviewerNotes: _stringOrNull(json["reviewer_notes"]),
      imagesCount: _toIntOrZero(json["images_count"]),
      servicesCount: _toIntOrZero(json["services_count"]),
      firstImageUrl: _stringOrNull(json["first_image_url"]),
      createdAt: _parseDate(json["created_at"]),
      updatedAt: _parseDate(json["updated_at"]),
    );
  }
}

class _SubmissionStatusFilter {
  final String labelKey;
  final String? value;

  const _SubmissionStatusFilter({required this.labelKey, required this.value});
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}

class _SubmissionStatusStyle {
  final Color background;
  final Color border;
  final Color foreground;

  const _SubmissionStatusStyle({
    required this.background,
    required this.border,
    required this.foreground,
  });
}

_SubmissionStatusStyle _statusStyle(String rawStatus) {
  switch (rawStatus.toUpperCase()) {
    case "APPROVED":
      return _SubmissionStatusStyle(
        background: const Color(0xCC0F7B57),
        border: const Color(0x9934D399),
        foreground: Colors.white,
      );
    case "REJECTED":
      return _SubmissionStatusStyle(
        background: const Color(0xCC9F1239),
        border: const Color(0x99FB7185),
        foreground: Colors.white,
      );
    default:
      return _SubmissionStatusStyle(
        background: const Color(0xCC8A4B0F),
        border: const Color(0x99FBBF24),
        foreground: Colors.white,
      );
  }
}

String _statusLabel(String lang, String rawStatus) {
  switch (rawStatus.toUpperCase()) {
    case "APPROVED":
      return t(lang, "my_listing_submissions.status_approved");
    case "REJECTED":
      return t(lang, "my_listing_submissions.status_rejected");
    default:
      return t(lang, "my_listing_submissions.status_pending");
  }
}

String _compactLocation(String city, String country) {
  final parts = [city.trim(), country.trim()].where((part) => part.isNotEmpty);
  return parts.join(", ");
}

String _formatDate(DateTime? value) {
  if (value == null) return "—";
  return DateFormat("dd MMM yyyy").format(value.toLocal());
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _toIntOrZero(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? "") ?? 0;
}
