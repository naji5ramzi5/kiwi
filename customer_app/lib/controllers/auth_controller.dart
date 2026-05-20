import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;
  
  var isLoading = false.obs;
  var userProfile = <String, dynamic>{}.obs;
  
  bool get isLoggedIn => supabase.auth.currentUser != null;

  @override
  void onInit() {
    super.onInit();
    if (isLoggedIn) {
      fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      userProfile.value = data;
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<bool> login(String phone, String password) async {
    try {
      isLoading(true);
      
      // Supabase usually uses email. We can sign in with phone if configured.
      // For now, we will try to find the user in profiles and sign in.
      // If the user wants phone+password, they might be using email in the background 
      // or we use a custom login function. 
      // Let's assume standard email/password for now or phone if enabled.
      
      final AuthResponse res = await supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );
      
      if (res.user != null) {
        await fetchUserProfile();
        // Go back to the screen that requested login (usually Cart)
        Get.back(result: true);
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('خطأ في الدخول', e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> signUp(String name, String phone, String password) async {
    try {
      isLoading(true);
      
      final AuthResponse res = await supabase.auth.signUp(
        phone: phone,
        password: password,
        data: {'full_name': name},
      );

      if (res.user != null) {
        // The profile might be created by a DB trigger, but let's make sure
        await supabase.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': name,
          'phone': phone,
          'role': 'customer',
        });
        
        await fetchUserProfile();
        Get.back(result: true);
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('خطأ في التسجيل', e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    userProfile.clear();
    Get.offAllNamed('/login'); // Assuming login route exists
  }
}
