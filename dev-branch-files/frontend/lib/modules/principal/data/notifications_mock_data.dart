import '../models/app_notification.dart';

/// Seed notifications spanning all four categories.
class NotificationsMockData {
  NotificationsMockData._();

  static List<AppNotification> all() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n01',
        title: 'Semester 6 Results Published',
        message:
            'Results for Semester 6, 2025-26 have been published by the Examination Cell.',
        category: NotificationCategory.academic,
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: false,
      ),
      AppNotification(
        id: 'n02',
        title: 'Fire Drill Scheduled Tomorrow',
        message:
            'A mandatory fire safety drill will be conducted campus-wide at 11:00 AM tomorrow.',
        category: NotificationCategory.emergency,
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: false,
      ),
      AppNotification(
        id: 'n03',
        title: 'Odd Semester Timetable Circular',
        message:
            'Revised timetable for the odd semester is effective from next Monday.',
        category: NotificationCategory.circular,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: false,
      ),
      AppNotification(
        id: 'n04',
        title: 'Annual Sports Day Announcement',
        message:
            'Annual Sports Day will be held on August 15th at the main ground.',
        category: NotificationCategory.announcement,
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        isRead: true,
      ),
      AppNotification(
        id: 'n05',
        title: 'Internal Assessment II Schedule',
        message:
            'Internal Assessment II for all departments begins August 10th.',
        category: NotificationCategory.academic,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AppNotification(
        id: 'n06',
        title: 'Campus Power Maintenance Notice',
        message:
            'Scheduled power maintenance on Saturday from 8:00 AM to 12:00 PM.',
        category: NotificationCategory.circular,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      AppNotification(
        id: 'n07',
        title: 'NAAC Peer Team Visit Confirmed',
        message:
            'The NAAC peer team visit is confirmed for the last week of August.',
        category: NotificationCategory.announcement,
        createdAt: now.subtract(const Duration(days: 4)),
        isRead: true,
      ),
      AppNotification(
        id: 'n08',
        title: 'Medical Emergency Contact Update',
        message:
            'Updated campus medical emergency contact numbers have been circulated.',
        category: NotificationCategory.emergency,
        createdAt: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];
  }
}
