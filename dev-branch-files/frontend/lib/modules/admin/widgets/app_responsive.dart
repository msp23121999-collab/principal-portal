import 'package:flutter/material.dart';

/// Centralized Enterprise Responsive Architecture for KSRCE ERP
class AppResponsive {
  static const double mobileMax = 599;
  static const double tabletMax = 1023;
  static const double desktopMax = 1439;

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

  /// Returns 4/4/2/2 for KPI cards per row based on breakpoints
  static int kpiCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1440) return 4;
    if (width >= 1024) return 4;
    return 2;
  }

  /// Returns 4/4/2/2 for general content cards per row
  static int gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1440) return 4;
    if (width >= 1024) return 4;
    return 2;
  }

  /// Adaptive Screen Padding: Desktop (24px), Tablet (16px), Mobile (12px)
  static EdgeInsets adaptivePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(12);
    if (isTablet(context)) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
  }

  /// Adaptive Card Padding
  static EdgeInsets cardPadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }
}

/// Adaptive Layout Builder Widget
class ResponsiveLayout extends StatelessWidget {

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.largeDesktop,
  });
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? largeDesktop;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
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

/// Universal Responsive Grid View Container
class ResponsiveGrid extends StatelessWidget {

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mainAxisExtent = 135.0,
    this.crossAxisSpacing = 14.0,
    this.mainAxisSpacing = 14.0,
    this.crossAxisCount,
  });
  final List<Widget> children;
  final double mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int? crossAxisCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        final count = crossAxisCount ?? AppResponsive.gridCrossAxisCount(context);
        final isMobile = AppResponsive.isMobile(context);
        final effectiveExtent = isMobile && mainAxisExtent > 90.0 ? 85.0 : mainAxisExtent;
        final effectiveSpacing = isMobile ? 10.0 : crossAxisSpacing;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: effectiveSpacing,
            mainAxisSpacing: effectiveSpacing,
            mainAxisExtent: effectiveExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
}

class ResponsiveTableContainer extends StatelessWidget {

  const ResponsiveTableContainer({
    super.key,
    required this.child,
    this.minWidth = 650.0,
  });
  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: targetWidth),
            child: child,
          ),
        );
      },
    );
}
