import 'package:flutter/material.dart';

class HodToast {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    double? bottom,
    double? right,
  }) {
    final Color bgColor = isError
        ? const Color(0xFFDC2626) // Red for errors/warnings
        : (isSuccess ? const Color(0xFF16A34A) : const Color(0xFF2563EB)); // Blue default

    final IconData icon = isError
        ? Icons.error_outline_rounded
        : (isSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double effectiveRightMargin = right ?? (isMobile ? 16 : 70);
    final double effectiveBottomMargin = bottom ?? 40;
    final double leftMargin = isMobile
        ? 16
        : (screenWidth - 350).clamp(16.0, screenWidth - effectiveRightMargin);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        backgroundColor: bgColor,
        duration: duration,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: EdgeInsets.only(
          bottom: effectiveBottomMargin,
          right: effectiveRightMargin,
          left: leftMargin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
