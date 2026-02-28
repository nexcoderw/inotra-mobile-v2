import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/page_header.dart";

class TripPackagesPage extends StatefulWidget {
  const TripPackagesPage({super.key});

  @override
  State<TripPackagesPage> createState() => _TripPackagesPageState();
}

class _TripPackagesPageState extends State<TripPackagesPage> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  final List<_Package> _packages = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = "";
  String? _error;
  bool _showBackToTop = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchPage(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async => _fetchPage(reset: true);

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }
    final show = _scrollCtrl.position.pixels > 300;
    if (show != _showBackToTop) {
      setState(() => _showBackToTop = show);
    }
  }

  Future<void> _fetchPage({required bool reset}) async {
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _packages.clear();
      }
      _error = null;
    });

    try {
      final uri = Api.url(
        "${PackageEndpoints.list}?page=$_page&page_size=10${_query.isNotEmpty ? "&search=$_query" : ""}",
      );
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final results = (decoded is Map ? decoded["results"] : decoded) as List? ?? [];
        final items =
            results.whereType<Map<String, dynamic>>().map(_Package.fromJson).toList();
        setState(() {
          final existing = _packages.map((e) => e.id).toSet();
          final unique = items.where((e) => !existing.contains(e.id)).toList();
          _packages.addAll(unique);
          _hasMore = items.length >= 10;
          if (_hasMore) _page += 1;
        });
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String v) {
    setState(() {}); // refresh clear icon visibility
    _query = v.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_query.isEmpty) {
        _fetchPage(reset: true);
        return;
      }
      if (_query.length < 3) {
        setState(() {
          _packages.clear();
          _hasMore = false;
          _error = null;
          _loading = false;
        });
        return;
      }
      _fetchPage(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: PageHeader(
                        title: t(lang, "packages.title"),
                        onBack: () => Navigator.maybePop(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: t(lang, "packages.search_hint"),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 10, right: 6),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSearch01,
                              size: 16,
                              strokeWidth: 2,
                            ),
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _onSearchChanged("");
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: scheme.surfaceVariant.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: "DM Sans",
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: const SizedBox(height: 8),
                  ),
                  if (_loading && _packages.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: _PackageSkeleton(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _packages.length) {
                          return const SizedBox.shrink();
                        }
                        final p = _packages[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: _PackageCard(
                            pkg: p,
                            lang: lang,
                            scheme: scheme,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.tripPackageDetails,
                              arguments: p.id,
                            ),
                          ),
                        );
                      },
                      childCount: _packages.length + (_loading ? 1 : 0),
                    ),
                  ),
                  if (_error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              t(lang, "packages.error"),
                              style: TextStyle(
                                color: scheme.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(onPressed: () => _fetchPage(reset: true), child: Text(t(lang, "common.try_again"))),
                          ],
                        ),
                      ),
                    ),
                  if (!_loading && _packages.isEmpty && _error == null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            t(lang, "packages.empty"),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            ),
            if (_showBackToTop)
              Positioned(
                right: 16,
                bottom: 18,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: () => _scrollCtrl.animateTo(
                    0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Package {
  final String id;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final int durationDays;

  _Package({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.durationDays,
  });

  static _Package fromJson(Map<String, dynamic> json) {
    return _Package(
      id: json["id"]?.toString() ?? "",
      title: json["title"] as String? ?? json["name"] as String?,
      subtitle: json["location"] as String? ?? json["description"] as String?,
      imageUrl: (json["cover_url"] ?? json["image"] ?? json["cover_image"]) as String?,
      durationDays: (json["duration_days"] as num?)?.toInt() ?? 0,
    );
  }
}

class _PackageCard extends StatelessWidget {
  final _Package pkg;
  final String lang;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _PackageCard({
    required this.pkg,
    required this.lang,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final radius = BorderRadius.circular(isTablet ? 26 : 22);
    final title = (pkg.title?.trim().isNotEmpty ?? false)
        ? pkg.title!.trim()
        : t(lang, "packages.title");
    final subtitle = (pkg.subtitle?.trim().isNotEmpty ?? false) ? pkg.subtitle!.trim() : "";

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: isTablet ? 230 : 210,
          child: Stack(
            children: [
              // Base surface (fallback when no image).
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.surface,
                      scheme.surface.withOpacity(0.82),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),

              // Hero image.
              if (pkg.imageUrl != null)
                Positioned.fill(
                  child: Image.network(
                    pkg.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: scheme.surfaceVariant.withOpacity(0.7)),
                    loadingBuilder: (context, child, evt) {
                      if (evt == null) return child;
                      return Container(color: scheme.surfaceVariant.withOpacity(0.7));
                    },
                  ),
                )
              else
                Positioned.fill(
                  child: Container(color: scheme.surfaceVariant.withOpacity(0.7)),
                ),

              // Soft bottom gradient only.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.40),
                        Colors.black.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _GlassFooter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.05,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 12.5 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.86),
                            height: 1.15,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: "${pkg.durationDays} ${t(lang, "packages.days")}",
                          ),
                          const Spacer(),
                          _MiniCTA(),
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

class _GlassFooter extends StatelessWidget {
  final Widget child;
  const _GlassFooter({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: Colors.white.withOpacity(0.95),
      ),
    );
  }
}

class _PackageSkeleton extends StatelessWidget {
  const _PackageSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final radius = BorderRadius.circular(isTablet ? 26 : 22);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: isTablet ? 230 : 210,
        child: Stack(
          children: [
            Container(
              color: scheme.surfaceVariant.withOpacity(0.55),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 10,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.18),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
