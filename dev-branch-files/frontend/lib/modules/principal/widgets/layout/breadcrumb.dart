import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';

/// '>' separated breadcrumb trail shown beneath the PageHeader title.
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, required this.segments});

  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    return Row(
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
