import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase error: $e');
  }
  runApp(const TerrariumApp());
}

class TerrariumApp extends StatelessWidget {
  const TerrariumApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerrariumApp',
      debugShowCheckedModeBanner: false,
      theme: T.theme(),
      home: const AuthScreen(),
    );
  }
}
