/// Desktop-first breakpoints. Widths are lower bounds for each named
/// breakpoint; the app never targets anything below [floor].
class Breakpoints {
  Breakpoints._();

  static const double xl = 1920;
  static const double lg = 1600;
  static const double md = 1440;
  static const double sm = 1366;

  /// Smallest supported width (tablet landscape). No horizontal scrolling
  /// is ever acceptable at this floor.
  static const double floor = 1024;
}

/// Responsive column-count helper for KPI/analytics grids.
int gridColumnsForWidth(double width) {
  if (width >= Breakpoints.md) return 4;
  if (width >= Breakpoints.sm) return 3;
  return 2;
}

/// Page padding shrinks slightly at the narrowest supported width.
double pagePaddingForWidth(double width) {
  return width >= Breakpoints.sm ? 24 : 16;
}
