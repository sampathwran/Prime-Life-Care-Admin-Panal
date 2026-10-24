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
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'
  final TextEditingController _searchCtrl = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getServiceIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'moon':
        return Icons.nights_stay_rounded;
      case 'home':
        return Icons.home_work_rounded;
      case 'baby':
        return Icons.child_care_rounded;
      case 'brain':
        return Icons.psychology_rounded;
      case 'clock':
        return Icons.access_time_filled_rounded;
      case 'smile':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'heartpulse':
      default:
        return Icons.medical_services_rounded;
    }
  }

  Color _getIconColor(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'sun':
        return Colors.amber.shade700;
      case 'moon':
        return Colors.indigo.shade600;
      case 'home':
        return AppTheme.primaryBlue;
      case 'baby':
        return Colors.pink.shade500;
      case 'brain':
        return Colors.purple.shade600;
      case 'clock':
        return Colors.blueGrey.shade700;
      case 'smile':
        return Colors.teal.shade600;
      case 'heartpulse':
      default:
        return AppTheme.rose600;
    }
  }

  Color _getIconBgColor(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'sun':
        return Colors.amber.shade50;
      case 'moon':
        return Colors.indigo.shade50;
      case 'home':
        return AppTheme.blueLight;
      case 'baby':
        return Colors.pink.shade50;
      case 'brain':
        return Colors.purple.shade50;
      case 'clock':
        return Colors.blueGrey.shade50;
      case 'smile':
        return Colors.teal.shade50;
      case 'heartpulse':
      default:
        return AppTheme.rose50;
    }
  }

  String _getCategoryDisplayName(String catKey) {
    switch (catKey.toLowerCase()) {
      case 'elderly_care':
        return 'Elderly Care';
      case 'child_care':
        return 'Child & Post-Natal';
      case 'short_visit':
        return 'Doctor Home Visits';
      case 'recovery':
        return 'Post-Surgery Recovery';
      case 'specialized':
        return 'Specialized Care';
      case 'clinical':
        return 'Clinical Assessment';
      default:
        return catKey
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final allServices = provider.services;

    // Dynamically collect unique categories from data
    final Set<String> categoriesSet = {'all', 'elderly_care', 'child_care', 'short_visit'};
    for (final s in allServices) {
      if (s.category.isNotEmpty) categoriesSet.add(s.category);
    }
    final categoryList = categoriesSet.toList();

    final query = _searchQuery.trim().toLowerCase();
    final currentStatus = _statusFilter;
    final currentCategory = _selectedCategory;

    // Filter services based on category, search query, and status
    final filteredServices = allServices.where((s) {
      // Category filter
      if (currentCategory != 'all' && s.category != currentCategory) {
        return false;
      }
      // Status filter
      if (currentStatus == 'active' && !s.isActive) return false;
      if (currentStatus == 'inactive' && s.isActive) return false;

      // Search query
      if (query.isNotEmpty) {
        final matchName = s.nameEn.toLowerCase().contains(query) || s.nameSi.toLowerCase().contains(query);
        final matchDesc = s.shortDescription.toLowerCase().contains(query) || s.shortDescriptionSi.toLowerCase().contains(query);
        final matchTier = s.tiers.any((t) =>
            t.tierName.toLowerCase().contains(query) ||
            t.duties.any((d) => d.toLowerCase().contains(query)));
        return matchName || matchDesc || matchTier;
      }

      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================= TOP HEADER BAR =======================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Care Packages & Staff Tiers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.slate900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.emerald200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_done_rounded, size: 12, color: AppTheme.emerald800),
                              SizedBox(width: 4),
                              Text(
                                'Live Web Sync',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.emerald800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage home healthcare packages, caregiver tiers (NVQ 4, NVQ 5, Nurse, Doctor) and dynamic shift pricing live on the web.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Global "Publish All to Website" Button
                  ElevatedButton.icon(
                    onPressed: provider.isPublishingServices
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await provider.publishAllServicesToFirestore();
                            messenger.hideCurrentSnackBar();
                            if (success) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'All ${provider.services.length} Care Packages & Staff Tiers successfully published live to primelifecare.lk website!',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.emeraldGreen,
                                  duration: const Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to publish services. Please check connection.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    icon: provider.isPublishingServices
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: Text(
                      provider.isPublishingServices ? 'Publishing...' : 'Publish All to Website',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add New Service button
                  ElevatedButton.icon(
                    onPressed: () => _openServiceDialog(context, null),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add New Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================= SEARCH & FILTER BAR =======================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Search Input
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search packages, tiers or responsibilities...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      filled: true,
                      fillColor: Colors.grey.shade50,
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
                const SizedBox(width: 12),

                // Status Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.slate800, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'active', child: Text('Live on Web Only ✓')),
                        DropdownMenuItem(value: 'inactive', child: Text('Drafts / Hidden ✕')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _statusFilter = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ======================= CATEGORY FILTER TABS =======================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categoryList.map((catKey) {
                final count = catKey == 'all'
                    ? allServices.length
                    : allServices.where((s) => s.category == catKey).length;
                final label = catKey == 'all' ? 'All Packages' : _getCategoryDisplayName(catKey);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildCategoryChip(label, catKey, count),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // ======================= SERVICES LIST =======================
          filteredServices.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 44, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          'No services found matching your criteria.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try changing filters or click "Add New Service" to create one.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredServices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    return _buildServiceCard(context, service, provider);
                  },
                ),
        ],
      ),
    );
  }

  // ======================= CATEGORY CHIP =======================
  Widget _buildCategoryChip(String label, String categoryKey, int count) {
    final isSelected = _selectedCategory == categoryKey;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = categoryKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                  fontSize: 10,
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

  // ======================= MAIN SERVICE CARD =======================
  Widget _buildServiceCard(BuildContext context, ServiceModel service, AdminProvider provider) {
    final iconColor = _getIconColor(service.icon);
    final iconBgColor = _getIconBgColor(service.icon);
    final iconData = _getServiceIconData(service.icon);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: service.isActive ? Colors.grey.shade200 : Colors.grey.shade300,
          width: service.isActive ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconColor.withOpacity(0.2)),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            service.nameEn,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.slate900,
                            ),
                          ),
                          // Shift Hours Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Text(
                              '${service.hours} Hours Shift',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.blueLight,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                            ),
                            child: Text(
                              _getCategoryDisplayName(service.category),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          // Published / Live Status Switch
                          InkWell(
                            onTap: () {
                              provider.toggleServiceActive(service.id, !service.isActive);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    !service.isActive
                                        ? '${service.nameEn} is now LIVE on the website!'
                                        : '${service.nameEn} has been hidden from website.',
                                  ),
                                  backgroundColor: !service.isActive ? AppTheme.emeraldGreen : Colors.grey.shade800,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: service.isActive ? AppTheme.emerald50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: service.isActive ? AppTheme.emerald200 : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    service.isActive ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
                                    size: 11,
                                    color: service.isActive ? AppTheme.emerald800 : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    service.isActive ? 'Live on Web ✓' : 'Draft / Hidden',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: service.isActive ? AppTheme.emerald800 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        service.nameSi,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.shortDescription,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Pricing & Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Starting from',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    Text(
                      currencyFormat.format(service.defaultPriceLKR),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      service.pricingUnit,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Package
                        OutlinedButton.icon(
                          onPressed: () => _openServiceDialog(context, service),
                          icon: const Icon(Icons.edit_outlined, size: 13),
                          label: const Text('Edit Package', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            minimumSize: Size.zero,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Add Tier Shortcut
                        ElevatedButton.icon(
                          onPressed: () => _openTierDialog(context, service: service, existingTier: null),
                          icon: const Icon(Icons.add_rounded, size: 13),
                          label: const Text('Add Tier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            minimumSize: Size.zero,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Delete Package
                        IconButton(
                          onPressed: () => _confirmDeletePackage(context, service, provider),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          tooltip: 'Delete Package',
                          padding: const EdgeInsets.all(5),
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(backgroundColor: Colors.red.shade50),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tiers Sub-Section
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'AVAILABLE CAREGIVER TIERS & RESPONSIBILITIES',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppTheme.slate800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            '${service.tiers.length} Tiers Defined',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _openTierDialog(context, service: service, existingTier: null),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 13, color: AppTheme.primaryBlue),
                      label: const Text('+ Add New Tier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Responsive Tiers Cards Wrap
                service.tiers.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Text(
                            'No tiers added yet. Click "+ Add New Tier" above to define staff qualification pricing.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: service.tiers.map((tier) {
                          return _buildTierCard(context, service, tier, provider);
                        }).toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================= INDIVIDUAL TIER CARD =======================
  Widget _buildTierCard(BuildContext context, ServiceModel service, TierPricing tier, AdminProvider provider) {
    final isHighlighted = tier.isRecommended || tier.tierId.contains('nvq_4') || tier.tierId.contains('doctor');

    return Container(
      width: 275,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? AppTheme.primaryBlue.withOpacity(0.4) : Colors.grey.shade200,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.tierName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted ? AppTheme.primaryBlue : AppTheme.slate900,
                      ),
                    ),
                    if (tier.badge.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isHighlighted ? Colors.amber.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isHighlighted ? Colors.amber.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          tier.badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isHighlighted ? Colors.amber.shade900 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openQuickPriceDialog(context, service, tier, provider),
                borderRadius: BorderRadius.circular(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'Client: ${currencyFormat.format(tier.priceLKR)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Staff: LKR ${tier.staffPayoutRateLKR.toInt()}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Duties list
          ...tier.duties.map((duty) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.emeraldGreen),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        duty,
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 6),

          // Actions row inside Tier
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _openTierDialog(context, service: service, existingTier: tier),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 12, color: Colors.grey.shade700),
                      const SizedBox(width: 3),
                      Text('Edit Tier', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _confirmDeleteTier(context, service, tier, provider),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 12, color: Colors.red),
                      SizedBox(width: 3),
                      Text('Delete', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================= DELETE CONFIRMATIONS =======================
  void _confirmDeletePackage(BuildContext context, ServiceModel service, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Care Package?'),
        content: Text('Are you sure you want to permanently delete "${service.nameEn}"?\n\nThis will remove it from both the Admin Portal and the Public Website.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.deleteService(service.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Package "${service.nameEn}" deleted!'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTier(BuildContext context, ServiceModel service, TierPricing tier, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Tier?'),
        content: Text('Are you sure you want to remove tier "${tier.tierName}" from package "${service.nameEn}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.deleteTier(serviceId: service.id, tierId: tier.tierId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tier "${tier.tierName}" removed!'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove Tier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ======================= QUICK PRICE EDIT =======================
  void _openQuickPriceDialog(BuildContext context, ServiceModel service, TierPricing tier, AdminProvider provider) {
    final priceCtrl = TextEditingController(text: tier.priceLKR.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Price - ${tier.tierName}'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service: ${service.nameEn}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Rate in LKR',
                  prefixText: 'LKR ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceCtrl.text.trim());
              if (newPrice != null && newPrice > 0) {
                provider.updateServicePrice(service.id, tier.tierId, newPrice);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Price updated to LKR ${currencyFormat.format(newPrice)} for ${tier.tierName}!'),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            child: const Text('Save Price'),
          ),
        ],
      ),
    );
  }

  // ======================= PACKAGE CREATE / EDIT DIALOG =======================
  void _openServiceDialog(BuildContext context, ServiceModel? existing) {
    final isEditing = existing != null;
    final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final nameSiCtrl = TextEditingController(text: existing?.nameSi ?? '');
    final descEnCtrl = TextEditingController(text: existing?.shortDescription ?? '');
    final descSiCtrl = TextEditingController(text: existing?.shortDescriptionSi ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.defaultPriceLKR.toInt().toString() : '4500');
    final hoursCtrl = TextEditingController(text: existing != null ? existing.hours.toString() : '12');

    String category = existing?.category ?? 'elderly_care';
    String shiftType = existing?.shiftType ?? '12h_day';
    String pricingUnit = existing?.pricingUnit ?? '/ day';
    String icon = existing?.icon ?? 'HeartPulse';
    bool isActive = existing?.isActive ?? true;

    final List<TierPricing> tempTiers = existing != null
        ? List<TierPricing>.from(existing.tiers)
        : [
            TierPricing(
              tierId: 'basic_aide',
              tierName: 'Basic Companion Aide',
              tierNameSi: 'මූලික සහායක',
              priceLKR: 3000,
              duties: ['Friendly conversation & companionship', 'Assistance with routine meals', 'Accompanying on short walks'],
            ),
            TierPricing(
              tierId: 'nvq_4_caregiver',
              tierName: 'NVQ 4 Certified Caregiver',
              tierNameSi: 'NVQ 4 පුහුණු සාත්තු',
              badge: 'Most Popular ⭐',
              isRecommended: true,
              priceLKR: 4500,
              duties: ['Bed turning every 2h & pressure sore care', 'Daily vitals log (BP, Sugar, Pulse)', 'Strict medication adherence'],
            ),
          ];

    final List<String> availableIcons = ['Sun', 'Moon', 'Home', 'HeartPulse', 'Baby', 'Brain', 'Clock', 'Smile'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEditing ? 'Edit Care Package' : 'Create New Care Package', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: Container(
              width: 650,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: English & Sinhala Names
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameEnCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Package Name (English) *',
                              hintText: 'e.g. 12-Hour Day Shift Care',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: nameSiCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Package Name (Sinhala)',
                              hintText: 'e.g. පැය 12 දිවා සාත්තු සේවය',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Category & Shift Hours
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ['elderly_care', 'child_care', 'short_visit', 'recovery', 'specialized', 'clinical'].contains(category)
                                ? category
                                : 'elderly_care',
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'elderly_care', child: Text('Elderly Care')),
                              DropdownMenuItem(value: 'child_care', child: Text('Child & Post-Natal')),
                              DropdownMenuItem(value: 'short_visit', child: Text('Doctor Home Visits')),
                              DropdownMenuItem(value: 'recovery', child: Text('Post-Surgery Recovery')),
                              DropdownMenuItem(value: 'specialized', child: Text('Specialized Medical')),
                              DropdownMenuItem(value: 'clinical', child: Text('Clinical Assessment')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: hoursCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Shift Hours (e.g. 12, 24, 2)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 3: Starting Base Price & Billing Unit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Starting Base Price (LKR)',
                              prefixText: 'LKR ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ['/ day', '/ night', '/ visit', '/ month'].contains(pricingUnit) ? pricingUnit : '/ day',
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
                    const SizedBox(height: 12),

                    // Icon Picker Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Package Icon:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableIcons.map((icName) {
                              final isIcSelected = icon.toLowerCase() == icName.toLowerCase();
                              final icData = _getServiceIconData(icName);
                              final icColor = _getIconColor(icName);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => setDialogState(() => icon = icName),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isIcSelected ? icColor.withOpacity(0.12) : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isIcSelected ? icColor : Colors.grey.shade300,
                                        width: isIcSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(icData, color: icColor, size: 16),
                                        const SizedBox(width: 5),
                                        Text(
                                          icName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isIcSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isIcSelected ? icColor : Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Short Description (English & Sinhala)
                    TextField(
                      controller: descEnCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Short Description (English)',
                        hintText: 'e.g. 07:00 AM - 07:00 PM dedicated daytime care for bedridden or elderly...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descSiCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Short Description (Sinhala)',
                        hintText: 'e.g. උදෑසන 7 සිට සවස 7 දක්වා ඇඳ විවේකයේ සිටින වැඩිහිටියන් සඳහා...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Published on Web Switch
                    SwitchListTile(
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                      title: const Text('Publish Live on Website', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      subtitle: const Text('When enabled, this care package will be visible to public users on primelifecare.lk', style: TextStyle(fontSize: 10.5)),
                      activeColor: AppTheme.emeraldGreen,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const Divider(),
                    const SizedBox(height: 6),

                    // Tiers in this package list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Caregiver Tiers (${tempTiers.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate900)),
                        TextButton.icon(
                          onPressed: () {
                            _openQuickAddTierInsideDialog(context, onAdded: (newTier) {
                              setDialogState(() => tempTiers.add(newTier));
                            });
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Tier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    ...tempTiers.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final t = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.tierName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  Text('${currencyFormat.format(t.priceLKR)} ${t.pricingUnit} • ${t.duties.length} responsibilities', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                              onPressed: () {
                                setDialogState(() => tempTiers.removeAt(idx));
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                onPressed: () async {
                  if (nameEnCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a Package Name in English!'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final pkgId = existing?.id ?? 'svc_${DateTime.now().millisecondsSinceEpoch}';
                  final hours = int.tryParse(hoursCtrl.text.trim()) ?? 12;
                  final defaultPrice = double.tryParse(priceCtrl.text.trim()) ?? 4500.0;

                  final updatedPkg = ServiceModel(
                    id: pkgId,
                    nameEn: nameEnCtrl.text.trim(),
                    nameSi: nameSiCtrl.text.trim().isNotEmpty ? nameSiCtrl.text.trim() : nameEnCtrl.text.trim(),
                    category: category,
                    hours: hours,
                    shiftType: shiftType,
                    defaultPriceLKR: defaultPrice,
                    pricingUnit: pricingUnit,
                    shortDescription: descEnCtrl.text.trim(),
                    shortDescriptionSi: descSiCtrl.text.trim(),
                    icon: icon,
                    tiers: tempTiers,
                    isActive: isActive,
                    sortOrder: existing?.sortOrder ?? 10,
                  );

                  final messenger = ScaffoldMessenger.of(context);
                  final adminProvider = context.read<AdminProvider>();
                  Navigator.pop(ctx);

                  if (isEditing) {
                    await adminProvider.updateService(updatedPkg);
                  } else {
                    await adminProvider.addService(updatedPkg);
                  }
                  await adminProvider.publishAllServicesToFirestore();

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Care package "${updatedPkg.nameEn}" saved and published to website!'),
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(isEditing ? 'Save & Publish Changes' : 'Create & Publish Package'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper to add a tier while inside the Package dialog
  void _openQuickAddTierInsideDialog(BuildContext context, {required Function(TierPricing) onAdded}) {
    final tNameCtrl = TextEditingController();
    final tPriceCtrl = TextEditingController(text: '4500');
    final tDutiesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (qCtx) => AlertDialog(
        title: const Text('Add Tier to Package'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tNameCtrl,
                decoration: const InputDecoration(labelText: 'Tier Name (e.g. NVQ 4 Certified Caregiver)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price per Shift (LKR)', prefixText: 'LKR ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tDutiesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Responsibilities (one per line)',
                  hintText: 'Assisted sponge bathing\nRoutine meal prep\nFeeding & medication reminding',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(qCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (tNameCtrl.text.trim().isEmpty) return;
              final dutiesList = tDutiesCtrl.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final newTier = TierPricing(
                tierId: 'tier_${DateTime.now().millisecondsSinceEpoch}',
                tierName: tNameCtrl.text.trim(),
                priceLKR: double.tryParse(tPriceCtrl.text.trim()) ?? 4500.0,
                duties: dutiesList.isNotEmpty ? dutiesList : ['Dedicated patient care and routine assistance'],
              );
              onAdded(newTier);
              Navigator.pop(qCtx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ======================= STANDALONE TIER EDIT / CREATE MODAL =======================
  void _openTierDialog(BuildContext context, {required ServiceModel service, TierPricing? existingTier}) {
    final isEditing = existingTier != null;
    final nameCtrl = TextEditingController(text: existingTier?.tierName ?? '');
    final nameSiCtrl = TextEditingController(text: existingTier?.tierNameSi ?? '');
    final badgeCtrl = TextEditingController(text: existingTier?.badge ?? '');
    final priceCtrl = TextEditingController(text: existingTier != null ? existingTier.priceLKR.toInt().toString() : '4500');
    final staffPayoutCtrl = TextEditingController(text: existingTier != null ? existingTier.staffPayoutRateLKR.toInt().toString() : '3600');
    final dutyInputCtrl = TextEditingController();
    bool isRecommended = existingTier?.isRecommended ?? false;
    String pricingUnit = existingTier?.pricingUnit ?? service.pricingUnit;

    final List<String> duties = existingTier != null
        ? List<String>.from(existingTier.duties)
        : [
            'Conversation & companionship',
            'Assisted sponge bathing',
            'Routine meal prep',
            'Feeding & medication reminding',
          ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setTierState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEditing ? 'Edit Staff Tier' : 'Add New Staff Tier', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Package: ${service.nameEn}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: Container(
              width: 520,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier Name English
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tier Title (English) *',
                        hintText: 'e.g. NVQ 4 Certified Caregiver',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tier Name Sinhala
                    TextField(
                      controller: nameSiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tier Title (Sinhala)',
                        hintText: 'e.g. NVQ 4 පුහුණු සාත්තු සේවක',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price & Pricing Unit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price per Shift (Client) *',
                              prefixText: 'LKR ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: staffPayoutCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Staff Payout Rate (LKR) *',
                              prefixText: 'LKR ',
                              helperText: 'Shown on Staff App',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ['/ day', '/ night', '/ visit', '/ month'].contains(pricingUnit) ? pricingUnit : '/ day',
                            decoration: const InputDecoration(
                              labelText: 'Pricing Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: '/ day', child: Text('/ day (දිනකට)')),
                              DropdownMenuItem(value: '/ night', child: Text('/ night (රාත්‍රියකට)')),
                              DropdownMenuItem(value: '/ visit', child: Text('/ visit (පැමිණීමකට)')),
                              DropdownMenuItem(value: '/ month', child: Text('/ month (මසකට)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setTierState(() => pricingUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Badge Text
                    TextField(
                      controller: badgeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Badge Pill Text',
                        hintText: 'e.g. Most Popular ⭐, Diploma Clinical, Night Companion',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Recommended toggle
                    CheckboxListTile(
                      value: isRecommended,
                      onChanged: (val) => setTierState(() => isRecommended = val ?? false),
                      title: const Text('Highlight as Recommended Tier ⭐', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Adds prominent highlight border and recommendation badge on the website.', style: TextStyle(fontSize: 10.5)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const Divider(),
                    const SizedBox(height: 6),

                    // Responsibilities List
                    const Text('Responsibilities / Duties:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                    const SizedBox(height: 6),

                    // Duty add field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dutyInputCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Type a duty (e.g. Bed turning every 2h)...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setTierState(() {
                                  duties.add(val.trim());
                                  dutyInputCtrl.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (dutyInputCtrl.text.trim().isNotEmpty) {
                              setTierState(() {
                                duties.add(dutyInputCtrl.text.trim());
                                dutyInputCtrl.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Current duties list
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Column(
                          children: duties.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final duty = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.emeraldGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(duty, style: const TextStyle(fontSize: 11)),
                                  ),
                                  InkWell(
                                    onTap: () => setTierState(() => duties.removeAt(idx)),
                                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter Tier Title!'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final newTierObj = TierPricing(
                    tierId: existingTier?.tierId ?? 'tier_${DateTime.now().millisecondsSinceEpoch}',
                    tierName: nameCtrl.text.trim(),
                    tierNameSi: nameSiCtrl.text.trim(),
                    badge: badgeCtrl.text.trim(),
                    priceLKR: double.tryParse(priceCtrl.text.trim()) ?? 4500.0,
                    staffPayoutRateLKR: double.tryParse(staffPayoutCtrl.text.trim()) ?? ((double.tryParse(priceCtrl.text.trim()) ?? 4500.0) * 0.80),
                    pricingUnit: pricingUnit,
                    duties: duties.isNotEmpty ? duties : ['Patient companionship and routine care'],
                    isRecommended: isRecommended,
                  );

                  final messenger = ScaffoldMessenger.of(context);
                  final adminProvider = context.read<AdminProvider>();
                  Navigator.pop(ctx);

                  await adminProvider.saveTier(
                        serviceId: service.id,
                        tier: newTierObj,
                        isNew: !isEditing,
                      );

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Tier "${newTierObj.tierName}" saved for "${service.nameEn}"!'),
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                child: Text(isEditing ? 'Save Tier Changes' : 'Add Tier to Package'),
              ),
            ],
          );
        },
      ),
    );
  }
}
