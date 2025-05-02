import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const WeCareApp());
}

class WeCareApp extends StatelessWidget {
  const WeCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A),
          primary: const Color(0xFF26A69A),
          secondary: const Color(0xFF80CBC4),
          background: const Color(0xFFF5F5F5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
