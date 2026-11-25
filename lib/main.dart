import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:billshield/theme/app_theme.dart';
import 'package:billshield/screens/dashboard_screen.dart';
import 'package:billshield/database/app_database.dart';
import 'package:billshield/services/hive_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorageService.init();
  if (!kIsWeb) {
    try {
      await AppDatabase.instance.database;
    } catch (_) {}
  }
  runApp(const BillShieldApp());
}

class BillShieldApp extends StatefulWidget {
  const BillShieldApp({super.key});

  @override
  State<BillShieldApp> createState() => _BillShieldAppState();
}

class _BillShieldAppState extends State<BillShieldApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final savedMode = await AppDatabase.instance.getSetting('themeMode');
      if (savedMode != null && mounted) {
        setState(() {
          _themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    setState(() {
      _themeMode = newMode;
    });
    try {
      await AppDatabase.instance.setSetting(
        'themeMode',
        isDark ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BillShield',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: DashboardScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}
