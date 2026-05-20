import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var currentBranchId = ''.obs;
  var currentBranchName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkActivation();
  }

  Future<void> checkActivation() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('access_code');
    if (code != null) {
      await activateWithCode(code, silent: true);
    }
  }

  Future<bool> activateWithCode(String code, {bool silent = false}) async {
    try {
      if (!silent) isLoading(true);
      
      // Attempting to select by access_code
      final response = await supabase
          .from('branches')
          .select()
          .eq('access_code', code);

      if (response != null && response.isNotEmpty) {
        final branch = response.first;
        currentBranchId.value = branch['id'];
        currentBranchName.value = branch['name'];
        
        // Save code for future runs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_code', code);
        
        isLoggedIn.value = true;
        return true;
      } else {
        if (!silent) Get.snackbar('تنبيه', 'رمز التفعيل هذا غير موجود في النظام. يرجى التأكد من الرمز الصحيح من لوحة التحكم.', 
          backgroundColor: Colors.orange, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      String errorMsg = e.toString();
      
      if (errorMsg.contains('access_code')) {
        errorMsg = "خطأ في قاعدة البيانات: لم يتم العثور على عمود الرمز. \nحل المشكلة: يرجى تشغيل كود SQL في لوحة تحكم Supabase لتحديث المخطط.";
      }

      if (!silent) Get.snackbar('خطأ في الاتصال', errorMsg, 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 15),
        mainButton: TextButton(
          onPressed: () => Get.back(),
          child: const Text('فهمت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      );
      return false;
    } finally {
      if (!silent) isLoading(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_code');
    isLoggedIn.value = false;
  }
}
