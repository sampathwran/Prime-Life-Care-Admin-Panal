import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/admin_provider.dart';
import '../models/medical_item_model.dart';
import '../models/store_category_model.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage hospital beds, ripple mattresses, adult diapers, wheelchairs, and monthly rentals.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openCategoryManagerDialog(context),
                    icon: const Icon(Icons.category_rounded, size: 14),
                    label: const Text('Manage Categories', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reset Store to 1 Authentic Product?'),
                          content: const Text(
                            'This will clean old dummy items and set the verified 3-Function Electric Hospital Bed with 5 multi-angle photos and 14% discount.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                              child: const Text('Confirm Reset', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await provider.seedDefaultStoreProduct();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Store inventory updated with authentic 3-Function Hospital Bed!')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Seed 1 Authentic Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openItemDialog(context, null),
                    icon: const Icon(Icons.add_box_outlined, size: 14),
                    label: const Text('Add Medical Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

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
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Low Stock Alerts (≤ 5)',
                  value: '${provider.lowStockItemsCount}',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 8),
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
          const SizedBox(height: 10),

          // Inventory & Rental Capacity Chart
          const InventoryRentalChart(),

          const SizedBox(height: 10),

          // Filter bar & Search
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCatChip('All Products', 'all', provider.medicalItems.length),
                      ...provider.storeCategories.map((cat) {
                        final count = provider.medicalItems.where((m) => m.category == cat.id).length;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _buildCatChip(cat.nameEn, cat.id, count),
                        );
                      }),
                      ...provider.medicalItems
                          .map((m) => m.category)
                          .toSet()
                          .where((cId) => !provider.storeCategories.any((cat) => cat.id == cId))
                          .map((extraCat) => Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _buildCatChip(
                                  extraCat.isNotEmpty ? (extraCat[0].toUpperCase() + extraCat.substring(1)) : 'General',
                                  extraCat,
                                  provider.medicalItems.where((m) => m.category == extraCat).length,
                                ),
                              )),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _openCategoryManagerDialog(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 12, color: AppTheme.primaryBlue),
                              SizedBox(width: 4),
                              Text(
                                '+ Add Category',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 220,
                height: 32,
                child: TextField(
                  onChanged: (val) => setState(() => _searchFilter = val),
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, size: 15),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Product Grid
          items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Center(
                    child: Text(
                      'No medical supplies found.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth < 680
                        ? 1
                        : (constraints.maxWidth < 1050 ? 2 : 3);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 250,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildProductCard(context, item);
                      },
                    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.slate900 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.slate800,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9.5,
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: SizedBox(
                  height: 95,
                  width: double.infinity,
                  child: item.imageUrls.isNotEmpty
                      ? Image.network(
                          item.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(Icons.medical_services_outlined, size: 28, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined, size: 28, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              // Category & rental badge
              Positioned(
                top: 6,
                left: 6,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    if (item.canRent) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.repeat, size: 8, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'RENTAL',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library, size: 10, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          '${item.imageUrls.length}',
                          style: const TextStyle(fontSize: 9, color: Colors.white),
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate900,
                    ),
                  ),
                  Text(
                    item.nameSi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                  ),
                  const Spacer(),

                  // Pricing row (Sale Price + Regular Price if discounted)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Sale: ', style: TextStyle(fontSize: 8.5, color: Colors.grey.shade500)),
                              if (item.discountPercentage > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    '-${item.discountPercentage}%',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            currencyFormat.format(item.salePriceLKR),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.slate900,
                            ),
                          ),
                          if (item.regularPriceLKR > item.salePriceLKR)
                            Text(
                              currencyFormat.format(item.regularPriceLKR),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      if (item.canRent && item.monthlyRentLKR != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Rent / Month', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                            Text(
                              currencyFormat.format(item.monthlyRentLKR),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Stock & Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLowStock ? Colors.amber.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isLowStock ? Colors.amber.shade300 : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                              size: 10,
                              color: isLowStock ? Colors.amber.shade900 : Colors.green.shade800,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Stock: ${item.stock}',
                              style: TextStyle(
                                fontSize: 9.5,
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
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            tooltip: 'Edit Item',
                            padding: const EdgeInsets.all(2),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Medical Item?', style: TextStyle(fontSize: 14)),
                                  content: Text('Are you sure you want to remove "${item.nameEn}" from the catalog?', style: const TextStyle(fontSize: 12)),
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
                            icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                            tooltip: 'Delete Item',
                            padding: const EdgeInsets.all(2),
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
    final provider = context.read<AdminProvider>();
    final availableCategories = List<StoreCategoryModel>.from(provider.storeCategories);
    if (existing != null && !availableCategories.any((c) => c.id == existing.category)) {
      availableCategories.add(StoreCategoryModel(
        id: existing.category,
        nameEn: existing.category.isNotEmpty ? (existing.category[0].toUpperCase() + existing.category.substring(1)) : 'General',
        nameSi: existing.category,
      ));
    }

    final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final nameSiCtrl = TextEditingController(text: existing?.nameSi ?? '');
    final brandCtrl = TextEditingController(text: existing?.brand ?? 'Prime Medical');
    final badgeCtrl = TextEditingController(text: existing?.badge ?? (existing?.discountPercentage != null && existing!.discountPercentage > 0 ? '${existing.discountPercentage}% OFF' : ''));
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final regularPriceCtrl = TextEditingController(
      text: existing != null ? existing.regularPriceLKR.toStringAsFixed(0) : '215000',
    );
    final salePriceCtrl = TextEditingController(
      text: existing != null ? existing.salePriceLKR.toStringAsFixed(0) : '185000',
    );
    final stockCtrl = TextEditingController(text: existing != null ? existing.stock.toString() : '6');
    final rentPriceCtrl = TextEditingController(text: existing?.monthlyRentLKR?.toStringAsFixed(0) ?? '15000');
    final depositCtrl = TextEditingController(text: existing?.securityDepositLKR?.toStringAsFixed(0) ?? '25000');
    final singleUrlCtrl = TextEditingController();

    List<String> imageUrls = List<String>.from(existing?.imageUrls ?? []);
    String category = existing?.category ?? (availableCategories.isNotEmpty ? availableCategories.first.id : 'equipment');
    bool canRent = existing?.canRent ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final regVal = double.tryParse(regularPriceCtrl.text.trim()) ?? 0;
          final saleVal = double.tryParse(salePriceCtrl.text.trim()) ?? 0;
          final discountPct = (regVal > saleVal && regVal > 0)
              ? (((regVal - saleVal) / regVal) * 100).round()
              : 0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medical_services_rounded, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Medical Product' : 'Add New Medical Product',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: English Name
                    TextField(
                      controller: nameEnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Name (English) *',
                        hintText: 'e.g. 3-Function Motorized Electric ICU & Home Care Hospital Bed',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Sinhala Name & Brand
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: nameSiCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Product Name (Sinhala)',
                              hintText: 'e.g. විදුලි මෝටර් සහිත රෝහල් ඇඳ (3-Function)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: brandCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Brand / Manufacturer',
                              hintText: 'e.g. Prime Medical',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 3: Category & Stock
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: availableCategories.any((c) => c.id == category)
                                ? category
                                : (availableCategories.isNotEmpty ? availableCategories.first.id : 'equipment'),
                            decoration: const InputDecoration(
                              labelText: 'Category *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              ...availableCategories.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      '${c.nameEn} (${c.nameSi})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11.5),
                                    ),
                                  )),
                              const DropdownMenuItem(
                                value: '__new_category__',
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 14, color: AppTheme.primaryBlue),
                                    SizedBox(width: 6),
                                    Text(
                                      '+ Add New Category...',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val == '__new_category__') {
                                _showQuickAddCategoryDialog(context, (newCatId) {
                                  setDialogState(() {
                                    category = newCatId;
                                    final newCat = context.read<AdminProvider>().storeCategories.firstWhere(
                                          (c) => c.id == newCatId,
                                          orElse: () => StoreCategoryModel(id: newCatId, nameEn: newCatId, nameSi: newCatId),
                                        );
                                    if (!availableCategories.any((c) => c.id == newCatId)) {
                                      availableCategories.add(newCat);
                                    }
                                  });
                                });
                              } else if (val != null) {
                                setDialogState(() => category = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Units in Stock *',
                              hintText: '6',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 4: Pricing (Regular, Sale & Discount Badge)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: regularPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setDialogState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'Regular Price (LKR)',
                                    hintText: '215000',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    prefixText: 'Rs. ',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: salePriceCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setDialogState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'Sale Price (LKR) *',
                                    hintText: '185000',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    prefixText: 'Rs. ',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: badgeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Promo Badge Tag',
                                    hintText: '14% OFF',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (discountPct > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-$discountPct% OFF',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Customer Saves Rs. ${(regVal - saleVal).toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Rental Toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            dense: true,
                            title: const Text('Available for Monthly Rental?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: const Text('Allow patient families to rent per month with refundable deposit', style: TextStyle(fontSize: 10.5)),
                            value: canRent,
                            onChanged: (val) {
                              setDialogState(() => canRent = val ?? false);
                            },
                          ),
                          if (canRent)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: rentPriceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Monthly Rent (LKR)',
                                        hintText: '15000',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        prefixText: 'Rs. ',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: depositCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Refundable Deposit (LKR)',
                                        hintText: '25000',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        prefixText: 'Rs. ',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Multi-Image Manager (Up to 5 images)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Product Images (Up to 5 Multi-Angle Photos)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: imageUrls.length >= 5 ? Colors.red.shade100 : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${imageUrls.length} / 5 Images',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: imageUrls.length >= 5 ? Colors.red.shade800 : AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Thumbnails Strip
                          if (imageUrls.isNotEmpty)
                            Container(
                              height: 70,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: imageUrls.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, idx) {
                                  final img = imageUrls[idx];
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(5),
                                          child: Image.network(
                                            img,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(child: Icon(Icons.broken_image, size: 20)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              imageUrls.removeAt(idx);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 10, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        left: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            '#${idx + 1}',
                                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                          // Add / Upload Buttons
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: imageUrls.length >= 5
                                    ? null
                                    : () async {
                                        try {
                                          final picked = await FilePicker.pickFile(
                                            type: FileType.custom,
                                            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                                          );
                                          if (picked != null) {
                                            final bytes = await picked.readAsBytes();
                                            final ext = (picked.extension ?? 'jpg').toLowerCase();
                                            final mimeExt = ext == 'jpg' ? 'jpeg' : ext;
                                            final base64String = base64Encode(bytes);
                                            final dataUrl = 'data:image/$mimeExt;base64,$base64String';
                                            setDialogState(() {
                                              if (imageUrls.length < 5) {
                                                imageUrls.add(dataUrl);
                                              }
                                            });
                                          }
                                        } catch (e) {
                                          debugPrint('File picker error: $e');
                                        }
                                      },
                                icon: const Icon(Icons.upload_file_rounded, size: 14),
                                label: const Text('Upload Photo (PC)', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.slate900,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: singleUrlCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Or paste image URL...',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.add_link_rounded, size: 18),
                                      tooltip: 'Add URL',
                                      onPressed: () {
                                        final url = singleUrlCtrl.text.trim();
                                        if (url.isNotEmpty && imageUrls.length < 5) {
                                          setDialogState(() {
                                            imageUrls.add(url);
                                            singleUrlCtrl.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Clinical Description
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Product Clinical Description & Features',
                        hintText: 'Enter clinical features, motor adjustments, load capacity, mattress specs, and warranty...',
                        border: OutlineInputBorder(),
                        isDense: true,
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
                  final reg = double.tryParse(regularPriceCtrl.text.trim()) ?? 0;
                  final sale = double.tryParse(salePriceCtrl.text.trim()) ?? reg;
                  final discount = (reg > sale && reg > 0)
                      ? (((reg - sale) / reg) * 100).round()
                      : 0;

                  final updatedItem = MedicalItemModel(
                    id: existing?.id ?? 'med_${DateTime.now().millisecondsSinceEpoch}',
                    nameEn: nameEnCtrl.text.trim(),
                    nameSi: nameSiCtrl.text.trim().isEmpty ? nameEnCtrl.text.trim() : nameSiCtrl.text.trim(),
                    category: category,
                    regularPriceLKR: reg > 0 ? reg : sale,
                    salePriceLKR: sale > 0 ? sale : reg,
                    discountPercentage: discount,
                    brand: brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : 'Prime Medical',
                    badge: badgeCtrl.text.trim().isNotEmpty ? badgeCtrl.text.trim() : (discount > 0 ? '$discount% OFF' : null),
                    canRent: canRent,
                    monthlyRentLKR: canRent ? double.tryParse(rentPriceCtrl.text.trim()) : null,
                    securityDepositLKR: canRent ? double.tryParse(depositCtrl.text.trim()) : null,
                    stock: int.tryParse(stockCtrl.text.trim()) ?? 1,
                    imageUrls: imageUrls.isEmpty
                        ? ['https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&q=80&w=800']
                        : imageUrls,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(isEditing ? 'Save Product' : 'Add to Catalog'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuickAddCategoryDialog(BuildContext context, ValueChanged<String> onAdded) {
    final nameEnCtrl = TextEditingController();
    final nameSiCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue, size: 20),
            SizedBox(width: 8),
            Text('Add New Product Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameEnCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category Name (English) *',
                hintText: 'e.g. Respiratory & Oxygen',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameSiCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name (Sinhala)',
                hintText: 'e.g. ශ්වසන සහ ඔක්සිජන් උපකරණ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final en = nameEnCtrl.text.trim();
              if (en.isEmpty) return;
              final si = nameSiCtrl.text.trim().isNotEmpty ? nameSiCtrl.text.trim() : en;
              final slug = en
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                  .replaceAll(RegExp(r'^_+|_+$'), '');

              final newCat = StoreCategoryModel(
                id: slug.isNotEmpty ? slug : 'cat_${DateTime.now().millisecondsSinceEpoch}',
                nameEn: en,
                nameSi: si,
                sortOrder: 99,
                isDefault: false,
              );

              context.read<AdminProvider>().addStoreCategory(newCat);
              onAdded(newCat.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Add & Select', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openCategoryManagerDialog(BuildContext context) {
    final nameEnCtrl = TextEditingController();
    final nameSiCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    bool isCustomId = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final provider = ctx.watch<AdminProvider>();
          final categories = provider.storeCategories;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.category_rounded, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Manage Store Item Categories',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create and organize product categories for the public Medical Store and Admin Inventory. Changes sync live with the website.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),

                    // Add Category Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.add_circle, size: 15, color: AppTheme.primaryBlue),
                              SizedBox(width: 6),
                              Text(
                                'Add New Category',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: nameEnCtrl,
                                  onChanged: (val) {
                                    if (!isCustomId) {
                                      final slug = val
                                          .trim()
                                          .toLowerCase()
                                          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                                          .replaceAll(RegExp(r'^_+|_+$'), '');
                                      idCtrl.text = slug;
                                      setDialogState(() {});
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Category Name (English) *',
                                    hintText: 'e.g. Respiratory & Oxygen Equipment',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: nameSiCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Category Name (Sinhala)',
                                    hintText: 'e.g. ශ්වසන සහ ඔක්සිජන් උපකරණ',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: idCtrl,
                                  onChanged: (_) => isCustomId = true,
                                  decoration: const InputDecoration(
                                    labelText: 'Category Key / ID (slug)',
                                    hintText: 'e.g. respiratory_oxygen',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final en = nameEnCtrl.text.trim();
                                  final si = nameSiCtrl.text.trim();
                                  var id = idCtrl.text.trim().toLowerCase();
                                  if (en.isEmpty) return;
                                  if (id.isEmpty) {
                                    id = en.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
                                  }

                                  final newCat = StoreCategoryModel(
                                    id: id,
                                    nameEn: en,
                                    nameSi: si.isNotEmpty ? si : en,
                                    sortOrder: categories.length + 1,
                                    isDefault: false,
                                  );

                                  await ctx.read<AdminProvider>().addStoreCategory(newCat);
                                  nameEnCtrl.clear();
                                  nameSiCtrl.clear();
                                  idCtrl.clear();
                                  isCustomId = false;
                                  setDialogState(() {});
                                },
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Add Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Existing Categories Table
                    const Text(
                      'All Active Categories',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate900),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, idx) {
                          final cat = categories[idx];
                          final count = provider.medicalItems.where((m) => m.category == cat.id).length;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.folder_outlined, size: 16, color: AppTheme.slate900),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.nameEn,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        '${cat.nameSi} • Key: ${cat.id}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: count > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: count > 0 ? Colors.green.shade200 : Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    '$count items',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: count > 0 ? Colors.green.shade800 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!cat.isDefault)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    tooltip: 'Delete Category',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Delete Category?'),
                                          content: Text('Are you sure you want to delete category "${cat.nameEn}"? Items using this category will remain, but the category filter pill will be removed.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                                            ElevatedButton(
                                              onPressed: () {
                                                ctx.read<AdminProvider>().deleteStoreCategory(cat.id);
                                                Navigator.pop(c);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
