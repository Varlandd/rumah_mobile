import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/rumah_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RumahProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()), // Added this provider
      ],
      child: MaterialApp(
        title: 'RumahKu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0f766e),
            primary: const Color(0xFF0f766e),
          ),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF0f766e),
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
  