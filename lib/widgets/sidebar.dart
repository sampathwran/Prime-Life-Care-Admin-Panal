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
    '/staff',
    '/staff-approvals',
    '/users',
    '/services',
    '/inventory',
    '/orders',
    '/clinical-logs',
    '/reviews',
    '/reports',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final selectedIdx = provider.selectedNavIndex;

    final pendingStaffApprovals = provider.caregivers
        .where((c) => c.isPendingApproval || c.hasPendingQualificationUpgrade)
        .length;

    final navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Executive Dashboard'},
      {'icon': Icons.assignment_rounded, 'label': 'All Bookings & Dispatch'},
      {'icon': Icons.badge_rounded, 'label': 'Caregivers & Staff'},
      {'icon': Icons.verified_user_rounded, 'label': 'Staff Approvals & Upgrades'},
      {'icon': Icons.people_outline_rounded, 'label': 'Registered Users & Families'},
      {'icon': Icons.medical_services_rounded, 'label': 'Services & Staff Tiers'},
      {'icon': Icons.storefront_rounded, 'label': 'Medical Store Inventory'},
      {'icon': Icons.local_shipping_rounded, 'label': 'Orders & Rentals'},
      {'icon': Icons.favorite_rounded, 'label': 'Clinical Logs & Vitals'},
      {'icon': Icons.star_rate_rounded, 'label': 'Google Reviews & Web'},
      {'icon': Icons.analytics_rounded, 'label': 'Reports & Settings'},
    ];

    return Container(
      width: 215,
      color: AppTheme.slate900,
      child: Column(
        children: [
          // Header / Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.favorite_rounded,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
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
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OPERATIONS ADMIN',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: navItems.length,
              itemBuilder: (context, idx) {
                final item = navItems[idx];
                final route = navRoutes[idx];
                final isSelected = currentPath != null
                    ? (currentPath == route || currentPath!.startsWith('$route/'))
                    : selectedIdx == idx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        provider.setSelectedNavIndex(idx);
                        if (idx == 1) {
                          provider.setSelectedBookingTab('all');
                        }
                        context.go(route);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected ? Colors.white : AppTheme.slate400,
                              size: 16,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.slate200,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            if (route == '/bookings' && provider.pendingDispatchesCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppTheme.amber500,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${provider.pendingDispatchesCount}',
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primaryBlue : AppTheme.slate900,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (route == '/staff' && provider.caregivers.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppTheme.primaryBlue.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${provider.caregivers.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (route == '/staff-approvals' && pendingStaffApprovals > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppTheme.amber500,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$pendingStaffApprovals',
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primaryBlue : AppTheme.slate900,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (route == '/users' && provider.users.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppTheme.emerald100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${provider.users.length}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.emerald800,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (route == '/orders' && provider.pendingOrdersCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppTheme.rose500,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${provider.pendingOrdersCount}',
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primaryBlue : Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (route == '/reviews' && provider.publishedReviews.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${provider.publishedReviews.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
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
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155), width: 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryBlue,
                  child: const Text(
                    'OP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'admin@primelifecare.lk',
                        style: TextStyle(
                          color: AppTheme.slate400,
                          fontSize: 9.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
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
