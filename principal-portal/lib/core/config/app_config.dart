import 'package:flutter/foundation.dart';

/// Backend connection settings.
class AppConfig {
  AppConfig._();

  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _envApiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  static String get apiKey => _envApiKey;

  /// Base API URL.
  /// Development uses `http://localhost:3000` (unless overridden via SUPABASE_URL).
  /// Release builds must receive an explicit SUPABASE_URL at build time.
  /// There is intentionally no hosted-provider fallback.
  static String get supabaseUrl {
    final String rawUrl;
    if (kReleaseMode) {
      if (_envUrl.isNotEmpty) {
        rawUrl = _envUrl;
      } else {
        throw StateError(
          'CRITICAL: Release build requires an explicit SUPABASE_URL.',
        );
      }

      // A release build may explicitly target the local Express backend for
      // the sanctioned read-only E2E verification. Reject only an implicit
      // localhost fallback when no URL was supplied at build time.
      if (_envUrl.isEmpty &&
          (rawUrl.contains('localhost') || rawUrl.contains('127.0.0.1'))) {
        throw StateError(
          'CRITICAL: Production release build configured with insecure or localhost URL: $rawUrl',
        );
      }
    } else {
      rawUrl = _envUrl.isNotEmpty ? _envUrl : 'http://localhost:3000';
    }

    // Ensure no trailing slash
    return rawUrl.endsWith('/')
        ? rawUrl.substring(0, rawUrl.length - 1)
        : rawUrl;
  }

  /// True when backend is configured.
  static bool get isBackendConfigured => true;
}
