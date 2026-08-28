import 'package:flutter/material.dart';
import 'package:erp_unified/modules/admin/app/theme/app_colors.dart';
import 'package:erp_unified/modules/admin/app/theme/app_spacing.dart';
import 'package:erp_unified/modules/admin/app/theme/app_typography.dart';

enum AppButtonType { primary, secondary, destructive }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case AppButtonType.primary:
        bgColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case AppButtonType.secondary:
        bgColor = Colors.white;
        textColor = AppColors.textSecondary;
        borderSide = const BorderSide(color: AppColors.border, width: 1.0);
        break;
      case AppButtonType.destructive:
        bgColor = AppColors.error;
        textColor = Colors.white;
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: textColor,
      elevation: 0,
      side: borderSide,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      ),
    );

    Widget childContent;
    if (isLoading) {
      childContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else {
      if (icon != null) {
        childContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            AppSpacing.gapSm,
            Text(label, style: AppTypography.buttonText.copyWith(color: textColor)),
          ],
        );
      } else {
        childContent = Text(label, style: AppTypography.buttonText.copyWith(color: textColor));
      }
    }

    return ElevatedButton(
      style: buttonStyle,
      onPressed: isLoading ? null : onPressed,
      child: childContent,
    );
  }
}


