import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class ShiftDistributionChart extends StatefulWidget {
  const ShiftDistributionChart({super.key});

  @override
  State<ShiftDistributionChart> createState() => _ShiftDistributionChartState();
}

class _ShiftDistributionChartState extends State<ShiftDistributionChart> {
  int touchedIndex = -1;

  final List<Map<String, dynamic>> shiftData = [
    {
      'title': '24h Live-in',
      'value': 42.0,
      'count': 18,
      'color': const Color(0xFF4F46E5), // Indigo
    },
    {
      'title': '12h Day Shift',
      'value': 32.0,
      'count': 14,
      'color': AppTheme.primaryBlue,
    },
    {
      'title': '12h Night Shift',
      'value': 16.0,
      'count': 7,
      'color': const Color(0xFFF59E0B), // Amber
    },
    {
      'title': 'Doctor Visits',
      'value': 10.0,
      'count': 4,
      'color': const Color(0xFF10B981), // Emerald
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Shift Category Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ratio of 24h Live-in, Day, Night, and Doctor Visits',
                    style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '43 Active Patients',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                height: 180,
                width: 180,
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
                    sectionsSpace: 3,
                    centerSpaceRadius: 46,
                    sections: List.generate(shiftData.length, (i) {
                      final isTouched = i == touchedIndex;
                      final fontSize = isTouched ? 14.0 : 11.0;
                      final radius = isTouched ? 48.0 : 42.0;
                      final item = shiftData[i];

                      return PieChartSectionData(
                        color: item['color'] as Color,
                        value: item['value'] as double,
                        title: '${(item['value'] as double).toInt()}%',
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.slate800,
                              ),
                            ),
                          ),
                          Text(
                            '${item['count']} Shifts',
                            style: TextStyle(
                              fontSize: 12,
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
