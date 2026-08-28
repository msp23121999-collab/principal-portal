import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/inputs/filter_chip_group.dart';
import '../../../core/widgets/layout/content_scaffold.dart';
import '../../../core/widgets/layout/page_header.dart';
import '../models/app_notification.dart';
import '../providers/notifications_providers.dart';
import '../widgets/create_notice_dialog.dart';
import '../widgets/notification_list.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(notificationCategoryFilterProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return ContentScaffold(
      children: [
        PageHeader(
          title: 'Notifications',
          breadcrumbSegments: const ['Administration', 'Notifications'],
          subtitle:
              '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
          actions: [
            SecondaryButton(
              label: 'Mark All as Read',
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
            ),
            PrimaryButton(
              label: 'Create Notice',
              onPressed: () => CreateNoticeDialog.show(context),
            ),
          ],
        ),
        FilterChipGroup<NotificationCategory>(
          value: selectedCategory,
          items: NotificationCategory.values,
          itemLabel: (c) => c.label,
          onChanged: (value) =>
              ref.read(notificationCategoryFilterProvider.notifier).state =
                  value,
        ),
        const NotificationList(),
      ],
    );
  }
}
