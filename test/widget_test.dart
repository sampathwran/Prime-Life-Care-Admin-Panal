import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prime_life_care_admin/main.dart';
import 'package:prime_life_care_admin/providers/admin_provider.dart';

void main() {
  testWidgets('Admin panel smoke test on desktop viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AdminProvider(),
        child: const PrimeLifeCareAdminApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    expect(find.text('OPERATIONS ADMIN'), findsOneWidget);
    expect(find.text('Executive Operations Overview'), findsOneWidget);
  });
}
