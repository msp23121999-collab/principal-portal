import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';

/// Standard scrollable page-content wrapper with responsive padding —
/// every feature screen's body sits inside one of these.
class ContentScaffold extends StatelessWidget {
  const ContentScaffold({super.key, required this.children, this.spacing = 20});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.pagePadding(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i != 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}
