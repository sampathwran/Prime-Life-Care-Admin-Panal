import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class FinancialGrowthChart extends StatelessWidget {
  const FinancialGrowthChart({super.key});

  @override
  Widget build(BuildContext context) {
    final months = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    // Revenue in thousands LKR
    final careServices = [180.0, 220.0, 260.0, 310.0, 380.0, 440.0];
    final equipmentSales = [60.0, 75.0, 90.0, 110.0, 130.0, 155.0];
    final rentals = [35.0, 45.0, 60.0, 75.0, 95.0, 120.0];

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
                    '6-Month Financial Growth by Business Stream',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Revenue scaling across Home Nursing, Equipment Sales, and Monthly Rentals (in 000s LKR)',
                    style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendDot('Home Care', AppTheme.primaryBlue),
                  const SizedBox(width: 14),
                  _buildLegendDot('Store Sales', AppTheme.emeraldGreen),
                  const SizedBox(width: 14),
                  _buildLegendDot('Rentals', const Color(0xFF9333EA)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 500,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.slate100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: 100,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}k',
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
                        if (idx >= 0 && idx < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              months[idx],
                              style: const TextStyle(
                                fontSize: 11,
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
                        String cat = 'Care';
                        if (spot.barIndex == 1) cat = 'Store';
                        if (spot.barIndex == 2) cat = 'Rentals';
                        return LineTooltipItem(
                          '$cat: LKR ${currencyFormat.format(spot.y * 1000)}',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Care Services (Blue)
                  LineChartBarData(
                    spots: List.generate(careServices.length, (i) => FlSpot(i.toDouble(), careServices[i])),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.primaryBlue,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ),
                  ),
                  // Store Sales (Emerald)
                  LineChartBarData(
                    spots: List.generate(equipmentSales.length, (i) => FlSpot(i.toDouble(), equipmentSales[i])),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.emeraldGreen,
                    barWidth: 3,
                  ),
                  // Rentals (Purple)
                  LineChartBarData(
                    spots: List.generate(rentals.length, (i) => FlSpot(i.toDouble(), rentals[i])),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF9333EA),
                    barWidth: 3,
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
