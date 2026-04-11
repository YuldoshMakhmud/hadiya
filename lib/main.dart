import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/orders_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/country_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'admin/admin_app.dart';
import 'services/telegram_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv load: $e');
  }

  // Firebase init
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Mobile: anonymous auth
  if (!kIsWeb) {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (_) {}
  }

  if (kIsWeb) {
    const appMode =
        String.fromEnvironment('APP_MODE', defaultValue: 'miniapp');

    if (appMode == 'admin') {
      runApp(const AdminApp());
    } else {
      // Miniapp — Telegram SDK
      TelegramService.ready();
      TelegramService.expand();

      final provider = AppProvider();
      await provider.init();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => OrdersProvider()),
          ],
          child: const HadiyaApp(initialRoute: '/home'),
        ),
      );
    }
  } else {
    // Mobile app
    final provider = AppProvider();
    await provider.init();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ],
        child: const HadiyaApp(),
      ),
    );
  }
}

class HadiyaApp extends StatelessWidget {
  final String initialRoute;
  const HadiyaApp({super.key, this.initialRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hadiya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: initialRoute,
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/country': (_) => const CountrySelectionScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/search': (_) => const SearchScreen(),
      },
    );
  }
}
