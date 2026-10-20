import 'package:flutter/material.dart';
import 'dashboard.dart';

class SplashScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const SplashScreen({
    Key? key,
    this.currentThemeMode = ThemeMode.system,
    this.onThemeModeChanged,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressVal;

  String _statusMessage = 'Initializing NEPRA Tariff Calculator...';

  @override
  void initState() {
    super.initState();

    // Main entrance & timeline controller (5.5s total)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    // Subtle logo breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Concentric ripple rings around logo
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Choreographed Animations
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _progressVal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeInOut),
      ),
    );

    _mainController.forward();

    // Update status text along the timeline
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Loading Appliance Simulator...';
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Protection Shield Active ✓';
        });
      }
    });

    // Auto navigate after 5.5 seconds
    Future.delayed(const Duration(milliseconds: 5500), () {
      if (mounted) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Dashboard(
            currentThemeMode: widget.currentThemeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF0D9488),
      body: InkWell(
        onTap: _navigateToDashboard, // Tap anywhere to skip
        child: SafeArea(
          child: Stack(
            children: [
              // Background Gradient Glow
              Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.tealAccent.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Animated Shield Logo with Concentric Pulse Rings
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Ripple Animation
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, child) {
                            return Container(
                              width: 140 + (_rippleController.value * 40),
                              height: 140 + (_rippleController.value * 40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber.withOpacity(
                                    (1.0 - _rippleController.value).clamp(0.0, 1.0),
                                  ),
                                  width: 2.0,
                                ),
                              ),
                            );
                          },
                        ),

                        // Logo Container
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_pulseController.value * 0.05),
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.4),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.asset(
                                    'images/logo2.jpg',
                                    width: 95,
                                    height: 95,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Animated Text
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: Colors.amber,
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BillShield',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.8,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Smart NEPRA Tariff & Unit Predictor',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Progress Bar & Dynamic Loading Message
                    FadeTransition(
                      opacity: _textFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48.0)
                            .copyWith(bottom: 36.0),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _progressVal,
                              builder: (context, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: _progressVal.value,
                                    backgroundColor: Colors.white24,
                                    color: Colors.amber,
                                    minHeight: 5,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _statusMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap anywhere to skip',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
