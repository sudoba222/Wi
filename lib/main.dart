import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_services.dart';
import 'services/chat_service.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WiApp());
}

class WiApp extends StatefulWidget {
  const WiApp({Key? key}) : super(key: key);

  @override
  State<WiApp> createState() => _WiAppState();
}

class _WiAppState extends State<WiApp> with WidgetsBindingObserver {
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService = AuthService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _authService.setUserOnline();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.detached) {
      _authService.setUserOffline();
    }
  }

  @override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      Provider<AuthService>(create: (_) => _authService),
      Provider<ChatService>(create: (_) => ChatService()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Wi Tajikistan',
          theme: ThemeData(
            fontFamily: 'Roboto',
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            fontFamily: 'Roboto',
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    ),
  );
}
}