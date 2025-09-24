import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart'; // For color constants and HomePage

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7603B8),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
          height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
          child: Image.asset(
            'assets/icon.png',
            fit: BoxFit.contain, // This will scale the image to fit while maintaining aspect ratio
          ),
        ),
      ),
    );
  }
}