import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/features/profile/models/principal_profile.dart';
import 'package:principal_portal/features/profile/providers/principal_profile_providers.dart';

import 'fixtures/portal_fixtures.dart';

/// Regression cover for a blank `principal_profiles.name`.
///
/// `AppShell` derived the avatar initial with:
///
/// ```dart
/// final profileName = ...valueOrNull?.name.trim() ?? 'Principal';
/// userInitial: profileName.characters.first,
/// ```
///
/// `??` fires on null only. `PrincipalProfile.name` is built with
/// `row.strOr('name', '')`, so a NULL or blank `name` column arrives as an
/// empty string, `??` does not fire, and `''.characters.first` throws
/// `Bad state: No element`. That happens inside the shell that wraps every
/// route, so the failure was not confined to the profile screen — the whole
/// portal rendered a red error box on every page.
///
/// The existing suite never caught it because no fixture supplies a profile at
/// all: `principalProfileProvider` throws without a database, `valueOrNull` is
/// null, and only the null branch was ever exercised.
void main() {
  const Size surface = Size(1600, 1200);

  PrincipalProfile profileNamed(String name) => PrincipalProfile(
    name: name,
    designation: 'Principal',
    employeeId: 'KSRCE/PRIN/001',
    dateOfBirth: DateTime(1970),
    gender: '—',
    experienceYears: 0,
    hodExperienceYears: 0,
    education: const [],
    researchPapers: const [],
    awards: const [],
    documents: const [],
    responsibilities: const [],
    officeDetails: const OfficeDetails(
      cabinLocation: '—',
      officeHours: '—',
      extensionNumber: '—',
    ),
    contactInfo: const ContactInfo(email: '—', phone: '—', address: '—'),
  );

  Future<void> pumpWithProfileName(WidgetTester tester, String name) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() {
      tester.view.reset();
      return tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...portalOverrides(),
          principalProfileProvider.overrideWith(
            (ref) async => profileNamed(name),
          ),
        ],
        child: const PrincipalPortalApp(),
      ),
    );

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('a blank profile name does not take the shell down', (
    tester,
  ) async {
    await pumpWithProfileName(tester, '');

    expect(
      tester.takeException(),
      isNull,
      reason:
          'An empty name reached String.characters.first and threw '
          'Bad state: No element, which failed every route in the portal.',
    );
  });

  testWidgets('a whitespace-only profile name does not take the shell down', (
    tester,
  ) async {
    await pumpWithProfileName(tester, '   ');

    expect(tester.takeException(), isNull);
  });

  testWidgets('a real name still supplies its own initial', (tester) async {
    await pumpWithProfileName(tester, 'Dr. S. Venkataraman');

    expect(tester.takeException(), isNull);
    expect(find.text('Dr. S. Venkataraman'), findsWidgets);
  });
}
