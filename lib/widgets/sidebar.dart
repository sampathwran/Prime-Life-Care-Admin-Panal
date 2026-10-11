import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final String? currentPath;

  const Sidebar({super.key, this.currentPath});

  static const List<String> navRoutes = [
    '/dashboard',
    '/bookings',
    '/services',
    '/inventory',
    '/orders',
    '/staff',
    '/clinical-logs',
    '/reports',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final selectedIdx = provider.selectedNavIndex;

    final navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Executive Dashboard'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Bookings & Dispatch'},
      {'icon': Icons.medical_services_rounded, 'label': 'Services & Staff Tiers'},
      {'icon': Icons.storefront_rounded, 'label': 'Medical Store Inventory'},
      {'icon': Icons.local_shipping_rounded, 'label': 'Orders & Rentals'},
      {'icon': Icons.people_alt_rounded, 'label': 'Caregivers & Staff'},
      {'icon': Icons.favorite_rounded, 'label': 'Clinical Logs & Vitals'},
      {'icon': Icons.analytics_rounded, 'label': 'Reports & Settings'},
    ];

    return Container(
      width: 270,
      color: AppTheme.slate900,
      child: Column(
        children: [
          // Header / Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                          children: [
                            TextSpan(
                              text: 'PRIME LIFE ',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'CARE',
                              style: TextStyle(color: Color(0xFF60A5FA)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OPERATIONS ADMIN',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nav Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, idx) {
                final item = navItems[idx];
                final route = navRoutes[idx];
                final isSelected = currentPath != null
                    ? (currentPath == route || currentPath!.startsWith('$route/'))
                    : selectedIdx == idx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        provider.setSelectedNavIndex(idx);
                        context.go(route);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected ? Colors.white : AppTheme.slate400,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.slate200,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (idx == 1 && provider.pendingDispatchesCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppTheme.amber500,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${provider.pendingDispatchesCount}',
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primaryBlue : AppTheme.slate900,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (idx == 4 && provider.pendingOrdersCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppTheme.rose500,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${provider.pendingOrdersCount}',
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primaryBlue : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User info footer
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155), width: 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryBlue,
                  child: const Text(
                    'OP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Operations Lead',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'admin@primelifecare.lk',
                        style: TextStyle(
                          color: AppTheme.slate400,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.emerald500,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
