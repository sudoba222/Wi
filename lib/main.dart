import 'package:flutter/material.dart';

const Color kDarkPurple = Color(0xFF210B2C);
const Color kWisteria = Color(0xFFBC96E6);
const Color kSunglow = Color(0xFFFFD166);
const Color kWhite = Color(0xFFFFFFFF);

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
        scaffoldBackgroundColor: kWhite,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Tooltip(
            message: 'Menu',
            child: Icon(Icons.menu, color: kDarkPurple, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: kWisteria,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search, color: kWhite, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      enabled: false, // Make it read-only for now
                      style: const TextStyle(color: kWhite, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search',
                        hintStyle: const TextStyle(color: kWhite, fontSize: 16),
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      cursorColor: kWhite,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Tooltip(
            message: 'Find a Job',
            child: Icon(Icons.work_outline, color: kDarkPurple, size: 28),
          ),
          const SizedBox(width: 16),
          Tooltip(
            message: 'Profile',
            child: Icon(Icons.person_outline, color: kDarkPurple, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedsPlaceholder() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kDarkPurple.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Feeds Part',
          style: const TextStyle(
            color: kDarkPurple,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 32, right: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavCircleButton(
              icon: Icons.home,
              onTap: () {},
            ),
            _NavCircleButton(
              icon: Icons.add,
              onTap: () {},
            ),
            _NavCircleButton(
              icon: Icons.message,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: _buildFeedsPlaceholder()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavCircleButton({
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: kSunglow,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kDarkPurple.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: kDarkPurple, size: 28),
        ),
      ),
    );
  }
}