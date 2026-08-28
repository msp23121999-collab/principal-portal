import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/repository.dart';
import '../../../core/services/storage/read_state_store.dart';
import '../data/notifications_repository.dart';
import '../models/app_notification.dart';

final notificationsRepositoryProvider = Provider(
  (ref) => NotificationsRepository(),
);

/// Feed as fetched, plus where it came from.
final notificationsSourcedProvider =
    FutureProvider<Sourced<List<AppNotification>>>((ref) {
      return ref.watch(notificationsRepositoryProvider).fetchAll();
    });

/// Mutable notification list — marking an item read updates only this
/// portal's copy; the source tables belong to the Faculty and Student
/// portals and are never written to.
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier(List<AppNotification> initial)
    : super([]) {
    _init(initial);
  }

  void _init(List<AppNotification> initial) {
    final readIds = ReadStateStore.load(null);
    state = [
      for (final n in initial)
        if (readIds.contains(n.id) || n.isRead) n.copyWith(isRead: true) else n,
    ];
  }

  void _persistReads(List<AppNotification> current) {
    ReadStateStore.save(
      null,
      current.where((n) => n.isRead).map((n) => n.id),
    );
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    _persistReads(state);
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
    _persistReads(state);
  }
}

/// Rebuilds once the fetch resolves. Empty until then, so the unread badge
/// counts real alerts rather than invented ones.
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
      final fetched = ref
          .watch(notificationsSourcedProvider)
          .valueOrNull
          ?.value;
      return NotificationsNotifier(fetched ?? const []);
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
