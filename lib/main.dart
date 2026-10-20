import 'package:flutter/material.dart';
import 'pages/dashboard.dart';
import 'pages/splash_screen.dart';

void main() => runApp(const BillShieldApp());

class BillShieldApp extends StatefulWidget {
  const BillShieldApp({Key? key}) : super(key: key);

  @override
  State<BillShieldApp> createState() => _BillShieldAppState();
}

class _BillShieldAppState extends State<BillShieldApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BillShield',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,

      home: SplashScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}