import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_formatter.dart';

/// Themed date-picker trigger field. Wraps [showDatePicker] with the app's
/// visual language so every date input looks identical.
class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.width,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? label;
  final double? width;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: AppRadius.smRadius,
        onTap: () => _pick(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.calendar,
                size: 18,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Flexible, because [width] fixes the box: without it a label
              // wider than the remaining space overflows the row rather than
              // being trimmed, which is a rendering error, not a cosmetic one.
              Flexible(
                child: Text(
                  value == null
                      ? (label ?? 'Select date')
                      : DateFormatter.shortDate(value!),
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
