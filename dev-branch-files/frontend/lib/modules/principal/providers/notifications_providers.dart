import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notifications_mock_data.dart';
import '../models/app_notification.dart';

/// Mutable notification list — opening/reading a notification marks it read
/// in place (the mock stand-in for a write-backed "mark as read" API call).
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(NotificationsMockData.all());

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
      return NotificationsNotifier();
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

/// null = all categories.
final notificationCategoryFilterProvider = StateProvider<NotificationCategory?>(
  (ref) => null,
);

final filteredNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final all = ref.watch(notificationsProvider);
  final category = ref.watch(notificationCategoryFilterProvider);
  if (category == null) return all;
  return all.where((n) => n.category == category).toList();
});
