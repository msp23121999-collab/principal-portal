import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_button.dart';

class AppFilterBottomSheet extends StatelessWidget {

  const AppFilterBottomSheet({
    super.key,
    required this.title,
    required this.child,
    required this.onApply,
    required this.onReset,
  });
  final String title;
  final Widget child;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.borderRadiusLg),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.h2,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            AppSpacing.gapMd,
            child,
            AppSpacing.gapLg,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Reset',
                    type: AppButtonType.secondary,
                    onPressed: () {
                      onReset();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: AppButton(
                    label: 'Apply Filters',
                    type: AppButtonType.primary,
                    onPressed: () {
                      onApply();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}
