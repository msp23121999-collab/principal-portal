import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/secondary_button.dart';
import '../motion/fade_in.dart';

/// Shown when an async provider fails to load.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'Something went wrong while loading this data.',
    this.onRetry,
    this.error,
  });

  final String message;
  final VoidCallback? onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    // Debug builds only — the raw error carries backend detail that has no
    // business in a live browser console. The message shown below is the
    // sanitised one.
    if (error != null && kDebugMode) {
      debugPrint('ErrorState caught: $error');
    }
    return FadeIn(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tinted disc rather than a bare glyph, so the state reads as
                // deliberate rather than as a broken icon slot.
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.dangerTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.warning,
                    size: 32,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                // The driver's own text is kept — hiding it would leave nobody
                // able to say why a screen failed — but it is demoted to a
                // diagnostic block. Previously it was concatenated onto the
                // message, so a Postgres error was the loudest thing on screen.
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppRadius.smRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '$error',
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: AppColors.secondaryText),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SecondaryButton(label: 'Retry', onPressed: onRetry),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
