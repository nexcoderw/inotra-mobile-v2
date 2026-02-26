import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../i18n/lang.dart";

final class AuthUI {
  AuthUI._();

  static Text heading(String key, {String? lang, Color? color}) => Text(
        tr(key),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
          color: color ?? Colors.black,
        ),
      );

  static Text subheading(String key, {String? lang, Color? color}) => Text(
        tr(key),
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.black.withOpacity(0.45),
          fontWeight: FontWeight.w500,
        ),
      );

  static Text label(String text, {Color? color}) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color ?? Colors.black,
        ),
      );

  static const TextStyle fieldTextStyle = TextStyle(
    fontSize: 12,
    letterSpacing: 1.2,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static InputDecoration fieldDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12,
        color: Colors.black.withOpacity(0.45),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
    );
  }

  static Widget prefixIcon(dynamic icon) => Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: HugeIcon(
          icon: icon,
          size: 22,
          strokeWidth: 2,
          color: Colors.black.withOpacity(0.45),
        ),
      );

  static Widget primaryPillButton({
    required String text,
    required VoidCallback? onPressed,
    bool busy = false,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          busy ? tr("auth.wait") : text,
          style: buttonTextStyle,
        ),
      ),
    );
  }

  static Widget orDivider() => Row(
        children: [
          Expanded(child: Divider(color: Colors.black.withOpacity(0.10))),
          const SizedBox(width: 12),
          Text(
            tr("auth.or"),
            style: TextStyle(
              color: Colors.black.withOpacity(0.35),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.black.withOpacity(0.10))),
        ],
      );
}
