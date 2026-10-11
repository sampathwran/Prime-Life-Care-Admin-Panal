import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_button.dart';
import '../widgets/invoice_dialog.dart';

class OrdersRentalsView extends StatefulWidget {
  const OrdersRentalsView({super.key});

  @override
  State<OrdersRentalsView> createState() => _OrdersRentalsViewState();
}

class _OrdersRentalsViewState extends State<OrdersRentalsView> {
  String _activeTab = 'all';
  final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final orders = provider.orders.where((o) {
      if (_activeTab == 'rentals') return o.isRental;
      if (_activeTab == 'pending_slip') return o.paymentStatus == 'pending_verification';
      if (_activeTab == 'active') return o.orderStatus == 'dispatched' || o.orderStatus == 'delivered';
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store Orders & Equipment Rentals',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track medical supplies purchases, active hospital bed & wheelchair rentals, and verify bank slips.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 18, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      '${provider.orders.length} Total Orders / Rentals',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tabs
          Row(
            children: [
              _buildTabButton('All Orders', 'all', provider.orders.length),
              const SizedBox(width: 8),
              _buildTabButton(
                'Equipment Rentals',
                'rentals',
                provider.orders.where((o) => o.isRental).length,
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                'Pending Bank Slips',
                'pending_slip',
                provider.orders.where((o) => o.paymentStatus == 'pending_verification').length,
                highlight: true,
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                'Dispatched / Active',
                'active',
                provider.orders.where((o) => o.orderStatus == 'dispatched' || o.orderStatus == 'delivered').length,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Orders Table
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders matching the selected filter.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 20,
                          headingRowHeight: 48,
                          dataRowMaxHeight: 78,
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                          columns: const [
                            DataColumn(label: Text('ORDER / RENTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('CUSTOMER & DELIVERY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('ITEMS ORDERED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('PAYMENT METHOD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: orders.map((order) {
                            return DataRow(
                              cells: [
                                // Order Code & Date
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            order.orderCode,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate900),
                                          ),
                                          if (order.isRental) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.purple.shade200),
                                              ),
                                              child: Text(
                                                'RENTAL',
                                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        order.createdAt,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                      if (order.isRental && order.rentalEndDate != null)
                                        Text(
                                          'Due: ${order.rentalEndDate}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                        ),
                                    ],
                                  ),
                                ),

                                // Customer & Address
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        order.customerName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.slate900),
                                      ),
                                      Text(
                                        order.customerPhone,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                      Text(
                                        '${order.deliveryAddress} (${order.district})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),

                                // Items
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: order.items.map((it) {
                                      return Text(
                                        '• ${it.itemName} (x${it.quantity})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                                      );
                                    }).toList(),
                                  ),
                                ),

                                // Total Amount
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        currencyFormat.format(order.totalAmountLKR),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                      if (order.securityDepositLKR != null)
                                        Text(
                                          'Deposit: ${currencyFormat.format(order.securityDepositLKR)}',
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ),

                                // Payment Method & Verification
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        order.paymentMethod.toUpperCase(),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate800),
                                      ),
                                      const SizedBox(height: 3),
                                      _buildPaymentStatusBadge(order.paymentStatus),
                                    ],
                                  ),
                                ),

                                // Order Status
                                DataCell(
                                  DropdownButton<String>(
                                    value: order.orderStatus,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'dispatched', child: Text('Dispatched', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'delivered', child: Text('Delivered', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled', style: TextStyle(fontSize: 12))),
                                    ],
                                    onChanged: (newStatus) {
                                      if (newStatus != null) {
                                        context.read<AdminProvider>().updateOrderStatus(order.id, newStatus);
                                      }
                                    },
                                  ),
                                ),

                                // Actions
                                DataCell(
                                  Row(
                                    children: [
                                      if (order.paymentStatus == 'pending_verification')
                                        ElevatedButton(
                                          onPressed: () => _showBankSlipModal(context, order),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber.shade700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          child: const Text('Verify Slip'),
                                        ),
                                      const SizedBox(width: 6),
                                      WhatsAppButton(
                                        phoneNumber: order.customerPhone,
                                        customMessage:
                                            'Hello ${order.customerName}, regarding your Prime Life Care Order ${order.orderCode} (${order.isRental ? "Equipment Rental" : "Medical Supplies"}). Status: ${order.orderStatus.toUpperCase()}.',
                                        label: 'WhatsApp',
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.receipt_outlined, size: 18),
                                        tooltip: 'Digital Invoice',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => InvoiceDialog(
                                              invoiceCode: order.orderCode,
                                              clientName: order.customerName,
                                              clientPhone: order.customerPhone,
                                              serviceOrItemName: order.items.map((i) => '${i.itemName} (x${i.quantity})').join(', '),
                                              date: order.createdAt,
                                              totalLKR: order.totalAmountLKR,
                                              status: order.paymentStatus == 'paid' ? 'Paid' : 'Pending',
                                            ),
                                          );
                                        },
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
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey, int count, {bool highlight = false}) {
    final isSelected = _activeTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight && !isSelected ? Colors.amber.shade600 : (isSelected ? AppTheme.slate900 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.slate800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: highlight ? Colors.amber.shade100 : (isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: highlight ? Colors.amber.shade900 : (isSelected ? Colors.white : Colors.grey.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'paid':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        text = 'PAID ✓';
        break;
      case 'pending_verification':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        text = 'SLIP REVIEW';
        break;
      case 'cod_pending':
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        text = 'COD ON DELIVERY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  void _showBankSlipModal(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text('Bank Deposit Slip Verification - ${order.orderCode}'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bank Account:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Commercial Bank of Ceylon'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Account Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Prime Life Care (Pvt) Ltd'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Deposited Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormat.format(order.totalAmountLKR),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Attached Slip Filename:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(order.bankSlipUrl ?? 'slip_receipt.jpg', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt, size: 48, color: Colors.blueGrey),
                    const SizedBox(height: 8),
                    Text(
                      'Customer Slip Preview: ${order.bankSlipUrl ?? "commercial_bank_ref_8932.jpg"}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Bank Ref: CMB-2026-98124 | Branch: Dehiwala', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AdminProvider>().approveBankTransfer(order.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment approved for ${order.orderCode}! Order marked as Dispatched.'),
                  backgroundColor: AppTheme.emeraldGreen,
                ),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve Slip & Mark Paid'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
