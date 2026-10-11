import 'package:go_router/go_router.dart';
import '../views/main_layout.dart';
import '../views/dashboard_view.dart';
import '../views/bookings_view.dart';
import '../views/services_manager_view.dart';
import '../views/store_inventory_view.dart';
import '../views/orders_rentals_view.dart';
import '../views/staff_directory_view.dart';
import '../views/clinical_logs_view.dart';
import '../views/reports_settings_view.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/dashboard',
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardView(),
          ),
        ),
        GoRoute(
          path: '/bookings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookingsView(),
          ),
        ),
        GoRoute(
          path: '/services',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ServicesManagerView(),
          ),
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StoreInventoryView(),
          ),
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OrdersRentalsView(),
          ),
        ),
        GoRoute(
          path: '/staff',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StaffDirectoryView(),
          ),
        ),
        GoRoute(
          path: '/clinical-logs',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ClinicalLogsView(),
          ),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReportsSettingsView(),
          ),
        ),
      ],
    ),
  ],
);
