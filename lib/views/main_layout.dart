import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_app_bar.dart';
import '../theme/app_theme.dart';
import 'dashboard_view.dart';
import 'bookings_view.dart';
import 'services_manager_view.dart';
import 'store_inventory_view.dart';
import 'orders_rentals_view.dart';
import 'staff_directory_view.dart';
import 'clinical_logs_view.dart';
import 'reports_settings_view.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIdx = context.watch<AdminProvider>().selectedNavIndex;

    final views = const [
      DashboardView(),
      BookingsView(),
      ServicesManagerView(),
      StoreInventoryView(),
      OrdersRentalsView(),
      StaffDirectoryView(),
      ClinicalLogsView(),
      ReportsSettingsView(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.slate100,
      body: Row(
        children: [
          // Collapsible / Fixed Dark Sidebar
          const Sidebar(),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Global Bar
                const TopAppBar(),

                // Active Module View
                Expanded(
                  child: IndexedStack(
                    index: selectedIdx.clamp(0, views.length - 1),
                    children: views,
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
