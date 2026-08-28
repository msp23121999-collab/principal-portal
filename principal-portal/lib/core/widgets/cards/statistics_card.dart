import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../motion/animated_count.dart';

/// KPI stat card: a big number, a label, an icon, and an optional trend
/// delta (e.g. "+4.2%"). Used across Dashboard and every analytics module.
class StatisticsCard extends StatefulWidget {
  const StatisticsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBackground,
    this.trendValue,
    this.isTrendPositive = true,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String? trendValue;
  final bool isTrendPositive;
  final String? subtitle;

  static const double minHeight = 132;

  @override
  State<StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<StatisticsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final trendColor = widget.isTrendPositive
        ? AppColors.success
        : AppColors.danger;
    final themeColor = widget.iconColor ?? AppColors.primaryBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppMotion.adaptive(context, AppMotion.normal),
        curve: AppMotion.standard,
        constraints: const BoxConstraints(minHeight: StatisticsCard.minHeight),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: _isHovered
                ? themeColor.withValues(alpha: 0.45)
                : AppColors.border,
          ),
          boxShadow: AppElevation.forHoverAccent(
            isHovered: _isHovered,
            accentColor: themeColor,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.mdRadius,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColor,
                        themeColor.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.label,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: widget.iconBackground ??
                              AppColors.getSoftBackgroundFor(themeColor),
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: widget.iconColor ?? AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Wrap, not Row: a short delta like "+4.2%" sits beside the
                  // value, while a longer one such as "12.6% vs Last Year"
                  // continues on the next line rather than overflowing the tile.
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      // Counts up on first paint. The figure itself is unchanged — the
                      // animation ends exactly on the value handed in.
                      AnimatedCount(
                        value: widget.value,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (widget.trendValue != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isTrendPositive
                                    ? AppIcons.trendUp
                                    : AppIcons.trendDown,
                                size: 14,
                                color: trendColor,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  widget.trendValue!,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: trendColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
