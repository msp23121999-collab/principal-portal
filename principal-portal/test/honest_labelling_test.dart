import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/widgets/layout/sidebar_item.dart';

import 'fixtures/portal_fixtures.dart';

/// Guards a screen that once described something this portal cannot do.
///
/// **Account Security** stated a password "last changed 45 days ago",
/// offered Change Password, showed a working two-factor toggle, and listed two
/// recent sign-ins with times and browsers. There is no authentication in this
/// portal at all — no login route, no session, no credentials.
///
/// An empty screen looks empty, so nobody is fooled by it. This one looked
/// finished, which is why it needs a test and the empty ones do not.
///
/// Digital Repository had the same problem — drag-and-drop upload and a
/// per-row Download for files that were never stored — and was covered here
/// too until the screen was removed from the portal entirely.
const Size _surface = Size(1600, 1500);
const Duration _mockLatency = Duration(milliseconds: 600);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(_mockLatency);
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() {
    tester.view.reset();
    return tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: portalOverrides(),
      child: const PrincipalPortalApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _open(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(of: find.byType(SidebarItem), matching: find.text(label))
        .first,
  );
  await _settle(tester);
}

void main() {
  group('Direct-access portal does not claim authentication UI', () {
    testWidgets('does not expose an obsolete Account Security tab', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _open(tester, 'My Profile');

      expect(find.text('Account Security'), findsNothing);
      expect(find.text('Sign-in is Enabled'), findsNothing);
      expect(find.textContaining('Row-Level Security'), findsNothing);
      expect(find.textContaining('enforces strict authentication'), findsNothing);
    });

    testWidgets('shows no invented password age or login history', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _open(tester, 'My Profile');

      for (final invented in const [
        'Last changed 45 days ago',
        'Today, 09:14 AM — Chrome on Windows',
        'Yesterday, 06:48 PM — Chrome on Windows',
      ]) {
        expect(
          find.text(invented),
          findsNothing,
          reason: '"$invented" was a fixed string, not a fact.',
        );
      }
    });

    testWidgets('does not expose dead authentication controls', (tester) async {
      await _pumpApp(tester);
      await _open(tester, 'My Profile');

      expect(find.text('Two-factor authentication'), findsNothing);
      expect(find.text('Change Password'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });
  });
}
