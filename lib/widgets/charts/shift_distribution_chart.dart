import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class ShiftDistributionChart extends StatefulWidget {
  const ShiftDistributionChart({super.key});

  @override
  State<ShiftDistributionChart> createState() => _ShiftDistributionChartState();
}

class _ShiftDistributionChartState extends State<ShiftDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final bookings = provider.bookings;
    final totalBookings = bookings.length;
    final activeCount = bookings.where((b) => b.status != 'completed').length;

    // Real aggregation from live Firestore bookings
    int liveInCount = 0;
    int dayShiftCount = 0;
    int nightShiftCount = 0;
    int visitCount = 0;

    for (final b in bookings) {
      final st = b.shiftType.toLowerCase();
      final sn = b.serviceName.toLowerCase();
      if (st.contains('24') || st.contains('live') || b.shiftHours >= 24 || sn.contains('24') || sn.contains('live-in')) {
        liveInCount++;
      } else if (st.contains('night') || sn.contains('night')) {
        nightShiftCount++;
      } else if (st.contains('visit') || sn.contains('doctor') || b.shiftHours <= 4) {
        visitCount++;
      } else {
        dayShiftCount++;
      }
    }

    final List<Map<String, dynamic>> shiftData = [];
    if (liveInCount > 0) {
      shiftData.add({
        'title': '24h Live-in Care',
        'value': totalBookings > 0 ? (liveInCount / totalBookings) * 100 : 0.0,
        'count': liveInCount,
        'color': const Color(0xFF4F46E5), // Indigo
      });
    }
    if (dayShiftCount > 0) {
      shiftData.add({
        'title': '12h Day Shift',
        'value': totalBookings > 0 ? (dayShiftCount / totalBookings) * 100 : 0.0,
        'count': dayShiftCount,
        'color': AppTheme.primaryBlue,
      });
    }
    if (nightShiftCount > 0) {
      shiftData.add({
        'title': '12h Night Shift',
        'value': totalBookings > 0 ? (nightShiftCount / totalBookings) * 100 : 0.0,
        'count': nightShiftCount,
        'color': const Color(0xFFF59E0B), // Amber
      });
    }
    if (visitCount > 0) {
      shiftData.add({
        'title': 'Clinical & Doctor Visits',
        'value': totalBookings > 0 ? (visitCount / totalBookings) * 100 : 0.0,
        'count': visitCount,
        'color': const Color(0xFF10B981), // Emerald
      });
    }

    if (touchedIndex >= shiftData.length) {
      touchedIndex = -1;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Active Shift Category Breakdown',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Live ratio of 24h Live-in, Day, Night, and Doctor Visits from real bookings',
                      style: TextStyle(fontSize: 10, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  totalBookings == 0
                      ? '0 Bookings'
                      : '$activeCount Active • $totalBookings Total',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shiftData.isEmpty)
            Container(
              height: 100,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.pie_chart_outline_rounded, size: 22, color: AppTheme.slate400),
                  SizedBox(width: 10),
                  Text(
                    'No bookings recorded yet. As clients book shifts, real distribution appears here.',
                    style: TextStyle(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  height: 130,
                  width: 130,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: List.generate(shiftData.length, (i) {
                        final isTouched = i == touchedIndex;
                        final fontSize = isTouched ? 11.0 : 9.0;
                        final radius = isTouched ? 34.0 : 28.0;
                        final item = shiftData[i];
                        final pct = item['value'] as double;

                        return PieChartSectionData(
                          color: item['color'] as Color,
                          value: pct,
                          title: '${pct.toStringAsFixed(0)}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legends
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: shiftData.map((item) {
                      final count = item['count'] as int;
                      final pct = item['value'] as double;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: item['color'] as Color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.slate800,
                                ),
                              ),
                            ),
                            Text(
                              '$count Shift${count == 1 ? '' : 's'} (${pct.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
