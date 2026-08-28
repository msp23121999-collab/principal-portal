import 'package:flutter/material.dart';
import '../../constants/breakpoints.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'breadcrumb.dart';

/// Standard page header: title + breadcrumb trail on the left, trailing
/// action buttons on the right. Every feature screen starts with one of
/// these directly under the TopBar.
///
/// Actions drop beneath the title once the content area is narrower than
/// [Breakpoints.md], so analytics pages can carry a full run of year
/// selectors and export buttons without squeezing the title.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.breadcrumbSegments,
    this.actions = const [],
    this.subtitle,
  });

  final String title;
  final List<String>? breadcrumbSegments;
  final List<Widget> actions;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return _titleBlock(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final actionBar = Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: actions,
        );

        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleBlock(context),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: actionBar,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _titleBlock(context)),
            const SizedBox(width: AppSpacing.md),
            Align(
              alignment: Alignment.topRight,
              child: actionBar,
            ),
          ],
        );
      },
    );
  }

  Widget _titleBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breadcrumbSegments != null) ...[
          Breadcrumb(segments: breadcrumbSegments!),
          const SizedBox(height: AppSpacing.sm),
        ],
        // A short brand rule set against the title, so the top of every screen
        // has an anchor instead of text floating on the page background. Two
        // stops rather than a flat fill: the fade reads as deliberate at this
        // size, where a solid bar reads as a stray divider.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 28,
              margin: const EdgeInsets.only(right: AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryBlue, AppColors.darkBlue],
                ),
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            // Aligned to the title, clear of the rule.
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          ),
        ],
      ],
    );
  }
}
