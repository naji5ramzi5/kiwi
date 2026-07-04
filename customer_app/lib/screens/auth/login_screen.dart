import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';
import 'signup_screen.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(LucideIcons.arrowRight, color: themeTextColor),
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Image.asset(
                          'assets/images/kwi.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'login'.tr,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'مرحباً بك مجدداً في Kiwi',
                style: TextStyle(fontSize: 14, color: themeTextSecColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              _buildTextField(
                context,
                label: 'phone'.tr,
                hint: '07X XXXX XXXX',
                icon: LucideIcons.phone,
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                context,
                label: 'password'.tr,
                hint: '••••••••',
                icon: LucideIcons.lock,
                controller: passwordController,
                isPassword: true,
              ),
              
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Obx(() => ElevatedButton(
                onPressed: authController.isLoading.value ? null : () async {
                  final success = await authController.login(
                    phoneController.text,
                    passwordController.text,
                  );
                  if (success) {
                    Get.offAll(() => const MainScreen());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                ),
                child: authController.isLoading.value 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'login'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              )),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ليس لديك حساب؟ ', style: TextStyle(color: themeTextSecColor)),
                  GestureDetector(
                    onTap: () => Get.to(() => const SignupScreen()),
                    child: const Text('إنشاء حساب', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label, 
    required String hint, 
    required IconData icon, 
    required TextEditingController controller,
    bool isPassword = false, 
    TextInputType? keyboardType
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: themeTextColor),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: TextStyle(color: themeTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: themeTextSecColor.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: themeTextSecColor, size: 20),
            filled: true,
            fillColor: isDark ? AppTheme.surfaceDark : AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
