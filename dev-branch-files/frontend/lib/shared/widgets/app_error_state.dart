import 'package:flutter/material.dart';

import 'package:erp_unified/modules/admin/app/theme/app_colors.dart';
import 'package:erp_unified/modules/admin/app/theme/app_spacing.dart';
import 'package:erp_unified/modules/admin/app/theme/app_typography.dart';
import 'app_button.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'Connection Issue',
    this.description =
    'Failed to connect to the node server. Please verify your connection settings.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Card(
          color: AppColors.errorLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSpacing.borderRadiusMd,
            ),
            side: const BorderSide(
              color: AppColors.error,
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.error,
                ),

                AppSpacing.gapMd,

                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),

                AppSpacing.gapSm,

                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (onRetry != null) ...[
                  AppSpacing.gapMd,
                  AppButton(
                    label: 'Try Again',
                    type: AppButtonType.destructive,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

