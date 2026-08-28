import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// General-purpose card with a title/subtitle header and an arbitrary
/// content slot — used for department lists, faculty/student summaries,
/// and any section that isn't a raw chart or table.
class AnalyticsCard extends StatefulWidget {
  const AnalyticsCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.minHeight,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;
  final double? minHeight;

  @override
  State<AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<AnalyticsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.primaryBlue;

    final card = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppMotion.adaptive(context, AppMotion.normal),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: _isHovered
                ? themeColor.withValues(alpha: 0.35)
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
              // Subtle left accent line indicating it's an analytics block
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor, themeColor.withValues(alpha: 0.3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: widget.padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryText,
                                    ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.trailing != null) widget.trailing!,
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    widget.child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.minHeight == null) return card;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight!),
      child: card,
    );
  }
}
