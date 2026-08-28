import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';

/// A single sidebar navigation row: icon, label, active indicator.
/// Collapses to icon-only when [expanded] is false.
class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expanded = true,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expanded;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.danger
        : (selected ? AppColors.primaryBlue : AppColors.secondaryText);

    final row = Row(
      children: [
        Icon(icon, size: 20, color: color),
        if (expanded) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    return Tooltip(
      message: expanded ? '' : label,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.smRadius,
        child: InkWell(
          borderRadius: AppRadius.smRadius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppColors.dangerTint
                  : (selected ? AppColors.primaryBlueTint : Colors.transparent),
              borderRadius: AppRadius.smRadius,
              border: selected
                  ? const Border(
                      left: BorderSide(color: AppColors.primaryBlue, width: 3),
                    )
                  : const Border(
                      left: BorderSide(color: Colors.transparent, width: 3),
                    ),
            ),
            child: row,
          ),
        ),
      ),
    );
  }
}
