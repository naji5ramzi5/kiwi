import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';
import '../../controllers/auth_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: themeTextColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
               Center(
                 child: Container(
                   width: 100,
                   height: 100,
                   decoration: BoxDecoration(
                     boxShadow: [
                       BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
                     ],
                   ),
                   child: ClipOval(
                     child: Container(
                       color: Colors.white,
                       child: Padding(
                         padding: const EdgeInsets.all(18),
                         child: Image.asset(
                           'assets/images/kwi.png',
                           fit: BoxFit.contain,
                         ),
                       ),
                     ),
                   ),
                 ),
               ),
              const SizedBox(height: 20),
              Text(
                'signup'.tr,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'أنشئ حسابك الآن وابدأ التسوق',
                style: TextStyle(fontSize: 14, color: themeTextSecColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              _buildTextField(
                context,
                label: 'name'.tr,
                hint: 'أحمد محمود',
                icon: LucideIcons.user,
                controller: nameController,
              ),
              const SizedBox(height: 20),

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
              
              const SizedBox(height: 32),
              
              Obx(() => ElevatedButton(
                onPressed: authController.isLoading.value ? null : () async {
                  final success = await authController.signUp(
                    nameController.text,
                    phoneController.text,
                    passwordController.text,
                  );
                  if (success) {
                    if (Get.previousRoute.isNotEmpty && Get.previousRoute != '/signup') {
                      Get.back();
                    } else {
                      Get.offAll(() => const MainScreen());
                    }
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
                      'signup'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              )),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('لديك حساب بالفعل؟ ', style: TextStyle(color: themeTextSecColor)),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text('تسجيل الدخول', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
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
