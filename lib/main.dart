import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';

void main() {
  runApp(const WiApp());
}

class WiApp extends StatelessWidget {
  const WiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wi Tajikistan',
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}