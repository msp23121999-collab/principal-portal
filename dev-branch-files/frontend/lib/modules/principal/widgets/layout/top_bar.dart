import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../buttons/icon_action_button.dart';
import '../inputs/search_field.dart';

/// Fixed top navigation bar: portal badge, global search, notifications
/// bell, profile avatar, and a live clock.
class TopBar extends StatefulWidget {
  const TopBar({
    super.key,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.unreadNotificationCount = 0,
    this.userName = 'Dr. Principal',
    this.userInitial = 'P',
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
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
          ),
          const SizedBox(width: AppSpacing.xl),
          const Expanded(
            child: SearchField(
              hintText: 'Search students, faculty, departments...',
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Row(
            children: [
              Icon(AppIcons.calendar, size: 16, color: AppColors.secondaryText),
              const SizedBox(width: AppSpacing.xs),
              Text(
                DateFormatter.shortDate(_now),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(AppIcons.clock, size: 16, color: AppColors.secondaryText),
              const SizedBox(width: AppSpacing.xs),
              Text(
                DateFormatter.time(_now),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          IconActionButton(
            icon: AppIcons.notifications,
            tooltip: 'Notifications',
            badgeCount: widget.unreadNotificationCount,
            onPressed: widget.onNotificationsTap,
          ),
          const SizedBox(width: AppSpacing.md),
          InkWell(
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
          ),
        ],
      ),
    );
  }
}
