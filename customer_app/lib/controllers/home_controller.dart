import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeController extends GetxController {
  final supabase = Supabase.instance.client;

  var products = <Map<String, dynamic>>[].obs;
  var branches = <Map<String, dynamic>>[].obs;
  var selectedBranch = Rxn<Map<String, dynamic>>();
  var banners = <Map<String, dynamic>>[].obs;
  var storyGroups = <Map<String, dynamic>>[].obs;
  var categories = <String>[].obs;
  
  var isLoadingProducts = true.obs;
  var isLoadingBranches = true.obs;
  var isLoadingBanners = true.obs;
  var isLoadingStories = true.obs;
  var isLocating = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBanners();
    fetchStoryGroups();
    initializeHome();
  }

  Future<void> initializeHome() async {
    await findBestBranchByLocation();
    await fetchProducts();
  }

  Future<void> findBestBranchByLocation() async {
    try {
      isLocating(true);
      isLoadingBranches(true);

      // 1. Request Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // 2. Get Coordinates
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        
        // 3. Call Smart Selection RPC (find_best_branch_v2)
        final List<dynamic> response = await supabase.rpc('find_best_branch_v2', params: {
          'customer_lat': position.latitude,
          'customer_lng': position.longitude,
        });

        if (response.isNotEmpty) {
          final bestBranchId = response[0]['id'];
          
          // Fetch full branch details
          final branchData = await supabase.from('branches').select().eq('id', bestBranchId).single();
          selectedBranch.value = branchData;
          
          // Fetch other active branches for the manual selector if needed
          final allBranches = await supabase.from('branches').select().eq('status', 'نشط');
          branches.value = List<Map<String, dynamic>>.from(allBranches);
        } else {
          Get.snackbar('تنبيه', 'التوصيل غير متاح في موقعك حالياً', snackPosition: SnackPosition.BOTTOM);
          // Fallback to all branches
          await fetchAllBranches();
        }
      } else {
        await fetchAllBranches();
      }
    } catch (e) {
      print('Error in smart selection: $e');
      await fetchAllBranches();
    } finally {
      isLocating(false);
      isLoadingBranches(false);
    }
  }

  Future<void> fetchAllBranches() async {
    try {
      final response = await supabase.from('branches').select().eq('status', 'نشط');
      branches.value = List<Map<String, dynamic>>.from(response);
      if (branches.isNotEmpty && selectedBranch.value == null) {
        selectedBranch.value = branches.first;
      }
    } catch (e) {
      print('Error fetching branches: $e');
    }
  }

  Future<void> fetchBanners() async {
    try {
      isLoadingBanners(true);
      final response = await supabase
          .from('banners')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      banners.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching banners: $e');
    } finally {
      isLoadingBanners(false);
    }
  }

  Future<void> fetchStoryGroups() async {
    try {
      isLoadingStories(true);
      final response = await supabase
          .from('story_groups')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      storyGroups.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching stories: $e');
    } finally {
      isLoadingStories(false);
    }
  }

  Future<void> fetchProducts() async {
    if (selectedBranch.value == null) return;
    
    try {
      isLoadingProducts(true);
      final response = await supabase
          .from('products')
          .select('*, branch_inventory!inner(actual_stock, branch_id)')
          .eq('branch_inventory.branch_id', selectedBranch.value!['id'])
          .gt('branch_inventory.actual_stock', 0); // Only show in-stock products
      
      products.value = List<Map<String, dynamic>>.from(response);
      
      final Set<String> uniqueCategories = {};
      for (var product in products) {
        if (product['category'] != null) {
          uniqueCategories.add(product['category']);
        }
      }
      categories.value = uniqueCategories.toList();
      
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      isLoadingProducts(false);
    }
  }

  void changeBranch(Map<String, dynamic> branch) {
    selectedBranch.value = branch;
    fetchProducts();
  }
}
