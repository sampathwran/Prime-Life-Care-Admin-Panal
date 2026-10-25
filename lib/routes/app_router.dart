import 'package:go_router/go_router.dart';
import '../views/main_layout.dart';
import '../views/dashboard_view.dart';
import '../views/bookings_view.dart';
import '../views/registered_users_view.dart';
import '../views/services_manager_view.dart';
import '../views/store_inventory_view.dart';
import '../views/orders_rentals_view.dart';
import '../views/staff_directory_view.dart';
import '../views/staff_approvals_view.dart';
import '../views/clinical_logs_view.dart';
import '../views/reviews_manager_view.dart';
import '../views/gallery_manager_view.dart';
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
          path: '/users',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RegisteredUsersView(),
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
          path: '/staff-approvals',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StaffApprovalsView(),
          ),
        ),
        GoRoute(
          path: '/clinical-logs',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ClinicalLogsView(),
          ),
        ),
        GoRoute(
          path: '/reviews',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReviewsManagerView(),
          ),
        ),
        GoRoute(
          path: '/gallery',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GalleryManagerView(),
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
