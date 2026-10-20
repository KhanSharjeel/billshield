import 'package:flutter/material.dart';
import 'dart:async'; // Required for the Timer
import 'dashboard.dart'; // So we can navigate to your dashboard

class SplashScreen extends StatefulWidget {
  // We pass the theme variables here so the splash screen matches dark/light mode
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SplashScreen({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

// SingleTickerProviderStateMixin is the engine that drives Flutter animations!
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Set up the Animation Controller (The master clock for the animation)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // The animation takes 2 seconds
    );

    // 2. Create a Scale Tween (Zooming the logo from 50% to 100% size)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack) // Adds a nice bounce effect
    );

    // 3. Create a Fade Tween (Going from completely invisible to fully visible)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn)
    );

    // 4. Start the animation!
    _controller.forward();

    // 5. After 3 seconds, automatically navigate to the Dashboard
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(
            isDarkMode: widget.isDarkMode,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    // Always dispose of controllers to prevent memory leaks when the screen closes
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dynamic background color based on Dark Mode
      backgroundColor: widget.isDarkMode ? const Color(0xFF101B2D) : Colors.teal.shade50,
      body: Center(
        // Wrap everything in your transition widgets
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'images/logo3.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "BillShield",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: widget.isDarkMode ? Colors.tealAccent : Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Predict & Manage",
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 3,
                    color: widget.isDarkMode ? Colors.grey.shade400 : Colors.teal.shade700,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}