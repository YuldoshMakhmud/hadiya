import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_main_screen.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hadiya — Admin Panel',
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
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1A5C52)),
              ),
            );
          }
          if (snapshot.data != null) {
            return const AdminMainScreen();
          }
          return const AdminLoginScreen();
        },
      ),
    );
  }
}
