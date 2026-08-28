import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Inter-based TextTheme mapped onto Material 3 slots. Every screen should
/// pull styles from `Theme.of(context).textTheme.*` rather than constructing
/// ad hoc TextStyle instances.
///
/// [AppFontSizes] below is the single place any size is stated. Changing a
/// value there moves that role on all 22 screens at once, which is the whole
/// point of the arrangement — `test/typography_consistency_test.dart` fails
/// the build if a widget starts stating a size of its own.
///
/// ## Why the font is bundled rather than fetched
///
/// This used to build its base theme with the `google_fonts` package, which
/// downloads Inter from `fonts.gstatic.com` on first paint. That had three
/// costs: the portal's
/// typography depended on a third party being reachable, every visitor's
/// browser announced itself to that third party, and the external origin made a
/// strict Content-Security-Policy impossible to write. Inter is now bundled
/// under `assets/fonts/` (SIL Open Font License 1.1, see `assets/fonts/OFL.txt`)
/// and the `google_fonts` dependency is gone.
///
/// Only the four weights the portal actually renders are shipped — 400, 500,
/// 600 and 700. Adding a weight means adding the file *and* the `pubspec.yaml`
/// entry; asking for an unbundled weight makes Flutter synthesise it, which
/// looks subtly wrong rather than failing loudly.
class AppTypography {
  AppTypography._();

  /// The bundled family name, as declared in `pubspec.yaml`.
  ///
  /// Stated once so the theme, the tests and any future caller agree. A typo
  /// here does not throw — Flutter silently falls back to the platform default,
  /// which is the exact failure this change exists to remove — so
  /// `test/bundled_font_test.dart` asserts the declaration and the asset files
  /// line up.
  static const String fontFamily = 'Inter';

  static TextTheme get textTheme {
    // `.apply` carries the family onto every slot, including the ones not
    // restated below, so nothing silently keeps the platform default.
    final base = ThemeData.light().textTheme.apply(fontFamily: fontFamily);
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: AppFontSizes.headlineMedium,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
        height: 1.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: AppFontSizes.headlineSmall,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
        height: 1.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: AppFontSizes.titleLarge,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: AppFontSizes.titleMedium,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: AppFontSizes.titleSmall,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: AppFontSizes.bodyLarge,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryText,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: AppFontSizes.bodyMedium,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryText,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: AppFontSizes.bodySmall,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryText,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: AppFontSizes.labelSmall,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryText,
      ),
    );
  }
}

/// The portal's type scale, in logical pixels.
///
/// Every size the application renders is one of these nine numbers. They are
/// gathered here rather than spread through the theme so the scale can be read
/// at a glance and adjusted as a set: nudging one value in isolation is how a
/// scale stops being a scale.
///
/// The portal originally shipped at 24/20/18/16/14 for headings and titles
/// and 16/14/12/11 for body copy. Every value has been raised by roughly a
/// quarter so the portal reads comfortably on a large desktop display and from
/// across a room during a review.
///
/// The gaps between the roles were kept in proportion rather than adding a
/// flat number to each, so the hierarchy still reads the same: a page title is
/// still clearly a page title beside its body text. Adding a constant instead
/// would have compressed the top of the scale and flattened that difference.
///
/// If a further change is wanted, move all nine together and keep those gaps —
/// a heading two points above its body text stops looking like a heading. Then
/// run `flutter test`, which renders every screen at 900 to 1600px and fails
/// if the new sizes no longer fit.
class AppFontSizes {
  AppFontSizes._();

  /// Page titles ("Dashboard"), and the headline figure on a statistics card.
  static const double headlineMedium = 24;

  /// Section headings that outrank a card title.
  static const double headlineSmall = 20;

  /// Card, chart and table headings ("Department Summary").
  static const double titleLarge = 18;

  /// Table column headings.
  static const double titleMedium = 16;

  /// Tab labels, row titles, emphasised figures inside a card.
  static const double titleSmall = 14;

  /// Long-form body copy.
  static const double bodyLarge = 16;

  /// Default reading size: table cells, form fields, most paragraphs.
  static const double bodyMedium = 14;

  /// Card subtitles and supporting detail.
  static const double bodySmall = 12;

  /// The smallest role — chips, badges, timestamps.
  static const double labelSmall = 11;

  // ---------------------------------------------------------------------------
  // Sizes below the nine-step scale.
  // ---------------------------------------------------------------------------

  /// Heading for a standalone surface that is not a portal page — the sign-in
  /// card. Deliberately below [headlineSmall]: the login card is narrow.
  static const double authTitle = 20;

  /// Dense supporting text: helper lines under a field, inline validation,
  /// secondary detail in a compact card.
  static const double caption = 12;

  /// The smallest text the portal uses. Badge and pill interiors only, where
  /// the surrounding shape already carries the meaning.
  static const double badge = 10;
}

/// Text styles for the roles that fall outside Material's `TextTheme` slots.
///
/// Reach for `Theme.of(context).textTheme` first — these are only for the three
/// sizes above, which have no natural slot. Using them keeps widgets free of
/// `fontSize:` literals.
class AppTextStyles {
  AppTextStyles._();

  /// Heading on the sign-in card.
  static TextStyle authTitle(BuildContext context) =>
      (Theme.of(context).textTheme.headlineSmall ?? const TextStyle()).copyWith(
        fontSize: AppFontSizes.authTitle,
      );

  /// Helper and validation text beneath an input.
  static TextStyle caption(BuildContext context) =>
      (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
        fontSize: AppFontSizes.caption,
      );

  /// Text inside a badge or pill.
  static TextStyle badge(BuildContext context) =>
      (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
        fontSize: AppFontSizes.badge,
        fontWeight: FontWeight.w600,
      );
}
