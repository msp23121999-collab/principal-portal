import 'package:flutter/material.dart';
import '../core/constants/breakpoints.dart';

/// Layout helpers shared across feature screens for responsive grids.
class ResponsiveUtils {
  ResponsiveUtils._();

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static int gridColumns(BuildContext context) =>
      gridColumnsForWidth(widthOf(context));

  static double pagePadding(BuildContext context) =>
      pagePaddingForWidth(widthOf(context));

  static bool isFloor(BuildContext context) =>
      widthOf(context) < Breakpoints.sm;
}

/// A responsive wrap-based grid that lays out fixed-width cards with a
/// consistent gutter, reflowing column count by available width instead of
/// ever introducing horizontal scroll.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.gutter = 16,
    this.minTileWidth = 260,
  });

  final List<Widget> children;
  final double gutter;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / (minTileWidth + gutter))
            .floor()
            .clamp(1, children.isEmpty ? 1 : children.length);
        final tileWidth =
            (constraints.maxWidth - (gutter * (columns - 1))) / columns;
        return Wrap(
          spacing: gutter,
          runSpacing: gutter,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
