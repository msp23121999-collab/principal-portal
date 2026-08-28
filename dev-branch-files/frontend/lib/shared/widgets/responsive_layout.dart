import 'package:flutter/material.dart';

/// Centralized Enterprise Responsive Architecture for KSRCE ERP
class AppResponsive {
  static const double mobileMax = 599.0;
  static const double tabletMax = 1023.0;
  static const double desktopMax = 1439.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMax && width <= tabletMax;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > tabletMax && width <= desktopMax;
  }

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > desktopMax;

  /// Returns 4/4/2/1 for KPI cards per row based on breakpoints
  static int kpiCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1440) return 4;
    if (width >= 1024) return 4;
    if (width >= 600) return 2;
    return 1;
  }

  /// Returns 4/3/2/1 for general content cards per row
  static int gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1440) return 4;
    if (width >= 1024) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  /// Adaptive Screen Padding: Desktop (24px), Tablet (16px), Mobile (12px)
  static EdgeInsets adaptivePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(12.0);
    if (isTablet(context)) return const EdgeInsets.all(16.0);
    return const EdgeInsets.all(24.0);
  }

  /// Adaptive Card Padding
  static EdgeInsets cardPadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(12.0);
    return const EdgeInsets.all(16.0);
  }
}

/// Adaptive Layout Builder Widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > AppResponsive.desktopMax && largeDesktop != null) {
          return largeDesktop!;
        }
        if (constraints.maxWidth >= 1024) {
          return desktop;
        }
        if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Universal Responsive Grid View Container
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mainAxisExtent = 135.0,
    this.crossAxisSpacing = 14.0,
    this.mainAxisSpacing = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = AppResponsive.gridCrossAxisCount(context);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Responsive Data Table Container with Horizontal Scroll Protection
class ResponsiveTableContainer extends StatelessWidget {
  final Widget child;
  final double minWidth;

  const ResponsiveTableContainer({
    super.key,
    required this.child,
    this.minWidth = 850.0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: minWidth,
        child: child,
      ),
    );
  }
}


