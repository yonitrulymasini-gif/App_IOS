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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}