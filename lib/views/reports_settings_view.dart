import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/financial_growth_chart.dart';

class ReportsSettingsView extends StatefulWidget {
  const ReportsSettingsView({super.key});

  @override
  State<ReportsSettingsView> createState() => _ReportsSettingsViewState();
}

class _ReportsSettingsViewState extends State<ReportsSettingsView> {
  final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

  final _mohRegCtrl = TextEditingController(text: 'MOH/PHS/2026/8942');
  final _carelineCtrl = TextEditingController(text: '+94 77 123 4567');
  final _whatsappCtrl = TextEditingController(text: '+94 77 123 4567');
  final _bankNameCtrl = TextEditingController(text: 'Commercial Bank of Ceylon');
  final _bankAccCtrl = TextEditingController(text: '1000 2489 1234');
  final _bankHolderCtrl = TextEditingController(text: 'Prime Life Care (Pvt) Ltd');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Reports & System Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Revenue audit, MOH Sri Lanka compliance details, and dispatch communication channels.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Financial Audit & Dispatch Ledger exported as CSV successfully!'),
                        backgroundColor: AppTheme.emeraldGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Export Audit Report (CSV)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.slate900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Revenue Breakdown Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 750;
                final double cardWidth = isCompact ? (constraints.maxWidth - 8) / 2 : (constraints.maxWidth - 16) / 3;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: isCompact && constraints.maxWidth < 480 ? constraints.maxWidth : cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Gross Realized Revenue',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey),
                                  ),
                                ),
                                Icon(Icons.monetization_on_outlined, color: AppTheme.emeraldGreen, size: 18),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormat.format(provider.totalRevenueLKR),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.trending_up, size: 13, color: AppTheme.emeraldGreen),
                                const SizedBox(width: 3),
                                Text(
                                  '+18.4% from last month',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreen),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isCompact && constraints.maxWidth < 480 ? constraints.maxWidth : cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Active Caregiver Shifts',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey),
                                  ),
                                ),
                                Icon(Icons.badge_outlined, color: AppTheme.primaryBlue, size: 18),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${provider.activeShiftsCount} Shifts Active',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${provider.pendingDispatchesCount} pending dispatches',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isCompact && constraints.maxWidth < 480 ? constraints.maxWidth : cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Equipment On Hire',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey),
                                  ),
                                ),
                                Icon(Icons.repeat, color: Colors.purple, size: 18),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${provider.activeRentalsCount} Hospital Units',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Recurring monthly rental income',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),

            // 6-Month Business Streams Financial Growth Chart
            const FinancialGrowthChart(),

            const SizedBox(height: 10),

            // District Shift Coverage Table
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Islandwide Healthcare Coverage Matrix',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: 160, child: _buildDistrictTile('Colombo District', '5 Active Shifts', '12 Available Staff', Colors.blue)),
                        const SizedBox(width: 8),
                        SizedBox(width: 160, child: _buildDistrictTile('Gampaha District', '3 Active Shifts', '6 Available Staff', Colors.teal)),
                        const SizedBox(width: 8),
                        SizedBox(width: 160, child: _buildDistrictTile('Kandy District', '1 Active Shift', '4 Available Staff', Colors.amber)),
                        const SizedBox(width: 8),
                        SizedBox(width: 160, child: _buildDistrictTile('Galle & South', '1 Active Shift', '3 Available Staff', Colors.indigo)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // MOH & Organization Settings Form
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Healthcare Regulatory & Clinical Hotlines',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('System and MOH configuration updated successfully!'),
                              backgroundColor: AppTheme.emeraldGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Save Settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mohRegCtrl,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(
                            labelText: 'Ministry of Health (MOH) Registration Number',
                            labelStyle: TextStyle(fontSize: 10.5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.verified_outlined, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _carelineCtrl,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(
                            labelText: '24/7 Clinical Emergency Hotline',
                            labelStyle: TextStyle(fontSize: 10.5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_in_talk_outlined, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _whatsappCtrl,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp Dispatch Direct Channel (+94)',
                            labelStyle: TextStyle(fontSize: 10.5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.chat_outlined, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _bankNameCtrl,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(
                            labelText: 'Designated Corporate Bank',
                            labelStyle: TextStyle(fontSize: 10.5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_outlined, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bankAccCtrl,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(
                            labelText: 'Bank Account Number for Deposit Slips',
                            labelStyle: TextStyle(fontSize: 10.5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _bankHolderCtrl,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(
                            labelText: 'Registered Account Holder Name',
                            labelStyle: TextStyle(fontSize: 10.5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business_outlined, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildDistrictTile(String name, String shifts, String staff, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color.shade900),
          ),
          const SizedBox(height: 3),
          Text(shifts, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          Text(staff, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
