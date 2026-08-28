import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// Card-framed filter strip that sits directly beneath a page header:
/// a wrapping run of dropdowns followed by Apply and Reset.
///
/// Owns no filter state — [filters] are supplied already bound to their
/// providers, so this only handles arrangement and the two actions.
class AnalyticsFilterBar extends StatelessWidget {
  const AnalyticsFilterBar({
    super.key,
    required this.filters,
    this.onApply,
    this.onReset,
    this.applyLabel = 'Apply Filters',
    this.resetLabel = 'Reset',
  });

  final List<Widget> filters;
  final VoidCallback? onApply;
  final VoidCallback? onReset;
  final String applyLabel;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: filters,
          ),
          if (onApply != null || onReset != null)
            Wrap(
              spacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (onApply != null)
                  PrimaryButton(label: applyLabel, onPressed: onApply),
                if (onReset != null)
                  SecondaryButton(label: resetLabel, onPressed: onReset),
              ],
            ),
        ],
      ),
    );
  }
}
