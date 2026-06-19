import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class T {
  // Surface
  static const bg       = Color(0xFF0F1210);
  static const surface  = Color(0xFF171C17);
  static const elevated = Color(0xFF1E241E);
  static const border   = Color(0xFF242C24);
  static const divider  = Color(0xFF1C221C);

  // Text
  static const textPrimary   = Color(0xFFECF0EC);
  static const textSecondary = Color(0xFF6A7D6A);
  static const textTertiary  = Color(0xFF3D4D3D);

  // Accent
  static const green  = Color(0xFF3DD68C);
  static const blue   = Color(0xFF5B9CF6);
  static const amber  = Color(0xFFF59E0B);
  static const red    = Color(0xFFEF4444);

  // Type scale
  static const t12 = TextStyle(fontSize: 12, height: 1.4);
  static const t13 = TextStyle(fontSize: 13, height: 1.4);
  static const t14 = TextStyle(fontSize: 14, height: 1.5);
  static const t15 = TextStyle(fontSize: 15, height: 1.5);
  static const t17 = TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w600);
  static const t22 = TextStyle(fontSize: 22, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.5);

  static ThemeData theme() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: green,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: textSecondary, size: 20),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? bg : textSecondary),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? green : elevated),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 0),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: elevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: green)),
      hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
    ),
  );
}
