import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/constants/api/my_listing_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../core/utils/rwf_currency.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../widgets/my_listings/bookings/my_listing_booking_header.dart";
import "../../widgets/my_listings/bookings/my_listing_booking_list_section.dart";
import "../../widgets/my_listings/bookings/my_listing_booking_metrics_row.dart";
import "../../widgets/my_listings/bookings/my_listing_bookings_models.dart";

class MyListingBookingPage extends StatefulWidget {
  const MyListingBookingPage({super.key});

  @override
  State<MyListingBookingPage> createState() => _MyListingBookingPageState();
}

class _MyListingBookingPageState extends State<MyListingBookingPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MyListingBookingPreview> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final lang = currentLangSync();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = AuthSession.instance.value.accessToken;
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _bookings = const [];
          _isLoading = false;
          _errorMessage = t(lang, "my_listings.bookings.error_subtitle");
        });
        return;
      }

      final response = await http
          .get(
            Api.url(
              MyListingEndpoints.bookings,
            ).replace(queryParameters: {"page_size": "40", "page": "1"}),
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _bookings = const [];
          _isLoading = false;
          _errorMessage = t(lang, "my_listings.bookings.error_subtitle");
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      List raw = const [];
      if (decoded is Map && decoded["results"] is List) {
        raw = decoded["results"] as List;
      } else if (decoded is List) {
        raw = decoded;
      }

      final bookings =
          raw
              .whereType<Map>()
              .map(
                (item) => MyListingBookingPreview.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
            ..sort(_sortBookings);

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookings = const [];
        _isLoading = false;
        _errorMessage = t(lang, "my_listings.bookings.error_subtitle");
      });
    }
  }

  int _sortBookings(MyListingBookingPreview a, MyListingBookingPreview b) {
    if (a.isUpcoming != b.isUpcoming) {
      return a.isUpcoming ? -1 : 1;
    }

    final aDate = a.checkIn ?? a.bookedOn ?? DateTime(2000);
    final bDate = b.checkIn ?? b.bookedOn ?? DateTime(2000);

    return a.isUpcoming ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final hasBookings = _bookings.isNotEmpty;

    final upcomingCount = _bookings
        .where((booking) => booking.isUpcoming)
        .length;
    final totalNights = _bookings.fold<int>(
      0,
      (sum, booking) => sum + booking.nights,
    );
    final totalPaidRwf = _bookings.fold<int>(
      0,
      (sum, booking) => sum + booking.totalPaidRwf,
    );
    final propertyCount = _bookings
        .map((booking) => booking.propertyKey)
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width >= 1180
            ? 28.0
            : width >= 760
            ? 24.0
            : 16.0;
        final showLoadingMetrics = _isLoading && !hasBookings;

        return RefreshIndicator(
          onRefresh: _loadBookings,
          color: Theme.of(context).colorScheme.primary,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLowest.withValues(alpha: 0.96),
                ],
              ),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    32,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MyListingBookingHeader(),
                        const SizedBox(height: 16),
                        MyListingBookingMetricsRow(
                          items: [
                            MyListingBookingMetricItem(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              label: t(
                                lang,
                                "my_listings.bookings.summary_upcoming",
                              ),
                              value: showLoadingMetrics
                                  ? "—"
                                  : "$upcomingCount",
                              detail: t(
                                lang,
                                "my_listings.bookings.summary_upcoming_sub",
                              ),
                              accent: const Color(0xFF0F8F5F),
                            ),
                            MyListingBookingMetricItem(
                              icon: HugeIcons.strokeRoundedCalendarCheckIn01,
                              label: t(
                                lang,
                                "my_listings.bookings.summary_nights",
                              ),
                              value: showLoadingMetrics ? "—" : "$totalNights",
                              detail: t(
                                lang,
                                "my_listings.bookings.summary_nights_sub",
                              ),
                              accent: const Color(0xFF1877B8),
                            ),
                            MyListingBookingMetricItem(
                              icon: HugeIcons.strokeRoundedWallet02,
                              label: t(
                                lang,
                                "my_listings.bookings.summary_paid",
                              ),
                              value: showLoadingMetrics
                                  ? "—"
                                  : RwfCurrency.format(totalPaidRwf),
                              detail: t(
                                lang,
                                "my_listings.bookings.summary_paid_sub",
                              ),
                              accent: const Color(0xFFC07A12),
                            ),
                            MyListingBookingMetricItem(
                              icon: HugeIcons.strokeRoundedHome05,
                              label: t(
                                lang,
                                "my_listings.bookings.summary_properties",
                              ),
                              value: showLoadingMetrics
                                  ? "—"
                                  : "$propertyCount",
                              detail: t(
                                lang,
                                "my_listings.bookings.summary_properties_sub",
                              ),
                              accent: const Color(0xFF5E6B7A),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        MyListingBookingListSection(
                          bookings: _bookings,
                          isLoading: _isLoading,
                          errorMessage: _errorMessage,
                          onRetry: _loadBookings,
                        ),
                      ],
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
