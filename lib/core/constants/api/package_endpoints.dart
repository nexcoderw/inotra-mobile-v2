final class PackageEndpoints {
  PackageEndpoints._();

  static const list = "api/packages/";
  static const fullList = "api/packages/full/";

  static String detail(String packageId) => "api/package/$packageId/";
}