import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/app_provider.dart';
import 'screens/web_home_screen.dart';

class HadiyaWebApp extends StatelessWidget {
  const HadiyaWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
      ],
      child: MaterialApp(
        title: 'Hadiya Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A5C52),
            primary: const Color(0xFF1A5C52),
            secondary: const Color(0xFFF2E4CF),
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F8F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
            titleTextStyle: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const WebHomeScreen(),
      ),
    );
  }
}
