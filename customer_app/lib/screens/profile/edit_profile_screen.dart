import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final AuthController authController = Get.find<AuthController>();

  int nameChangesLeft = 2;
  bool phoneCanChange = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = authController.userProfile();
    _nameController = TextEditingController(text: profile['full_name']?.toString() ?? '');
    _phoneController = TextEditingController(text: profile['phone']?.toString() ?? '');

    nameChangesLeft = 2 - (profile['name_change_count'] as int? ?? 0);
    phoneCanChange = !(profile['phone_changed'] as bool? ?? false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('تنبيه', 'الاسم لا يمكن أن يكون فارغاً',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (name.length < 2) {
      Get.snackbar('تنبيه', 'الاسم يجب أن يكون حرفين على الأقل',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (phone.isEmpty) {
      Get.snackbar('تنبيه', 'رقم الهاتف لا يمكن أن يكون فارغاً',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    final oldProfile = authController.userProfile();
    final oldName = oldProfile['full_name']?.toString() ?? '';
    final oldPhone = oldProfile['phone']?.toString() ?? '';

    if (name == oldName && phone == oldPhone) {
      Get.snackbar('تنبيه', 'لم يتم تغيير أي بيانات',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSaving = true);

    final updates = <String, dynamic>{};

    if (name != oldName) {
      if (nameChangesLeft <= 0) {
        Get.snackbar('ممنوع', 'لقد استنفذت عدد مرات تغيير الاسم المسموح بها',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        setState(() => _isSaving = false);
        return;
      }
      updates['full_name'] = name;
      updates['name_change_count'] = (oldProfile['name_change_count'] as int? ?? 0) + 1;
    }

    if (phone != oldPhone) {
      if (!phoneCanChange) {
        Get.snackbar('ممنوع', 'لا يمكن تغيير رقم الهاتف بعد الآن',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        setState(() => _isSaving = false);
        return;
      }
      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 10 || digits.length > 15) {
        Get.snackbar('خطأ', 'رقم الهاتف غير صحيح، يرجى إدخال رقم عراقي صحيح',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        setState(() => _isSaving = false);
        return;
      }
      updates['phone'] = phone;
      updates['phone_changed'] = true;
    }

    if (updates.isEmpty) {
      setState(() => _isSaving = false);
      return;
    }

    final success = await authController.updateProfile(updates);
    setState(() => _isSaving = false);

    if (success) {
      Get.snackbar('تم', 'تم تحديث البيانات بنجاح',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      setState(() {
        nameChangesLeft = 2 - ((updates['name_change_count'] as int? ?? 0));
        phoneCanChange = !(updates['phone_changed'] as bool? ?? false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final surfaceColor = isDark ? AppTheme.surfaceDark : Colors.white;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('تعديل الحساب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Cairo')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('الاسم الكامل', textSecColor),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 15),
                    decoration: _inputDecoration(
                      hint: 'أدخل اسمك الكامل',
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nameChangesLeft > 0
                        ? 'يمكنك تغيير الاسم $nameChangesLeft مرات أخرى'
                        : 'لا يمكن تغيير الاسم بعد الآن',
                    style: TextStyle(
                      fontSize: 11,
                      color: nameChangesLeft > 0 ? AppTheme.primary : Colors.red.shade400,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('رقم الهاتف', textSecColor),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 15),
                    decoration: _inputDecoration(
                      hint: 'أدخل رقم الهاتف',
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phoneCanChange
                        ? 'يمكنك تغيير رقم الهاتف مرة واحدة فقط'
                        : 'لا يمكن تغيير رقم الهاتف بعد الآن',
                    style: TextStyle(
                      fontSize: 11,
                      color: phoneCanChange ? AppTheme.primary : Colors.red.shade400,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'حفظ التغييرات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textSecColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: textSecColor,
        fontFamily: 'Cairo',
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required bool isDark, required Color surfaceColor}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Cairo', fontSize: 13),
      filled: true,
      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
