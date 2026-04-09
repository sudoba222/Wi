// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_services.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash/splash_page.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WiApp());
}

class WiApp extends StatelessWidget {
  const WiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Firebase auth service — single source of truth for current user
        Provider<AuthService>(create: (_) => AuthService()),
        // Controls light / dark mode toggle from the drawer
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Controls EN / RU / TJ language selection
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Wi Tajikistan',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            // Light theme
            theme: ThemeData(
              fontFamily: 'Roboto',
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.splashPurple,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.background,
            ),
            // Dark theme
            darkTheme: ThemeData(
              fontFamily: 'Roboto',
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.splashPurple,
                brightness: Brightness.dark,
              ).copyWith(
                surface: const Color(0xFF1A0A22),
                onSurface: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFF1A0A22),
              cardColor: const Color(0xFF2D1040),
            ),
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
