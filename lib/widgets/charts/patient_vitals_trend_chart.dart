import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class PatientVitalsTrendChart extends StatelessWidget {
  const PatientVitalsTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final times = ['06:00 AM', '09:00 AM', '12:00 PM', '03:00 PM', '06:00 PM', '09:00 PM'];

    // Sample patient vitals throughout shift
    final bpSystolic = [124.0, 136.0, 122.0, 128.0, 120.0, 124.0];
    final bloodSugar = [114.0, 142.0, 128.0, 135.0, 118.0, 122.0];
    final pulseRate = [72.0, 78.0, 74.0, 76.0, 72.0, 74.0];

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '24-Hour Patient Vitals Progression Curve',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Blood Pressure (Systolic), Blood Sugar (mg/dL), and Heart Pulse over time',
                      style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _buildLegendDot('BP Systolic', const Color(0xFFF43F5E)), // Rose
                  const SizedBox(width: 14),
                  _buildLegendDot('Blood Sugar', const Color(0xFFF59E0B)), // Amber
                  const SizedBox(width: 14),
                  _buildLegendDot('Heart Pulse', AppTheme.primaryBlue),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 60,
                maxY: 160,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.slate100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slate400,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < times.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              times[idx],
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppTheme.slate600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String name = 'BP';
                        if (spot.barIndex == 1) name = 'Sugar';
                        if (spot.barIndex == 2) name = 'Pulse';
                        return LineTooltipItem(
                          '$name: ${spot.y.toInt()}',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Blood Pressure Systolic (Rose)
                  LineChartBarData(
                    spots: List.generate(bpSystolic.length, (i) => FlSpot(i.toDouble(), bpSystolic[i])),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFFF43F5E),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  // Blood Sugar (Amber)
                  LineChartBarData(
                    spots: List.generate(bloodSugar.length, (i) => FlSpot(i.toDouble(), bloodSugar[i])),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFFF59E0B),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  // Pulse (Blue)
                  LineChartBarData(
                    spots: List.generate(pulseRate.length, (i) => FlSpot(i.toDouble(), pulseRate[i])),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.primaryBlue,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
        ),
      ],
    );
  }
}
