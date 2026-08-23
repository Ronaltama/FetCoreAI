import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/mqtt_service.dart';
import 'providers/device_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/control_screen.dart';
import 'screens/info_screen.dart';
import 'screens/log_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final mqttService = MqttService();
  mqttService.connect();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider(mqttService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: MaterialApp(
        title: 'Pestzone Spray',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  String? _selectedDeviceIdForControl;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          onDeviceTap: (deviceId) {
            setState(() {
              _selectedDeviceIdForControl = deviceId;
              _currentIndex = 1;
            });
          },
        );
      case 1:
        return ControlScreen(initialDeviceId: _selectedDeviceIdForControl);
      case 2:
        return const LogScreen();
      case 3:
        return const InfoScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildScreen(_currentIndex),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          decoration: BoxDecoration(
            color: context.colors.cardBg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: context.colors.primaryGreen,
                unselectedItemColor: context.colors.textSecondary,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    activeIcon: Icon(Icons.home_rounded, size: 28),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.tune_rounded),
                    activeIcon: Icon(Icons.tune_rounded, size: 28),
                    label: 'Kontrol',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_rounded),
                    activeIcon: Icon(Icons.analytics_rounded, size: 28),
                    label: 'Log',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_rounded),
                    activeIcon: Icon(Icons.settings_rounded, size: 28),
                    label: 'Pengaturan',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
