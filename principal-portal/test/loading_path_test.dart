import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/features/dashboard/screens/dashboard_screen.dart';

void main() {
  testWidgets('Loading path UI test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 2000));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );

    await tester.pump();
  });
}
