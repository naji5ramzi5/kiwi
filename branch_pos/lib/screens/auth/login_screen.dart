import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Very light emerald
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(LucideIcons.leaf, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 32),
              const Text('تفعيل نسخة الفرع', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('يرجى إدخال رمز التفعيل الخاص بالفرع الممنوح من الإدارة', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 48),
              
              _buildField('رمز التفعيل', LucideIcons.key, emailController, hint: 'مثال: FR-1234'),
              const SizedBox(height: 24),
              // Password field hidden for activation-only mode if requested, but kept for security
              _buildField('كلمة السر (اختياري)', LucideIcons.lock, passwordController, isPass: true, hint: '••••••••'),
              
              const SizedBox(height: 40),
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authController.isLoading.value ? null : () async {
                    // Logic to activate via code
                    final success = await authController.activateWithCode(emailController.text);
                    if (success) {
                      Get.snackbar('تم التفعيل', 'تم ربط هذه النسخة بالفرع بنجاح');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: authController.isLoading.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('دخول للمنظومة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              )),
              
              const SizedBox(height: 32),
              const Text('جميع الحقوق محفوظة لمنظومة "فرش" 2026 ©', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {bool isPass = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass && !showPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppTheme.primary.withOpacity(0.5)),
            suffixIcon: isPass ? IconButton(
              icon: Icon(showPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
              onPressed: () => setState(() => showPassword = !showPassword),
            ) : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
