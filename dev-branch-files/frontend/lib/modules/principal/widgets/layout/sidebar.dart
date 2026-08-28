import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/nav_destinations.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
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
    required this.onLogout,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final expanded = !collapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: expanded ? kSidebarExpandedWidth : kSidebarCollapsedWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'ERP System',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      AppIcons.menu,
                      size: 20,
                      color: AppColors.secondaryText,
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
          if (!expanded)
            IconButton(
              icon: const Icon(
                AppIcons.menu,
                size: 20,
                color: AppColors.secondaryText,
              ),
              onPressed: () =>
                  ref.read(sidebarCollapsedProvider.notifier).state = false,
              tooltip: 'Expand sidebar',
            ),
          const Divider(height: 1),
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
                      style: Theme.of(context).textTheme.labelSmall,
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
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: SidebarItem(
              icon: AppIcons.logout,
              label: 'Logout',
              selected: false,
              expanded: expanded,
              onTap: onLogout,
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }
}
