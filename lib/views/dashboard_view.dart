import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/whatsapp_button.dart';
import '../widgets/invoice_dialog.dart';
import '../widgets/charts/weekly_revenue_chart.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final currency = NumberFormat('#,##0', 'en_US');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Executive Operations Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.slate900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time live caregiver dispatches, revenue tracking, and medical inventory across Sri Lanka.',
                      style: TextStyle(fontSize: 13, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New Booking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      provider.setSelectedNavIndex(1);
                      context.go('/bookings');
                    },
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.inventory_2_rounded, size: 16),
                    label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.slate800,
                      side: const BorderSide(color: AppTheme.slate200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      provider.setSelectedNavIndex(3);
                      context.go('/inventory');
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4 Key KPI Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth < 220 ? constraints.maxWidth : cardWidth,
                    child: StatCard(
                      title: 'Gross Platform Revenue',
                      value: 'LKR ${currency.format(provider.totalRevenueLKR)}',
                      subtitle: 'Bookings & Medical Store sales',
                      icon: Icons.payments_rounded,
                      iconColor: AppTheme.primaryBlue,
                      iconBgColor: AppTheme.blueLight,
                      badgeText: '+18.4% MoM',
                      badgeColor: AppTheme.emerald500,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth < 220 ? constraints.maxWidth : cardWidth,
                    child: StatCard(
                      title: 'Caregivers On Duty Today',
                      value: '${provider.activeShiftsCount} Active',
                      subtitle: '100% Police & Health cleared',
                      icon: Icons.verified_user_rounded,
                      iconColor: AppTheme.emerald500,
                      iconBgColor: AppTheme.emerald100,
                      badgeText: '99.4% Match',
                      badgeColor: AppTheme.emerald500,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth < 220 ? constraints.maxWidth : cardWidth,
                    child: StatCard(
                      title: 'Pending Dispatch Review',
                      value: '${provider.pendingDispatchesCount} Requests',
                      subtitle: 'Requires supervisor matching',
                      icon: Icons.assignment_late_rounded,
                      iconColor: AppTheme.amber500,
                      iconBgColor: AppTheme.amber100,
                      badgeText: 'Needs Action',
                      badgeColor: AppTheme.amber800,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth < 220 ? constraints.maxWidth : cardWidth,
                    child: StatCard(
                      title: 'Equipment Orders & Rentals',
                      value: '${provider.orders.length} Active',
                      subtitle: '${provider.activeRentalsCount} hospital beds on rent',
                      icon: Icons.local_shipping_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBgColor: const Color(0xFFF3E8FF),
                      badgeText: 'COD & Bank',
                      badgeColor: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Weekly Realized Revenue & Shift Curve
          const WeeklyRevenueChart(),

          const SizedBox(height: 28),

          // Two Panels: Recent Live Dispatch Bookings & Quick Alerts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Recent Bookings Table
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.flash_on_rounded, color: AppTheme.primaryBlue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Live Dispatch & Caregiver Duties',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => provider.setSelectedNavIndex(1),
                            child: const Text('View All Bookings →', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Table
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowColor: WidgetStateProperty.all(AppTheme.slate50),
                          columns: const [
                            DataColumn(label: Text('CODE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                            DataColumn(label: Text('PATIENT & LOCATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                            DataColumn(label: Text('SERVICE & TIER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                            DataColumn(label: Text('ASSIGNED CAREGIVER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                          ],
                          rows: provider.bookings.map((b) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(b.bookingCode, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.primaryBlue)),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(b.patientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                      Text('${b.city}, ${b.district}', style: const TextStyle(fontSize: 11, color: AppTheme.slate500)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(b.serviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                      Text(b.staffTierName, style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  b.assignedCaregiverName != null
                                      ? Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: AppTheme.emerald500, size: 14),
                                            const SizedBox(width: 4),
                                            Text(b.assignedCaregiverName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                          ],
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppTheme.amber100, borderRadius: BorderRadius.circular(6)),
                                          child: const Text('Unassigned', style: TextStyle(fontSize: 11, color: AppTheme.amber800, fontWeight: FontWeight.bold)),
                                        ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: b.status == 'in_progress'
                                          ? AppTheme.emerald100
                                          : b.status == 'caregiver_assigned'
                                              ? AppTheme.blueLight
                                              : AppTheme.amber100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      b.status.toUpperCase().replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: b.status == 'in_progress'
                                            ? AppTheme.emerald800
                                            : b.status == 'caregiver_assigned'
                                                ? AppTheme.primaryBlue
                                                : AppTheme.amber800,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      WhatsAppButton(
                                        phone: b.contactPhone,
                                        message: 'Hello ${b.contactName}, this is Prime Life Care dispatch coordination regarding booking ${b.bookingCode}. Your caregiver ${b.assignedCaregiverName ?? "assignment"} is in progress.',
                                        isCompact: true,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.slate600, size: 20),
                                        tooltip: 'View Official Invoice',
                                        onPressed: () => InvoiceDialog.show(context, b),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Right Column: Active Equipment Rentals & Quick Actions
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // Quick WhatsApp Broadcast Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.chat_bubble_rounded, color: AppTheme.whatsappGreen, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Careline Dispatch WhatsApp',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Send instant WhatsApp booking confirmations, caregiver assignments, or hospital bed delivery slips directly from this portal.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.send_rounded, size: 14),
                                  label: const Text('Careline Broadcast', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.whatsappGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                    WhatsAppHelper.launchWhatsApp(
                                      context,
                                      '+94771234567',
                                      'Prime Life Care Live Operations Hub Broadcast Active.',
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Active Hospital Bed & Equipment Rentals Tracker Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.bed_rounded, color: AppTheme.primaryBlue, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Active Rentals (Beds/Air)',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.slate900),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => provider.setSelectedNavIndex(4),
                                child: const Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          ...provider.orders.where((o) => o.isRental).map((rental) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.slate50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.slate200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          rental.customerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: AppTheme.blueLight, borderRadius: BorderRadius.circular(6)),
                                        child: Text(rental.orderCode, style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rental.items.first.itemName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.slate600),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Text('Renewal: ${rental.rentalEndDate ?? "N/A"}', style: const TextStyle(fontSize: 10, color: AppTheme.slate500)),
                                      WhatsAppButton(
                                        phone: rental.customerPhone,
                                        message: 'Hello ${rental.customerName}, this is Prime Life Care. Your hospital equipment rental (${rental.orderCode}) renewal is scheduled for ${rental.rentalEndDate}. Please let us know if you wish to extend.',
                                        label: 'Remind',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
