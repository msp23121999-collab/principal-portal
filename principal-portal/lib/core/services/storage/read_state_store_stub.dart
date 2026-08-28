/// Non-web stand-in for the browser's `localStorage`.
///
/// The Dart VM the widget tests run on has no `dart:js_interop`, so importing
/// `package:web` there fails to compile. Every call here is a no-op: read state
/// is a browser convenience, and a test that cannot reach a browser should see
/// nothing marked read rather than fail to load at all.
class ReadStateStoreImpl {
  ReadStateStoreImpl._();

  static Set<String> load(String key) => <String>{};

  static void save(String key, Iterable<String> ids) {}

  static void clear(String key) {}
}
