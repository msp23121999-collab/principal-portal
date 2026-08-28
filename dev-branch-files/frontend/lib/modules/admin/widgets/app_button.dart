import 'package:flutter/material.dart';
import '../theme.dart';
enum AppButtonType { primary, secondary, destructive }

class AppButton extends StatelessWidget {

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    var borderSide = BorderSide.none;

    switch (type) {
      case AppButtonType.primary:
        bgColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case AppButtonType.secondary:
        bgColor = Colors.white;
        textColor = AppColors.textSecondary;
        borderSide = const BorderSide(color: AppColors.border);
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
          strokeWidth: 2,
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
