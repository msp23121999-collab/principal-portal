import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_spacing.dart';
import '../utils/date_formatter.dart';
import './cards/notification_card.dart';
import './feedback/empty_state.dart';
import '../models/app_notification.dart';
import '../providers/notifications_providers.dart';

/// Filtered notification feed — tapping a card marks it read.
class NotificationList extends ConsumerWidget {
  const NotificationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(filteredNotificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    if (notifications.isEmpty) {
      return const EmptyState(message: 'No notifications in this category.');
    }

    return Column(
      children: [
        for (final n in notifications)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: NotificationCard(
              icon: n.category.icon,
              title: n.title,
              message: n.message,
              timestamp: DateFormatter.relative(n.createdAt),
              isUnread: !n.isRead,
              iconColor: n.category.color,
              onTap: () => notifier.markRead(n.id),
            ),
          ),
      ],
    );
  }
}
