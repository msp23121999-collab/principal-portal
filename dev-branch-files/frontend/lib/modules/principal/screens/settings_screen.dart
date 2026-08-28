import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/analytics_card.dart';
import '../widgets/inputs/filter_dropdown.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../widgets/layout/sidebar.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_toggle_row.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final emailNotifications = ref.watch(emailNotificationsProvider);
    final smsNotifications = ref.watch(smsNotificationsProvider);
    final pushNotifications = ref.watch(pushNotificationsProvider);
    final sidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    final compactDateFormat = ref.watch(compactDateFormatProvider);

    return ContentScaffold(
      children: [
        const PageHeader(
          title: 'Settings',
          breadcrumbSegments: ['Administration', 'Settings'],
          subtitle: 'Profile preferences, appearance, and system preferences',
        ),
        AnalyticsCard(
          title: 'Profile Preferences',
          subtitle: 'Choose how you want to be notified',
          child: Column(
            children: [
              SettingsToggleRow(
                label: 'Email Notifications',
                subtitle: 'Receive daily digests and approval alerts by email',
                value: emailNotifications,
                onChanged: (v) =>
                    ref.read(emailNotificationsProvider.notifier).state = v,
              ),
              const Divider(),
              SettingsToggleRow(
                label: 'SMS Notifications',
                subtitle: 'Receive urgent alerts via SMS',
                value: smsNotifications,
                onChanged: (v) =>
                    ref.read(smsNotificationsProvider.notifier).state = v,
              ),
              const Divider(),
              SettingsToggleRow(
                label: 'Push Notifications',
                subtitle: 'Receive in-app notifications on this device',
                value: pushNotifications,
                onChanged: (v) =>
                    ref.read(pushNotificationsProvider.notifier).state = v,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnalyticsCard(
          title: 'Appearance',
          subtitle: 'Theme and display preferences',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              FilterDropdown<AppThemeMode>(
                value: themeMode,
                items: AppThemeMode.values,
                itemLabel: (m) => m == AppThemeMode.dark
                    ? '${m.label} (coming soon)'
                    : m.label,
                width: 260,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).state = value;
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnalyticsCard(
          title: 'Language',
          subtitle: 'Preferred display language',
          child: FilterDropdown<AppLanguage>(
            value: language,
            items: AppLanguage.values,
            itemLabel: (l) => l.label,
            width: 260,
            onChanged: (value) {
              if (value != null) {
                ref.read(languageProvider.notifier).state = value;
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        AnalyticsCard(
          title: 'System Preferences',
          subtitle: 'Layout and formatting preferences',
          child: Column(
            children: [
              SettingsToggleRow(
                label: 'Collapse Sidebar by Default',
                subtitle: 'Start with a compact icon-only sidebar',
                value: sidebarCollapsed,
                onChanged: (v) =>
                    ref.read(sidebarCollapsedProvider.notifier).state = v,
              ),
              const Divider(),
              SettingsToggleRow(
                label: 'Compact Date Format',
                subtitle: 'Show dates as 30/07/26 instead of Jul 30, 2026',
                value: compactDateFormat,
                onChanged: (v) =>
                    ref.read(compactDateFormatProvider.notifier).state = v,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
