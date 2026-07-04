import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var userProfile = <String, dynamic>{}.obs;
  final Rxn<User> currentUser = Rxn<User>(Supabase.instance.client.auth.currentUser);
  late final StreamSubscription _authSub;

  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      currentUser.value = data.session?.user;
      if (data.session != null) {
        fetchUserProfile();
      } else {
        userProfile.clear();
      }
    });
    if (isLoggedIn) {
      fetchUserProfile();
    }
  }

  @override
  void onClose() {
    _authSub.cancel();
    super.onClose();
  }

  Future<void> fetchUserProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        userProfile.value = Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('fetchUserProfile error: $e');
    }
  }

  /// Normalizes an Iraqi phone number to a pure digit string.
  /// Accepts formats: 07XX XXX XXXX, 0770XXXXXXX, +964770XXXXXXX, 964770XXXXXXX, 00770XXXXXXX
  /// Returns the normalized number with leading zero preserved (e.g. 07886443032).
  String _normalizePhone(String phone) {
    String cleaned = phone.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
    if (cleaned.startsWith('00')) cleaned = cleaned.substring(2);
    if (cleaned.startsWith('964')) cleaned = '0${cleaned.substring(3)}';
    if (!cleaned.startsWith('0')) cleaned = '0$cleaned';
    return cleaned;
  }

  /// Generates a hidden email from a phone number.
  /// Uses [freshapp.com] which has a valid TLD (unlike [freshapp.local]
  /// which is reserved for multicast DNS per RFC 6762 and gets rejected
  /// by Supabase/GoTrue email validation).
  String _phoneToEmail(String phone) {
    final normalized = _normalizePhone(phone);
    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint('[Auth] Generated email: user_${digitsOnly}@freshapp.com');
    return 'user_${digitsOnly}@freshapp.com';
  }

  bool _validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) {
      _showError('رقم الهاتف غير صحيح', 'يرجى إدخال رقم هاتف عراقي صحيح (11 رقم)');
      return false;
    }
    return true;
  }

  Future<bool> login(String phone, String password) async {
    try {
      isLoading(true);

      final trimmed = phone.trim();
      if (trimmed.isEmpty) {
        _showError('رقم الهاتف مطلوب', 'الرجاء إدخال رقم الهاتف');
        return false;
      }
      if (password.length < 6) {
        _showError('كلمة المرور قصيرة', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
        return false;
      }
      if (!_validatePhone(trimmed)) return false;

      final email = _phoneToEmail(trimmed);
      debugPrint('[Auth] Attempting login with email: $email');

      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await fetchUserProfile();
        Get.snackbar(
          'أهلاً بك!',
          'تم تسجيل الدخول بنجاح',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return true;
      }
      return false;
    } on AuthException catch (e) {
      debugPrint('[Auth] Login AuthException: ${e.message}');
      String msg = e.message;
      if (msg.contains('Invalid login credentials') || msg.contains('invalid_credentials')) {
        msg = 'رقم الهاتف أو كلمة المرور غير صحيحة';
      } else if (msg.contains('User not found')) {
        msg = 'لا يوجد حساب بهذا الرقم، يرجى إنشاء حساب جديد';
      } else if (msg.contains('Email not confirmed')) {
        msg = 'يرجى تأكيد بريدك الإلكتروني أولاً أو تواصل مع الدعم';
      } else if (msg.contains('Email address is invalid') || msg.contains('invalid email')) {
        msg = 'صيغة رقم الهاتف غير صحيحة، يرجى التحقق';
      }
      _showError('خطأ في الدخول', msg);
      return false;
    } catch (e) {
      debugPrint('[Auth] Login unexpected error: $e');
      _showError('خطأ', 'حدث خطأ غير متوقع، تأكد من الاتصال بالإنترنت');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> signUp(String name, String phone, String password) async {
    try {
      isLoading(true);

      final trimmedName = name.trim();
      if (trimmedName.isEmpty || trimmedName.length < 2) {
        _showError('الاسم مطلوب', 'الرجاء إدخال اسمك الكامل (حرفين على الأقل)');
        return false;
      }
      if (phone.trim().isEmpty) {
        _showError('رقم الهاتف مطلوب', 'الرجاء إدخال رقم الهاتف');
        return false;
      }
      if (password.length < 6) {
        _showError('كلمة المرور قصيرة', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
        return false;
      }
      if (!_validatePhone(phone.trim())) return false;

      final normalizedPhone = _normalizePhone(phone);
      final email = _phoneToEmail(normalizedPhone);
      debugPrint('[Auth] Attempting signup with email: $email, phone: $normalizedPhone');

      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name.trim(),
          'phone': normalizedPhone,
          'role': 'customer',
        },
      );

      if (res.user != null) {
        debugPrint('[Auth] Signup success, user ID: ${res.user!.id}');

        try {
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': trimmedName,
            'phone': normalizedPhone,
            'role': 'customer',
          });
          debugPrint('[Auth] Profile upserted successfully');
        } catch (profileErr) {
          debugPrint('[Auth] Profile upsert error: $profileErr');
        }

        if (res.session == null) {
          debugPrint('[Auth] No session returned. Attempting auto-login...');
          bool autoLoggedIn = false;
          for (int attempt = 1; attempt <= 5; attempt++) {
            try {
              await supabase.auth.signInWithPassword(
                email: email,
                password: password,
              );
              debugPrint('[Auth] Auto-login attempt $attempt succeeded');
              autoLoggedIn = true;
              break;
            } catch (e) {
              debugPrint('[Auth] Auto-login attempt $attempt failed: $e');
              if (attempt < 5) {
                await Future.delayed(Duration(milliseconds: 800 * attempt));
              }
            }
          }
          if (!autoLoggedIn) {
            debugPrint('[Auth] All auto-login attempts failed');
          }
        }

        await fetchUserProfile();
        Get.snackbar(
          'مرحباً ${trimmedName.split(' ').first}!',
          'تم إنشاء حسابك بنجاح',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return true;
      }

      debugPrint('[Auth] Signup returned null user');
      Get.snackbar(
        'تحقق من بريدك',
        'تم إرسال رابط تأكيد، أو تواصل مع الدعم لتفعيل حسابك',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.amber.shade700.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } on AuthException catch (e) {
      debugPrint('[Auth] Signup AuthException: ${e.message}');
      String msg = e.message;
      if (msg.contains('already registered') || msg.contains('already been registered')) {
        msg = 'هذا الرقم مسجل بالفعل، يرجى تسجيل الدخول';
      } else if (msg.contains('Password should be')) {
        msg = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      } else if (msg.contains('Email address is invalid') || msg.contains('invalid email')) {
        msg = 'صيغة رقم الهاتف غير صحيحة، يرجى التحقق';
      }
      _showError('خطأ في التسجيل', msg);
      return false;
    } catch (e) {
      debugPrint('[Auth] Signup unexpected error: $e');
      _showError('خطأ', 'حدث خطأ غير متوقع، تأكد من الاتصال بالإنترنت');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('profiles').update(updates).eq('id', userId);
      await fetchUserProfile();
      return true;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحديث البيانات، تأكد من الاتصال بالإنترنت',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      userProfile.clear();
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      debugPrint('Logout error: $e');
      Get.offAll(() => const LoginScreen());
    }
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade600.withOpacity(0.92),
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }
}
