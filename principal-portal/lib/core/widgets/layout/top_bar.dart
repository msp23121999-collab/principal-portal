import 'dart:async';

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../search/global_search_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_formatter.dart';
import '../buttons/icon_action_button.dart';

/// Fixed top navigation bar: portal badge, global search, notifications
/// bell, profile avatar, and a live clock.
class TopBar extends StatefulWidget {
  const TopBar({
    super.key,
    required this.onNotificationsTap,
    required this.onProfileTap,
    required this.onSearchNavigate,
    this.unreadNotificationCount = 0,
    // The office, not a person. `AppShell` always passes the signed-in
    // Principal's own name; this default only stands in before the profile
    // resolves, and it used to be the invented 'Dr. Principal' — a name shown
    // to every user regardless of who they were.
    this.userName = 'Principal',
    this.userInitial = 'P',
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  /// Opens the screen a chosen search result points at.
  final void Function(String route) onSearchNavigate;
  final int unreadNotificationCount;
  final String userName;
  final String userInitial;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Content widths below which the bar sheds its decorative pieces so
  /// search, notifications, and the profile avatar always survive.
  static const double _hideClockBelow = 900;
  static const double _hideBadgeBelow = 660;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showClock = constraints.maxWidth >= _hideClockBelow;
          final showBadge = constraints.maxWidth >= _hideBadgeBelow;

          return Row(
            children: [
              if (showBadge) ...[
                _portalBadge(context),
                const SizedBox(width: AppSpacing.xl),
              ],
              Expanded(
                child: GlobalSearchField(onNavigate: widget.onSearchNavigate),
              ),
              if (showClock) ...[
                const SizedBox(width: AppSpacing.xl),
                _clock(context),
              ],
              const SizedBox(width: AppSpacing.lg),
              IconActionButton(
                icon: AppIcons.notifications,
                tooltip: 'Notifications',
                badgeCount: widget.unreadNotificationCount,
                onPressed: widget.onNotificationsTap,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: AppSpacing.md),
              _avatar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _portalBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: AppRadius.smRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppConstants.portalName,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _clock(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(AppIcons.calendar, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.xs),
        Text(
          DateFormatter.shortDate(_now),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.primaryText),
        ),
        const SizedBox(width: AppSpacing.md),
        const Icon(AppIcons.clock, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.xs),
        Text(
          DateFormatter.time(_now),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.primaryText),
        ),
      ],
    );
  }

  Widget _avatar(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.smRadius,
      onTap: widget.onProfileTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.userInitial,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
