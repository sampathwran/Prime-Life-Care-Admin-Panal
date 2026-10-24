import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class WeeklyRevenueChart extends StatefulWidget {
  const WeeklyRevenueChart({super.key});

  @override
  State<WeeklyRevenueChart> createState() => _WeeklyRevenueChartState();
}

class _WeeklyRevenueChartState extends State<WeeklyRevenueChart> {
  final currencyFormat = NumberFormat('#,##0', 'en_US');

  String _period = 'weekly'; // 'weekly' | 'monthly' | 'custom'
  DateTimeRange? _customDateRange;

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      try {
        final parts = raw.split('-');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      helpText: 'Select Revenue Date Range',
      cancelText: 'Cancel',
      confirmText: 'Apply Filter',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.slate800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _period = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final bookings = provider.bookings;
    final orders = provider.orders;

    String title;
    String subtitle;
    String badgeText;
    List<String> labels = [];
    List<double> values = [];
    double maxY;
    double yInterval;

    final now = DateTime.now();

    if (_period == 'monthly') {
      title = 'Realized Monthly Revenue & Shift Curve';
      subtitle = 'Four-week home healthcare bookings + equipment sales (${DateFormat('MMMM yyyy').format(now)})';
      labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];

      // Calculate 4 weekly blocks of the current month
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      final week1Start = firstDayOfMonth;
      final week1End = DateTime(now.year, now.month, 7, 23, 59, 59);

      final week2Start = DateTime(now.year, now.month, 8);
      final week2End = DateTime(now.year, now.month, 14, 23, 59, 59);

      final week3Start = DateTime(now.year, now.month, 15);
      final week3End = DateTime(now.year, now.month, 21, 23, 59, 59);

      final week4Start = DateTime(now.year, now.month, 22);
      final week4End = DateTime(now.year, now.month, daysInMonth, 23, 59, 59);

      final weekRanges = [
        [week1Start, week1End],
        [week2Start, week2End],
        [week3Start, week3End],
        [week4Start, week4End],
      ];

      values = weekRanges.map((range) {
        final start = range[0];
        final end = range[1];
        double sum = 0.0;

        for (var b in bookings) {
          final bDate = _parseDate(b.startDate) ?? _parseDate(b.createdAt);
          if (bDate != null && !bDate.isBefore(start) && !bDate.isAfter(end)) {
            sum += b.totalCostLKR;
          }
        }
        for (var o in orders) {
          final oDate = _parseDate(o.rentalStartDate) ?? _parseDate(o.createdAt);
          if (oDate != null && !oDate.isBefore(start) && !oDate.isAfter(end)) {
            sum += o.totalAmountLKR;
          }
        }
        return sum;
      }).toList();

      final totalMonth = values.reduce((a, b) => a + b);
      badgeText = totalMonth > 0 ? 'Live Month: LKR ${currencyFormat.format(totalMonth)}' : '0.00 This Month';
    } else if (_period == 'custom' && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end;
      final daysDiff = end.difference(start).inDays + 1;

      title = 'Custom Period Revenue Curve';
      subtitle = '${DateFormat('dd MMM yyyy').format(start)} – ${DateFormat('dd MMM yyyy').format(end)} ($daysDiff Days)';

      if (daysDiff <= 7) {
        labels = List.generate(daysDiff, (i) {
          final d = start.add(Duration(days: i));
          return DateFormat('E, d MMM').format(d);
        });

        values = List.generate(daysDiff, (i) {
          final targetDay = start.add(Duration(days: i));
          double sum = 0.0;
          for (var b in bookings) {
            final bDate = _parseDate(b.startDate) ?? _parseDate(b.createdAt);
            if (bDate != null && _isSameDay(bDate, targetDay)) {
              sum += b.totalCostLKR;
            }
          }
          for (var o in orders) {
            final oDate = _parseDate(o.rentalStartDate) ?? _parseDate(o.createdAt);
            if (oDate != null && _isSameDay(oDate, targetDay)) {
              sum += o.totalAmountLKR;
            }
          }
          return sum;
        });
      } else {
        const count = 6;
        labels = List.generate(count, (i) {
          final frac = i / (count - 1);
          final daysOffset = (daysDiff * frac).round().clamp(0, daysDiff - 1);
          final d = start.add(Duration(days: daysOffset));
          return DateFormat('d MMM').format(d);
        });

        values = List.generate(count, (i) {
          final step = daysDiff / count;
          final intervalStart = start.add(Duration(days: (i * step).round()));
          final intervalEnd = start.add(Duration(days: (((i + 1) * step) - 1).round().clamp(0, daysDiff - 1)));

          double sum = 0.0;
          for (var b in bookings) {
            final bDate = _parseDate(b.startDate) ?? _parseDate(b.createdAt);
            if (bDate != null && !bDate.isBefore(intervalStart) && !bDate.isAfter(intervalEnd)) {
              sum += b.totalCostLKR;
            }
          }
          for (var o in orders) {
            final oDate = _parseDate(o.rentalStartDate) ?? _parseDate(o.createdAt);
            if (oDate != null && !oDate.isBefore(intervalStart) && !oDate.isAfter(intervalEnd)) {
              sum += o.totalAmountLKR;
            }
          }
          return sum;
        });
      }

      final totalCustom = values.reduce((a, b) => a + b);
      badgeText = totalCustom > 0 ? 'Total: LKR ${currencyFormat.format(totalCustom)}' : '$daysDiff Days Range';
    } else {
      // Default: Weekly - Mon to Sun (Exact Real Revenue from Firestore Bookings & Orders)
      title = 'Realized Weekly Revenue & Shift Curve';
      subtitle = 'Daily home healthcare bookings + medical equipment revenue (Mon – Sun)';
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      // Start of current week (Monday)
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

      values = List.generate(7, (i) {
        final targetDay = weekDays[i];
        double sum = 0.0;

        for (var b in bookings) {
          final bDate = _parseDate(b.startDate) ?? _parseDate(b.createdAt);
          if (bDate != null) {
            // If multi-day shift with price per day, attribute to each active shift day
            if (b.durationDays > 1 && b.pricePerDayLKR > 0) {
              final shiftEnd = bDate.add(Duration(days: b.durationDays));
              if (!targetDay.isBefore(bDate) && targetDay.isBefore(shiftEnd)) {
                sum += b.pricePerDayLKR;
              }
            } else if (_isSameDay(bDate, targetDay)) {
              sum += b.totalCostLKR;
            }
          }
        }

        for (var o in orders) {
          final oDate = _parseDate(o.rentalStartDate) ?? _parseDate(o.createdAt);
          if (oDate != null && _isSameDay(oDate, targetDay)) {
            sum += o.totalAmountLKR;
          }
        }

        return sum;
      });

      final totalWeek = values.reduce((a, b) => a + b);
      badgeText = totalWeek > 0 ? 'Live Week: LKR ${currencyFormat.format(totalWeek)}' : '0.00 This Week';
    }

    final periodTotal = values.reduce((a, b) => a + b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    if (maxVal > 0) {
      maxY = (maxVal * 1.25).ceilToDouble();
      yInterval = (maxY / 4).ceilToDouble();
    } else {
      maxY = 20000.0;
      yInterval = 5000.0;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title, Period Total & Trend Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      subtitle,
                      style: const TextStyle(fontSize: 10, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: periodTotal > 0 ? AppTheme.emerald100 : AppTheme.slate100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          periodTotal > 0 ? Icons.trending_up : Icons.show_chart_rounded,
                          size: 12,
                          color: periodTotal > 0 ? AppTheme.emerald800 : AppTheme.slate600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: periodTotal > 0 ? AppTheme.emerald800 : AppTheme.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  SelectableText(
                    'Period Total: LKR ${currencyFormat.format(periodTotal)}',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.slate600),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Period Filter Chips (Weekly | Monthly | Custom Range) - Pure English
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFilterPill(
                id: 'weekly',
                label: 'Weekly',
                icon: Icons.calendar_view_week_rounded,
                isSelected: _period == 'weekly',
                onTap: () {
                  setState(() => _period = 'weekly');
                },
              ),
              _buildFilterPill(
                id: 'monthly',
                label: 'Monthly',
                icon: Icons.calendar_month_rounded,
                isSelected: _period == 'monthly',
                onTap: () {
                  setState(() => _period = 'monthly');
                },
              ),
              _buildFilterPill(
                id: 'custom',
                label: _period == 'custom' && _customDateRange != null
                    ? '${DateFormat('d MMM').format(_customDateRange!.start)} – ${DateFormat('d MMM').format(_customDateRange!.end)}'
                    : 'Custom Range',
                icon: Icons.date_range_rounded,
                isSelected: _period == 'custom',
                onTap: _pickCustomRange,
              ),
              if (_period == 'custom' && _customDateRange != null)
                InkWell(
                  onTap: _pickCustomRange,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_calendar_rounded, size: 11, color: AppTheme.primaryBlue),
                        SizedBox(width: 3),
                        Text('Change Dates', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Line Chart Area with Full 7-Day / Multi-Point Real Visibility
          SizedBox(
            height: 175,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval > 0 ? yInterval : 5000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.slate100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: yInterval > 0 ? yInterval : 5000,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            '${(value / 1000).toInt()}k',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.slate400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if ((value - idx).abs() > 0.05 || idx < 0 || idx >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[idx],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.slate600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: -0.3,
                maxX: (labels.length - 1) + 0.3,
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.round().clamp(0, labels.length - 1);
                        final label = labels[idx];
                        return LineTooltipItem(
                          '$label\nLKR ${currencyFormat.format(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      values.length,
                      (i) => FlSpot(i.toDouble(), values[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: AppTheme.primaryBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2.2,
                        strokeColor: AppTheme.primaryBlue,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.22),
                          AppTheme.primaryBlue.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String id,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.slate100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.slate200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : AppTheme.slate700,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.slate800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
