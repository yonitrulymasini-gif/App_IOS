import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class T {
  // Surfaces — Terra DA
  static const bg       = Color(0xFF0A1A0F);
  static const surface  = Color(0xFF0F1F14);
  static const card     = Color(0xFF162018);
  static const card2    = Color(0xFF1A2A1F);
  static const border   = Color(0x12FFFFFF);

  // Text
  static const textPrimary   = Color(0xFFE8F0EB);
  static const textSecondary = Color(0xFF6B8A72);
  static const textTertiary  = Color(0xFF3A5040);

  // Accents
  static const green      = Color(0xFF3DD68C);
  static const greenBtn   = Color(0xFF8DC97A);
  static const gold       = Color(0xFFC9A84C);
  static const red        = Color(0xFFEF4444);
  static const redBg      = Color(0x308B2020);

  // Type — serif pour titres, system pour corps
  static TextStyle serif(double size, {FontWeight w = FontWeight.w700, Color c = textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: size, fontWeight: w, color: c, height: 1.15);

  static const t11 = TextStyle(fontSize: 11, height: 1.4, letterSpacing: 1.2);
  static const t12 = TextStyle(fontSize: 12, height: 1.4);
  static const t13 = TextStyle(fontSize: 13, height: 1.5);
  static const t14 = TextStyle(fontSize: 14, height: 1.5);
  static const t15 = TextStyle(fontSize: 15, height: 1.5);
  static const t16 = TextStyle(fontSize: 16, height: 1.4);
  static const t17 = TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w600);

  static ThemeData theme() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: green,
      error: red,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 20),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? bg : textSecondary),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? green : card2),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 0.5, space: 0),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green)),
      hintStyle: const TextStyle(color: textTertiary, fontSize: 16),
    ),
  );
}
