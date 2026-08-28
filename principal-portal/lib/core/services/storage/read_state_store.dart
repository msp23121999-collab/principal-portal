import 'read_state_store_stub.dart'
    if (dart.library.js_interop) 'read_state_store_web.dart';

/// Remembers which notifications the signed-in Principal has already read.
///
/// The key is scoped to the Supabase user id. The portal previously wrote to a
/// single global key, so on a shared browser the next Principal to sign in
/// inherited the previous one's read state — alerts they had never seen were
/// already marked read, and the unread badge undercounted.
///
/// The implementation is chosen at compile time: the browser version uses
/// `package:web`, which does not exist on the Dart VM the widget tests run on,
/// so a no-op stub stands in there.
class ReadStateStore {
  ReadStateStore._();

  static const String _prefix = 'principal_read_notifications';

  /// The storage key for [userId], or the shared key when no one is signed in
  /// (a portal running without a backend has no identity to scope to).
  static String keyFor(String? userId) =>
      userId == null || userId.isEmpty ? _prefix : '$_prefix:$userId';

  static Set<String> load(String? userId) =>
      ReadStateStoreImpl.load(keyFor(userId));

  static void save(String? userId, Iterable<String> ids) =>
      ReadStateStoreImpl.save(keyFor(userId), ids);

  /// Called on sign-out, so read state does not outlive the session that
  /// produced it.
  static void clear(String? userId) => ReadStateStoreImpl.clear(keyFor(userId));
}
