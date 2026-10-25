import 'dart:convert';
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

    return SingleChildScrollView(
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
          orders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'No orders matching the selected filter.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
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
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        horizontalMargin: 20,
                        headingRowHeight: 48,
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 90,
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
                                  InkWell(
                                    onTap: () => _showOrderDetailsModal(context, order),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          for (var i = 0; i < order.items.length && i < 2; i++) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: _buildImageOrFallback(order.items[i].imageUrl, width: 28, height: 28),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ConstrainedBox(
                                                    constraints: const BoxConstraints(maxWidth: 190),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          order.items[i].itemName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                                                        ),
                                                        Text(
                                                          'Qty: ${order.items[i].quantity} • Rs. ${order.items[i].priceLKR.toStringAsFixed(0)}',
                                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          if (order.items.length > 2)
                                            Text(
                                              '+${order.items.length - 2} more items...',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                            ),
                                        ],
                                      ),
                                    ),
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
                                      ElevatedButton.icon(
                                        onPressed: () => _showOrderDetailsModal(context, order),
                                        icon: const Icon(Icons.visibility_rounded, size: 13),
                                        label: const Text('View Order'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (order.paymentStatus == 'pending_verification')
                                        ElevatedButton(
                                          onPressed: () => _showBankSlipModal(context, order),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber.shade700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  Widget _buildImageOrFallback(String? imageUrl, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Icon(Icons.medical_services_outlined, size: 18, color: Colors.grey),
      );
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: const Icon(Icons.broken_image, size: 18, color: Colors.grey),
          ),
        );
      } catch (_) {}
    }
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Icon(Icons.medical_services_outlined, size: 18, color: Colors.grey),
      ),
    );
  }

  void _showFullscreenSlip(BuildContext context, String slipUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: _buildImageOrFallback(slipUrl, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailsModal(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) {
        String currentStatus = order.orderStatus;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 660,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogCtx).size.height * 0.9),
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryBlue, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      order.orderCode,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                                    ),
                                    const SizedBox(width: 8),
                                    if (order.isRental)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.purple.shade200),
                                        ),
                                        child: Text(
                                          'EQUIPMENT RENTAL',
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ordered: ${order.createdAt}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Scrollable content body
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer and Delivery Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Customer & Delivery Destination',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                                      ),
                                      WhatsAppButton(
                                        phoneNumber: order.customerPhone,
                                        customMessage: 'Hello ${order.customerName}, regarding your Prime Life Care Order ${order.orderCode}.',
                                        label: 'WhatsApp Customer',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 6,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            order.customerName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate900),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            order.customerPhone,
                                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${order.deliveryAddress} (${order.district})',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Items List Card
                            const Text(
                              'Ordered Items & Quantities',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < order.items.length; i++) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        color: i.isEven ? Colors.white : Colors.grey.shade50,
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: _buildImageOrFallback(order.items[i].imageUrl, width: 44, height: 44),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    order.items[i].itemName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate900),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Unit Price: LKR ${order.items[i].priceLKR.toStringAsFixed(0)}',
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.blue.shade200),
                                              ),
                                              child: Text(
                                                'Qty: ${order.items[i].quantity}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.primaryBlue),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'LKR ${(order.items[i].priceLKR * order.items[i].quantity).toStringAsFixed(0)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate900),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (i < order.items.length - 1)
                                        const Divider(height: 1, thickness: 1),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Total & Payment Summary Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Payment Method: ',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                                          ),
                                          Text(
                                            order.paymentMethod == 'cod' ? 'Cash on Delivery (COD)' : 'Direct Bank Transfer',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text('Payment Status: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          _buildPaymentStatusBadge(order.paymentStatus),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Total Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(
                                        currencyFormat.format(order.totalAmountLKR),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Bank Transfer Slip Section (if applicable)
                            if (order.paymentMethod != 'cod') ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.receipt_long, size: 18, color: Colors.amber),
                                            SizedBox(width: 6),
                                            Text(
                                              'Bank Deposit Slip & Verification',
                                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                                            ),
                                          ],
                                        ),
                                        if (order.paymentStatus == 'pending_verification')
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              context.read<AdminProvider>().approveBankTransfer(order.id);
                                              setDialogState(() {
                                                currentStatus = 'dispatched';
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Payment approved for ${order.orderCode}! Order marked as Dispatched.'),
                                                  backgroundColor: AppTheme.emeraldGreen,
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.check, size: 14),
                                            label: const Text('Approve Slip & Mark Paid'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.emeraldGreen,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (order.bankReference != null && order.bankReference!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Bank Reference: ${order.bankReference}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate900),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    if (order.bankSlipUrl != null && order.bankSlipUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: () => _showFullscreenSlip(context, order.bankSlipUrl!),
                                          child: Container(
                                            constraints: const BoxConstraints(maxHeight: 220),
                                            width: double.infinity,
                                            color: Colors.black12,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                _buildImageOrFallback(order.bankSlipUrl, width: double.infinity, height: 220),
                                                Positioned(
                                                  bottom: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black87,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                                        SizedBox(width: 4),
                                                        Text('Click to Zoom Slip', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          'No deposit slip image attached by customer.',
                                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),

                    // Footer with Status Changer and Invoice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Order Status: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButton<String>(
                                value: currentStatus,
                                underline: const SizedBox(),
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'dispatched', child: Text('Dispatched', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'delivered', child: Text('Delivered', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    context.read<AdminProvider>().updateOrderStatus(order.id, newStatus);
                                    setDialogState(() {
                                      currentStatus = newStatus;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
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
                              icon: const Icon(Icons.receipt_outlined, size: 15),
                              label: const Text('Digital Invoice', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Done', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bank Account:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Commercial Bank of Ceylon'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Account Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Prime Life Care (Pvt) Ltd'),
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
                    if (order.bankReference != null && order.bankReference!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bank Reference:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(order.bankReference!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.bankSlipUrl != null && order.bankSlipUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: _buildImageOrFallback(order.bankSlipUrl, fit: BoxFit.contain),
                  ),
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text('No deposit slip image attached by customer.'),
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
