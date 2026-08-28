import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Static (non-shimmering, per "no flashy animation") placeholder block
/// shown while async sections load.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.6),
        borderRadius: borderRadius ?? AppRadius.smRadius,
      ),
    );
  }
}

/// A skeleton shaped like a StatisticsCard/AnalyticsCard for grid loading
/// states.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(height: 12, width: 90),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 24, width: 70),
          Spacer(),
          LoadingSkeleton(height: 10, width: 120),
        ],
      ),
    );
  }
}
