// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/auth_services.dart';
import '../../models/user_profile.dart';
import '../profile/profile_page.dart';
import 'feed_page.dart';
import 'messages_page.dart';
import 'post_page.dart';

// HomePage — root scaffold that owns the drawer and bottom nav
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  UserProfile? _userProfile;

  final _pages = [FeedPage(), MessagesPage()];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      final p = await auth.getFullUserProfile(auth.currentUser!.uid);
      if (mounted) setState(() => _userProfile = p);
    }
  }

  void _onTap(int index) => setState(() => _currentIndex = index);
  void _openPost() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostPage()));
  void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      body: PageWithDrawerCallback(
        onOpenDrawer: openDrawer,
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      drawer: _AppDrawer(userProfile: _userProfile),
      bottomNavigationBar: _BottomBar(currentIndex: _currentIndex, onTap: _onTap, onPost: _openPost),
    );
  }
}

// InheritedWidget so FeedPage can call openDrawer without prop drilling
class PageWithDrawerCallback extends InheritedWidget {
  final VoidCallback onOpenDrawer;
  const PageWithDrawerCallback({required this.onOpenDrawer, required super.child});

  static PageWithDrawerCallback? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageWithDrawerCallback>();

  @override
  bool updateShouldNotify(PageWithDrawerCallback old) => onOpenDrawer != old.onOpenDrawer;
}

// Side drawer — profile header, nav shortcuts, dark mode, language, help, sign-out
class _AppDrawer extends StatelessWidget {
  final UserProfile? userProfile;
  const _AppDrawer({this.userProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E0B2C) : AppColors.white;
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final sub = isDark ? Colors.white54 : AppColors.mutedText;

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          children: [
            // Brand gradient header with user info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.darkPurple, AppColors.splashPurple]),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (userProfile != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userProfile: userProfile!)));
                    },
                    child: _GradAvatar(name: userProfile?.name ?? 'U', size: 54, fontSize: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full name — large and bold
                        Text(userProfile?.name ?? 'Your Name',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        // Job title
                        if (userProfile?.jobTitle?.isNotEmpty == true)
                          Text(userProfile!.jobTitle!,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        // Company
                        if (userProfile?.company?.isNotEmpty == true)
                          Text(userProfile!.company!,
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                        const SizedBox(height: 2),
                        // Email in smaller muted text
                        Text(auth.currentUser?.email ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Dark mode toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        _Chip(icon: theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                        const SizedBox(width: 14),
                        Expanded(child: Text(lang.t('darkMode'), style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w500))),
                        Switch(
                          value: theme.isDark,
                          onChanged: (_) => theme.toggle(),
                          activeColor: AppColors.sunglow,
                          activeTrackColor: AppColors.sunglow.withOpacity(0.3),
                          inactiveThumbColor: AppColors.mutedText,
                        ),
                      ],
                    ),
                  ),

                  // Language selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _Chip(icon: Icons.language_rounded),
                          const SizedBox(width: 14),
                          Text(lang.t('language'), style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w500)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          const SizedBox(width: 50),
                          _LangPill(label: 'EN', active: lang.lang == AppLanguage.en, onTap: () => lang.setLanguage(AppLanguage.en)),
                          const SizedBox(width: 8),
                          _LangPill(label: 'RU', active: lang.lang == AppLanguage.ru, onTap: () => lang.setLanguage(AppLanguage.ru)),
                          const SizedBox(width: 8),
                          _LangPill(label: 'TJ', active: lang.lang == AppLanguage.tj, onTap: () => lang.setLanguage(AppLanguage.tj)),
                        ]),
                      ],
                    ),
                  ),

                  _Div(isDark: isDark),

                  _Tile(icon: Icons.help_outline_rounded, label: lang.t('helpSupport'), textColor: text, onTap: () => Navigator.pop(context)),
                  _Tile(icon: Icons.info_outline_rounded, label: lang.t('about'), textColor: text, onTap: () => Navigator.pop(context)),

                  _Div(isDark: isDark),

                  // Sign out in red
                  _Tile(icon: Icons.logout_rounded, label: lang.t('signOut'), textColor: Colors.red, iconColor: Colors.red,
                    onTap: () async { Navigator.pop(context); await auth.signOut(); }),
                ],
              ),
            ),

            Padding(padding: const EdgeInsets.all(16), child: Text('Wi Tajikistan v1.0', style: TextStyle(color: sub, fontSize: 11))),
          ],
        ),
      ),
    );
  }
}

// Drawer list tile
class _Tile extends StatelessWidget {
  final IconData icon; final String label; final Color textColor; final Color? iconColor; final VoidCallback onTap;
  const _Tile({required this.icon, required this.label, required this.textColor, required this.onTap, this.iconColor});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: _Chip(icon: icon, color: iconColor),
    title: Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
    onTap: onTap,
  );
}

// Small icon chip
class _Chip extends StatelessWidget {
  final IconData icon; final Color? color;
  const _Chip({required this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.wisteria;
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: c, size: 20),
    );
  }
}

// Horizontal section divider
class _Div extends StatelessWidget {
  final bool isDark; const _Div({required this.isDark});
  @override
  Widget build(BuildContext context) => Divider(
    color: isDark ? Colors.white12 : AppColors.mutedText.withOpacity(0.15),
    height: 20, indent: 16, endIndent: 16,
  );
}

// Language selection pill
class _LangPill extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _LangPill({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.sunglow : AppColors.wisteria.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.sunglow : AppColors.wisteria.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: active ? AppColors.darkPurple : AppColors.mutedText, fontSize: 13, fontWeight: FontWeight.w700)),
    ),
  );
}

// Gradient avatar circle
class _GradAvatar extends StatelessWidget {
  final String name; final double size; final double fontSize;
  const _GradAvatar({required this.name, required this.size, required this.fontSize});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.wisteria, AppColors.splashPurple])),
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w700))),
  );
}

// Floating bottom nav pill
class _BottomBar extends StatelessWidget {
  final int currentIndex; final ValueChanged<int> onTap; final VoidCallback onPost;
  const _BottomBar({required this.currentIndex, required this.onTap, required this.onPost});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D1040) : AppColors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.sunglow.withOpacity(0.55), width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.sunglow.withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 6)),
              BoxShadow(color: AppColors.darkPurple.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, index: 0, currentIndex: currentIndex, onTap: onTap),
              // Center amber post button
              Expanded(
                child: GestureDetector(
                  onTap: onPost,
                  child: Center(
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.sunglow,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.sunglow.withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.add_rounded, color: AppColors.darkPurple, size: 30),
                    ),
                  ),
                ),
              ),
              _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, index: 1, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

// A nav tab with an animated amber indicator line above the icon
class _NavItem extends StatelessWidget {
  final IconData icon; final IconData activeIcon; final int index; final int currentIndex; final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.index, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicator pill — animates width to 0 when inactive
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isActive ? 22 : 0, height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(color: AppColors.sunglow, borderRadius: BorderRadius.circular(2)),
            ),
            Icon(isActive ? activeIcon : icon, size: 26,
              color: isActive ? (isDark ? AppColors.sunglow : AppColors.darkPurple) : AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
