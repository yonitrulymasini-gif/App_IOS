import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase initialisé');
  } catch (e) {
    print('❌ Erreur Firebase : $e');
  }
  runApp(const TerrariumApp());
}

class TerrariumApp extends StatelessWidget {
  const TerrariumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  title: 'Terrarium',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1F1A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4ADE80),
      secondary: Color(0xFF60A5FA),
      surface: Color(0xFF242B24),
      background: Color(0xFF1A1F1A),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF242B24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((s) =>
        s.contains(MaterialState.selected) ? const Color(0xFF1A1F1A) : const Color(0xFF6B8F6B)),
      trackColor: MaterialStateProperty.resolveWith((s) =>
        s.contains(MaterialState.selected) ? const Color(0xFF4ADE80) : const Color(0xFF2D3F2D)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1F1A),
      foregroundColor: Color(0xFFE8F0E8),
      elevation: 0,
      titleTextStyle: TextStyle(color: Color(0xFFE8F0E8), fontSize: 16, fontWeight: FontWeight.w500),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFE8F0E8)),
      bodySmall: TextStyle(color: Color(0xFF6B8F6B)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF4ADE80),
      foregroundColor: Color(0xFF1A1F1A),
    ),
    useMaterial3: true,
  ),
  home: const AuthScreen(),
);
}
}
