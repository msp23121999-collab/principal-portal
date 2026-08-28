import 'package:flutter/material.dart';

class DeanMetricData {
  final String label;
  final String value;
  final String trendText;
  final bool isPositiveTrend;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  DeanMetricData({
    required this.label,
    required this.value,
    required this.trendText,
    required this.isPositiveTrend,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

class DepartmentPerformance {
  final String code;
  final String name;
  final double passPercentage;
  final double avgSgpa;
  final int totalStudents;

  DepartmentPerformance({
    required this.code,
    required this.name,
    required this.passPercentage,
    required this.avgSgpa,
    required this.totalStudents,
  });
}

class DeanAlert {
  final String title;
  final String subtitle;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  DeanAlert({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class AcademicEventItem {
  final String month;
  final String day;
  final String title;
  final String dateRange;
  final String category;
  final Color categoryBg;
  final Color categoryColor;

  AcademicEventItem({
    required this.month,
    required this.day,
    required this.title,
    required this.dateRange,
    required this.category,
    required this.categoryBg,
    required this.categoryColor,
  });
}
