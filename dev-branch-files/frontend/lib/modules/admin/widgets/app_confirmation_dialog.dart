import 'package:flutter/material.dart';
import '../theme.dart';

enum ConfirmationType { delete, edit, general }

class AppConfirmationDialog extends StatefulWidget {
  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.type = ConfirmationType.delete,
    this.verifyText,
    this.verifyHint,
  });
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final ConfirmationType type;

  /// If provided, the user must type this exact string to enable the confirm button.
  final String? verifyText;

  /// Hint shown above the verify input, e.g. "Type the user name to confirm"
  final String? verifyHint;

  @override
  State<AppConfirmationDialog> createState() => _AppConfirmationDialogState();
}

class _AppConfirmationDialogState extends State<AppConfirmationDialog> {
  final TextEditingController _verifyController = TextEditingController();
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    // If no verification text required, start as verified
    if (widget.verifyText == null) _verified = true;
    _verifyController.addListener(_checkVerification);
  }

  void _checkVerification() {
    final isMatch = _verifyController.text.trim() == widget.verifyText?.trim();
    if (isMatch != _verified) setState(() => _verified = isMatch);
  }

  @override
  void dispose() {
    _verifyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.type == ConfirmationType.edit
        ? AppColors.info
        : widget.type == ConfirmationType.delete
        ? AppColors.error
        : AppColors.primary;

    final iconData = widget.type == ConfirmationType.edit
        ? Icons.edit_note_rounded
        : widget.type == ConfirmationType.delete
        ? Icons.delete_forever_rounded
        : Icons.help_outline_rounded;

    final actionNote = widget.type == ConfirmationType.delete
        ? 'This action will permanently remove the data from all records and the database. This cannot be undone.'
        : widget.type == ConfirmationType.edit
        ? 'If confirmed, the changes will be applied and updated across all linked records and the database.'
        : 'Please confirm to proceed with this action.';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      backgroundColor: Colors.white,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusMd,
                      ),
                    ),
                    child: Icon(iconData, color: accentColor, size: 24),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              const Divider(),
              AppSpacing.gapMd,

              // Main content
              Text(
                widget.content,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              AppSpacing.gapMd,

              // Warning note box
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(17),
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusMd,
                  ),
                  border: Border.all(color: accentColor.withAlpha(63)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      widget.type == ConfirmationType.delete
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: Text(
                        actionNote,
                        style: AppTypography.bodySmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Verification Text Field ---
              if (widget.verifyText != null) ...[
                AppSpacing.gapMd,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.borderRadiusMd,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.verifyHint ??
                            'To confirm, type  "${widget.verifyText}"  below:',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      AppSpacing.gapSm,
                      TextField(
                        controller: _verifyController,
                        autofocus: true,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.verifyText,
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadiusMd,
                            ),
                            borderSide: BorderSide(
                              color: _verified
                                  ? AppColors.success
                                  : AppColors.border,
                              width: _verified ? 1.5 : 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadiusMd,
                            ),
                            borderSide: BorderSide(
                              color: _verified
                                  ? AppColors.success
                                  : AppColors.border,
                              width: _verified ? 1.5 : 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadiusMd,
                            ),
                            borderSide: BorderSide(
                              color: _verified
                                  ? AppColors.success
                                  : accentColor,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: _verified
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              AppSpacing.gapLg,

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (widget.onCancel != null) widget.onCancel!();
                    },
                    child: Text(
                      widget.cancelLabel,
                      style: AppTypography.buttonText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  AppSpacing.gapSm,
                  AnimatedOpacity(
                    opacity: _verified ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadiusMd,
                          ),
                        ),
                      ),
                      onPressed: _verified
                          ? () {
                              Navigator.of(context).pop();
                              widget.onConfirm();
                            }
                          : null,
                      child: Text(
                        widget.confirmLabel,
                        style: AppTypography.buttonText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
