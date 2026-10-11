import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_button.dart';
import '../widgets/invoice_dialog.dart';

class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  String _selectedFilter = 'all';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final currency = NumberFormat('#,##0', 'en_US');

    final filteredList = provider.bookings.filter((b) {
      if (_selectedFilter != 'all' && b.status != _selectedFilter) return false;
      if (provider.searchQuery.isNotEmpty) {
        final q = provider.searchQuery.toLowerCase();
        return b.patientName.toLowerCase().contains(q) ||
            b.bookingCode.toLowerCase().contains(q) ||
            b.city.toLowerCase().contains(q) ||
            b.district.toLowerCase().contains(q) ||
            b.contactName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Caregiver Bookings & Live Dispatch',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.slate900, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Supervise requested elder & child care duties, verify patient mobility, and assign cleared NVQ staff.',
                    style: TextStyle(fontSize: 13, color: AppTheme.slate500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Total: ${provider.bookings.length} Bookings',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.slate700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Filter Tabs
          Row(
            children: [
              _buildFilterChip('all', 'All Bookings (${provider.bookings.length})'),
              const SizedBox(width: 8),
              _buildFilterChip('pending_review', 'Pending Dispatch (${provider.pendingDispatchesCount})'),
              const SizedBox(width: 8),
              _buildFilterChip('caregiver_assigned', 'Caregiver Assigned'),
              const SizedBox(width: 8),
              _buildFilterChip('in_progress', 'On Duty (Active)'),
              const SizedBox(width: 8),
              _buildFilterChip('completed', 'Completed'),
            ],
          ),

          const SizedBox(height: 20),

          // Main Bookings Table Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.slate200),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 22,
                headingRowColor: WidgetStateProperty.all(AppTheme.slate50),
                columns: const [
                  DataColumn(label: Text('CODE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                  DataColumn(label: Text('PATIENT DETAILS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                  DataColumn(label: Text('MOBILITY & MEDICAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                  DataColumn(label: Text('SERVICE & SHIFT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                  DataColumn(label: Text('ASSIGNED CAREGIVER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                  DataColumn(label: Text('TOTAL (LKR)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                  DataColumn(label: Text('DISPATCH ACTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.slate500))),
                ],
                rows: filteredList.map((b) {
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
                            Text('${b.patientName} (${b.patientAge} Yrs, ${b.patientGender})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            Text('${b.city}, ${b.district} • Contact: ${b.contactPhone}', style: const TextStyle(fontSize: 10, color: AppTheme.slate500)),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: b.mobility == 'bedridden' ? AppTheme.rose100 : AppTheme.slate100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                b.mobility.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: b.mobility == 'bedridden' ? AppTheme.rose800 : AppTheme.slate700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(b.medicalConditions, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppTheme.slate600)),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(b.serviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text('${b.staffTierName} • ${b.shiftHours}h Shift (${b.durationDays} Days)', style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue)),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            if (b.assignedCaregiverName != null) ...[
                              const Icon(Icons.check_circle_rounded, color: AppTheme.emerald500, size: 14),
                              const SizedBox(width: 4),
                              Text(b.assignedCaregiverName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                            ] else ...[
                              const Text('Not Assigned', style: TextStyle(fontSize: 11, color: AppTheme.rose500, fontWeight: FontWeight.bold)),
                            ],
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 18),
                              tooltip: 'Assign or Change Caregiver',
                              onPressed: () => _showAssignCaregiverDialog(context, b),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text('LKR ${currency.format(b.totalCostLKR)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.slate900)),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          initialValue: b.status,
                          onSelected: (val) => provider.updateBookingStatus(b.id, val),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: b.status == 'in_progress'
                                  ? AppTheme.emerald100
                                  : b.status == 'caregiver_assigned'
                                      ? AppTheme.blueLight
                                      : b.status == 'completed'
                                          ? AppTheme.slate100
                                          : AppTheme.amber100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.status.toUpperCase().replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 10,
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
                                const Icon(Icons.arrow_drop_down, size: 14),
                              ],
                            ),
                          ),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'pending_review', child: Text('Pending Review')),
                            const PopupMenuItem(value: 'caregiver_assigned', child: Text('Caregiver Assigned')),
                            const PopupMenuItem(value: 'in_progress', child: Text('In Progress (On Duty)')),
                            const PopupMenuItem(value: 'completed', child: Text('Completed')),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WhatsAppButton(
                              phone: b.contactPhone,
                              message: 'Hello ${b.contactName}, this is Prime Life Care. Your booking ${b.bookingCode} for ${b.patientName} is confirmed with caregiver ${b.assignedCaregiverName ?? "assigned staff"}. Contact: ${b.assignedCaregiverPhone ?? "+94 11 234 5678"}.',
                              label: 'WhatsApp Family',
                            ),
                            const SizedBox(width: 4),
                            if (b.assignedCaregiverPhone != null)
                              WhatsAppButton(
                                phone: b.assignedCaregiverPhone!,
                                message: 'Duty Dispatch Prime Life Care: Patient ${b.patientName} (${b.patientAge}y), Address: ${b.address}, ${b.city}. Start: ${b.startDate}. Family: ${b.contactName} (${b.contactPhone}).',
                                label: 'Dispatch Staff',
                              ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.receipt_rounded, color: AppTheme.slate700, size: 18),
                              tooltip: 'Print Invoice Receipt',
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label) {
    final isSelected = _selectedFilter == filterId;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterId),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.slate900 : AppTheme.slate200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.slate700,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

extension IterableFilter<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T element) test) => where(test);
}
