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
      _showError('invalid_phone_title'.tr, 'invalid_phone_msg'.tr);
      return false;
    }
    return true;
  }

  Future<bool> login(String phone, String password) async {
    try {
      isLoading(true);

      final trimmed = phone.trim();
      if (trimmed.isEmpty) {
        _showError('phone_required'.tr, 'please_enter_phone'.tr);
        return false;
      }
      if (password.length < 6) {
        _showError('password_short'.tr, 'password_too_short'.tr);
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
          'welcome'.tr,
          'login_success'.tr,
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
        msg = 'invalid_credentials'.tr;
      } else if (msg.contains('User not found')) {
        msg = 'no_account_found'.tr;
      } else if (msg.contains('Email not confirmed')) {
        msg = 'email_not_confirmed'.tr;
      } else if (msg.contains('Email address is invalid') || msg.contains('invalid email')) {
        msg = 'invalid_phone_format'.tr;
      }
      _showError('login_error'.tr, msg);
      return false;
    } catch (e) {
      debugPrint('[Auth] Login unexpected error: $e');
      _showError('error'.tr, 'unexpected_error'.tr);
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
        _showError('name_required'.tr, 'name_too_short'.tr);
        return false;
      }
      if (phone.trim().isEmpty) {
        _showError('phone_required'.tr, 'please_enter_phone'.tr);
        return false;
      }
      if (password.length < 6) {
        _showError('password_short'.tr, 'password_too_short'.tr);
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
          'hello_user'.trParams({'name': trimmedName.split(' ').first}),
          'account_created'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return true;
      }

      debugPrint('[Auth] Signup returned null user');
      Get.snackbar(
        'check_email'.tr,
        'verification_sent'.tr,
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
        msg = 'phone_already_registered'.tr;
      } else if (msg.contains('Password should be')) {
        msg = 'password_too_short'.tr;
      } else if (msg.contains('Email address is invalid') || msg.contains('invalid email')) {
        msg = 'invalid_phone_format'.tr;
      }
      _showError('signup_error'.tr, msg);
      return false;
    } catch (e) {
      debugPrint('[Auth] Signup unexpected error: $e');
      _showError('error'.tr, 'unexpected_error'.tr);
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
      Get.snackbar('error'.tr, 'profile_update_error'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      debugPrint('[Auth] Reset password AuthException: ${e.message}');
      _showError('error'.tr, e.message);
      rethrow;
    } catch (e) {
      debugPrint('[Auth] Reset password error: $e');
      _showError('error'.tr, 'unexpected_error'.tr);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    await supabase.auth.signOut();
    userProfile.clear();
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
