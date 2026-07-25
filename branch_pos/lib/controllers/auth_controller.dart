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

      if (code.trim().isEmpty) {
        if (!silent) {
          Get.snackbar('تنبيه', 'يرجى إدخال رمز التفعيل',
              backgroundColor: Colors.orange, colorText: Colors.white);
        }
        return false;
      }

      final response = await supabase
          .from('branches')
          .select('id, name, access_code')
          .eq('access_code', code.trim());

      if (response != null && response.isNotEmpty) {
        final branch = response.first;
        final branchId = branch['id'] as String;
        final branchName = branch['name'] ?? 'فرع غير معرف';

        final cleanId = branchId.replaceAll('-', '');
        final email = 'branch_${cleanId.substring(0, 10)}@freshapp.com';
        final password = 'FreshPOS_${cleanId.substring(0, 8)}!';

        AuthResponse authRes;
        try {
          authRes = await supabase.auth.signInWithPassword(
              email: email, password: password);
        } catch (_) {
          authRes =
              await supabase.auth.signUp(email: email, password: password);
        }

        if (authRes.user != null) {
          await supabase.from('profiles').upsert({
            'id': authRes.user!.id,
            'role': 'branch_manager',
            'full_name': 'مدير $branchName',
            'branch_id': branchId,
            'phone': '+964770${cleanId.substring(0, 7)}',
          });
        }

        currentBranchId.value = branchId;
        currentBranchName.value = branchName;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_code', code.trim());

        isLoggedIn.value = true;
        return true;
      } else {
        if (!silent) {
          Get.snackbar('تنبيه',
              'رمز التفعيل "$code" غير موجود في النظام. يرجى التأكد من الرمز الصحيح من لوحة التحكم.',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 5));
        }
        return false;
      }
    } on PostgrestException catch (e) {
      String errorMsg;
      if (e.message.contains('relation') && e.message.contains('does not exist')) {
        errorMsg = 'خطأ: جدول الفروع غير موجود في قاعدة البيانات.';
      } else if (e.message.contains('column') && e.message.contains('does not exist')) {
        errorMsg = 'خطأ في هيكل قاعدة البيانات. يرجى التحقق من وجود عمود "access_code" في جدول branches.';
      } else {
        errorMsg = 'خطأ في قاعدة البيانات: ${e.message}';
      }

      if (!silent) {
        Get.snackbar('خطأ', errorMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 8));
      }
      return false;
    } catch (e) {
      String errorMsg = e.toString();

      if (errorMsg.contains('SocketException') || errorMsg.contains('Connection')) {
        errorMsg = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';
      } else if (errorMsg.contains('timeout')) {
        errorMsg = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';
      } else if (errorMsg.contains('API key')) {
        errorMsg = 'خطأ في مفتاح API. يرجى التحقق من إعدادات الاتصال.';
      }

      if (!silent) {
        Get.snackbar('خطأ في الاتصال', errorMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 8));
      }
      return false;
    } finally {
      if (!silent) isLoading(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_code');
    try {
      await supabase.auth.signOut();
    } catch (_) {}
    isLoggedIn.value = false;
    currentBranchId.value = '';
    currentBranchName.value = '';
  }
}
