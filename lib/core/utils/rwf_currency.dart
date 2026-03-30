import "package:intl/intl.dart";

final class RwfCurrency {
  RwfCurrency._();

  static final NumberFormat _decimal = NumberFormat.decimalPattern();

  static String format(num value) {
    return "RWF ${_decimal.format(value.round())}";
  }

  static String compact(num value) {
    final abs = value.abs();
    final sign = value < 0 ? "-" : "";

    if (abs >= 1000000) {
      final short = abs >= 10000000
          ? (abs / 1000000).toStringAsFixed(0)
          : (abs / 1000000).toStringAsFixed(1);
      return "${sign}RWF ${_trim(short)}M";
    }

    if (abs >= 1000) {
      final short = abs >= 100000
          ? (abs / 1000).toStringAsFixed(0)
          : (abs / 1000).toStringAsFixed(1);
      return "${sign}RWF ${_trim(short)}K";
    }

    return "${sign}RWF ${_decimal.format(abs.round())}";
  }

  static String _trim(String value) {
    if (!value.contains(".")) return value;
    return value.replaceFirst(RegExp(r"\.?0+$"), "");
  }
}
