import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../controllers/auth_controller.dart';
import 'main_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _textController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startAnimations();
  }

  void _startAnimations() async {
    final box = GetStorage();
    final seen = box.read('splash_seen') ?? false;
    if (seen) {
      _navigateToNext();
      return;
    }
    _glowController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    box.write('splash_seen', true);
    _navigateToNext();
  }

  void _navigateToNext() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    final auth = Get.find<AuthController>();
    auth.fetchUserProfile();
    if (auth.isLoggedIn) {
      Get.offAll(() => const MainScreen(), transition: Transition.fadeIn);
    } else {
      Get.offAll(() => const LoginScreen(), transition: Transition.fadeIn);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF22C55E),
              Color(0xFF4ADE80),
              Color(0xFF86EFAC),
              Color(0xFFBBF7D0),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated grid pattern background
            CustomPaint(
              size: size,
              painter: _GridPainter(animation: _glowAnimation.value),
            ),

            // Animated glow behind logo
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 280 * _glowAnimation.value,
                  height: 280 * _glowAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.18 * _glowAnimation.value),
                        Colors.white.withOpacity(0.06 * _glowAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Floating particles with more variety
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Stack(
                  children: [
                    ...List.generate(8, (i) {
                      final angle = (i / 8) * 2 * math.pi;
                      final phase = _particleController.value * 2 * math.pi + i * 0.8;
                      final dist = 100 + 40 * math.sin(phase);
                      return Positioned(
                        left: size.width / 2 + dist * math.cos(angle) - 3,
                        top: size.height / 2 - 140 + dist * math.sin(angle) - 3,
                        child: Opacity(
                          opacity: 0.15 + 0.2 * math.sin(phase),
                          child: Container(
                            width: i % 2 == 0 ? 6 : 4,
                            height: i % 2 == 0 ? 6 : 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),

            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glassmorphic logo container
                AnimatedBuilder(
                  animation: Listenable.merge([_scaleAnimation, _logoFadeAnimation]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoFadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.05),
                                blurRadius: 60,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  'assets/images/kwi.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_grocery_store_rounded,
                                        size: 70,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Brand name with enhanced shadow
                AnimatedBuilder(
                  animation: _logoFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoFadeAnimation.value,
                      child: child,
                    );
                  },
                  child: const Text(
                    'Kiwi',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 5,
                      fontFamily: 'Cairo',
                      shadows: [
                        Shadow(
                          color: Color(0x60000000),
                          blurRadius: 25,
                          offset: Offset(0, 5),
                        ),
                        Shadow(
                          color: Color(0x3034D399),
                          blurRadius: 40,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                AnimatedBuilder(
                  animation: _logoFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: (_logoFadeAnimation.value * 0.7).clamp(0.0, 1.0),
                      child: child,
                    );
                  },
                  child: Text(
                    'توصيل الطلبات الطازجة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 1.5,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Arabic tagline with enhanced glassmorphism
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: SlideTransition(
                    position: _textSlideAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded, size: 18, color: Colors.amber.shade300),
                          const SizedBox(width: 8),
                          const Text(
                            'نوصلها لك بأسرع وقت',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Loading dots
            Positioned(
              bottom: 60,
              child: AnimatedBuilder(
                animation: _textFadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFadeAnimation.value,
                    child: child,
                  );
                },
                child: const _LoadingDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final progress = (((_controller.value - delay) % 1.0 + 1.0) % 1.0);
            final scale = 0.5 + (math.sin(progress * math.pi) * 0.5);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double animation;

  _GridPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025 + 0.015 * animation)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final diagPaint = Paint()
      ..color = Colors.white.withOpacity(0.015 + 0.01 * animation)
      ..strokeWidth = 0.3;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), diagPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), diagPaint);
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.animation != animation;
}
