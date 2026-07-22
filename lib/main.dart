import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/constants/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'screens/naats_bayanat_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/zikr_screen.dart';
import 'screens/utility_screens.dart';
import 'screens/islamic_calendar_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/misc_screens.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'widgets/common_widgets.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Local notifications + background video polling
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ZikrProvider()),
        ChangeNotifierProvider(create: (_) => KhatamProvider()),
        ChangeNotifierProvider(create: (_) => QuranSettingsProvider()),
      ],
      child: const SaifiTVApp(),
    ),
  );
}

class SaifiTVApp extends StatelessWidget {
  const SaifiTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, theme, __) => MaterialApp(
        title: 'Saifi TV – Islamic Videos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: theme.themeMode,
        home: const CustomSplashScreen(),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == 0 || index == 1 || index == 3 || index == 4) {
      setState(() => _currentIndex = index);
    } else {
      Widget screen;
      switch (index) {
        case 2: screen = const BayanatScreen(); break;
        case 5: screen = const PrayerTimesScreen(); break;
        case 6: screen = const QiblaScreen(); break;
        case 7: screen = const IslamicCalendarScreen(); break;
        case 8: screen = const HadithScreen(); break;
        case 9: screen = FavoritesScreen(onNavTap: _onNavTap); break;
        case 10: screen = const SearchScreen(); break;
        case 11: screen = const NotificationSettingsScreen(); break;
        case 12: screen = const PrivacyScreen(); break;
        case 13: screen = const AboutScreen(); break;
        default: return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(onNavTap: _onNavTap);
      case 1:
        return const NaatsScreen();
      case 2:
        return const BayanatScreen();
      case 3:
        return const QuranScreen();
      case 4:
        return const ZikrScreen();
      case 5:
        return const PrayerTimesScreen();
      case 6:
        return const QiblaScreen();
      case 7:
        return const IslamicCalendarScreen();
      case 8:
        return const HadithScreen();
      case 9:
        return FavoritesScreen(onNavTap: _onNavTap);
      case 10:
        return const SearchScreen();
      case 11:
        return const NotificationSettingsScreen();
      case 12:
        return const PrivacyScreen();
      case 13:
        return const AboutScreen();
      default:
        return HomeScreen(onNavTap: _onNavTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavTap: _onNavTap,
      ),
      body: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildScreen(),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex < 5 ? _currentIndex : 0,
        onTap: _onNavTap,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.music_note_rounded,
                label: 'Naats',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'Quran',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.track_changes_rounded,
                label: 'Zikr',
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
              _NavItem(
                icon: Icons.menu_rounded,
                label: 'More',
                isSelected: false,
                onTap: () => Scaffold.of(context).openDrawer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.15),
                    AppColors.gold.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.gold : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
