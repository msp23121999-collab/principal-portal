import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

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
    this.matchHeights = false,
  });

  final List<Widget> children;
  final double gutter;
  final double minTileWidth;
  final bool matchHeights;

  /// Columns to lay the tiles out in.
  ///
  /// The widest fit is not always the tidiest. Six cards in four columns
  /// leaves a two-tile hole on the second row, which is the ragged gap the
  /// dashboard used to show; six in three columns fills both rows exactly.
  /// So among the widest fit and one column narrower, this prefers whichever
  /// leaves fewer empty slots on the last row, and only then prefers more
  /// columns.
  int _columnsFor(double width) {
    final widest = (width / (minTileWidth + gutter)).floor().clamp(
      1,
      children.length,
    );
    if (widest <= 1) return 1;

    int emptySlots(int columns) {
      final remainder = children.length % columns;
      return remainder == 0 ? 0 : columns - remainder;
    }

    final narrower = widest - 1;
    return emptySlots(narrower) < emptySlots(widest) ? narrower : widest;
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);

        final rows = <List<Widget>>[];
        for (var i = 0; i < children.length; i += columns) {
          rows.add(
            children.sublist(i, (i + columns).clamp(0, children.length)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: gutter),
              // Rows are laid out explicitly rather than with a Wrap, so the
              // gutter between rows is the same as the one between columns and
              // a short last row keeps its tiles at the same width as the rows
              // above instead of stretching them.
              //
              // Heights are matched by the cards themselves — see
              // [StatisticsCard.minHeight]. IntrinsicHeight would be the
              // obvious tool and cannot be used: it refuses to measure a
              // subtree containing a LayoutBuilder, which several cards have.
              Builder(
                builder: (context) {
                  Widget rowContent = Row(
                    crossAxisAlignment: matchHeights
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.start,
                    children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0) SizedBox(width: gutter),
                        Expanded(
                          child: c < rows[r].length
                              ? rows[r][c]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  );

                  if (matchHeights) {
                    rowContent = IntrinsicHeight(child: rowContent);
                  }

                  return rowContent;
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
