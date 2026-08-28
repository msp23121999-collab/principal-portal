import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';
import '../../utils/responsive_utils.dart';
import '../motion/fade_in.dart';

/// Standard scrollable page-content wrapper with responsive padding —
/// every feature screen's body sits inside one of these.
///
/// Bands are introduced in reading order rather than all in one frame. On the
/// long analytics pages the whole body appearing at once reads as a jump; a
/// short staggered entrance lets the eye land on the header and the KPI row
/// first, which is what the Principal opens these pages for. The stagger is
/// capped inside [AppMotion.stagger] and collapses to nothing when the browser
/// asks for reduced motion, so a page is never slow to become usable.
class ContentScaffold extends StatelessWidget {
  const ContentScaffold({
    super.key,
    required this.children,
    this.spacing = 20,
    this.animateEntrance = true,
  });

  final List<Widget> children;
  final double spacing;

  /// Set false for a body that manages its own entrance.
  final bool animateEntrance;

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
            if (animateEntrance)
              FadeIn(delay: AppMotion.stagger(i), child: children[i])
            else
              children[i],
          ],
        ],
      ),
    );
  }
}
