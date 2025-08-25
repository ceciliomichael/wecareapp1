import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found, using default values
    debugPrint('Warning: .env file not found, using default configuration');
  }

  // Initialize services
  await NotificationService.initialize();
  await SubscriptionService.initializeDefaultPlans();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const WeCareApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WeCareApp extends StatelessWidget {
  const WeCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WeCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0050AA), // Deep blue from logo
          primary: const Color(0xFF0050AA), // Deep blue for primary elements
          secondary: const Color(0xFFF88C24), // Orange for accent elements
          tertiary: const Color(0xFF2C96EE), // Light blue from "We" in logo
          surface: const Color(0xFFF5F5F5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Set this to false to prevent accidental app exits with back button
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final currentContext = navigatorKey.currentContext;
          if (currentContext == null) return;

          // Show an exit confirmation dialog when back button is pressed at the root
          final shouldPop =
              await showDialog<bool>(
                context: currentContext,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Exit App?'),
                      content: const Text(
                        'Are you sure you want to exit the app?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
              ) ??
              false;

          if (shouldPop && navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).pop();
          }
        },
        child: const SplashScreen(),
      ),
    );
  }
}
