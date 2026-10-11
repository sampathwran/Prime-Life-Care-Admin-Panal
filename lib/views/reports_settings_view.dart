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
      padding: const EdgeInsets.all(24.0),
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Revenue audit, MOH Sri Lanka compliance details, and dispatch communication channels.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export Audit Report (CSV)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.slate900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue Breakdown Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Gross Realized Revenue', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                            Icon(Icons.monetization_on_outlined, color: AppTheme.emeraldGreen, size: 24),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currencyFormat.format(provider.totalRevenueLKR),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.trending_up, size: 16, color: AppTheme.emeraldGreen),
                            const SizedBox(width: 4),
                            Text(
                              '+18.4% from last month',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreen),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Active Caregiver Shifts', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                            Icon(Icons.badge_outlined, color: AppTheme.primaryBlue, size: 24),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${provider.activeShiftsCount} Shifts Active',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${provider.pendingDispatchesCount} pending family dispatches',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Equipment On Hire', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                            Icon(Icons.repeat, color: Colors.purple, size: 24),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${provider.activeRentalsCount} Hospital Units',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Recurring monthly rental income stream',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 6-Month Business Streams Financial Growth Chart
            const FinancialGrowthChart(),

            const SizedBox(height: 24),

            // District Shift Coverage Table
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Islandwide Healthcare Coverage Matrix',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildDistrictTile('Colombo District', '5 Active Shifts', '12 Available Staff', Colors.blue),
                      const SizedBox(width: 12),
                      _buildDistrictTile('Gampaha District', '3 Active Shifts', '6 Available Staff', Colors.teal),
                      const SizedBox(width: 12),
                      _buildDistrictTile('Kandy District', '1 Active Shift', '4 Available Staff', Colors.amber),
                      const SizedBox(width: 12),
                      _buildDistrictTile('Galle & South', '1 Active Shift', '3 Available Staff', Colors.indigo),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // MOH & Organization Settings Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900),
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text('Save Settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mohRegCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Ministry of Health (MOH) Registration Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.verified_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _carelineCtrl,
                          decoration: const InputDecoration(
                            labelText: '24/7 Clinical Emergency Hotline',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_in_talk_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _whatsappCtrl,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp Dispatch Direct Channel (+94)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.chat_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _bankNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Designated Corporate Bank',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bankAccCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bank Account Number for Deposit Slips',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _bankHolderCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Registered Account Holder Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business_outlined),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color.shade900),
            ),
            const SizedBox(height: 6),
            Text(shifts, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(staff, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
