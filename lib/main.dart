import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('WeCare App: Flutter binding initialized');

    // Load environment configuration
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('WeCare App: Environment configuration loaded successfully');
    } catch (e) {
      // .env file not found, using default values
      debugPrint('WeCare App: Warning - .env file not found, using default configuration: $e');
    }

    // Initialize services with error handling
    try {
      await NotificationService.initialize();
      debugPrint('WeCare App: Notification service initialized successfully');
    } catch (e) {
      debugPrint('WeCare App: Warning - Notification service failed to initialize: $e');
    }

    try {
      await SubscriptionService.initializeDefaultPlans();
      debugPrint('WeCare App: Subscription service initialized successfully');
    } catch (e) {
      debugPrint('WeCare App: Warning - Subscription service failed to initialize: $e');
    }

    // Set preferred orientations
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      debugPrint('WeCare App: Screen orientation preferences set');
    } catch (e) {
      debugPrint('WeCare App: Warning - Failed to set screen orientation: $e');
    }

    debugPrint('WeCare App: Starting app...');
    runApp(const WeCareApp());
  } catch (e, stackTrace) {
    debugPrint('WeCare App: Critical error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to run the app with minimal configuration
    runApp(const WeCareApp());
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WeCareApp extends StatelessWidget {
  const WeCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('WeCareApp: Building material app...');
    
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
      home: const SplashScreen(),
    );
  }
}
