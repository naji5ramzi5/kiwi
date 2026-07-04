import os
p = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\controllers\favorites_controller.dart'
content = """import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_controller.dart';

class FavoritesController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  
  var favoriteProductIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (authController.isLoggedIn) {
      loadFavorites();
    }
    
    // Listen to login changes
    ever(authController.rxIsLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        loadFavorites();
      } else {
        favoriteProductIds.clear();
      }
    });
  }

  Future<void> loadFavorites() async {
    try {
      if (!authController.isLoggedIn) return;
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('favorites').select('product_id').eq('customer_id', userId);
      final Set<String> ids = {};
      for (var row in data) {
        if (row['product_id'] != null) {
          ids.add(row['product_id'].toString());
        }
      }
      favoriteProductIds.value = ids;
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  Future<void> toggleFavorite(String productId) async {
    if (!authController.isLoggedIn) {
      Get.snackbar('تنبيه', 'يجب تسجيل الدخول لإضافة المنتجات إلى المفضلة');
      return;
    }
    final userId = supabase.auth.currentUser!.id;
    final isFav = favoriteProductIds.contains(productId);

    try {
      if (isFav) {
        // Remove
        favoriteProductIds.remove(productId);
        await supabase.from('favorites').delete().eq('customer_id', userId).eq('product_id', productId);
      } else {
        // Add
        favoriteProductIds.add(productId);
        await supabase.from('favorites').insert({
          'customer_id': userId,
          'product_id': productId,
        });
      }
    } catch (e) {
      print("Error toggling favorite: $e");
      // Rollback
      if (isFav) {
        favoriteProductIds.add(productId);
      } else {
        favoriteProductIds.remove(productId);
      }
    }
  }

  bool isFavorite(String productId) {
    return favoriteProductIds.contains(productId);
  }
}
"""
open(p, 'w', encoding='utf-8').write(content)
