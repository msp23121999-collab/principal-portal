import 'package:flutter/material.dart';

/// A single row in the Dashboard's recent-activity feed.
class RecentActivity {
  const RecentActivity({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime timestamp;
}
