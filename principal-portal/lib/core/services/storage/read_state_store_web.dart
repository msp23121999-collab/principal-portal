import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Browser-backed store for which notifications a Principal has already read.
///
/// Only notification ids are kept. No message body, no personal data and no
/// credential ever reaches this store — Supabase manages the session itself,
/// and duplicating a token into our own key would give an attacker a second
/// place to look.
class ReadStateStoreImpl {
  ReadStateStoreImpl._();

  static Set<String> load(String key) {
    try {
      final stored = web.window.localStorage.getItem(key);
      if (stored == null) return <String>{};
      return Set<String>.from(jsonDecode(stored) as Iterable);
    } catch (error) {
      // A corrupt or foreign value must not stop the feed from rendering.
      if (kDebugMode) {
        debugPrint('Failed to read notification state from local storage.');
      }
      return <String>{};
    }
  }

  static void save(String key, Iterable<String> ids) {
    try {
      web.window.localStorage.setItem(key, jsonEncode(ids.toList()));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to persist notification state to local storage.');
      }
    }
  }

  static void clear(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to clear notification state from local storage.');
      }
    }
  }
}
