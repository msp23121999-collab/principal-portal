import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/core/theme/app_typography.dart';

/// Locks Inter to the bundle.
///
/// The portal used to call `GoogleFonts.interTextTheme()`, which fetches the
/// typeface from `fonts.gstatic.com` on first paint. When that request is slow,
/// blocked by a campus filter, or refused by a Content-Security-Policy, Flutter
/// does not fail — it quietly renders the platform default and the whole type
/// scale shifts. A silent fallback is exactly the kind of regression no visual
/// test catches, so the wiring is asserted here instead.
///
/// These tests read `pubspec.yaml` and the asset directory rather than trusting
/// the declaration, because the three things that must agree — the family name
/// in Dart, the family name in the manifest, and the files on disk — are
/// declared in three different places and Flutter reports a mismatch by
/// substituting a different font rather than by throwing.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  /// The weights the portal actually renders. Adding one here without adding
  /// the file makes Flutter synthesise it, which looks subtly wrong.
  const expectedWeights = <int>[400, 500, 600, 700];

  test('the pubspec was found', () {
    // Guards the guard: run from the wrong directory and every assertion below
    // would pass against an empty string.
    expect(pubspec, contains('name: principal_portal'));
  });

  test('google_fonts is not a dependency', () {
    expect(
      pubspec.contains('google_fonts'),
      isFalse,
      reason:
          'Re-adding google_fonts reintroduces a runtime request to a third '
          'party and puts an external origin back into the CSP.',
    );
  });

  test('no source file reaches for GoogleFonts', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('GoogleFonts'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the Inter family is declared with every weight the portal uses', () {
    expect(pubspec, contains('family: Inter'));

    for (final weight in expectedWeights) {
      expect(
        pubspec,
        contains('weight: $weight'),
        reason: 'Weight $weight is rendered somewhere in lib/ but not bundled.',
      );
    }
  });

  test('every font asset the pubspec declares is actually on disk', () {
    // A declared-but-missing asset fails the build, but a *renamed* one fails
    // by falling back — so the file list is checked, not just the declaration.
    final declared = RegExp(
      r'asset:\s*(assets/fonts/[^\s]+)',
    ).allMatches(pubspec).map((m) => m.group(1)!).toList();

    expect(
      declared.length,
      expectedWeights.length,
      reason: 'Expected one asset per bundled weight.',
    );

    for (final path in declared) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: '$path is declared in pubspec.yaml but is not in the tree.',
      );
    }
  });

  test('the licence ships with the fonts, as the OFL requires', () {
    final licence = File('assets/fonts/OFL.txt');
    expect(licence.existsSync(), isTrue);
    expect(
      licence.readAsStringSync(),
      contains('SIL OPEN FONT LICENSE'),
      reason: 'The OFL requires the licence to travel with the font files.',
    );
  });

  test('every text theme slot resolves to the bundled family', () {
    // `.apply(fontFamily:)` is what carries the family onto the slots the theme
    // does not restate. If that call were dropped, the restated slots would
    // still look right while the rest silently fell back.
    final theme = AppTypography.textTheme;

    final slots = <String, TextStyle?>{
      'displayLarge': theme.displayLarge,
      'displayMedium': theme.displayMedium,
      'displaySmall': theme.displaySmall,
      'headlineMedium': theme.headlineMedium,
      'headlineSmall': theme.headlineSmall,
      'titleLarge': theme.titleLarge,
      'titleMedium': theme.titleMedium,
      'titleSmall': theme.titleSmall,
      'bodyLarge': theme.bodyLarge,
      'bodyMedium': theme.bodyMedium,
      'bodySmall': theme.bodySmall,
      'labelLarge': theme.labelLarge,
      'labelSmall': theme.labelSmall,
    };

    slots.forEach((name, style) {
      expect(
        style?.fontFamily,
        AppTypography.fontFamily,
        reason: '$name does not use the bundled family.',
      );
    });
  });
}
