/// No-op implementation for non-browser targets.
class BrowserStorage {
  static String? read(String key) => null;

  static void write(String key, String value) {}

  static void delete(String key) {}
}
