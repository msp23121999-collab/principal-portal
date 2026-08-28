import 'package:flutter/material.dart';

/// Centralized icon aliases — one icon per concept, referenced everywhere
/// that concept appears (sidebar, page headers, cards) so the same idea
/// never renders with two different glyphs across the app.
class AppIcons {
  AppIcons._();

  // Navigation / modules
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData profile = Icons.person_outline;
  static const IconData institution = Icons.account_balance_outlined;
  static const IconData department = Icons.apartment_outlined;
  static const IconData faculty = Icons.groups_outlined;
  static const IconData students = Icons.school_outlined;
  static const IconData attendance = Icons.event_available_outlined;
  static const IconData results = Icons.assessment_outlined;
  static const IconData placements = Icons.work_outline;
  static const IconData leave = Icons.fact_check_outlined;
  static const IconData reports = Icons.description_outlined;
  static const IconData notifications = Icons.notifications_none_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData logout = Icons.logout_outlined;

  // Common actions / chrome
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData clock = Icons.access_time;
  static const IconData trendUp = Icons.trending_up;
  static const IconData trendDown = Icons.trending_down;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData chevronDown = Icons.keyboard_arrow_down;
  static const IconData menu = Icons.menu;
  static const IconData close = Icons.close;
  static const IconData check = Icons.check_circle_outline;
  static const IconData warning = Icons.error_outline;
  static const IconData info = Icons.info_outline;
  static const IconData download = Icons.download_outlined;
  static const IconData upload = Icons.upload_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData add = Icons.add;
  static const IconData approve = Icons.check;
  static const IconData reject = Icons.close;
  static const IconData mail = Icons.mail_outline;
  static const IconData phone = Icons.phone_outlined;
  static const IconData location = Icons.location_on_outlined;
  static const IconData document = Icons.insert_drive_file_outlined;
  static const IconData award = Icons.emoji_events_outlined;
  static const IconData research = Icons.science_outlined;
  static const IconData education = Icons.school;
  static const IconData security = Icons.lock_outline;
  static const IconData language = Icons.language_outlined;
  static const IconData theme = Icons.palette_outlined;
  static const IconData company = Icons.business_outlined;
  static const IconData currency = Icons.payments_outlined;
  static const IconData avatarFallback = Icons.account_circle_outlined;
}
