import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';

/// '>' separated breadcrumb trail shown beneath the PageHeader title.
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, required this.segments});

  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    // Wrap rather than Row: a deep trail beside wide header actions would
    // otherwise overflow instead of continuing on a second line.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          Text(
            segments[i],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: i == segments.length - 1
                  ? AppColors.primaryText
                  : AppColors.secondaryText,
              fontWeight: i == segments.length - 1
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          if (i != segments.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(
                AppIcons.chevronRight,
                size: 14,
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ],
    );
  }
}
