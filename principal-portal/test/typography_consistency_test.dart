import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Locks the type scale in place.
///
/// Every page in the portal reads its text sizes from one place —
/// `AppTypography.textTheme`, mapped onto the Material 3 slots. A page title is
/// 24px because it is `headlineMedium`, a card title is 18px because it is
/// `titleLarge`, and a table cell is 14px because it is `bodyMedium`. Nothing
/// states a size of its own.
///
/// That is easy to hold today and easy to lose one commit at a time: a single
/// `fontSize: 15` on a heading is invisible in review and permanently breaks
/// the rhythm between that screen and the twenty-one beside it.
///
/// These tests read the source and fail on the ways that scale can be escaped,
/// so the guarantee is enforced rather than remembered.
void main() {
  final lib = Directory('lib');
  final dartFiles = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// Files allowed to break a given rule — the one place the scale is defined.
  bool isTypographySource(File file) => file.path
      .replaceAll(r'\', '/')
      .endsWith('core/theme/app_typography.dart');

  bool isThemeSource(File file) =>
      file.path.replaceAll(r'\', '/').endsWith('core/theme/app_theme.dart');

  /// Reports every offending line, so a failure names the work rather than
  /// just announcing that there is some.
  List<String> offenders(
    Iterable<File> files,
    Pattern pattern, {
    bool Function(File)? allow,
  }) {
    final found = <String>[];
    for (final file in files) {
      if (allow != null && allow(file)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains(pattern)) {
          final path = file.path.replaceAll(r'\', '/');
          found.add('$path:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    return found;
  }

  test('the source tree was found', () {
    // Guards the guard: if the scan silently matched nothing because the tests
    // ran from an unexpected directory, every assertion below would pass while
    // checking nothing at all.
    expect(lib.existsSync(), isTrue, reason: 'lib/ not found');
    expect(dartFiles.length, greaterThan(200));
  });

  test('no widget states a font size of its own', () {
    final found = offenders(dartFiles, 'fontSize:', allow: isTypographySource);

    expect(
      found,
      isEmpty,
      reason:
          'Text sizes belong to AppTypography, so one page cannot drift away '
          'from the rest. Use the nearest Theme.of(context).textTheme slot — '
          'headlineMedium 24, headlineSmall 20, titleLarge 18, titleMedium 16, '
          'titleSmall 14, bodyMedium 14, bodySmall 12, labelSmall 11 — and add '
          'a slot there if none fits.\n${found.join('\n')}',
    );
  });

  test('no text style opts out of inheriting the scale', () {
    // A TextStyle with inherit: false discards the size it was given instead
    // of merging with it, which is a hardcoded size wearing a disguise.
    final found = offenders(dartFiles, 'inherit: false');

    expect(
      found,
      isEmpty,
      reason:
          'inherit: false drops the inherited size. Prefer '
          'textTheme.<slot>.copyWith(...) so only colour and weight change.\n'
          '${found.join('\n')}',
    );
  });

  test('fonts are loaded in one place', () {
    final found = offenders(
      dartFiles,
      'GoogleFonts.',
      allow: isTypographySource,
    );

    expect(
      found,
      isEmpty,
      reason:
          'Calling GoogleFonts directly builds a style outside the scale and '
          'reintroduces its own sizes.\n${found.join('\n')}',
    );
  });

  test('no screen substitutes its own text theme', () {
    final found = offenders(
      dartFiles,
      'textTheme:',
      allow: (f) => isThemeSource(f) || isTypographySource(f),
    );

    expect(
      found,
      isEmpty,
      reason:
          'A local textTheme override re-sizes an entire subtree.\n'
          '${found.join('\n')}',
    );
  });

  test('no screen rescales text', () {
    final found = offenders(dartFiles, RegExp('textScaler|textScaleFactor'));

    expect(
      found,
      isEmpty,
      reason:
          'Rescaling multiplies every size on that subtree, so the page no '
          'longer matches the others.\n${found.join('\n')}',
    );
  });

  test('every screen takes its title from PageHeader', () {
    // Page titles are the most visible size on any screen. Routing all of them
    // through one widget is what makes 'Dashboard' and 'Finance Overview' the
    // same size; a screen printing its own Text would be free to differ.
    final screens = dartFiles
        .where((f) => f.path.replaceAll(r'\', '/').contains('/screens/'))
        .toList();

    expect(screens.length, greaterThan(15));

    final missing = <String>[];
    for (final screen in screens) {
      final source = screen.readAsStringSync();
      // Either directly, or via TabbedPage, which builds one internally.
      if (!source.contains('PageHeader') && !source.contains('TabbedPage')) {
        missing.add(screen.path.replaceAll(r'\', '/'));
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'These screens build their own title instead of using PageHeader or '
          'TabbedPage, so their heading size can drift:\n${missing.join('\n')}',
    );
  });
}
