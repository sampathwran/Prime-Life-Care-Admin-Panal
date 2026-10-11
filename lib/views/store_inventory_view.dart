import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/medical_item_model.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/inventory_rental_chart.dart';

class StoreInventoryView extends StatefulWidget {
  const StoreInventoryView({super.key});

  @override
  State<StoreInventoryView> createState() => _StoreInventoryViewState();
}

class _StoreInventoryViewState extends State<StoreInventoryView> {
  String _selectedCategory = 'all';
  String _searchFilter = '';
  final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final items = provider.medicalItems.where((item) {
      if (_selectedCategory != 'all' && item.category != _selectedCategory) {
        return false;
      }
      if (_searchFilter.isNotEmpty) {
        final query = _searchFilter.toLowerCase();
        return item.nameEn.toLowerCase().contains(query) ||
            item.nameSi.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
      }
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
                    'Medical Store & Equipment Inventory',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage hospital beds, ripple mattresses, adult diapers, wheelchairs, and monthly rentals.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openItemDialog(context, null),
                icon: const Icon(Icons.add_box_outlined, size: 18),
                label: const Text('Add Medical Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Inventory KPI Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Items Catalog',
                  value: '${provider.medicalItems.length}',
                  icon: Icons.inventory_2_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  title: 'Low Stock Alerts (≤ 5)',
                  value: '${provider.lowStockItemsCount}',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  title: 'Rentable Equipment',
                  value: '${provider.medicalItems.where((m) => m.canRent).length}',
                  icon: Icons.accessible_forward_rounded,
                  color: AppTheme.emeraldGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Inventory & Rental Capacity Chart
          const InventoryRentalChart(),

          const SizedBox(height: 20),

          // Filter bar & Search
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCatChip('All Products', 'all', provider.medicalItems.length),
                      const SizedBox(width: 8),
                      _buildCatChip(
                        'Equipment',
                        'equipment',
                        provider.medicalItems.where((m) => m.category == 'equipment').length,
                      ),
                      const SizedBox(width: 8),
                      _buildCatChip(
                        'Mobility',
                        'mobility',
                        provider.medicalItems.where((m) => m.category == 'mobility').length,
                      ),
                      const SizedBox(width: 8),
                      _buildCatChip(
                        'Hygiene & Diapers',
                        'hygiene',
                        provider.medicalItems.where((m) => m.category == 'hygiene').length,
                      ),
                      const SizedBox(width: 8),
                      _buildCatChip(
                        'Vitals Monitoring',
                        'monitoring',
                        provider.medicalItems.where((m) => m.category == 'monitoring').length,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                height: 40,
                child: TextField(
                  onChanged: (val) => setState(() => _searchFilter = val),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Product Grid
          items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'No medical supplies found.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildProductCard(context, item);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.slate900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatChip(String label, String key, int count) {
    final isSelected = _selectedCategory == key;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.slate900 : Colors.grey.shade300,
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
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, MedicalItemModel item) {
    final isLowStock = item.stock <= 5;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview banner with rental tag & image count
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: item.imageUrls.isNotEmpty
                      ? Image.network(
                          item.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(Icons.medical_services_outlined, size: 40, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined, size: 36, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              // Category & rental badge
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    if (item.canRent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.repeat, size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'RENTAL',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Multi-image count pill
              if (item.imageUrls.length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library, size: 11, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${item.imageUrls.length} photos',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate900,
                    ),
                  ),
                  Text(
                    item.nameSi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  const Spacer(),

                  // Pricing row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buy Price', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          Text(
                            currencyFormat.format(item.buyPriceLKR),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.slate900,
                            ),
                          ),
                        ],
                      ),
                      if (item.canRent && item.monthlyRentLKR != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Rent / Month', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            Text(
                              currencyFormat.format(item.monthlyRentLKR),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stock & Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLowStock ? Colors.amber.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isLowStock ? Colors.amber.shade300 : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                              size: 12,
                              color: isLowStock ? Colors.amber.shade900 : Colors.green.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stock: ${item.stock}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLowStock ? Colors.amber.shade900 : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _openItemDialog(context, item),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            tooltip: 'Edit Item',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Medical Item?'),
                                  content: Text('Are you sure you want to remove "${item.nameEn}" from the catalog?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<AdminProvider>().deleteMedicalItem(item.id);
                                        Navigator.pop(ctx);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            tooltip: 'Delete Item',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openItemDialog(BuildContext context, MedicalItemModel? existing) {
    final isEditing = existing != null;
    final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final nameSiCtrl = TextEditingController(text: existing?.nameSi ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final buyPriceCtrl = TextEditingController(text: existing != null ? existing.buyPriceLKR.toString() : '');
    final stockCtrl = TextEditingController(text: existing != null ? existing.stock.toString() : '10');
    final rentPriceCtrl = TextEditingController(text: existing?.monthlyRentLKR?.toString() ?? '');
    final depositCtrl = TextEditingController(text: existing?.securityDepositLKR?.toString() ?? '');
    final imagesCtrl = TextEditingController(text: existing?.imageUrls.join('\n') ?? '');

    String category = existing?.category ?? 'equipment';
    bool canRent = existing?.canRent ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Medical Product' : 'Add New Medical Product'),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameEnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Name (English)',
                        hintText: 'e.g. Electric 3-Function Hospital Bed',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameSiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Name (Sinhala)',
                        hintText: 'e.g. විදුලි මෝටර් සහිත රෝහල් ඇඳ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'equipment', child: Text('Equipment (Beds, Pumps)')),
                              DropdownMenuItem(value: 'mobility', child: Text('Mobility (Wheelchairs)')),
                              DropdownMenuItem(value: 'hygiene', child: Text('Hygiene & Diapers')),
                              DropdownMenuItem(value: 'monitoring', child: Text('Vitals Monitoring')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Units in Stock',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: buyPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price (LKR)',
                        hintText: 'e.g. 145000',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rental Toggle
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available for Monthly Rental?'),
                      subtitle: const Text('Offer patient families monthly equipment hire with deposit'),
                      value: canRent,
                      onChanged: (val) {
                        setDialogState(() => canRent = val ?? false);
                      },
                    ),

                    if (canRent) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: rentPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monthly Rent (LKR)',
                                hintText: 'e.g. 14000',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: depositCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Refundable Deposit (LKR)',
                                hintText: 'e.g. 20000',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: imagesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Image URLs (1 to 5 URLs, 1 per line)',
                        hintText: 'https://images.unsplash.com/...\nhttps://images.unsplash.com/...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Product Clinical Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (nameEnCtrl.text.trim().isEmpty) return;
                  final rawUrls = imagesCtrl.text
                      .split('\n')
                      .map((u) => u.trim())
                      .where((u) => u.isNotEmpty)
                      .take(5)
                      .toList();

                  final updatedItem = MedicalItemModel(
                    id: existing?.id ?? 'med_${DateTime.now().millisecondsSinceEpoch}',
                    nameEn: nameEnCtrl.text.trim(),
                    nameSi: nameSiCtrl.text.trim().isEmpty ? nameEnCtrl.text.trim() : nameSiCtrl.text.trim(),
                    category: category,
                    buyPriceLKR: double.tryParse(buyPriceCtrl.text.trim()) ?? 0,
                    canRent: canRent,
                    monthlyRentLKR: canRent ? double.tryParse(rentPriceCtrl.text.trim()) : null,
                    securityDepositLKR: canRent ? double.tryParse(depositCtrl.text.trim()) : null,
                    stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
                    imageUrls: rawUrls.isEmpty
                        ? ['https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&q=80&w=800']
                        : rawUrls,
                    description: descCtrl.text.trim(),
                  );

                  if (isEditing) {
                    context.read<AdminProvider>().updateMedicalItem(updatedItem);
                  } else {
                    context.read<AdminProvider>().addMedicalItem(updatedItem);
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEditing ? 'Save Product' : 'Add to Catalog'),
              ),
            ],
          );
        },
      ),
    );
  }
}
