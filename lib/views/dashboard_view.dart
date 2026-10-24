import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/booking_model.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/whatsapp_button.dart';
import '../widgets/invoice_dialog.dart';
import '../widgets/charts/weekly_revenue_chart.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ScrollController _tableScrollController = ScrollController();

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  void _showAssignCaregiverDialog(BuildContext context, BookingModel booking) {
    final provider = context.read<AdminProvider>();
    final availableCaregivers = provider.caregivers;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: const [
              Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text('Assign Caregiver for Patient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient: ${booking.patientName} (${booking.patientAge} Yrs)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  'Required: ${booking.serviceName} • Tier: ${booking.staffTierName}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                ),
                Text(
                  'Location: ${booking.city}, ${booking.district}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
                ),
                const SizedBox(height: 16),
                const Text('Select Qualified & Cleared Caregiver:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.slate700)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableCaregivers.length,
                    itemBuilder: (ctx, idx) {
                      final cg = availableCaregivers[idx];
                      final isCurrent = booking.assignedCaregiverId == cg.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppTheme.blueLight : AppTheme.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent ? AppTheme.primaryBlue : AppTheme.slate200,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryBlue,
                              child: Text(cg.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            title: Row(
                              children: [
                                Text(cg.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                const SizedBox(width: 6),
                                if (cg.isPoliceVerified)
                                  const Icon(Icons.verified_rounded, size: 14, color: AppTheme.emerald500),
                              ],
                            ),
                            subtitle: Text('${cg.tierLabel} • ${cg.district}', style: const TextStyle(fontSize: 10, color: AppTheme.slate500)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrent ? AppTheme.emerald500 : AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                provider.assignCaregiver(booking.id, cg);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${cg.name} assigned to ${booking.patientName}!')),
                                );
                              },
                              child: Text(isCurrent ? 'Assigned' : 'Assign', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFunnelCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      title,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    SelectableText(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.slate900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String stageTitle,
    required String countText,
    String? subBadgeText,
    Color? subBadgeColor,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    stageTitle,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: iconColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  countText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: iconColor, letterSpacing: -0.3),
                ),
                if (subBadgeText != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: subBadgeColor ?? iconColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subBadgeText,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              hintText,
              style: TextStyle(fontSize: 9.5, color: iconColor.withOpacity(0.85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final currency = NumberFormat('#,##0', 'en_US');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Top Web Traffic & Online Engagement Funnel (Website Visitors, Registered Users, Bookings)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.blueLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.public_rounded, size: 14, color: AppTheme.primaryBlue),
                        ),
                        const SizedBox(width: 6),
                        const SelectableText(
                          'Prime Life Care Live Web Traffic & Digital Funnel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.slate900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.fiber_manual_record, size: 8, color: AppTheme.emerald800),
                          SizedBox(width: 4),
                          Text(
                            'Live Cloud Sync',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.emerald800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    final funnelCards = [
                      _buildFunnelCard(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFF0F9FF),
                        title: 'Website Visitors',
                        value: NumberFormat('#,##0', 'en_US').format(provider.totalWebsiteVisitors),
                        badgeText: provider.todayWebsiteVisitors > 0
                            ? '+${provider.todayWebsiteVisitors} Today'
                            : 'Live Active',
                        badgeColor: AppTheme.emerald500,
                        onTap: null,
                      ),
                      _buildFunnelCard(
                        icon: Icons.people_alt_rounded,
                        iconColor: AppTheme.emerald800,
                        bgColor: AppTheme.emerald100,
                        title: 'Registered Users',
                        value: '${provider.users.length} Users',
                        badgeText: 'View Directory →',
                        badgeColor: AppTheme.primaryBlue,
                        onTap: () {
                          provider.setSelectedNavIndex(2);
                          context.go('/users');
                        },
                      ),
                      _buildFunnelCard(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: AppTheme.primaryBlue,
                        bgColor: AppTheme.blueLight,
                        title: 'Total Bookings',
                        value: '${provider.bookings.length} Bookings',
                        badgeText: 'View All →',
                        badgeColor: AppTheme.primaryBlue,
                        onTap: () {
                          provider.setSelectedBookingTab('all');
                          provider.setSelectedNavIndex(1);
                          context.go('/bookings');
                        },
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: funnelCards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 6), child: c)).toList(),
                      );
                    }

                    return Row(
                      children: funnelCards.map((c) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: c == funnelCards.last ? 0 : 8),
                            child: c,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Real-Time Booking Dispatch Pipeline (5 Stages with live counts)
          Builder(builder: (ctx) {
            final allBookings = provider.bookings;
            final newWebCount = allBookings.where((b) => b.isNewWeb).length;
            final inProcessCount = allBookings.where((b) => b.isInProcess).length;
            final broadcastedBookings = allBookings.where((b) => b.isBroadcasted).toList();
            final broadcastedCount = broadcastedBookings.length;
            final onDutyCount = allBookings.where((b) => b.isOnDuty).length;
            final completedCount = allBookings.where((b) => b.isCompleted).length;

            int totalCandidatesInQueues = 0;
            for (var b in broadcastedBookings) {
              totalCandidatesInQueues += b.candidateQueue.length;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.hub_rounded, size: 14, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Live Bookings Dispatch Pipeline & Staff Queue Status',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          provider.setSelectedBookingTab('all');
                          provider.setSelectedNavIndex(1);
                          context.go('/bookings');
                        },
                        child: Text(
                          'View All (${allBookings.length}) →',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;
                      final pipelineCards = [
                        _buildPipelineCard(
                          icon: Icons.fiber_new_rounded,
                          iconColor: const Color(0xFFB45309),
                          bgColor: const Color(0xFFFFFBEB),
                          borderColor: const Color(0xFFFDE68A),
                          stageTitle: 'New Web (Unread)',
                          countText: '$newWebCount',
                          hintText: 'Pending review',
                          onTap: () {
                            provider.setSelectedBookingTab('pending_review');
                            provider.setSelectedNavIndex(1);
                            context.go('/bookings');
                          },
                        ),
                        _buildPipelineCard(
                          icon: Icons.hourglass_top_rounded,
                          iconColor: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFF0F9FF),
                          borderColor: const Color(0xFFBAE6FD),
                          stageTitle: 'In Process',
                          countText: '$inProcessCount',
                          hintText: 'Ops hold / Client notified',
                          onTap: () {
                            provider.setSelectedBookingTab('in_process');
                            provider.setSelectedNavIndex(1);
                            context.go('/bookings');
                          },
                        ),
                        _buildPipelineCard(
                          icon: Icons.broadcast_on_personal_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFFAF5FF),
                          borderColor: const Color(0xFFE9D5FF),
                          stageTitle: 'Released to Staff',
                          countText: '$broadcastedCount',
                          subBadgeText: totalCandidatesInQueues > 0 ? '⚡ $totalCandidatesInQueues Queued' : null,
                          subBadgeColor: const Color(0xFF8B5CF6),
                          hintText: 'Acceptance queue live',
                          onTap: () {
                            provider.setSelectedBookingTab('broadcasted');
                            provider.setSelectedNavIndex(1);
                            context.go('/bookings');
                          },
                        ),
                        _buildPipelineCard(
                          icon: Icons.assignment_turned_in_rounded,
                          iconColor: const Color(0xFF059669),
                          bgColor: const Color(0xFFECFDF5),
                          borderColor: const Color(0xFFA7F3D0),
                          stageTitle: 'On Duty Shifts',
                          countText: '$onDutyCount',
                          hintText: 'Caregiver assigned',
                          onTap: () {
                            provider.setSelectedBookingTab('on_duty');
                            provider.setSelectedNavIndex(1);
                            context.go('/bookings');
                          },
                        ),
                        _buildPipelineCard(
                          icon: Icons.task_alt_rounded,
                          iconColor: const Color(0xFF475569),
                          bgColor: const Color(0xFFF8FAFC),
                          borderColor: const Color(0xFFCBD5E1),
                          stageTitle: 'Completed',
                          countText: '$completedCount',
                          hintText: 'Duties signed off',
                          onTap: () {
                            provider.setSelectedBookingTab('completed');
                            provider.setSelectedNavIndex(1);
                            context.go('/bookings');
                          },
                        ),
                      ];

                      if (isNarrow) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: pipelineCards.map((c) => SizedBox(width: (constraints.maxWidth - 16) / 2, child: c)).toList(),
                        );
                      }

                      return Row(
                        children: pipelineCards.map((c) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: c == pipelineCards.last ? 0 : 8),
                              child: c,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),

          // Section Heading
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Executive Operations Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate900,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Real-time live caregiver dispatches, revenue tracking, and medical inventory across Sri Lanka.',
                style: TextStyle(fontSize: 11, color: AppTheme.slate500),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4 Key KPI Metric Cards (Compact Single Row)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;

              final cards = [
                StatCard(
                  title: 'Gross Revenue',
                  value: 'LKR ${currency.format(provider.totalRevenueLKR)}',
                  icon: Icons.payments_rounded,
                  iconColor: AppTheme.primaryBlue,
                  iconBgColor: AppTheme.blueLight,
                  badgeText: '+18.4%',
                  badgeColor: AppTheme.emerald500,
                  onTap: () {
                    provider.setSelectedNavIndex(8);
                    context.go('/reports');
                  },
                ),
                StatCard(
                  title: 'On Duty Caregivers',
                  value: '${provider.activeShiftsCount} Active',
                  icon: Icons.verified_user_rounded,
                  iconColor: AppTheme.emerald500,
                  iconBgColor: AppTheme.emerald100,
                  badgeText: 'Cleared',
                  badgeColor: AppTheme.emerald500,
                  onTap: () {
                    provider.setSelectedBookingTab('in_progress');
                    provider.setSelectedNavIndex(1);
                    context.go('/bookings');
                  },
                ),
                StatCard(
                  title: 'Pending Dispatch',
                  value: '${provider.pendingDispatchesCount} Requests',
                  icon: Icons.assignment_late_rounded,
                  iconColor: AppTheme.amber500,
                  iconBgColor: AppTheme.amber100,
                  badgeText: 'Action',
                  badgeColor: AppTheme.amber800,
                  onTap: () {
                    provider.setSelectedBookingTab('pending_review');
                    provider.setSelectedNavIndex(1);
                    context.go('/bookings');
                  },
                ),
                StatCard(
                  title: 'Orders & Rentals',
                  value: '${provider.orders.length} Active',
                  icon: Icons.local_shipping_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  iconBgColor: const Color(0xFFF3E8FF),
                  badgeText: '${provider.activeRentalsCount} Rentals',
                  badgeColor: const Color(0xFF8B5CF6),
                  onTap: () {
                    provider.setSelectedNavIndex(5);
                    context.go('/orders');
                  },
                ),
              ];

              if (isNarrow) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cards.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(width: 180, child: c),
                      );
                    }).toList(),
                  ),
                );
              }

              return Row(
                children: cards.map((c) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: c == cards.last ? 0 : 8),
                      child: c,
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 10),

          // Weekly Realized Revenue & Shift Curve
          const WeeklyRevenueChart(),

          const SizedBox(height: 10),

          // Two Panels: Recent Live Dispatch Bookings & Quick Alerts
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 950;

              final leftTable = Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.slate200),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.flash_on_rounded, color: AppTheme.primaryBlue, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Live Dispatch & Caregiver Duties',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            provider.setSelectedBookingTab('all');
                            provider.setSelectedNavIndex(1);
                            context.go('/bookings');
                          },
                          child: const Text('View All Bookings →', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Table
                    if (provider.bookings.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.inbox_rounded, size: 36, color: AppTheme.slate400),
                            SizedBox(height: 8),
                            SelectableText('No Live Bookings Found', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                            SizedBox(height: 4),
                            SelectableText('New patient bookings submitted from the website will automatically appear here in real-time.', style: TextStyle(fontSize: 11, color: AppTheme.slate500)),
                          ],
                        ),
                      )
                    else
                      Scrollbar(
                        controller: _tableScrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _tableScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SelectionArea(
                            child: DataTable(
                              columnSpacing: 8,
                              horizontalMargin: 8,
                              headingRowHeight: 32,
                              dataRowMinHeight: 46,
                              dataRowMaxHeight: 68,
                              headingRowColor: WidgetStateProperty.all(AppTheme.slate50),
                              columns: const [
                                DataColumn(label: Text('CODE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                                DataColumn(label: Text('PATIENT & LOCATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                                DataColumn(label: Text('SERVICE & TIER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                                DataColumn(label: Text('ASSIGNED CAREGIVER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                                DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                              ],
                            rows: provider.bookings.map((b) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SelectableText(b.bookingCode, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.primaryBlue)),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SelectableText(b.patientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                        SelectableText('${b.city}, ${b.district}', style: const TextStyle(fontSize: 9.5, color: AppTheme.slate500)),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SelectableText(b.serviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                                        SelectableText(b.staffTierName, style: const TextStyle(fontSize: 9.5, color: AppTheme.primaryBlue)),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (b.assignedCaregiverName != null) ...[
                                          const Icon(Icons.check_circle_rounded, color: AppTheme.emerald500, size: 13),
                                          const SizedBox(width: 3),
                                          SelectableText(b.assignedCaregiverName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                        ] else ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: AppTheme.amber100, borderRadius: BorderRadius.circular(4)),
                                            child: const Text('Unassigned', style: TextStyle(fontSize: 9.5, color: AppTheme.amber800, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 16),
                                          tooltip: 'Assign or Change Caregiver',
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                          onPressed: () => _showAssignCaregiverDialog(context, b),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      initialValue: b.status,
                                      tooltip: 'Change Status',
                                      onSelected: (val) => provider.updateBookingStatus(b.id, val),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: b.status == 'in_progress'
                                              ? AppTheme.emerald100
                                              : b.status == 'caregiver_assigned'
                                                  ? AppTheme.blueLight
                                                  : b.status == 'completed'
                                                      ? AppTheme.slate100
                                                      : AppTheme.amber100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              b.status.toUpperCase().replaceAll('_', ' '),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: b.status == 'in_progress'
                                                    ? AppTheme.emerald800
                                                    : b.status == 'caregiver_assigned'
                                                        ? AppTheme.primaryBlue
                                                        : b.status == 'completed'
                                                            ? AppTheme.slate700
                                                            : AppTheme.amber800,
                                              ),
                                            ),
                                            const Icon(Icons.arrow_drop_down, size: 13),
                                          ],
                                        ),
                                      ),
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'pending_review',
                                          child: Text('Pending Review', style: TextStyle(fontSize: 11)),
                                        ),
                                        const PopupMenuItem(
                                          value: 'caregiver_assigned',
                                          child: Text('Caregiver Assigned', style: TextStyle(fontSize: 11)),
                                        ),
                                        const PopupMenuItem(
                                          value: 'in_progress',
                                          child: Text('On Duty', style: TextStyle(fontSize: 11)),
                                        ),
                                        const PopupMenuItem(
                                          value: 'completed',
                                          child: Text('Completed', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
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
                                          icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.slate600, size: 16),
                                          tooltip: 'View Official Invoice',
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              );

              final rightCards = Column(
                children: [
                  // Active Hospital Bed & Equipment Rentals Tracker Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                                Icon(Icons.bed_rounded, color: AppTheme.primaryBlue, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Active Rentals (Beds/Air)',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.slate900),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => provider.setSelectedNavIndex(5),
                              child: const Text('View All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (provider.orders.where((o) => o.isRental).isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'No active equipment or bed rentals on hire.',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        else
                          ...provider.orders.where((o) => o.isRental).map((rental) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.slate50,
                              borderRadius: BorderRadius.circular(8),
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
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(color: AppTheme.blueLight, borderRadius: BorderRadius.circular(4)),
                                      child: Text(rental.orderCode, style: const TextStyle(fontSize: 9, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rental.items.first.itemName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: AppTheme.slate600),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text('Renewal: ${rental.rentalEndDate ?? "N/A"}', style: const TextStyle(fontSize: 9.5, color: AppTheme.slate500)),
                                    WhatsAppButton(
                                      phone: rental.customerPhone,
                                      message: 'Hello ${rental.customerName}, this is Prime Life Care. Your hospital equipment rental (${rental.orderCode}) renewal is scheduled for ${rental.rentalEndDate}. Please let us know if you wish to extend.',
                                      label: 'Remind',
                                      isCompact: true,
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
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: leftTable),
                    const SizedBox(width: 10),
                    Expanded(flex: 4, child: rightCards),
                  ],
                );
              }

              return Column(
                children: [
                  leftTable,
                  const SizedBox(height: 10),
                  rightCards,
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
  }
}
