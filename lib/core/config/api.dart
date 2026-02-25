import "env.dart";

final class Api {
  Api._();

  /// Builds a full URL from a relative path.
  /// Example: Api.url("api/auth/login/") -> https://api.inotra.rw/api/auth/login/
  static Uri url(String path) {
    final clean = _stripLeadingSlash(path);
    return Uri.parse("${Env.baseUrl}$clean");
  }

  static String _stripLeadingSlash(String v) {
    if (v.startsWith("/")) return v.substring(1);
    return v;
  }
}
