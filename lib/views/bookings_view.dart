import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking_model.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_button.dart';
import '../widgets/invoice_dialog.dart';
import '../widgets/booking_queue_dispatch_dialog.dart';
import '../widgets/charts/shift_distribution_chart.dart';

class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  String _localSearchQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _localSearchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
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
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient: ${booking.patientName} (${booking.patientAge} Yrs, ${booking.patientGender})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Required: ${booking.serviceName} • Tier: ${booking.staffTierName}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                ),
                Text(
                  'Location: ${booking.city}, ${booking.district}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Qualified & Cleared Caregiver:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.slate700),
                ),
                const SizedBox(height: 8),
                if (availableCaregivers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    child: const Text(
                      'No caregivers registered yet. Register caregivers from the Caregiver App or Staff Directory.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 290),
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
                            child: Text(
                              cg.name.isNotEmpty ? cg.name.substring(0, 1) : 'C',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(cg.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              const SizedBox(width: 6),
                              if (cg.isPoliceVerified)
                                const Icon(Icons.verified_rounded, size: 14, color: AppTheme.emerald500),
                            ],
                          ),
                          subtitle: Text(
                            '${cg.tierLabel} • ${cg.district} • Rating: ${cg.rating}★',
                            style: const TextStyle(fontSize: 10, color: AppTheme.slate500),
                          ),
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
                                SnackBar(
                                  backgroundColor: AppTheme.emerald800,
                                  content: Text('${cg.name} assigned to ${booking.patientName}! Updated in real-time.'),
                                ),
                              );
                            },
                            child: Text(
                              isCurrent ? 'Assigned' : 'Assign',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
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
            if (booking.assignedCaregiverId != null)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppTheme.rose500),
                icon: const Icon(Icons.person_remove_rounded, size: 16),
                label: const Text('Unassign Caregiver'),
                onPressed: () {
                  provider.unassignCaregiver(booking.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.rose500,
                      content: Text('Caregiver unassigned from ${booking.patientName}.'),
                    ),
                  );
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showStatusChangeConfirmDialog(
    BuildContext context,
    BookingModel booking,
    String newStatus, {
    VoidCallback? onConfirmed,
  }) {
    final provider = context.read<AdminProvider>();
    final newLabel = newStatus.toUpperCase().replaceAll('_', ' ');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirm Status Transition',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to transition booking ${booking.bookingCode}?',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.slate700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Status', style: TextStyle(fontSize: 10, color: AppTheme.slate500)),
                              const SizedBox(height: 4),
                              _buildStatusBadge(booking.status),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryBlue, size: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('New Target Status', style: TextStyle(fontSize: 10, color: AppTheme.slate500)),
                              const SizedBox(height: 4),
                              _buildStatusBadge(newStatus),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppTheme.slate200),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 14, color: AppTheme.slate500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Patient: ${booking.patientName} (${booking.city}, ${booking.district})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.slate600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                provider.updateBookingStatus(booking.id, newStatus);
                Navigator.pop(ctx);
                onConfirmed?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.emerald800,
                    content: Text('Booking ${booking.bookingCode} updated to $newLabel in real-time.'),
                  ),
                );
              },
              child: const Text('Confirm Transition', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, BookingModel booking) {
    final provider = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.rose100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: AppTheme.rose500, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Confirm Delete Booking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                    Text(booking.bookingCode, style: const TextStyle(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this booking for ${booking.patientName}?',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.slate800),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Patient: ${booking.patientName} (${booking.patientAge} Yrs, ${booking.patientGender})', style: const TextStyle(fontSize: 11.5, color: AppTheme.slate700)),
                      const SizedBox(height: 3),
                      Text('• Service: ${booking.serviceName} (${booking.staffTierName})', style: const TextStyle(fontSize: 11.5, color: AppTheme.slate700)),
                      const SizedBox(height: 3),
                      Text('• Family Contact: ${booking.contactName} (${booking.contactPhone})', style: const TextStyle(fontSize: 11.5, color: AppTheme.slate700)),
                      const SizedBox(height: 3),
                      Text('• Total Commitment: LKR ${NumberFormat("#,##0").format(booking.totalCostLKR)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.history_rounded, size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '7-Day Retention Notice: This booking will be archived in Deleted History for 7 days. You can restore it at any time. After 7 days, it will be automatically and permanently purged from the cloud.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.slate600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rose500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Delete (Move to History)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                provider.deleteBooking(booking.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.slate900,
                    duration: const Duration(seconds: 5),
                    content: Text('Booking ${booking.bookingCode} moved to Deleted History (7-day retention).'),
                    action: SnackBarAction(
                      label: 'View History',
                      textColor: const Color(0xFF60A5FA),
                      onPressed: () => _showDeletedHistoryDialog(context),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeletedHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<AdminProvider>(
          builder: (dialogCtx, provider, _) {
            final deletedList = provider.deletedBookings;
            final currency = NumberFormat('#,##0', 'en_US');
            final now = DateTime.now();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.rose100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_delete_rounded, color: AppTheme.rose500, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deleted Bookings History',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                        ),
                        Text(
                          '${deletedList.length} Archived • 7-Day Auto-Purge Cloud Retention',
                          style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: deletedList.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete_outline_rounded, size: 40, color: AppTheme.slate400),
                            SizedBox(height: 10),
                            Text(
                              'No Deleted Bookings in History',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.slate700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'When bookings are deleted, they are held here for 7 days before being automatically purged.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: AppTheme.slate500),
                            ),
                          ],
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: deletedList.length,
                          itemBuilder: (itemCtx, idx) {
                            final item = deletedList[idx];
                            final bookingCode = (item['bookingCode'] ?? item['id'] ?? 'N/A').toString();
                            final patientName = (item['patientName'] ?? 'Unknown Patient').toString();
                            final serviceName = (item['serviceName'] ?? 'Care Service').toString();
                            final totalCost = (item['totalCostLKR'] as num?)?.toDouble() ?? 0.0;
                            final phone = (item['contactPhone'] ?? '').toString();
                            final deletedAtStr = (item['deletedAt'] ?? '').toString();

                            DateTime? deletedAt = deletedAtStr.isNotEmpty ? DateTime.tryParse(deletedAtStr) : null;
                            int daysLeft = 7;
                            if (deletedAt != null) {
                              final elapsedDays = now.difference(deletedAt).inDays;
                              daysLeft = 7 - elapsedDays;
                              if (daysLeft < 1) daysLeft = 1;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.slate50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.slate200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              bookingCode,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.primaryBlue),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFFFDE68A)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.timer_outlined, size: 11, color: Color(0xFFD97706)),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'Auto-purges in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Patient: $patientName • $serviceName',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.slate800),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Total: LKR ${currency.format(totalCost)} • Contact: $phone • Deleted: ${deletedAt != null ? DateFormat("d MMM yyyy, HH:mm").format(deletedAt) : "Recently"}',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.slate500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    icon: const Icon(Icons.restore_rounded, size: 14),
                                    label: const Text('Restore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      provider.restoreBooking(bookingCode);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppTheme.emerald800,
                                          content: Text('Booking $bookingCode restored to active dispatch list!'),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.rose500, size: 18),
                                    tooltip: 'Delete Permanently Now',
                                    onPressed: () {
                                      provider.purgeBookingPermanently(bookingCode);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppTheme.slate900,
                                          content: Text('Booking $bookingCode permanently purged.'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExtendBookingDialog(BuildContext context, BookingModel booking, VoidCallback onUpdated) {
    int additionalDays = 7;
    final currency = NumberFormat('#,##0', 'en_US');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setExtendState) {
            final additionalCustFee = additionalDays * booking.pricePerDayLKR;
            final additionalStaffPay = additionalDays * booking.staffDailyPayoutLKR;
            final newTotalDays = booking.durationDays + additionalDays;
            final newTotalCost = booking.pricePerDayLKR * newTotalDays;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_alarm_rounded, color: AppTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Extend Care Duty Contract',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extend duty duration for ${booking.patientName} (${booking.bookingCode}). Customer invoice and caregiver payout will be recalculated automatically.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                    ),
                    const SizedBox(height: 14),
                    const Text('Select Additional Days:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [3, 7, 14, 28].map((days) {
                        final isSelected = additionalDays == days;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              label: Text('+$days Days', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryBlue,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.slate700),
                              onSelected: (val) {
                                if (val) setExtendState(() => additionalDays = days);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.slate50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('New Total Duration:', style: TextStyle(fontSize: 11, color: AppTheme.slate600)),
                              Text('${booking.durationDays} + $additionalDays = $newTotalDays Days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Additional Customer Billing:', style: TextStyle(fontSize: 11, color: AppTheme.slate600)),
                              Text('+ LKR ${currency.format(additionalCustFee)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Additional Staff Payout (80%):', style: TextStyle(fontSize: 11, color: AppTheme.slate600)),
                              Text('+ LKR ${currency.format(additionalStaffPay)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald600)),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Updated Contract:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              Text('LKR ${currency.format(newTotalCost)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text('Confirm +$additionalDays Days Extension'),
                  onPressed: () {
                    context.read<AdminProvider>().extendBookingDuration(booking.id, additionalDays);
                    Navigator.pop(dialogCtx);
                    onUpdated();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contract extended by $additionalDays days. New total: $newTotalDays days.'),
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEarlyDischargeDialog(BuildContext context, BookingModel booking, VoidCallback onUpdated) {
    int workedDays = booking.totalCompletedShifts > 0 ? booking.totalCompletedShifts : 1;
    final currency = NumberFormat('#,##0', 'en_US');
    final reasonController = TextEditingController(text: 'Family requested early discharge / patient recovered');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDischargeState) {
            final settledCustomerCost = workedDays * booking.pricePerDayLKR;
            final customerRefund = (booking.durationDays - workedDays) * booking.pricePerDayLKR;
            final settledStaffPayout = workedDays * booking.staffDailyPayoutLKR;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.amber100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppTheme.amber700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Early Discharge / Duty Termination',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discharge patient early and settle financial pro-rata. Caregiver will be freed immediately for other patient assignments.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Days Actually Worked:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          onPressed: workedDays > 1 ? () => setDischargeState(() => workedDays--) : null,
                        ),
                        Text('$workedDays of ${booking.durationDays} Days', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          onPressed: workedDays < booking.durationDays ? () => setDischargeState(() => workedDays++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason for Early Discharge',
                        labelStyle: const TextStyle(fontSize: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.amber50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.amber200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Settled Customer Billing:', style: TextStyle(fontSize: 11, color: AppTheme.slate700)),
                              Text('LKR ${currency.format(settledCustomerCost)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Customer Refund Amount:', style: TextStyle(fontSize: 11, color: AppTheme.slate700)),
                              Text('LKR ${currency.format(customerRefund)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.rose500)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Settled Staff Payout ($workedDays days):', style: const TextStyle(fontSize: 11, color: AppTheme.slate700)),
                              Text('LKR ${currency.format(settledStaffPayout)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amber700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Confirm Early Discharge & Settle'),
                  onPressed: () {
                    context.read<AdminProvider>().earlyDischargeBooking(
                      booking.id,
                      workedDays: workedDays,
                      reason: reasonController.text.trim(),
                    );
                    Navigator.pop(dialogCtx);
                    onUpdated();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Duty early discharged after $workedDays days. Caregiver freed for new assignments.'),
                        backgroundColor: AppTheme.emerald600,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCarePlanDialog(BuildContext context, BookingModel booking, VoidCallback onUpdated) {
    String bpFreq = booking.vitalsPlan?['bpFrequency']?.toString() ?? 'twice_daily';
    String sugarFreq = booking.vitalsPlan?['sugarFrequency']?.toString() ?? 'morning_fasting';
    int bedTurnHours = (booking.vitalsPlan?['bedTurnIntervalHours'] as num?)?.toInt() ?? 2;
    List<String> activeTasks = List<String>.from(booking.carePlanTasks);
    final customTaskController = TextEditingController();

    final availableTasks = [
      'BP & Pulse Monitoring',
      'Blood Glucose (Sugar) Test',
      '2-Hour Bed Repositioning (Bedsore Care)',
      'Medication Administration as per Prescription',
      'Catheter & Urine Output Bag Care',
      'Wound Dressing & Aseptic Care',
      'Ryles Tube / Feeding Tube Assistance',
      'Sponging, Bed Bath & Oral Hygiene',
      'Passive Limb Physiotherapy & Calming',
      'Fluid Intake & Output (I/O) Charting',
      'Fall Prevention & Safe Walking Assistance',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setPlanState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.monitor_heart_rounded, color: AppTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Configure Vitals & Bedside Care Routine',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set scheduled clinical monitoring and bedside care tasks for this patient. This routine syncs live to the caregiver\'s mobile app.',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.slate600),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.blueLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Service: ${booking.serviceName}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.auto_fix_high_rounded, size: 13, color: AppTheme.primaryBlue),
                              label: const Text('Apply Package Preset', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                              onPressed: () {
                                setPlanState(() {
                                  final s = booking.serviceName.toLowerCase();
                                  if (s.contains('surg')) {
                                    bpFreq = 'every_4_hours';
                                    sugarFreq = 'post_prandial';
                                    bedTurnHours = 2;
                                    activeTasks = [
                                      'BP & Pulse Monitoring',
                                      'Wound Dressing & Aseptic Care',
                                      'Medication Administration as per Prescription',
                                      'Catheter & Urine Output Bag Care',
                                      'Sponging, Bed Bath & Oral Hygiene',
                                    ];
                                  } else if (s.contains('bedridden') || s.contains('palliat')) {
                                    bpFreq = 'twice_daily';
                                    sugarFreq = 'morning_fasting';
                                    bedTurnHours = 2;
                                    activeTasks = [
                                      '2-Hour Bed Repositioning (Bedsore Care)',
                                      'Catheter & Urine Output Bag Care',
                                      'Ryles Tube / Feeding Tube Assistance',
                                      'Sponging, Bed Bath & Oral Hygiene',
                                      'Passive Limb Physiotherapy & Calming',
                                      'BP & Pulse Monitoring',
                                    ];
                                  } else {
                                    bpFreq = 'twice_daily';
                                    sugarFreq = 'morning_fasting';
                                    bedTurnHours = 2;
                                    activeTasks = [
                                      'BP & Pulse Monitoring',
                                      'Blood Glucose (Sugar) Test',
                                      'Medication Administration as per Prescription',
                                      'Sponging, Bed Bath & Oral Hygiene',
                                    ];
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Blood Pressure (BP) Frequency', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: bpFreq,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'twice_daily', child: Text('Twice Daily (Morning & Evening)', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'thrice_daily', child: Text('Thrice Daily (TDS)', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'every_4_hours', child: Text('Every 4 Hours (Critical)', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'once_daily', child: Text('Once Daily', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'as_needed', child: Text('As Needed (PRN)', style: TextStyle(fontSize: 11))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setPlanState(() => bpFreq = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Blood Glucose (Sugar) Test', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: sugarFreq,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'morning_fasting', child: Text('Morning Fasting (FBS)', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'pre_meals', child: Text('Pre-Meals (AC)', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'post_prandial', child: Text('Post-Prandial (PPBS)', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'twice_daily', child: Text('Twice Daily', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'none', child: Text('Not Required', style: TextStyle(fontSize: 11))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setPlanState(() => sugarFreq = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Bed Repositioning Interval (Bedsore Prevention): ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: bedTurnHours,
                            isDense: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 2, child: Text('Every 2 Hours (Standard Clinical Protocol)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
                              DropdownMenuItem(value: 3, child: Text('Every 3 Hours', style: TextStyle(fontSize: 11))),
                              DropdownMenuItem(value: 4, child: Text('Every 4 Hours', style: TextStyle(fontSize: 11))),
                              DropdownMenuItem(value: 0, child: Text('Patient is Fully Mobile (Not needed)', style: TextStyle(fontSize: 11))),
                            ],
                            onChanged: (val) {
                              if (val != null) setPlanState(() => bedTurnHours = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Mandatory Bedside Care Tasks:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: {...availableTasks, ...activeTasks}.map((task) {
                          final isChecked = activeTasks.contains(task);
                          return FilterChip(
                            label: Text(task, style: TextStyle(fontSize: 10.5, color: isChecked ? AppTheme.primaryBlue : AppTheme.slate700)),
                            selected: isChecked,
                            selectedColor: AppTheme.blueLight,
                            checkmarkColor: AppTheme.primaryBlue,
                            onSelected: (selected) {
                              setPlanState(() {
                                if (selected) {
                                  activeTasks.add(task);
                                } else {
                                  activeTasks.remove(task);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customTaskController,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Add custom bedside task (e.g. Insulin at 8 AM)...',
                                hintStyle: const TextStyle(fontSize: 11, color: AppTheme.slate400),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onSubmitted: (text) {
                                final trimmed = text.trim();
                                if (trimmed.isNotEmpty && !activeTasks.contains(trimmed)) {
                                  setPlanState(() {
                                    activeTasks.add(trimmed);
                                    customTaskController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Add Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final text = customTaskController.text.trim();
                              if (text.isNotEmpty && !activeTasks.contains(text)) {
                                setPlanState(() {
                                  activeTasks.add(text);
                                  customTaskController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Save Care & Vitals Plan'),
                  onPressed: () {
                    final vitalsPlan = {
                      'bpFrequency': bpFreq,
                      'sugarFrequency': sugarFreq,
                      'bedTurnIntervalHours': bedTurnHours,
                      'updatedAt': DateTime.now().toIso8601String(),
                      'updatedBy': 'Operations Admin',
                    };
                    context.read<AdminProvider>().updateCareAndVitalsPlan(
                      booking.id,
                      vitalsPlan: vitalsPlan,
                      carePlanTasks: activeTasks,
                    );
                    Navigator.pop(dialogCtx);
                    onUpdated();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vitals and Bedside Care Routine updated and synced to Caregiver App!'),
                        backgroundColor: AppTheme.emerald600,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBookingDetailsDialog(BuildContext context, BookingModel booking) {
    final currency = NumberFormat('#,##0', 'en_US');
    final provider = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final currentBooking = provider.bookings.firstWhere(
              (b) => b.id == booking.id || b.bookingCode == booking.bookingCode,
              orElse: () => booking,
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_ind_rounded, color: AppTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          'Booking Dossier • ${currentBooking.bookingCode}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                        ),
                        SelectableText(
                          'Registered: ${currentBooking.createdAt.isNotEmpty ? currentBooking.createdAt.split('T')[0] : "Recent"}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(currentBooking.status),
                ],
              ),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Section 1: Patient Medical Profile Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.slate200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.primaryBlue),
                                const SizedBox(width: 6),
                                const Text('Patient Medical Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.slate800)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: currentBooking.mobility == 'bedridden' ? AppTheme.rose100 : AppTheme.slate200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    currentBooking.mobility.toUpperCase().replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: currentBooking.mobility == 'bedridden' ? AppTheme.rose800 : AppTheme.slate700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: AppTheme.slate200),
                            Row(
                              children: [
                                Expanded(child: _infoItem('Patient Name', currentBooking.patientName)),
                                Expanded(child: _infoItem('Age & Gender', '${currentBooking.patientAge} Yrs • ${currentBooking.patientGender}')),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _infoItem('Medical Conditions & Clinical Notes', currentBooking.medicalConditions.isNotEmpty ? currentBooking.medicalConditions : 'None specified'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _infoItem('District & City', '${currentBooking.city}, ${currentBooking.district}')),
                                Expanded(child: _infoItem('Care Address', currentBooking.address.isNotEmpty ? currentBooking.address : 'Home residence')),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Section 2: Care Duty & Shift Details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.slate200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.medical_services_outlined, size: 16, color: AppTheme.primaryBlue),
                                SizedBox(width: 6),
                                Text('Service & Schedule Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.slate800)),
                              ],
                            ),
                            const Divider(height: 16, color: AppTheme.slate200),
                            Row(
                              children: [
                                Expanded(child: _infoItem('Service Category', currentBooking.serviceName)),
                                Expanded(child: _infoItem('Required Staff Tier', currentBooking.staffTierName)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _infoItem('Shift Configuration', '${currentBooking.shiftHours}h Shift (${currentBooking.shiftType})')),
                                Expanded(child: _infoItem('Duration & Start Date', '${currentBooking.durationDays} Days • Starts ${currentBooking.startDate}')),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _infoItem('Daily Rate', 'LKR ${currency.format(currentBooking.pricePerDayLKR)} / day')),
                                Expanded(child: _infoItem('Total Commitment', 'LKR ${currency.format(currentBooking.totalCostLKR)}', isBold: true, color: AppTheme.primaryBlue)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Section 3: Family Contact & Assigned Caregiver
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Family Contact
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.slate200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.phone_outlined, size: 15, color: AppTheme.primaryBlue),
                                      SizedBox(width: 6),
                                      Text('Family Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _infoItem('Contact Person', currentBooking.contactName),
                                  const SizedBox(height: 6),
                                  _infoItem('Phone Number', currentBooking.contactPhone),
                                  const SizedBox(height: 10),
                                  WhatsAppButton(
                                    phone: currentBooking.contactPhone,
                                    message: 'Hello ${currentBooking.contactName}, this is Prime Life Care regarding booking ${currentBooking.bookingCode} for ${currentBooking.patientName}.',
                                    label: 'WhatsApp Family',
                                    isCompact: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Caregiver
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: currentBooking.assignedCaregiverName != null ? AppTheme.blueLight.withOpacity(0.4) : AppTheme.rose100.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: currentBooking.assignedCaregiverName != null ? AppTheme.primaryBlue.withOpacity(0.3) : AppTheme.rose100,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        currentBooking.assignedCaregiverName != null ? Icons.verified_user_rounded : Icons.person_off_rounded,
                                        size: 15,
                                        color: currentBooking.assignedCaregiverName != null ? AppTheme.primaryBlue : AppTheme.rose500,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('Assigned Caregiver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                      if (currentBooking.hasCaregiverChangeRequest) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.rose500,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('CHANGE REQUESTED', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (currentBooking.hasCaregiverChangeRequest) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.rose100.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.rose500.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: AppTheme.rose500, size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Customer Requested Care Worker Change:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.rose500)),
                                                if (currentBooking.caregiverChangeCategory.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text('Reason: ${currentBooking.caregiverChangeCategory}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                                                ],
                                                Text('"${currentBooking.caregiverChangeReason}"', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.slate800)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  if (currentBooking.assignedCaregiverName != null) ...[
                                    _infoItem('Caregiver Name', currentBooking.assignedCaregiverName!),
                                    const SizedBox(height: 6),
                                    _infoItem('Caregiver Phone', currentBooking.assignedCaregiverPhone ?? 'Not on file'),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryBlue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                                          label: const Text('Change', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            Navigator.pop(dialogCtx);
                                            _showAssignCaregiverDialog(context, currentBooking);
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.rose500,
                                            side: BorderSide(color: AppTheme.rose500.withOpacity(0.4)),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          onPressed: () {
                                            provider.unassignCaregiver(currentBooking.id);
                                            setDialogState(() {});
                                          },
                                          child: const Text('Unassign', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const Text('No staff member assigned yet.', style: TextStyle(fontSize: 11, color: AppTheme.rose800)),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.person_add_rounded, size: 14),
                                      label: const Text('Assign Caregiver Now', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        Navigator.pop(dialogCtx);
                                        _showAssignCaregiverDialog(context, currentBooking);
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Section 4: Workflow Status & Payment Control
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.slate200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Status selector
                                const Text('Workflow Status: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                                const SizedBox(width: 6),
                                DropdownButton<String>(
                                  value: currentBooking.status,
                                  isDense: true,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'pending_review', child: Text('Pending Review')),
                                    DropdownMenuItem(value: 'caregiver_assigned', child: Text('Caregiver Assigned')),
                                    DropdownMenuItem(value: 'in_progress', child: Text('On Duty')),
                                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null && val != currentBooking.status) {
                                      _showStatusChangeConfirmDialog(
                                        context,
                                        currentBooking,
                                        val,
                                        onConfirmed: () => setDialogState(() {}),
                                      );
                                    }
                                  },
                                ),
                                const Spacer(),
                                // Payment Status selector
                                const Text('Payment: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                                const SizedBox(width: 6),
                                DropdownButton<String>(
                                  value: currentBooking.paymentStatus,
                                  isDense: true,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                                    DropdownMenuItem(value: 'advance_paid', child: Text('Advance Paid')),
                                    DropdownMenuItem(value: 'fully_paid', child: Text('Fully Paid')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      provider.updateBookingPaymentStatus(currentBooking.id, val);
                                      setDialogState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 12, color: AppTheme.slate200),
                            Row(
                              children: [
                                Icon(
                                  currentBooking.paymentMethod == 'bank_transfer' ? Icons.account_balance_rounded : Icons.payments_rounded,
                                  size: 14,
                                  color: currentBooking.paymentMethod == 'bank_transfer' ? AppTheme.primaryBlue : AppTheme.emerald600,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Payment Method: ${currentBooking.paymentMethod == 'bank_transfer' ? 'Direct Bank Transfer' : 'Cash to Caregiver on Duty'}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                                ),
                                if (currentBooking.advanceAmountLKR > 0) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.blueLight,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Advance: LKR ${currentBooking.advanceAmountLKR.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Section 5: Contract Management & Actions Toolbar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.blueLight.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.manage_history_rounded, size: 18, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            const Text(
                              'Contract Actions:',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.add_alarm_rounded, size: 14),
                              label: const Text('+ Extend Duty (+Days)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () => _showExtendBookingDialog(context, currentBooking, () => setDialogState(() {})),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.amber700,
                                side: BorderSide(color: AppTheme.amber700.withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 14),
                              label: const Text('Early Discharge / Settle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () => _showEarlyDischargeDialog(context, currentBooking, () => setDialogState(() {})),
                            ),
                          ],
                        ),
                      ),

                      if (currentBooking.earlyDischargeNote != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.amber50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.amber300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppTheme.amber700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentBooking.earlyDischargeNote!,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.amber900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Section 6: Prescribed Vitals & Bedside Care Routine
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.slate200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.monitor_heart_outlined, size: 16, color: AppTheme.primaryBlue),
                                const SizedBox(width: 6),
                                const Text('Prescribed Vitals & Bedside Care Routine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.slate800)),
                                const Spacer(),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: AppTheme.primaryBlue,
                                  ),
                                  icon: const Icon(Icons.edit_note_rounded, size: 15),
                                  label: const Text('Configure Routine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showEditCarePlanDialog(context, currentBooking, () => setDialogState(() {})),
                                ),
                              ],
                            ),
                            const Divider(height: 14, color: AppTheme.slate200),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoItem(
                                    'BP & Pulse Monitoring',
                                    (currentBooking.vitalsPlan?['bpFrequency']?.toString() ?? 'twice_daily').replaceAll('_', ' ').toUpperCase(),
                                  ),
                                ),
                                Expanded(
                                  child: _infoItem(
                                    'Blood Sugar Test (FBS/PPBS)',
                                    (currentBooking.vitalsPlan?['sugarFrequency']?.toString() ?? 'morning_fasting').replaceAll('_', ' ').toUpperCase(),
                                  ),
                                ),
                                Expanded(
                                  child: _infoItem(
                                    'Bed Repositioning Interval',
                                    'Every ${currentBooking.vitalsPlan?['bedTurnIntervalHours'] ?? 2} Hours',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Active Bedside Care Tasks:', style: TextStyle(fontSize: 10, color: AppTheme.slate500, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            if (currentBooking.carePlanTasks.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: currentBooking.carePlanTasks.map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blueLight,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                                  ),
                                  child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                                )).toList(),
                              )
                            else
                              const Text('Standard bedside care tasks assigned. Click "Configure Routine" to add specialized tasks.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.slate500)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Section 7: Daily Shift Attendance & Clinical Handover Dossier
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.slate200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history_toggle_off_rounded, size: 16, color: AppTheme.primaryBlue),
                                const SizedBox(width: 6),
                                const Text('Daily Shift Attendance & Handover Dossier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.slate800)),
                                const Spacer(),
                                if (currentBooking.isCaregiverCheckedIn)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emerald100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.emerald500),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.circle, color: AppTheme.emerald600, size: 8),
                                        SizedBox(width: 4),
                                        Text('Live On Shift Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emerald800)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.slate50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Contract Progress: ${currentBooking.totalCompletedShifts} of ${currentBooking.durationDays} Days Served',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700),
                                  ),
                                  Text(
                                    'Remaining: ${currentBooking.remainingDays} Days',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 16, color: AppTheme.slate200),
                            if (currentBooking.shifts.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: currentBooking.shifts.length,
                                separatorBuilder: (_, __) => const Divider(height: 12, color: AppTheme.slate100),
                                itemBuilder: (context, sIdx) {
                                  final s = currentBooking.shifts[sIdx];
                                  final dateStr = (s['date'] ?? s['clockInTime'] ?? 'Day ${sIdx + 1}').toString().split('T')[0];
                                  final inTime = (s['clockInTime'] ?? '').toString().split('T').length > 1 ? s['clockInTime'].toString().split('T')[1].substring(0, 5) : (s['clockInTime'] ?? '--');
                                  final outTime = (s['clockOutTime'] ?? '').toString().split('T').length > 1 ? s['clockOutTime'].toString().split('T')[1].substring(0, 5) : (s['clockOutTime'] ?? 'Active');
                                  final hours = s['hours']?.toString() ?? '12';
                                  final notes = s['handoverNotes']?.toString() ?? 'Shift completed and handover recorded.';
                                  final vitalsRecorded = s['vitalsCount'] ?? 0;

                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.slate50.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.slate200.withOpacity(0.6)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Shift #${sIdx + 1} • $dateStr',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate800),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'In: $inTime  |  Out: $outTime  (${hours}h)',
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Handover Notes: $notes',
                                          style: const TextStyle(fontSize: 10.5, color: AppTheme.slate700),
                                        ),
                                        if (vitalsRecorded > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '• $vitalsRecorded bedside vitals logged during this shift',
                                              style: const TextStyle(fontSize: 9.5, color: AppTheme.emerald600, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Column(
                                    children: const [
                                      Icon(Icons.access_time_rounded, size: 28, color: AppTheme.slate400),
                                      SizedBox(height: 6),
                                      Text(
                                        'No daily shifts logged yet.',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.slate600),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Once the caregiver clocks in & out daily via the Staff App, attendance records, hours, and bedside clinical handovers will appear here in real-time.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 10.5, color: AppTheme.slate500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppTheme.rose500),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete Booking'),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _showDeleteConfirmDialog(context, currentBooking);
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.slate700,
                    side: const BorderSide(color: AppTheme.slate200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('Print Invoice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    InvoiceDialog.show(context, currentBooking);
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoItem(String label, String value, {bool isBold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.slate500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppTheme.slate800,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, {BookingModel? booking}) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case 'in_progress':
      case 'on_duty':
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = booking?.assignedCaregiverName != null ? 'ON DUTY: ${booking!.assignedCaregiverName}' : 'ON DUTY';
        icon = Icons.assignment_turned_in_rounded;
        break;
      case 'caregiver_assigned':
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = booking?.assignedCaregiverName != null ? 'ASSIGNED: ${booking!.assignedCaregiverName}' : 'CAREGIVER ASSIGNED';
        icon = Icons.person_pin_circle_rounded;
        break;
      case 'broadcasted':
      case 'published_open':
        bg = const Color(0xFFFAF5FF);
        text = const Color(0xFF6B21A8);
        final qCount = booking?.candidateQueue.length ?? 0;
        label = 'RELEASED TO STAFF • $qCount/10 ACCEPTED';
        icon = Icons.broadcast_on_personal_rounded;
        break;
      case 'in_process':
      case 'under_review':
        bg = const Color(0xFFF0F9FF);
        text = const Color(0xFF0369A1);
        label = 'IN PROCESS (OPS HOLD)';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'completed':
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        label = 'COMPLETED';
        icon = Icons.task_alt_rounded;
        break;
      case 'pending_review':
      case 'new_web':
      default:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'NEW WEB BOOKING';
        icon = Icons.fiber_new_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: text),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String paymentStatus, VoidCallback onTap) {
    Color bg;
    Color text;
    String label;
    switch (paymentStatus) {
      case 'fully_paid':
        bg = AppTheme.emerald100;
        text = AppTheme.emerald800;
        label = 'PAID';
        break;
      case 'advance_paid':
        bg = AppTheme.blueLight;
        text = AppTheme.primaryBlue;
        label = 'ADVANCE';
        break;
      default:
        bg = AppTheme.amber100;
        text = AppTheme.amber800;
        label = 'UNPAID';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final currency = NumberFormat('#,##0', 'en_US');
    final selectedFilter = provider.selectedBookingTab;

    final allBookings = provider.bookings;
    final totalBookingsCount = allBookings.length;
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

    // Filter list by selected tab and search query
    final filteredList = allBookings.where((b) {
      if (selectedFilter == 'pending_review' && !b.isNewWeb) return false;
      if (selectedFilter == 'in_process' && !b.isInProcess) return false;
      if (selectedFilter == 'broadcasted' && !b.isBroadcasted) return false;
      if (selectedFilter == 'caregiver_assigned' && !b.isOnDuty) return false;
      if (selectedFilter == 'in_progress' && !b.isOnDuty) return false;
      if (selectedFilter == 'on_duty' && !b.isOnDuty) return false;
      if (selectedFilter == 'completed' && !b.isCompleted) return false;
      if (_localSearchQuery.isNotEmpty) {
        final q = _localSearchQuery;
        return b.patientName.toLowerCase().contains(q) ||
            b.bookingCode.toLowerCase().contains(q) ||
            b.city.toLowerCase().contains(q) ||
            b.district.toLowerCase().contains(q) ||
            b.contactName.toLowerCase().contains(q) ||
            b.contactPhone.toLowerCase().contains(q) ||
            b.serviceName.toLowerCase().contains(q) ||
            b.staffTierName.toLowerCase().contains(q) ||
            (b.assignedCaregiverName?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Real-time Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'All Bookings & Live Dispatch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.slate900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage each phase of patient care: Pending Review, Staff Assignment, On Duty monitoring, and Completion.',
                        style: TextStyle(fontSize: 11, color: AppTheme.slate500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: provider.isFirebaseConnected ? AppTheme.emerald500 : AppTheme.amber500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total: $totalBookingsCount Bookings',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate800),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Real-Time Shift Category Breakdown Chart
            const ShiftDistributionChart(),

            const SizedBox(height: 12),

            // Search Bar, Deleted History & Workflow Tabs Bar Card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Search Box, Result Counter & Deleted History Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.slate50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.slate200),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search by patient name, booking code, phone, district, or assigned caregiver...',
                              hintStyle: const TextStyle(color: AppTheme.slate400, fontSize: 11.5),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.slate400, size: 17),
                              suffixIcon: _localSearchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.slate400),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.blueLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Showing ${filteredList.length} of $totalBookingsCount',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // View Mode Toggle (Grid vs Table)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.slate100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.slate200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Grid View (Cards)',
                              child: InkWell(
                                onTap: () => setState(() => _isGridView = true),
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isGridView ? AppTheme.primaryBlue : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                  ),
                                  child: Icon(
                                    Icons.grid_view_rounded,
                                    size: 16,
                                    color: _isGridView ? Colors.white : AppTheme.slate600,
                                  ),
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Table View (Spreadsheet)',
                              child: InkWell(
                                onTap: () => setState(() => _isGridView = false),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: !_isGridView ? AppTheme.primaryBlue : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                  ),
                                  child: Icon(
                                    Icons.table_rows_rounded,
                                    size: 16,
                                    color: !_isGridView ? Colors.white : AppTheme.slate600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Deleted Bookings History Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.rose500,
                          side: BorderSide(color: AppTheme.rose500.withOpacity(0.35)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.auto_delete_rounded, size: 15, color: AppTheme.rose500),
                        label: Text(
                          'Deleted History (${provider.deletedBookings.length})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => _showDeletedHistoryDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 5 Workflow Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab(
                          id: 'all',
                          label: 'All Bookings',
                          count: totalBookingsCount,
                          isSelected: selectedFilter == 'all',
                          onTap: () => provider.setSelectedBookingTab('all'),
                          accentColor: AppTheme.slate800,
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          id: 'pending_review',
                          label: 'New Web (Unread)',
                          count: newWebCount,
                          isSelected: selectedFilter == 'pending_review',
                          onTap: () => provider.setSelectedBookingTab('pending_review'),
                          accentColor: const Color(0xFFB45309),
                          activeBgColor: const Color(0xFFFFFBEB),
                          badgeColor: const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          id: 'in_process',
                          label: 'In Process (Ops Hold)',
                          count: inProcessCount,
                          isSelected: selectedFilter == 'in_process',
                          onTap: () => provider.setSelectedBookingTab('in_process'),
                          accentColor: const Color(0xFF0369A1),
                          activeBgColor: const Color(0xFFF0F9FF),
                          badgeColor: const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          id: 'broadcasted',
                          label: totalCandidatesInQueues > 0 ? 'Released to Staff (⚡ $totalCandidatesInQueues Queued)' : 'Released to Staff',
                          count: broadcastedCount,
                          isSelected: selectedFilter == 'broadcasted',
                          onTap: () => provider.setSelectedBookingTab('broadcasted'),
                          accentColor: const Color(0xFF6B21A8),
                          activeBgColor: const Color(0xFFFAF5FF),
                          badgeColor: const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          id: 'on_duty',
                          label: 'On Duty Shifts',
                          count: onDutyCount,
                          isSelected: selectedFilter == 'on_duty' || selectedFilter == 'caregiver_assigned' || selectedFilter == 'in_progress',
                          onTap: () => provider.setSelectedBookingTab('on_duty'),
                          accentColor: const Color(0xFF047857),
                          activeBgColor: const Color(0xFFECFDF5),
                          badgeColor: const Color(0xFF059669),
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          id: 'completed',
                          label: 'Completed',
                          count: completedCount,
                          isSelected: selectedFilter == 'completed',
                          onTap: () => provider.setSelectedBookingTab('completed'),
                          accentColor: AppTheme.slate700,
                          activeBgColor: AppTheme.slate100,
                          badgeColor: AppTheme.slate600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Main Bookings View: Responsive Grid View (Default) or Data Table View
            if (_isGridView) ...[
              if (filteredList.isEmpty)
                _buildEmptyBookingsState(totalBookingsCount)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = 3;
                    if (width >= 1550) {
                      crossAxisCount = 4;
                    } else if (width >= 1100) {
                      crossAxisCount = 3;
                    } else if (width >= 680) {
                      crossAxisCount = 2;
                    } else {
                      crossAxisCount = 1;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 265,
                      ),
                      itemCount: filteredList.length,
                      itemBuilder: (context, idx) {
                        final b = filteredList[idx];
                        return _buildBookingGridCard(context, b, currency, provider);
                      },
                    );
                  },
                ),
            ] else ...[
              // Traditional Spreadsheet / Table View
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.slate200),
                ),
                padding: const EdgeInsets.all(8),
                child: filteredList.isEmpty
                    ? _buildEmptyBookingsState(totalBookingsCount)
                    : Scrollbar(
                        controller: _horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SelectionArea(
                          child: DataTable(
                            columnSpacing: 6,
                            horizontalMargin: 6,
                            headingRowHeight: 32,
                            dataRowMinHeight: 46,
                            dataRowMaxHeight: 66,
                            headingRowColor: WidgetStateProperty.all(AppTheme.slate50),
                            columns: const [
                              DataColumn(label: Text('CODE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: AppTheme.slate500))),
                              DataColumn(label: Text('PATIENT DETAILS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: AppTheme.slate500))),
                              DataColumn(label: Text('MOBILITY & MEDICAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: AppTheme.slate500))),
                              DataColumn(label: Text('SERVICE & SHIFT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: AppTheme.slate500))),
                              DataColumn(label: Text('ASSIGNED CAREGIVER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: AppTheme.slate500))),
                              DataColumn(label: Text('TOTAL & PAYMENT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: AppTheme.slate500))),
                              DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: AppTheme.slate500))),
                              DataColumn(label: Text('DISPATCH ACTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: AppTheme.slate500))),
                            ],
                            rows: filteredList.map((b) {
                              return DataRow(
                                cells: [
                                  // 1. Booking Code
                                  DataCell(
                                    TextButton.icon(
                                      onPressed: () => BookingQueueDispatchDialog.show(context, b),
                                      icon: const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.primaryBlue),
                                      label: Text(
                                        b.bookingCode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppTheme.primaryBlue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),

                                  // 2. Patient Details
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${b.patientName} (${b.patientAge} Yrs, ${b.patientGender})',
                                          maxLines: 1,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                                        ),
                                        Text(
                                          '${b.city}, ${b.district} • Ph: ${b.contactPhone}',
                                          maxLines: 1,
                                          style: const TextStyle(fontSize: 9.5, color: AppTheme.slate500),
                                        ),
                                        if (b.hasLocation) ...[
                                          const SizedBox(height: 2),
                                          InkWell(
                                            onTap: () => launchUrl(Uri.parse(b.effectiveMapsUrl)),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.location_on_rounded, size: 10, color: Color(0xFF2563EB)),
                                                  SizedBox(width: 2.5),
                                                  Text(
                                                    'Google Maps ↗',
                                                    style: TextStyle(
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF1D4ED8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    onTap: () => BookingQueueDispatchDialog.show(context, b),
                                  ),

                                  // 3. Mobility & Medical
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: b.mobility == 'bedridden' ? AppTheme.rose100 : AppTheme.slate100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            b.mobility.toUpperCase().replaceAll('_', ' '),
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                              color: b.mobility == 'bedridden' ? AppTheme.rose800 : AppTheme.slate700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        SelectableText(
                                          b.medicalConditions,
                                          maxLines: 1,
                                          style: const TextStyle(fontSize: 9.5, color: AppTheme.slate600),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 4. Service & Shift
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SelectableText(
                                          b.serviceName,
                                          maxLines: 1,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                        ),
                                        SelectableText(
                                          '${b.staffTierName} • ${b.shiftHours}h (${b.durationDays} Days)',
                                          maxLines: 1,
                                          style: const TextStyle(fontSize: 9.5, color: AppTheme.primaryBlue),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 5. Assigned Caregiver
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (b.assignedCaregiverName != null) ...[
                                          const Icon(Icons.check_circle_rounded, color: AppTheme.emerald500, size: 13),
                                          const SizedBox(width: 3),
                                          SelectableText(
                                            b.assignedCaregiverName!,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5),
                                          ),
                                        ] else ...[
                                          const Text(
                                            'Not Assigned',
                                            style: TextStyle(fontSize: 10.5, color: AppTheme.rose500, fontWeight: FontWeight.bold),
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

                                  // 6. Total Cost & Payment Status
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SelectableText(
                                          'Client: LKR ${currency.format(b.totalCostLKR)}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate900),
                                        ),
                                        const SizedBox(height: 1.5),
                                        SelectableText(
                                          'Staff: LKR ${currency.format(b.staffTotalPayoutLKR)}',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFF0D9488)),
                                        ),
                                        const SizedBox(height: 2),
                                        _buildPaymentBadge(
                                          b.paymentStatus,
                                          () {
                                            // Quick cycle payment status
                                            final nextStatus = b.paymentStatus == 'unpaid'
                                                ? 'advance_paid'
                                                : (b.paymentStatus == 'advance_paid' ? 'fully_paid' : 'unpaid');
                                            provider.updateBookingPaymentStatus(b.id, nextStatus);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 7. Status dropdown with Confirmation Dialog
                                  DataCell(
                                    PopupMenuButton<String>(
                                      initialValue: b.status,
                                      tooltip: 'Change Workflow Status',
                                      onSelected: (val) {
                                        if (val != b.status) {
                                          _showStatusChangeConfirmDialog(context, b, val);
                                        }
                                      },
                                      child: _buildStatusBadge(b.status, booking: b),
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'pending_review', child: Text('Pending Review / New Web', style: TextStyle(fontSize: 11))),
                                        const PopupMenuItem(value: 'in_process', child: Text('In Process (Ops Hold)', style: TextStyle(fontSize: 11))),
                                        const PopupMenuItem(value: 'broadcasted', child: Text('Released to Staff Apps', style: TextStyle(fontSize: 11))),
                                        const PopupMenuItem(value: 'caregiver_assigned', child: Text('Caregiver Assigned', style: TextStyle(fontSize: 11))),
                                        const PopupMenuItem(value: 'in_progress', child: Text('On Duty', style: TextStyle(fontSize: 11))),
                                        const PopupMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(fontSize: 11))),
                                      ],
                                    ),
                                  ),

                                  // 8. Dispatch Actions
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Quick Workflow Stage Action
                                        if (b.isNewWeb) ...[
                                          Tooltip(
                                            message: 'Accept booking & notify customer (Hold for Ops)',
                                            child: InkWell(
                                              onTap: () => provider.markBookingInProcess(b.id),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFF59E0B)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFFB45309)),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Accept Ops',
                                                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ] else if (b.isInProcess) ...[
                                          Tooltip(
                                            message: 'Release booking to staff mobile apps',
                                            child: InkWell(
                                              onTap: () => provider.broadcastBookingToStaff(b.id),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFAF5FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFA855F7)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.cell_tower_rounded, size: 12, color: Color(0xFF7E22CE)),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Release to App',
                                                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF6B21A8)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ] else if (b.isBroadcasted) ...[
                                          Tooltip(
                                            message: 'Open Live Applicant Queue & Dispatch Caregiver',
                                            child: InkWell(
                                              onTap: () => BookingQueueDispatchDialog.show(context, b),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFAF5FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFA855F7)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFF7E22CE)),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'Queue (${b.candidateQueue.length}/10)',
                                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF6B21A8)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],

                                        // 8A. WhatsApp Family Button (Green Pill)
                                        Tooltip(
                                          message: 'WhatsApp Family: ${b.contactName} (${b.contactPhone})',
                                          child: InkWell(
                                            onTap: () => WhatsAppHelper.launchWhatsApp(
                                              context,
                                              b.contactPhone,
                                              'Hello ${b.contactName}, this is Prime Life Care. Your booking ${b.bookingCode} for ${b.patientName} is confirmed with caregiver ${b.assignedCaregiverName ?? "assigned staff"}. Contact: ${b.assignedCaregiverPhone ?? "+94 11 234 5678"}.',
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFF22C55E)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.chat_bubble_rounded, size: 11.5, color: Color(0xFF16A34A)),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Family',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF15803D),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),

                                        // 8B. WhatsApp Staff Dispatch Button (Sky Blue Pill)
                                        if (b.assignedCaregiverPhone != null)
                                          Tooltip(
                                            message: 'Dispatch Staff WhatsApp: ${b.assignedCaregiverName} (${b.assignedCaregiverPhone})',
                                            child: InkWell(
                                              onTap: () => WhatsAppHelper.launchWhatsApp(
                                                context,
                                                b.assignedCaregiverPhone!,
                                                'Duty Dispatch Prime Life Care: Patient ${b.patientName} (${b.patientAge}y), Address: ${b.address}, ${b.city}. Start: ${b.startDate}. Family: ${b.contactName} (${b.contactPhone}).',
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0F2FE),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFF0284C7)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.badge_rounded, size: 12, color: Color(0xFF0284C7)),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Staff',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Color(0xFF0369A1),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Tooltip(
                                            message: 'No Caregiver Assigned Yet',
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: AppTheme.slate100,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppTheme.slate200),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.badge_outlined, size: 12, color: AppTheme.slate400),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Staff',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.slate400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 4),

                                        // 8C. Live Queue / Broadcast Dispatch Button
                                        IconButton(
                                          icon: Icon(
                                            b.status == 'broadcasted' ? Icons.format_list_numbered_rounded : Icons.cell_tower_rounded,
                                            color: b.status == 'broadcasted' ? Colors.amber.shade800 : AppTheme.primaryBlue,
                                            size: 17,
                                          ),
                                          tooltip: b.status == 'broadcasted'
                                              ? 'Live Candidate Queue (${b.candidateQueue.length}/${b.maxCandidates})'
                                              : 'Broadcast / Dispatch Queue',
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          onPressed: () => BookingQueueDispatchDialog.show(context, b),
                                        ),
                                        const SizedBox(width: 2),

                                        // Receipt Dialog Button
                                        IconButton(
                                          icon: const Icon(Icons.receipt_rounded, color: AppTheme.slate700, size: 16),
                                          tooltip: 'Print Invoice Receipt',
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          onPressed: () => InvoiceDialog.show(context, b),
                                        ),
                                        const SizedBox(width: 2),

                                        // Full Dossier Dialog Button
                                        IconButton(
                                          icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: 16),
                                          tooltip: 'View Full Dossier',
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          onPressed: () => _showBookingDetailsDialog(context, b),
                                        ),
                                        const SizedBox(width: 2),

                                        // Delete Booking Button (with Confirmation)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.rose500, size: 16),
                                          tooltip: 'Delete Booking (7-Day Cloud Retention)',
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.all(2),
                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          onPressed: () => _showDeleteConfirmDialog(context, b),
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBookingsState(int totalBookingsCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.slate100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, size: 40, color: AppTheme.slate400),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Bookings Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate800),
          ),
          const SizedBox(height: 6),
          Text(
            totalBookingsCount == 0
                ? 'No bookings have been recorded in the system yet.'
                : 'No bookings match your current filter, status tab, or search criteria.',
            style: const TextStyle(fontSize: 13, color: AppTheme.slate500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingGridCard(
    BuildContext context,
    BookingModel b,
    NumberFormat currency,
    AdminProvider provider,
  ) {
    Color statusAccentColor;
    if (b.isNewWeb) {
      statusAccentColor = Colors.amber.shade600;
    } else if (b.isInProcess) {
      statusAccentColor = const Color(0xFF2563EB);
    } else if (b.isBroadcasted) {
      statusAccentColor = const Color(0xFF9333EA);
    } else if (b.isOnDuty) {
      statusAccentColor = const Color(0xFF059669);
    } else if (b.isCompleted) {
      statusAccentColor = AppTheme.slate500;
    } else {
      statusAccentColor = AppTheme.primaryBlue;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: b.hasCaregiverChangeRequest ? AppTheme.rose200 : AppTheme.slate200,
          width: b.hasCaregiverChangeRequest ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top status accent stripe
            Container(
              height: 3,
              color: b.hasCaregiverChangeRequest ? AppTheme.rose500 : statusAccentColor,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Header Row: Booking Code, NEW tag, Payment Status, Status Badge Dropdown
                    Row(
                      children: [
                        InkWell(
                          onTap: () => BookingQueueDispatchDialog.show(context, b),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                b.bookingCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppTheme.primaryBlue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.open_in_new_rounded, size: 11, color: AppTheme.primaryBlue),
                            ],
                          ),
                        ),
                        if (b.isNewWeb) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                        const Spacer(),
                        _buildPaymentBadge(
                          b.paymentStatus,
                          () {
                            final nextStatus = b.paymentStatus == 'unpaid'
                                ? 'advance_paid'
                                : (b.paymentStatus == 'advance_paid' ? 'fully_paid' : 'unpaid');
                            provider.updateBookingPaymentStatus(b.id, nextStatus);
                          },
                        ),
                        const SizedBox(width: 5),
                        PopupMenuButton<String>(
                          initialValue: b.status,
                          tooltip: 'Change Workflow Status',
                          onSelected: (val) {
                            if (val != b.status) {
                              _showStatusChangeConfirmDialog(context, b, val);
                            }
                          },
                          child: _buildStatusBadge(b.status, booking: b),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'pending_review', child: Text('Pending Review / New Web', style: TextStyle(fontSize: 11))),
                            PopupMenuItem(value: 'in_process', child: Text('In Process (Ops Hold)', style: TextStyle(fontSize: 11))),
                            PopupMenuItem(value: 'broadcasted', child: Text('Released to Staff Apps', style: TextStyle(fontSize: 11))),
                            PopupMenuItem(value: 'caregiver_assigned', child: Text('Caregiver Assigned', style: TextStyle(fontSize: 11))),
                            PopupMenuItem(value: 'in_progress', child: Text('On Duty', style: TextStyle(fontSize: 11))),
                            PopupMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(fontSize: 11))),
                          ],
                        ),
                      ],
                    ),

                    // 2. Patient Details & Mobility Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppTheme.slate100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.slate600),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      b.patientName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.slate900),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${b.patientAge}y, ${b.patientGender})',
                                    style: const TextStyle(fontSize: 9.5, color: AppTheme.slate500, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: b.mobility == 'bedridden' ? AppTheme.rose100 : AppTheme.slate100,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      b.mobility.toUpperCase().replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.bold,
                                        color: b.mobility == 'bedridden' ? AppTheme.rose800 : AppTheme.slate700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1.5),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 10, color: AppTheme.slate400),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      '${b.city}, ${b.district} • Ph: ${b.contactPhone}',
                                      style: const TextStyle(fontSize: 9.5, color: AppTheme.slate600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (b.hasLocation) ...[
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => launchUrl(Uri.parse(b.effectiveMapsUrl)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(3),
                                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.map_rounded, size: 8.5, color: Color(0xFF2563EB)),
                                            SizedBox(width: 2),
                                            Text(
                                              'Maps',
                                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 3. Compact Integrated Service & Assigned Caregiver Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.slate200.withOpacity(0.8)),
                      ),
                      child: Row(
                        children: [
                          // Service & Duration
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.serviceName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5, color: AppTheme.slate800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1.5),
                                Text(
                                  '${b.staffTierName} • ${b.shiftHours}h • ${b.durationDays}d (${b.remainingDays}d left)',
                                  style: const TextStyle(fontSize: 9, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 24, color: AppTheme.slate200),
                          const SizedBox(width: 7),
                          // Caregiver & Duty Beacon
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        b.assignedCaregiverName ?? 'No Caregiver',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          color: b.assignedCaregiverName != null ? const Color(0xFF14532D) : AppTheme.rose800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1.5),
                                      if (b.assignedCaregiverName != null)
                                        Row(
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: b.isCaregiverCheckedIn ? const Color(0xFF16A34A) : Colors.amber.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              b.isCaregiverCheckedIn ? 'On Duty' : 'Awaiting Check-in',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                color: b.isCaregiverCheckedIn ? const Color(0xFF15803D) : Colors.amber.shade900,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        const Text('Assign staff', style: TextStyle(fontSize: 8.5, color: AppTheme.rose500)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppTheme.primaryBlue),
                                  tooltip: 'Assign or Change Caregiver',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                  onPressed: () => _showAssignCaregiverDialog(context, b),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 4. Caregiver Replacement Alert Banner (If Requested)
                    if (b.hasCaregiverChangeRequest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFFFDA4AF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.rose600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Change Req: ${b.caregiverChangeReason.isNotEmpty ? b.caregiverChangeReason : b.caregiverChangeCategory}',
                                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF9F1239)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 5. Financials Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Client: LKR ${currency.format(b.totalCostLKR)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate900),
                        ),
                        Text(
                          'Staff: LKR ${currency.format(b.staffTotalPayoutLKR)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 9.5, color: Color(0xFF0D9488)),
                        ),
                      ],
                    ),

                    const Divider(height: 1, thickness: 1, color: AppTheme.slate200),

                    // 6. Compact Operational Actions Bar
                    Row(
                      children: [
                        // Primary Workflow Action
                        if (b.isNewWeb) ...[
                          Expanded(
                            child: SizedBox(
                              height: 27,
                              child: ElevatedButton.icon(
                                onPressed: () => provider.markBookingInProcess(b.id),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 11),
                                label: const Text('Accept Ops', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF3C7),
                                  foregroundColor: const Color(0xFF92400E),
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFFF59E0B)),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                        ] else if (b.isInProcess) ...[
                          Expanded(
                            child: SizedBox(
                              height: 27,
                              child: ElevatedButton.icon(
                                onPressed: () => provider.broadcastBookingToStaff(b.id),
                                icon: const Icon(Icons.cell_tower_rounded, size: 11),
                                label: const Text('Release', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFAF5FF),
                                  foregroundColor: const Color(0xFF6B21A8),
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFFA855F7)),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                        ] else if (b.isBroadcasted) ...[
                          Expanded(
                            child: SizedBox(
                              height: 27,
                              child: ElevatedButton.icon(
                                onPressed: () => BookingQueueDispatchDialog.show(context, b),
                                icon: const Icon(Icons.flash_on_rounded, size: 11),
                                label: Text('Queue (${b.candidateQueue.length}/${b.maxCandidates})', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFAF5FF),
                                  foregroundColor: const Color(0xFF6B21A8),
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFFA855F7)),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: SizedBox(
                              height: 27,
                              child: OutlinedButton.icon(
                                onPressed: () => BookingQueueDispatchDialog.show(context, b),
                                icon: const Icon(Icons.visibility_rounded, size: 11),
                                label: const Text('Queue / Care', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  side: const BorderSide(color: AppTheme.primaryBlue),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),

                        // WhatsApp Family Button
                        Tooltip(
                          message: 'WhatsApp Family (${b.contactPhone})',
                          child: InkWell(
                            onTap: () => WhatsAppHelper.launchWhatsApp(
                              context,
                              b.contactPhone,
                              'Hello ${b.contactName}, this is Prime Life Care. Your booking ${b.bookingCode} for ${b.patientName} is confirmed with caregiver ${b.assignedCaregiverName ?? "assigned staff"}. Contact: ${b.assignedCaregiverPhone ?? "+94 11 234 5678"}.',
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 27,
                              height: 27,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF22C55E)),
                              ),
                              child: const Center(child: Icon(Icons.chat_bubble_rounded, size: 12, color: Color(0xFF16A34A))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),

                        // WhatsApp Staff Button
                        if (b.assignedCaregiverPhone != null) ...[
                          Tooltip(
                            message: 'WhatsApp Staff (${b.assignedCaregiverPhone})',
                            child: InkWell(
                              onTap: () => WhatsAppHelper.launchWhatsApp(
                                context,
                                b.assignedCaregiverPhone!,
                                'Duty Dispatch Prime Life Care: Patient ${b.patientName} (${b.patientAge}y), Address: ${b.address}, ${b.city}. Start: ${b.startDate}. Family: ${b.contactName} (${b.contactPhone}).',
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 27,
                                height: 27,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF0284C7)),
                                ),
                                child: const Center(child: Icon(Icons.badge_rounded, size: 12, color: Color(0xFF0284C7))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                        ],

                        // Invoice Receipt Button
                        IconButton(
                          icon: const Icon(Icons.receipt_rounded, color: AppTheme.slate700, size: 15),
                          tooltip: 'Print Invoice',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
                          onPressed: () => InvoiceDialog.show(context, b),
                        ),

                        // Full Dossier Button
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: 15),
                          tooltip: 'Full Dossier',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
                          onPressed: () => _showBookingDetailsDialog(context, b),
                        ),

                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.rose500, size: 15),
                          tooltip: 'Delete Booking',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
                          onPressed: () => _showDeleteConfirmDialog(context, b),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String id,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    Color? activeBgColor,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (activeBgColor ?? AppTheme.slate900) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.slate200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (activeBgColor != null ? accentColor : Colors.white) : AppTheme.slate700,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? (badgeColor ?? accentColor) : AppTheme.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.slate600,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
