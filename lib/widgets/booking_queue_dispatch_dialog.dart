import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking_model.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';
import 'whatsapp_button.dart';

class BookingQueueDispatchDialog extends StatelessWidget {
  final BookingModel booking;

  const BookingQueueDispatchDialog({super.key, required this.booking});

  static Future<void> show(BuildContext context, BookingModel booking) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BookingQueueDispatchDialog(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    // Re-fetch current booking from provider to keep live in sync
    final currentBooking = provider.bookings.firstWhere(
      (b) => b.id == booking.id || b.bookingCode == booking.bookingCode,
      orElse: () => booking,
    );

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Column(
          children: [
            // Header
            _buildHeader(context, currentBooking),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient & Booking Summary Card
                    _buildBookingSummaryCard(currentBooking),
                    const SizedBox(height: 20),

                    // Dispatch & Queue Section
                    _buildDispatchSection(context, provider, currentBooking),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BookingModel bk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: AppTheme.slate900,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Booking ${bk.bookingCode}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildStatusPill(bk.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${bk.serviceName} • Tier: ${bk.staffTierName} • ${bk.city}, ${bk.district}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'broadcasted':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = 'BROADCASTED (QUEUE OPEN)';
        break;
      case 'caregiver_assigned':
      case 'assigned':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        label = 'STAFF ASSIGNED';
        break;
      case 'in_progress':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
        label = 'IN PROGRESS (ACTIVE SHIFT)';
        break;
      case 'completed':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = 'COMPLETED';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        label = status.toUpperCase().replaceAll('_', ' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildBookingSummaryCard(BookingModel bk) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Patient: ${bk.patientName} (${bk.patientAge} Yrs • ${bk.patientGender})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.slate900),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Client Total: LKR ${bk.totalCostLKR.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.primaryBlue),
                  ),
                  Text(
                    'Staff Payout: LKR ${bk.staffTotalPayoutLKR.toInt()} (LKR ${bk.staffDailyPayoutLKR.toInt()}/day)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Medical Condition / Diagnosis: ${bk.medicalConditions}',
            style: const TextStyle(fontSize: 12.5, color: AppTheme.slate700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '📍 Address: ${bk.address.isNotEmpty ? bk.address : '${bk.city}, ${bk.district}'} • Duration: ${bk.durationDays} Days (${bk.shiftType})',
                  style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                ),
              ),
              if (bk.hasLocation)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 14),
                    label: const Text('Open Google Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final url = Uri.parse(bk.effectiveMapsUrl);
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Guardian: ${bk.contactName} (${bk.contactPhone})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate800),
              ),
              if (bk.contactPhone.isNotEmpty) ...[
                const SizedBox(width: 8),
                WhatsAppButton(
                  phoneNumber: bk.contactPhone,
                  label: 'Chat',
                  customMessage: 'Hello ${bk.contactName}, this is Prime Life Care Operations regarding booking ${bk.bookingCode}.',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchSection(BuildContext context, AdminProvider provider, BookingModel bk) {
    if (bk.status == 'caregiver_assigned' || bk.status == 'in_progress') {
      return _buildAssignedCaregiverView(context, provider, bk);
    } else if (bk.status == 'broadcasted') {
      return _buildLiveQueueView(context, provider, bk);
    } else {
      return _buildPreBroadcastView(context, provider, bk);
    }
  }

  Widget _buildPreBroadcastView(BuildContext context, AdminProvider provider, BookingModel bk) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cell_tower_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to Broadcast to Registered Caregivers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.slate900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Broadcast this booking to registered staff matching category "${bk.staffTierName}". Up to 10 staff members can accept in first-come queue order.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  provider.broadcastBookingToStaff(bk.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Booking ${bk.bookingCode} broadcasted to staff mobile apps!'),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Broadcast to Staff App (Matching Tier)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showManualCaregiverPicker(context, provider, bk),
                icon: const Icon(Icons.person_search_rounded, size: 16),
                label: const Text('Direct Manual Assign'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.slate800,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveQueueView(BuildContext context, AdminProvider provider, BookingModel bk) {
    final queue = bk.candidateQueue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.format_list_numbered_rounded, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '10-Candidate First-Come Queue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: queue.length >= 10 ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: queue.length >= 10 ? Colors.red.shade200 : Colors.blue.shade200),
                  ),
                  child: Text(
                    '${queue.length} / ${bk.maxCandidates} Accepted',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: queue.length >= 10 ? Colors.red.shade800 : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            if (queue.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  provider.assignFromCandidateQueue(bk.id, queue.first);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Duty auto-assigned to #1 Candidate: ${queue.first['caregiverName']}!'),
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: Text('Auto-Assign #1 (${queue.first['caregiverName']})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Staff members who accepted this booking in chronological order. First responder (#1) is automatically placed at the top of the queue.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),

        if (queue.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Waiting for qualified staff members to accept from mobile app...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate700),
                ),
                const SizedBox(height: 4),
                Text(
                  'This booking is visible to matching "${bk.staffTierName}" members in their app.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: queue.length,
            itemBuilder: (ctx, idx) {
              final candidate = queue[idx];
              final isFirst = idx == 0;
              final cgId = candidate['caregiverId']?.toString() ?? '';
              final cgName = candidate['caregiverName']?.toString() ?? 'Caregiver';
              final cgPhone = candidate['caregiverPhone']?.toString() ?? '';
              final rating = (candidate['rating'] as num?)?.toDouble() ?? 5.0;
              final tier = candidate['tier']?.toString() ?? 'NVQ 4';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isFirst ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFirst ? const Color(0xFF86EFAC) : Colors.grey.shade200,
                    width: isFirst ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Queue Badge
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isFirst ? const Color(0xFF059669) : AppTheme.slate800,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${idx + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                cgName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.slate900),
                              ),
                              const SizedBox(width: 6),
                              Text('($cgId)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              if (isFirst) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt_rounded, size: 12, color: Colors.amber),
                                      SizedBox(width: 2),
                                      Text(
                                        'FIRST RESPONDER',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tier: $tier • Rating: $rating ★ • Phone: $cgPhone',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    // Action
                    ElevatedButton(
                      onPressed: () {
                        provider.assignFromCandidateQueue(bk.id, candidate);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Duty assigned to $cgName!'),
                            backgroundColor: AppTheme.emeraldGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFirst ? const Color(0xFF059669) : AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isFirst ? 'Confirm #1' : 'Assign'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAssignedCaregiverView(BuildContext context, AdminProvider provider, BookingModel bk) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Active Assigned Caregiver',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.slate900),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  provider.unassignCaregiver(bk.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caregiver unassigned from booking.')),
                  );
                },
                icon: const Icon(Icons.person_remove_rounded, size: 16, color: Colors.red),
                label: const Text('Unassign Duty', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Assigned: ${bk.assignedCaregiverName ?? 'Caregiver'} (${bk.assignedCaregiverId ?? 'ID'})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.slate900),
          ),
          if (bk.assignedCaregiverPhone != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Contact: ${bk.assignedCaregiverPhone}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 8),
                WhatsAppButton(
                  phoneNumber: bk.assignedCaregiverPhone!,
                  label: 'Chat',
                  customMessage: 'Hello ${bk.assignedCaregiverName}, regarding your active duty on booking ${bk.bookingCode}.',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showManualCaregiverPicker(BuildContext context, AdminProvider provider, BookingModel bk) {
    final caregivers = provider.caregivers;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Caregiver Manually'),
        content: SizedBox(
          width: 450,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: caregivers.length,
            itemBuilder: (c, i) {
              final cg = caregivers[i];
              return ListTile(
                title: Text(cg.name),
                subtitle: Text('${cg.id} • ${cg.tierLabel} • ${cg.district}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    provider.assignCaregiver(bk.id, cg);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Assign'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
