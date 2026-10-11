import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_app_bar.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String? currentPath;

  const MainLayout({
    super.key,
    required this.child,
    this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        backgroundColor: AppTheme.slate100,
        body: Row(
          children: [
            // Dark Navigation Sidebar synced with URL routes
            Sidebar(currentPath: currentPath),

            // Main Content Body with Global Top Bar
            Expanded(
              child: Column(
                children: [
                  const TopAppBar(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
