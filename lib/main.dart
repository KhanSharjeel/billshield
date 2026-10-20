import 'package:flutter/material.dart';
import 'pages/dashboard.dart';

void main() => runApp(const BillShieldApp());

class BillShieldApp extends StatefulWidget {
  const BillShieldApp({Key? key}) : super(key: key);

  @override
  State<BillShieldApp> createState() => _BillShieldAppState();
}

class _BillShieldAppState extends State<BillShieldApp> {
  // 1. Create a variable to track the current theme
  ThemeMode _themeMode = ThemeMode.light;

  // 2. Create a function to toggle the theme
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
      // 3. Define the Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      // 4. Define the Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      // 5. Tell the app which theme to use right now
      themeMode: _themeMode,

      // 6. Pass the current state and the toggle function to the Dashboard
      home: Dashboard(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}