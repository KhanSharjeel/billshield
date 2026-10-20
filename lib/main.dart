import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';

void main() => runApp(const BillShieldApp());

class BillShieldApp extends StatefulWidget {
  const BillShieldApp({Key? key}) : super(key: key);

  @override
  State<BillShieldApp> createState() => _BillShieldAppState();
}

class _BillShieldAppState extends State<BillShieldApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BillShield',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: SplashScreen(
        currentThemeMode: _themeMode,
        onThemeModeChanged: _toggleThemeMode,
      ),
    );
  }
}
