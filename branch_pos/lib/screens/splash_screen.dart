import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../widgets/window_controls.dart';
import 'auth/login_screen.dart';
import 'main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _waitForInit();
  }

  Future<void> _waitForInit() async {
    // Wait for Supabase + DB to have time to initialize
    await Future.delayed(const Duration(milliseconds: 800));

    // Guaranteed navigation after timeout — even if everything fails
    Future.delayed(const Duration(seconds: 8), () {
      if (!_navigated && mounted) {
        _navigateToMain();
      }
    });

    try {
      _navigateToMain();
    } catch (e) {
      debugPrint('Splash init error: $e');
      // Fallback — navigate anyway after short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!_navigated && mounted) {
          _navigateToMain();
        }
      });
    }
  }

  void _navigateToMain() {
    if (_navigated || !mounted) return;
    _navigated = true;

    try {
      final AuthController authController =
          Get.isRegistered<AuthController>()
              ? Get.find<AuthController>()
              : Get.put(AuthController());

      Get.off(
        () => Obx(() =>
          authController.isLoggedIn.value
              ? const MainLayout()
              : const LoginScreen()
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      // Last resort — just go to login
      Get.off(
        () => const LoginScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const WindowControls(
            showTitle: true,
            title: 'Kiwi Fresh - نظام إدارة الفرع',
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, __, ___) => const Icon(
                      LucideIcons.leaf,
                      size: 80,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kiwi Fresh',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نظام إدارة الفروع',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
