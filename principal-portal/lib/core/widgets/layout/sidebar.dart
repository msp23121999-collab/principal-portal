import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../constants/breakpoints.dart';
import '../../constants/nav_destinations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/responsive_utils.dart';
import 'sidebar_item.dart';

/// Whether the sidebar is collapsed to icon-only mode.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

const double kSidebarExpandedWidth = 260;
const double kSidebarCollapsedWidth = 76;

/// Fixed left navigation rail: brand mark, 13 destinations, collapse
/// toggle, logout pinned to the bottom.
class Sidebar extends ConsumerWidget {
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.badgeCounts = const {},
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Pending counts keyed by route path, supplied by [AppShell] so this
  /// core widget stays free of feature-provider imports.
  final Map<String, int> badgeCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Below the desktop floor the rail collapses to icons regardless of
    // the user's preference — 260px of navigation would otherwise leave
    // too little room for page content on a tablet.
    final forcedByWidth = ResponsiveUtils.widthOf(context) < Breakpoints.floor;
    final collapsed = ref.watch(sidebarCollapsedProvider) || forcedByWidth;
    final expanded = !collapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: expanded ? kSidebarExpandedWidth : kSidebarCollapsedWidth,
      decoration: const BoxDecoration(
        color: AppColors.sidebarNavy,
        border: Border(right: BorderSide(color: AppColors.sidebarNavy)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: AppRadius.smRadius,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    AppIcons.education,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppConstants.orgShortCode,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        Text(
                          'ERP System',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      AppIcons.menu,
                      size: 20,
                      color: Colors.white70,
                    ),
                    onPressed: () =>
                        ref.read(sidebarCollapsedProvider.notifier).state =
                            true,
                    tooltip: 'Collapse sidebar',
                  ),
                ],
              ],
            ),
          ),
          // Hidden when the width forces collapse — the toggle would
          // otherwise appear to do nothing.
          if (!expanded && !forcedByWidth)
            IconButton(
              icon: const Icon(AppIcons.menu, size: 20, color: Colors.white70),
              onPressed: () =>
                  ref.read(sidebarCollapsedProvider.notifier).state = false,
              tooltip: 'Expand sidebar',
            ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              children: [
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'NAVIGATION',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white54),
                    ),
                  ),
                for (int i = 0; i < kNavDestinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: SidebarItem(
                      icon: kNavDestinations[i].icon,
                      label: kNavDestinations[i].label,
                      selected: selectedIndex == i,
                      expanded: expanded,
                      badgeCount: kNavDestinations[i].showsPendingBadge
                          ? (badgeCounts[kNavDestinations[i].path] ?? 0)
                          : 0,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
