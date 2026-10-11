import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';

class InvoiceDialog extends StatelessWidget {
  final BookingModel? booking;
  final String? invoiceCode;
  final String? clientName;
  final String? clientPhone;
  final String? serviceOrItemName;
  final String? date;
  final double? totalLKR;
  final String? status;

  const InvoiceDialog({
    super.key,
    this.booking,
    this.invoiceCode,
    this.clientName,
    this.clientPhone,
    this.serviceOrItemName,
    this.date,
    this.totalLKR,
    this.status,
  });

  static void show(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => InvoiceDialog(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    final code = booking?.bookingCode ?? invoiceCode ?? 'INV-2026-0001';
    final name = booking?.contactName ?? clientName ?? 'Valued Client';
    final phone = booking?.contactPhone ?? clientPhone ?? '';
    final address = booking != null ? '${booking!.city}, ${booking!.district}' : 'Colombo, Sri Lanka';
    final itemDesc = booking != null
        ? '${booking!.serviceName}\n(${booking!.staffTierName})'
        : (serviceOrItemName ?? 'Healthcare Service');
    final total = booking?.totalCostLKR ?? totalLKR ?? 0.0;
    final payStatus = booking?.paymentStatus ?? status ?? 'paid';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Letterhead
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'PRIME LIFE CARE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.slate900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Registered Healthcare Services (Pvt) Ltd',
                          style: TextStyle(fontSize: 11, color: AppTheme.slate500),
                        ),
                        Text(
                          'Ministry of Health Reg: MOH/PVT/2026/089',
                          style: TextStyle(fontSize: 10, color: AppTheme.slate400),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.blueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OFFICIAL INVOICE',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.slate900,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(color: AppTheme.slate200),
            const SizedBox(height: 16),

            // Billed to / Patient details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BILLED TO (CLIENT):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400)),
                      const SizedBox(height: 4),
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.slate900)),
                      Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.slate600)),
                      Text(address, style: const TextStyle(fontSize: 12, color: AppTheme.slate600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DETAILS & FULFILLMENT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400)),
                      const SizedBox(height: 4),
                      if (booking != null) ...[
                        Text('${booking!.patientName} (${booking!.patientAge} Yrs)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.slate900)),
                        Text('Assigned: ${booking!.assignedCaregiverName ?? "Pending Review"}', style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                        Text('Start: ${booking!.startDate} • ${booking!.durationDays} Days', style: const TextStyle(fontSize: 12, color: AppTheme.slate600)),
                      ] else ...[
                        Text('Transaction Date: ${date ?? "Today"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.slate800)),
                        const Text('Prime Life Care Official Receipt', style: TextStyle(fontSize: 12, color: AppTheme.slate600)),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Itemization Table
            Container(
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('ITEM / SERVICE DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                      Text('TOTAL (LKR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                    ],
                  ),
                  const Divider(color: AppTheme.slate200, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          itemDesc,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate900),
                        ),
                      ),
                      Text(
                        'LKR ${currencyFormatter.format(total)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.slate200, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL AMOUNT DUE:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                      ),
                      Text(
                        'LKR ${currencyFormatter.format(total)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment status & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: payStatus.contains('paid')
                        ? AppTheme.emerald100
                        : payStatus.contains('advance')
                            ? AppTheme.amber100
                            : AppTheme.rose100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'STATUS: ${payStatus.toUpperCase().replaceAll('_', ' ')}',
                    style: TextStyle(
                      color: payStatus.contains('paid')
                          ? AppTheme.emerald800
                          : payStatus.contains('advance')
                              ? AppTheme.amber800
                              : AppTheme.rose800,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print / PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preparing digital PDF receipt for download...')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
