import 'package:flutter/material.dart';
import '../theme.dart';
class AppStatusBadge extends StatelessWidget {

  const AppStatusBadge({
    super.key,
    required this.status,
  });
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color dotColor;

    final normalized = status.trim().toLowerCase();

    if (normalized == 'active' || normalized == 'completed' || normalized == 'success' || normalized == 'verified') {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      dotColor = AppColors.success;
    } else if (normalized == 'pending' || normalized == 'awaiting verification' || normalized == 'warning' || normalized == 'draft') {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
      dotColor = AppColors.warning;
    } else if (normalized == 'critical' || normalized == 'inactive' || normalized == 'error' || normalized == 'failed' || normalized == 'rejected') {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
      dotColor = AppColors.error;
    } else {
      bgColor = AppColors.primaryLight;
      textColor = AppColors.primary;
      dotColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: AppTypography.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
