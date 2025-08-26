import 'dart:async';
import 'package:flutter/material.dart';
import 'auth/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: Initializing...');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for splash screen display
      await Future.delayed(const Duration(seconds: 3));
      
      debugPrint('SplashScreen: Navigating to auth screen...');
      // Navigate to the auth screen after 3 seconds
      if (!_hasNavigated && mounted) {
        _hasNavigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      debugPrint('SplashScreen: Error during initialization - $e');
      // If navigation fails, try again after a delay
      if (!_hasNavigated && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _hasNavigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SplashScreen: Building splash screen...');
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with error handling
            _buildLogo(),
            const SizedBox(height: 30),
            // App Name
            const Text(
              'WeCare',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              'Connecting Helpers & Employers',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(75),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/wecarelogo.png',
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('SplashScreen: Failed to load logo image - $error');
            // Fallback UI if image fails to load
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 60,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
