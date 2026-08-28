import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeMode { light, dark }

extension AppThemeModeX on AppThemeMode {
  String get label => this == AppThemeMode.light ? 'Light' : 'Dark';
}

enum AppLanguage { english, tamil }

extension AppLanguageX on AppLanguage {
  String get label => this == AppLanguage.english ? 'English' : 'Tamil (தமிழ்)';
}

/// Local-only settings state — there is no backend to persist preferences
/// to yet, so these providers simply hold the current selection. Only the
/// theme mode is left at [AppThemeMode.light] functionally (dark theme
/// isn't built), matching the "wired but not all functional" scope for
/// this module.
final themeModeProvider = StateProvider<AppThemeMode>(
  (ref) => AppThemeMode.light,
);
final languageProvider = StateProvider<AppLanguage>(
  (ref) => AppLanguage.english,
);

final emailNotificationsProvider = StateProvider<bool>((ref) => true);
final smsNotificationsProvider = StateProvider<bool>((ref) => false);
final pushNotificationsProvider = StateProvider<bool>((ref) => true);

final compactDateFormatProvider = StateProvider<bool>((ref) => false);
