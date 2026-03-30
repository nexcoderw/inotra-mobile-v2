import "package:flutter/material.dart";

import "../../../../../core/constants/app_colors.dart";

enum DashboardPeriod { days7, days30, days90, custom }

extension DashboardPeriodExt on DashboardPeriod {
  String get label {
    switch (this) {
      case DashboardPeriod.days7:
        return "7D";
      case DashboardPeriod.days30:
        return "30D";
      case DashboardPeriod.days90:
        return "90D";
      case DashboardPeriod.custom:
        return "Custom";
    }
  }

  DateTimeRange? defaultRange() {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    switch (this) {
      case DashboardPeriod.days7:
        return DateTimeRange(start: d.subtract(const Duration(days: 6)), end: d);
      case DashboardPeriod.days30:
        return DateTimeRange(start: d.subtract(const Duration(days: 29)), end: d);
      case DashboardPeriod.days90:
        return DateTimeRange(start: d.subtract(const Duration(days: 89)), end: d);
      case DashboardPeriod.custom:
        return null;
    }
  }
}

class DashboardDateFilter extends StatelessWidget {
  final DashboardPeriod selected;
  final DateTimeRange range;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final ValueChanged<DateTimeRange> onRangeChanged;

  const DashboardDateFilter({
    super.key,
    required this.selected,
    required this.range,
    required this.onPeriodChanged,
    required this.onRangeChanged,
  });

  static const _months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  String get _customLabel {
    final s = range.start;
    final e = range.end;
    return "${_months[s.month - 1]} ${s.day} – ${_months[e.month - 1]} ${e.day}";
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: range,
      helpText: "SELECT DATE RANGE",
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onRangeChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: DashboardPeriod.values.map((p) {
          final active = selected == p;
          final chipLabel =
              (p == DashboardPeriod.custom && active) ? _customLabel : p.label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  onPeriodChanged(p);
                  if (p == DashboardPeriod.custom) {
                    await _openPicker(context);
                  } else {
                    final r = p.defaultRange();
                    if (r != null) onRangeChanged(r);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : scheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? AppColors.primary
                          : scheme.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : scheme.onSurface.withValues(alpha: 0.62),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
