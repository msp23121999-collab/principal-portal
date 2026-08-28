/// 8px-grid spacing scale. Never hardcode a raw padding/gap literal —
/// always reference one of these.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard page/content padding. Drops to [lg] at the 1024px breakpoint
  /// floor via ResponsiveUtils.pagePadding(width).
  static const double pagePadding = xl;

  /// Standard card internal padding.
  static const double cardPadding = lg;

  /// Standard grid gutter between cards.
  static const double gridGutter = lg;
}
