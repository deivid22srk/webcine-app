import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ApiService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineVS Proxy App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070913),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFA855F7),
          surface: Color(0xFF151833),
          background: Color(0xFF070913),
          error: Color(0xFFEF4444),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyLarge: GoogleFonts.inter(textStyle: ThemeData.dark().textTheme.bodyLarge),
          bodyMedium: GoogleFonts.inter(textStyle: ThemeData.dark().textTheme.bodyMedium),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF151833).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          elevation: 0,
        ),
      ),
      home: const InitializerScreen(),
    );
  }
}

class InitializerScreen extends StatelessWidget {
  const InitializerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    
    // Roteamento baseado no estado de login e seleção de perfil
    if (api.sessionToken == null) {
      return const LoginScreen();
    } else if (api.activeProfile == null) {
      return const ProfileScreen();
    } else {
      return const DashboardScreen();
    }
  }
}
