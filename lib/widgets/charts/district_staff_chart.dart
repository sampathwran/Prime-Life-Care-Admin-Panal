import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class DistrictStaffChart extends StatelessWidget {
  const DistrictStaffChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final caregivers = provider.caregivers;

    // Distinct districts from real caregiver data
    final districtSet = <String>{};
    for (final c in caregivers) {
      if (c.district.trim().isNotEmpty) {
        districtSet.add(c.district.trim());
      }
    }

    final List<String> districts = districtSet.isNotEmpty
        ? districtSet.toList()
        : ['Colombo', 'Gampaha', 'Kandy', 'Galle', 'Kurunegala'];

    final List<double> availableStaff = [];
    final List<double> onDutyStaff = [];
    double highestCount = 0;

    for (final dist in districts) {
      final avail = caregivers
          .where((c) => c.district.toLowerCase() == dist.toLowerCase() && c.status == 'available')
          .length
          .toDouble();
      final onDuty = caregivers
          .where((c) => c.district.toLowerCase() == dist.toLowerCase() && c.status == 'on_duty')
          .length
          .toDouble();

      availableStaff.add(avail);
      onDutyStaff.add(onDuty);

      if (avail > highestCount) highestCount = avail;
      if (onDuty > highestCount) highestCount = onDuty;
    }

    final double maxY = highestCount > 0 ? (highestCount + 2) : 5.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Islandwide Caregiver Capacity & Duty Status',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'District-by-district breakdown of available caregivers vs currently on-duty shifts',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.slate500),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendIndicator('Available Staff', AppTheme.emeraldGreen),
                  const SizedBox(width: 14),
                  _buildLegendIndicator('On Duty Dispatched', AppTheme.primaryBlue),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          caregivers.isEmpty
              ? Container(
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        '0 Caregivers Registered',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'District capacity bars will update in real time as staff members register in the Caregiver App.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 155,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final dist = districts[group.x.toInt()];
                            final isAvail = rodIndex == 0;
                            return BarTooltipItem(
                              '$dist\n${isAvail ? "Available" : "On Duty"}: ${rod.toY.toInt()} staff',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < districts.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    districts[idx],
                                    style: const TextStyle(
                                      color: AppTheme.slate600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: maxY > 5 ? 2 : 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: AppTheme.slate400,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 5 ? 2 : 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.slate100,
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(districts.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 6,
                          barRods: [
                            BarChartRodData(
                              toY: availableStaff[i],
                              color: AppTheme.emeraldGreen,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: onDutyStaff[i],
                              color: AppTheme.primaryBlue,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
        ),
      ],
    );
  }
}
