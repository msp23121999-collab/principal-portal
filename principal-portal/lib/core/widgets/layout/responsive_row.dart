import 'package:flutter/material.dart';
import '../../constants/breakpoints.dart';
import '../../theme/app_spacing.dart';

/// One column in a [ResponsiveRow], with the share of width it takes when
/// the row is laid out horizontally.
class ResponsiveColumn {
  const ResponsiveColumn({required this.child, this.flex = 1});

  final Widget child;
  final int flex;
}

/// Weighted columns that stack vertically once the viewport drops below
/// [stackBelow] — the main-content-plus-side-rail arrangement used by the
/// analytics pages.
///
/// [ResponsiveGrid] reflows equal-width tiles; this is for a small number
/// of deliberately unequal columns that must keep their proportions.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.columns,
    this.gutter = AppSpacing.xl,
    this.stackBelow = Breakpoints.sm,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<ResponsiveColumn> columns;
  final double gutter;
  final double stackBelow;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < columns.length; i++) ...[
                if (i != 0) SizedBox(height: gutter),
                columns[i].child,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            for (int i = 0; i < columns.length; i++) ...[
              if (i != 0) SizedBox(width: gutter),
              Expanded(flex: columns[i].flex, child: columns[i].child),
            ],
          ],
        );
      },
    );
  }
}
