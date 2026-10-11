import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';

class ServicesManagerView extends StatefulWidget {
  const ServicesManagerView({super.key});

  @override
  State<ServicesManagerView> createState() => _ServicesManagerViewState();
}

class _ServicesManagerViewState extends State<ServicesManagerView> {
  String _selectedCategory = 'all';
  final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final services = provider.services.where((s) {
      if (_selectedCategory == 'all') return true;
      return s.category == _selectedCategory;
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
                    'Care Packages & Staff Tiers',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage home healthcare tiers (NVQ 4, NVQ 5, Nurse, Doctor) and dynamic shift pricing.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openServiceDialog(context, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add New Service'),
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

          // Category Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Packages', 'all', provider.services.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Elderly Care',
                  'elderly_care',
                  provider.services.where((s) => s.category == 'elderly_care').length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Child & Post-Natal',
                  'child_care',
                  provider.services.where((s) => s.category == 'child_care').length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Doctor Home Visits',
                  'short_visit',
                  provider.services.where((s) => s.category == 'short_visit').length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Services Grid / List
          services.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'No services found in this category.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _buildServiceCard(context, service);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String categoryKey, int count) {
    final isSelected = _selectedCategory == categoryKey;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = categoryKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.slate800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
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

  Widget _buildServiceCard(BuildContext context, ServiceModel service) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AppTheme.primaryBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            service.nameEn,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.slate900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Text(
                              '${service.hours} Hours Shift',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        service.nameSi,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service.shortDescription,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Starting from',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    Text(
                      currencyFormat.format(service.defaultPriceLKR),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      service.pricingUnit,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _openServiceDialog(context, service),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Service & Tiers',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Service?'),
                                content: Text('Are you sure you want to delete "${service.nameEn}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<AdminProvider>().deleteService(service.id);
                                      Navigator.pop(ctx);
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'Delete Service',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Staff Tiers List
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AVAILABLE CAREGIVER TIERS & RESPONSIBILITIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.slate800,
                      ),
                    ),
                    Text(
                      '${service.tiers.length} Tiers Defined',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: service.tiers.map((tier) {
                    final isHighlighted = tier.tierId.contains('nvq_4') || tier.tierId.contains('doctor');
                    return Container(
                      width: 280,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isHighlighted ? AppTheme.primaryBlue.withOpacity(0.4) : Colors.grey.shade200,
                          width: isHighlighted ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tier.tierName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isHighlighted ? AppTheme.primaryBlue : AppTheme.slate900,
                                  ),
                                ),
                              ),
                              Text(
                                currencyFormat.format(tier.priceLKR),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.slate900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...tier.duties.map((duty) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.emeraldGreen),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        duty,
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openServiceDialog(BuildContext context, ServiceModel? existing) {
    final isEditing = existing != null;
    final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final nameSiCtrl = TextEditingController(text: existing?.nameSi ?? '');
    final descCtrl = TextEditingController(text: existing?.shortDescription ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.defaultPriceLKR.toString() : '4500');
    final hoursCtrl = TextEditingController(text: existing != null ? existing.hours.toString() : '12');
    String category = existing?.category ?? 'elderly_care';
    String pricingUnit = existing?.pricingUnit ?? '/ day';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Care Package' : 'Create New Care Package'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameEnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Package Name (English)',
                        hintText: 'e.g. 12-Hour Day Shift Care',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameSiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Package Name (Sinhala)',
                        hintText: 'e.g. පැය 12 දිවා සාත්තු සේවය',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                              DropdownMenuItem(value: 'elderly_care', child: Text('Elderly Care')),
                              DropdownMenuItem(value: 'child_care', child: Text('Child & Maternity')),
                              DropdownMenuItem(value: 'short_visit', child: Text('Doctor Home Visit')),
                              DropdownMenuItem(value: 'specialized', child: Text('Specialized Medical')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: hoursCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Shift Hours',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Base Price (LKR)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: pricingUnit,
                            decoration: const InputDecoration(
                              labelText: 'Billing Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: '/ day', child: Text('/ day (දිනකට)')),
                              DropdownMenuItem(value: '/ night', child: Text('/ night (රාත්‍රියකට)')),
                              DropdownMenuItem(value: '/ visit', child: Text('/ visit (පැමිණීමකට)')),
                              DropdownMenuItem(value: '/ month', child: Text('/ month (මසකට)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => pricingUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Short Description',
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
                  final updatedService = ServiceModel(
                    id: existing?.id ?? 'svc_${DateTime.now().millisecondsSinceEpoch}',
                    nameEn: nameEnCtrl.text.trim(),
                    nameSi: nameSiCtrl.text.trim().isEmpty ? nameEnCtrl.text.trim() : nameSiCtrl.text.trim(),
                    category: category,
                    hours: int.tryParse(hoursCtrl.text.trim()) ?? 12,
                    defaultPriceLKR: double.tryParse(priceCtrl.text.trim()) ?? 4500,
                    pricingUnit: pricingUnit,
                    shortDescription: descCtrl.text.trim(),
                    tiers: existing?.tiers ?? [
                      TierPricing(
                        tierId: 'nvq_4_caregiver',
                        tierName: 'NVQ 4 Certified Caregiver',
                        priceLKR: double.tryParse(priceCtrl.text.trim()) ?? 4500,
                        duties: ['Assisted bathing', 'Vitals recording', 'Feeding and medicine reminder'],
                      ),
                    ],
                  );

                  if (isEditing) {
                    context.read<AdminProvider>().updateService(updatedService);
                  } else {
                    context.read<AdminProvider>().addService(updatedService);
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEditing ? 'Save Changes' : 'Create Package'),
              ),
            ],
          );
        },
      ),
    );
  }
}
