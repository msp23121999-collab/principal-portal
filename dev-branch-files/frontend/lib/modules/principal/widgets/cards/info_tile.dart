import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';

/// A label/value pair — used heavily in Principal Profile tabs and detail
/// panels (Office Details, Contact, Documents metadata).
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.secondaryText),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
