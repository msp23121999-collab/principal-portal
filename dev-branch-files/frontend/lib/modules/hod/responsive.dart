import 'package:flutter/material.dart';

/// HOD Portal Responsive System & Breakpoint Utilities
class HodResponsive {
  // Breakpoints
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isLaptop(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 992 && w < 1200;
  }

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 768 && w < 992;
  }

  static bool isMobile(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w < 768;
  }

  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 480;

  // Drawer Width: 80% up to max 320px
  static double drawerWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w * 0.8).clamp(240.0, 320.0);
  }

  // Page Container Padding
  static double pagePadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 32.0;
    if (w >= 992) return 24.0;
    if (w >= 768) return 20.0;
    if (w >= 480) return 16.0;
    return 12.0;
  }

  static EdgeInsets pagePaddingInsets(BuildContext context) {
    final pad = pagePadding(context);
    return EdgeInsets.all(pad);
  }

  // Dynamic Spacing / Gap
  static double gap(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 24.0;
    if (w >= 768) return 20.0;
    if (w >= 480) return 16.0;
    return 12.0;
  }

  // Responsive Typography
  static double headingSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 34.0;
    if (w >= 768) return 30.0;
    return 26.0;
  }

  static double sectionSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 28.0;
    if (w >= 768) return 24.0;
    return 22.0;
  }

  static double bodySize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 16.0;
    if (w >= 768) return 15.0;
    return 14.0;
  }

  // Responsive Icon Container Size
  static double iconSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 56.0;
    if (w >= 768) return 52.0;
    return 48.0;
  }

  // Feature Card Columns (Mark View / Student Performance)
  // Desktop: 2, Laptop: 2, Tablet: 2, Mobile: 1
  static int featureCardColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w < 768 ? 1 : 2;
  }

  // Batch Cards Grid Columns
  // Desktop: 3, Laptop: 2, Tablet: 2, Mobile: 1
  static int batchGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 3;
    if (w >= 768) return 2;
    return 1;
  }

  // KPI Grid Columns
  // Viewport >= 1600px -> 5 columns, 1150-1599px -> 4 columns, 1000-1149px -> 3 columns, 768-999px -> 2 columns, <768px -> 1 column
  static int kpiGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1600) return 5;
    if (w >= 1150) return 4;
    if (w >= 1000) return 3;
    if (w >= 768) return 2;
    return 1;
  }

  // Form Columns
  // Desktop: 3, Laptop: 2, Tablet: 2, Mobile: 1
  static int formColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 3;
    if (w >= 768) return 2;
    return 1;
  }
}

/// A responsive page container that automatically applies standard padding
class HodPageContainer extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const HodPageContainer({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final padding = HodResponsive.pagePaddingInsets(context);

    if (scrollable) {
      return SingleChildScrollView(
        padding: padding,
        physics: const BouncingScrollPhysics(),
        child: child,
      );
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// A responsive section header that lays out title, breadcrumb, academic year, and action buttons according to breakpoint rules
class HodSectionHeader extends StatelessWidget {
  final String title;
  final String? breadcrumb;
  final String? academicYear;
  final List<Widget>? actions;

  const HodSectionHeader({
    super.key,
    required this.title,
    this.breadcrumb,
    this.academicYear,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1200;
    final isTablet = w >= 768 && w < 1200;

    final headingStyle = TextStyle(
      fontSize: HodResponsive.headingSize(context) - 8, // Clean header size
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F172A),
      letterSpacing: -0.5,
    );

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: headingStyle),
        if (breadcrumb != null) ...[
          const SizedBox(height: 4),
          Text(
            breadcrumb!,
            style: TextStyle(
              fontSize: HodResponsive.bodySize(context) - 2,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    final yearBadge = academicYear != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(
                  academicYear!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          )
        : null;

    final actionWidgets = actions != null && actions!.isNotEmpty
        ? (w < 768
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: actions!.map((act) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: act,
                    ),
                  );
                }).toList(),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ))
        : null;

    if (isDesktop) {
      // Single Row layout
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleColumn),
          if (yearBadge != null) ...[
            const SizedBox(width: 16),
            yearBadge,
          ],
          if (actionWidgets != null) ...[
            const SizedBox(width: 16),
            actionWidgets,
          ],
        ],
      );
    } else if (isTablet) {
      // Wrapped/Stacked layout for Tablet
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleColumn),
              if (yearBadge != null) yearBadge,
            ],
          ),
          if (actionWidgets != null) ...[
            const SizedBox(height: 12),
            actionWidgets,
          ],
        ],
      );
    } else {
      // Mobile layout: Stacked vertically, aligned left, action buttons full width
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleColumn,
          if (yearBadge != null) ...[
            const SizedBox(height: 10),
            yearBadge,
          ],
          if (actionWidgets != null) ...[
            const SizedBox(height: 12),
            actionWidgets,
          ],
        ],
      );
    }
  }
}
