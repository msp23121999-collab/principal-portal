import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// A single notification row: icon, title, message, relative timestamp,
/// and an unread indicator dot.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isUnread = false,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String timestamp;
  final bool isUnread;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.primaryBlue;

    return DecoratedBox(
      // Unread rows are lifted off the page; read ones stay flat. A list where
      // every row carried the same shadow gave the Principal no way to see at a
      // glance how much was still outstanding, which is the only question this
      // list exists to answer.
      decoration: BoxDecoration(
        borderRadius: AppRadius.smRadius,
        boxShadow: isUnread ? AppElevation.card : AppElevation.none,
      ),
      child: Material(
        color: isUnread ? AppColors.lightBlue : AppColors.surface,
        borderRadius: AppRadius.smRadius,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.veryLightBlue,
          borderRadius: AppRadius.smRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: isUnread
                    ? accent.withValues(alpha: 0.25)
                    : AppColors.border,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.smRadius,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A full-height accent edge on unread rows. The 8px dot on
                    // the far right was the only unread marker, and on a wide
                    // row it sat too far from the title to register.
                    SizedBox(
                      width: 3,
                      child: ColoredBox(
                        color: isUnread ? accent : Colors.transparent,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.getSoftBackgroundFor(accent),
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Icon(icon, size: 18, color: accent),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: isUnread
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        timestamp,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    message,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
