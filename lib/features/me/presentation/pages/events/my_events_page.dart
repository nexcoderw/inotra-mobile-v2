import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/my_event_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_MyEventItem> _events = [];

  Timer? _debounce;
  bool _loading = false;
  bool _hasMore = true;
  bool _showBackToTop = false;
  bool _hydrated = false;
  int _page = 1;
  String _query = "";
  String? _error;

  late AnimationController _entranceCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

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

    if (px >= _scrollCtrl.position.maxScrollExtent - 200 &&
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
        _events.clear();
        _hasMore = false;
        _error = t(_lang, "my_events.session_expired");
      });
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _events.clear();
        _hasMore = false;
        _error = t(_lang, "my_events.session_expired");
      });
      return;
    }

    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _events.clear();
      }
      _error = null;
    });

    final params = <String, String>{
      "page": "$_page",
      "page_size": "10",
      "ordering": "start_at",
      "sort": "asc",
    };
    if (_query.isNotEmpty) params["search"] = _query;

    try {
      final uri = Api.url(
        MyEventEndpoints.list,
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
          _events.clear();
          _hasMore = false;
          _error = t(_lang, "my_events.session_expired");
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
          .map((item) => _MyEventItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final existingIds = _events.map((e) => e.id).toSet();
      final unique = incoming
          .where((e) => !existingIds.contains(e.id))
          .toList();

      if (!mounted) return;
      setState(() {
        _events.addAll(unique);
        _hasMore = incoming.length >= 10;
        if (_hasMore) _page += 1;
        _hydrated = true;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _error = t(_lang, "my_events.timeout");
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
        _error = t(_lang, "my_events.load_failed");
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
          _events.clear();
          _hasMore = false;
          _error = null;
          _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;
    final hPad = isTablet ? 24.0 : 18.0;
    final crossCount = isTablet ? 2 : 1;
    final cardAspect = isTablet ? 0.66 : 0.70;

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
                              t(lang, "nav.my_events"),
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
                                    hintText: t(lang, "my_events.search_hint"),
                                    onChanged: _onSearchChanged,
                                    onClear: _clearSearch,
                                    isDark: isDark,
                                    scheme: scheme,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _ToolbarActionButton(
                                  label: t(lang, "my_events.add_event"),
                                  scheme: scheme,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.myEventAdd,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_loading && _events.isEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                    if (_events.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: cardAspect,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final showLoader = _loading && _events.isNotEmpty;
                              if (index >= _events.length) {
                                return showLoader
                                    ? _EventCardSkeleton(index: index)
                                    : const SizedBox.shrink();
                              }

                              final item = _events[index];
                              return _AnimatedGridItem(
                                index: index,
                                child: _MyEventPosterCard(
                                  item: item,
                                  lang: lang,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.eventDetails,
                                    arguments: item.id,
                                  ),
                                  onEdit: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.myEventEdit,
                                    arguments: {
                                      "eventId": item.id,
                                      "title": item.title,
                                    },
                                  ),
                                  onDelete: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.myEventDelete,
                                    arguments: {
                                      "eventId": item.id,
                                      "title": item.title,
                                    },
                                  ),
                                ),
                              );
                            },
                            childCount:
                                _events.length +
                                ((_loading && _events.isNotEmpty) ? 2 : 0),
                          ),
                        ),
                      ),
                    if (_error != null && _events.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverToBoxAdapter(
                          child: _ErrorPanel(
                            message: _error!,
                            onRetry: () => _fetchPage(reset: false),
                            retryText: t(lang, "common.try_again"),
                            scheme: scheme,
                          ),
                        ),
                      ),
                    if (!_loading && _events.isEmpty && _error != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          lang: lang,
                          scheme: scheme,
                          hasFilter: _query.isNotEmpty,
                          title: t(lang, "my_events.error_title"),
                          description: _error!,
                          actionLabel: t(lang, "common.try_again"),
                          onAction: () => _fetchPage(reset: true),
                        ),
                      ),
                    if (!_loading &&
                        _events.isEmpty &&
                        _error == null &&
                        _hydrated)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          lang: lang,
                          scheme: scheme,
                          hasFilter: _query.isNotEmpty,
                          title: t(lang, "my_events.empty_title"),
                          description: _query.isNotEmpty
                              ? t(lang, "my_events.empty_filtered")
                              : t(lang, "my_events.empty_default"),
                          actionLabel: _query.isNotEmpty
                              ? t(lang, "common.try_again")
                              : null,
                          onAction: _query.isNotEmpty
                              ? () {
                                  _searchCtrl.clear();
                                  _onSearchChanged("");
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
                  heroTag: "my-events-top",
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

class _MyEventPosterCard extends StatefulWidget {
  final _MyEventItem item;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyEventPosterCard({
    required this.item,
    required this.lang,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MyEventPosterCard> createState() => _MyEventPosterCardState();
}

class _MyEventPosterCardState extends State<_MyEventPosterCard>
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
                right: 14,
                child: Row(
                  children: [
                    _PosterActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: t(widget.lang, "my_events.edit_event"),
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 8),
                    _PosterActionButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: t(widget.lang, "my_events.delete_event"),
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _MyEventGlassFooter(
                  title: widget.item.title,
                  dateLabel: widget.item.dateLabel(widget.lang),
                  firstTicketLabel: widget.item.firstTicketLabel(widget.lang),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PosterActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.96),
                ),
              ),
            ),
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
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _ImagePlaceholder(scheme: scheme),
        loadingBuilder: (_, child, evt) =>
            evt == null ? child : _ImagePlaceholder(scheme: scheme),
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

class _MyEventGlassFooter extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String firstTicketLabel;

  const _MyEventGlassFooter({
    required this.title,
    required this.dateLabel,
    required this.firstTicketLabel,
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
                    child: _MetaPill(
                      icon: Icons.event_available_rounded,
                      label: dateLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaPill(
                      icon: Icons.confirmation_number_outlined,
                      label: firstTicketLabel,
                    ),
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
          Expanded(
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
                left: 14,
                right: 14,
                bottom: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.08 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 180,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
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
            ],
          ),
        );
      },
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

class _ToolbarActionButton extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _ToolbarActionButton({
    required this.label,
    required this.scheme,
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
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryText;
  final ColorScheme scheme;

  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.retryText,
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

class _EmptyState extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;
  final bool hasFilter;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.lang,
    required this.scheme,
    required this.hasFilter,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter
                  ? Icons.filter_list_off_rounded
                  : Icons.event_busy_outlined,
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

class _MyEventItem {
  final String id;
  final String title;
  final String? bannerUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final double? minTicketPrice;
  final List<String> ticketCategories;

  const _MyEventItem({
    required this.id,
    required this.title,
    required this.bannerUrl,
    required this.startAt,
    required this.endAt,
    required this.minTicketPrice,
    required this.ticketCategories,
  });

  factory _MyEventItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    final categories =
        (json["ticket_categories"] as List?)
            ?.map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[];

    return _MyEventItem(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? "Event").toString(),
      bannerUrl: (json["banner_url"] as String?)?.trim().isNotEmpty == true
          ? json["banner_url"] as String
          : null,
      startAt: parseDt(json["start_at"]?.toString()),
      endAt: parseDt(json["end_at"]?.toString()),
      minTicketPrice: json["min_ticket_price"] is num
          ? (json["min_ticket_price"] as num).toDouble()
          : double.tryParse("${json["min_ticket_price"] ?? ""}"),
      ticketCategories: categories,
    );
  }

  String dateLabel(String lang) {
    if (startAt == null && endAt == null) {
      return t(lang, "my_events.no_dates");
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

  String firstTicketLabel(String lang) {
    final firstCategory = ticketCategories.isNotEmpty
        ? ticketCategories.first
        : "";
    final price = minTicketPrice;

    if (firstCategory.isEmpty && price == null) {
      return t(lang, "my_events.ticket_none");
    }

    final priceLabel = price == null
        ? ""
        : price <= 0
        ? t(lang, "my_events.ticket_free")
        : "Rwf ${NumberFormat("#,###").format(price)}";

    if (firstCategory.isEmpty) return priceLabel;
    if (priceLabel.isEmpty) return firstCategory;
    return "$firstCategory · $priceLabel";
  }
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}
