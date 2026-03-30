import "dart:convert";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/app_colors.dart";
import "../../../../core/constants/api/my_event_endpoints.dart";
import "../../../../core/constants/api/my_listing_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../widgets/dashboard/dashboard_activity_chart.dart";
import "../widgets/dashboard/dashboard_date_filter.dart";
import "../widgets/dashboard/dashboard_events_section.dart";
import "../widgets/dashboard/dashboard_listings_section.dart";
import "../widgets/dashboard/dashboard_quick_actions.dart";
import "../widgets/dashboard/dashboard_recent_bookings.dart";
import "../widgets/dashboard/dashboard_revenue_card.dart";
import "../widgets/dashboard/dashboard_stat_card.dart";

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ── Date filter ──────────────────────────────────────────────────────────
  DashboardPeriod _period = DashboardPeriod.days30;
  late DateTimeRange _range;

  // ── Remote counts ────────────────────────────────────────────────────────
  bool _statsLoading = true;
  int? _listingCount;
  int? _eventCount;
  int? _bookingCount;
  int? _reviewCount;
  int? _listingSubCount;
  int? _eventSubCount;

  // ── Recent bookings ───────────────────────────────────────────────────────
  bool _bookingsLoading = true;
  List<BookingItem> _recentBookings = [];

  // ── Sample chart data (regenerated when range changes) ────────────────────
  List<double> _listingsChartData = [];
  List<double> _bookingsChartData = [];

  @override
  void initState() {
    super.initState();
    _range = DashboardPeriod.days30.defaultRange()!;
    _regenerateChartData();
    _loadAll();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _statsLoading = true;
      _bookingsLoading = true;
    });

    await Future.wait([
      _fetchCount(MyListingEndpoints.list, (c) => _listingCount = c),
      _fetchCount(MyEventEndpoints.list, (c) => _eventCount = c),
      _fetchCount(MyListingEndpoints.bookings, (c) => _bookingCount = c),
      _fetchCount(MyListingEndpoints.reviews, (c) => _reviewCount = c),
      _fetchCount(MyListingEndpoints.submissions, (c) => _listingSubCount = c),
      _fetchCount(MyEventEndpoints.submissions, (c) => _eventSubCount = c),
      _fetchRecentBookings(),
    ]);

    if (mounted) setState(() => _statsLoading = false);
  }

  Future<void> _fetchCount(
      String endpoint, void Function(int) onResult) async {
    try {
      final token = AuthSession.instance.value.accessToken;
      if (token == null) return;
      final resp = await http.get(
        Api.url(endpoint).replace(queryParameters: {"page_size": "1"}),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data["count"] is int) {
          if (mounted) setState(() => onResult(data["count"] as int));
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchRecentBookings() async {
    try {
      final token = AuthSession.instance.value.accessToken;
      if (token == null) return;
      final resp = await http.get(
        Api.url(MyListingEndpoints.bookings)
            .replace(queryParameters: {"page_size": "5", "page": "1"}),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List raw = [];
        if (data is Map && data["results"] is List) {
          raw = data["results"] as List;
        } else if (data is List) {
          raw = data;
        }
        if (mounted) {
          setState(() {
            _recentBookings = raw
                .whereType<Map>()
                .map((m) =>
                    BookingItem.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            _bookingsLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _bookingsLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _bookingsLoading = false);
    }
  }

  // ── Chart data ────────────────────────────────────────────────────────────

  void _regenerateChartData() {
    final days = _range.duration.inDays + 1;
    final seed = _range.start.millisecondsSinceEpoch ~/ 1000000;
    final rng1 = math.Random(seed + 1);
    final rng2 = math.Random(seed + 2);

    double v1 = 20 + rng1.nextDouble() * 30;
    double v2 = 8 + rng2.nextDouble() * 15;

    _listingsChartData = List.generate(days, (_) {
      v1 = (v1 + rng1.nextDouble() * 18 - 9).clamp(2.0, 100.0);
      return v1;
    });
    _bookingsChartData = List.generate(days, (_) {
      v2 = (v2 + rng2.nextDouble() * 10 - 5).clamp(0.0, 50.0);
      return v2;
    });
  }

  void _onRangeChanged(DateTimeRange r) {
    setState(() {
      _range = r;
      _regenerateChartData();
    });
  }

  void _onPeriodChanged(DashboardPeriod p) {
    setState(() => _period = p);
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _go(String route) => Navigator.pushNamed(context, route);

  // ── Spark data (sample, stable per stat) ──────────────────────────────────

  List<double> _spark(int seed) {
    final rng = math.Random(seed);
    double v = 10 + rng.nextDouble() * 20;
    return List.generate(7, (_) {
      v = (v + rng.nextDouble() * 10 - 5).clamp(1.0, 60.0);
      return v;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  String _displayName() {
    final name = AuthSession.instance.value.displayName ?? "";
    final first = name.split(" ").first;
    return first.isNotEmpty ? first : "there";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: scheme.surface,
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Greeting header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(scheme),
          ),

          // ── Date filter ─────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: DashboardDateFilter(
              selected: _period,
              range: _range,
              onPeriodChanged: _onPeriodChanged,
              onRangeChanged: _onRangeChanged,
            ),
          ),

          // ── Stat cards ───────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _buildStatsRow()),

          // ── Activity chart ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: DashboardActivityChart(
                range: _range,
                listingsData: _listingsChartData,
                bookingsData: _bookingsChartData,
              ),
            ),
          ),

          // ── Listings section ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: DashboardListingsSection(
                listingCount: _listingCount,
                bookingCount: _bookingCount,
                submissionCount: _listingSubCount,
                isLoading: _statsLoading,
                onViewAll: () => _go(AppRoutes.myListings),
              ),
            ),
          ),

          // ── Events section ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: DashboardEventsSection(
                eventCount: _eventCount,
                submissionCount: _eventSubCount,
                isLoading: _statsLoading,
                onViewAll: () => _go(AppRoutes.myEvents),
              ),
            ),
          ),

          // ── Revenue card (static) ────────────────────────────────────────
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(child: DashboardRevenueCard()),
          ),

          // ── Recent bookings ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: DashboardRecentBookings(
                bookings: _recentBookings,
                isLoading: _bookingsLoading,
                onViewAll: () => _go(AppRoutes.listingBooking),
              ),
            ),
          ),

          // ── Quick actions ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: DashboardQuickActions(
                onAddListing: () => _go(AppRoutes.myListings),
                onAddEvent: () => _go(AppRoutes.myEvents),
                onViewBookings: () => _go(AppRoutes.listingBooking),
                onViewTickets: () => _go(AppRoutes.eventTickets),
                onViewReviews: () => _go(AppRoutes.listingReviews),
                onViewReservations: () => _go(AppRoutes.tripReservations),
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Greeting header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final days = _range.duration.inDays + 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F2A1C),
                  const Color(0xFF081810),
                ]
              : [
                  AppColors.primary,
                  const Color(0xFF0A3D20),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_greeting()}, ${_displayName()} 👋",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your overview for the last $days days.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              // Summary chips row
              Row(children: [
                _HeaderChip(
                  label: "${_listingCount ?? "—"} Listings",
                  isLoading: _statsLoading,
                ),
                const SizedBox(width: 8),
                _HeaderChip(
                  label: "${_eventCount ?? "—"} Events",
                  isLoading: _statsLoading,
                ),
                const SizedBox(width: 8),
                _HeaderChip(
                  label: "${_bookingCount ?? "—"} Bookings",
                  isLoading: _statsLoading,
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stats row
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          DashboardStatCard(
            label: "Listings",
            value: _statsLoading ? "—" : "${_listingCount ?? 0}",
            icon: HugeIcons.strokeRoundedHome05,
            accentColor: AppColors.primary,
            trend: "active",
            isUp: true,
            sparkData: _spark(1),
            isLoading: _statsLoading,
          ),
          const SizedBox(width: 12),
          DashboardStatCard(
            label: "Events",
            value: _statsLoading ? "—" : "${_eventCount ?? 0}",
            icon: HugeIcons.strokeRoundedFireworks,
            accentColor: const Color(0xFFF59E0B),
            trend: "total",
            isUp: true,
            sparkData: _spark(2),
            isLoading: _statsLoading,
          ),
          const SizedBox(width: 12),
          DashboardStatCard(
            label: "Bookings",
            value: _statsLoading ? "—" : "${_bookingCount ?? 0}",
            icon: HugeIcons.strokeRoundedCalendar03,
            accentColor: const Color(0xFF0EA5E9),
            trend: "period",
            isUp: true,
            sparkData: _spark(3),
            isLoading: _statsLoading,
          ),
          const SizedBox(width: 12),
          DashboardStatCard(
            label: "Reviews",
            value: _statsLoading ? "—" : "${_reviewCount ?? 0}",
            icon: HugeIcons.strokeRoundedStar,
            accentColor: const Color(0xFFEC4899),
            sparkData: _spark(4),
            isLoading: _statsLoading,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header chips
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  final String label;
  final bool isLoading;

  const _HeaderChip({required this.label, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        isLoading ? "…" : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: isLoading ? 0.4 : 0.85),
        ),
      ),
    );
  }
}

