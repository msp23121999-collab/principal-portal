import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

enum NotificationCategory { announcement, academic, emergency, circular }

extension NotificationCategoryX on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.announcement:
        return 'Announcement';
      case NotificationCategory.academic:
        return 'Academic Alert';
      case NotificationCategory.emergency:
        return 'Emergency Alert';
      case NotificationCategory.circular:
        return 'Circular';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.announcement:
        return AppIcons.notifications;
      case NotificationCategory.academic:
        return AppIcons.results;
      case NotificationCategory.emergency:
        return AppIcons.warning;
      case NotificationCategory.circular:
        return AppIcons.document;
    }
  }

  Color get color {
    switch (this) {
      case NotificationCategory.announcement:
        return AppColors.primaryBlue;
      case NotificationCategory.academic:
        return AppColors.success;
      case NotificationCategory.emergency:
        return AppColors.danger;
      case NotificationCategory.circular:
        return AppColors.accentGold;
    }
  }
}

/// A single institution-wide notification/alert.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    category: category,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}
