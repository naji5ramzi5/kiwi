import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
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
                'welcome_back'.tr,
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
                  onPressed: () async {
                    final email = phoneController.text.trim();
                    if (email.isEmpty) {
                      Get.snackbar(
                        'forgot_password'.tr,
                        'enter_phone_reset'.tr,
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                      );
                      return;
                    }
                    try {
                      await authController.resetPassword(email);
                      Get.snackbar(
                        'sent'.tr,
                        'reset_link_sent'.tr,
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                      );
                    } catch (_) {
                      // Error snackbar is shown by the controller
                    }
                  },
                  child: Text('forgot_password_q'.tr, style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
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
                  Text('no_account'.tr, style: TextStyle(color: themeTextSecColor)),
                  GestureDetector(
                    onTap: () => Get.to(() => const SignupScreen()),
                    child: Text('create_account'.tr, style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
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
