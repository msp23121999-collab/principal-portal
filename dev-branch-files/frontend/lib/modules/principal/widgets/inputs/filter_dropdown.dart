import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';

/// Generic labeled dropdown filter (department, semester, status, ...)
/// used across analytics and list screens.
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.label,
    this.width,
  });

  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? label;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            isExpanded: width != null,
            icon: const Icon(
              AppIcons.chevronDown,
              size: 20,
              color: AppColors.secondaryText,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            items: [
              for (final item in items)
                DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    label == null
                        ? itemLabel(item)
                        : '$label: ${itemLabel(item)}',
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
