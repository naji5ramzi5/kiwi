import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:convert';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;

class HomeController extends GetxController {
  final supabase = Supabase.instance.client;

  var products = <Map<String, dynamic>>[].obs;
  var allProducts = <Map<String, dynamic>>[].obs;
  var branches = <Map<String, dynamic>>[].obs;
  var selectedBranch = Rxn<Map<String, dynamic>>();
  var banners = <Map<String, dynamic>>[].obs;
  var storyGroups = <Map<String, dynamic>>[].obs;
  var categories = <Map<String, dynamic>>[].obs;
  
  var isLoadingProducts = true.obs;
  var isLoadingBranches = true.obs;
  var isLoadingBanners = true.obs;
  var isLoadingStories = true.obs;
  var isLoadingCategories = true.obs;
  var isLocating = false.obs;

  var searchQuery = ''.obs;
  var userAddress = ''.obs;
  var isInDeliveryZone = true.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => filterProducts(), time: const Duration(milliseconds: 300));

    fetchBanners();
    fetchStoryGroups();
    fetchCategories();
    initializeHome();
  }

  void filterProducts() {
    if (searchQuery.value.trim().isEmpty) {
      products.value = List<Map<String, dynamic>>.from(allProducts);
    } else {
      final query = searchQuery.value.trim().toLowerCase();
      products.value = allProducts.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final category = (p['category'] ?? '').toString().toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    }
  }

  Future<void> initializeHome() async {
    await findBestBranchByLocation();
    await fetchProducts();
  }

  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=ar'));
      request.headers.set(HttpHeaders.userAgentHeader, 'KiwiApp/1.0');
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final json = jsonDecode(content);
        final address = json['address'];
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['governorate'] ?? 'بغداد';
          if (road.isNotEmpty) {
            return '$city، $road';
          }
          return city;
        }
      }
    } catch (e) {
      print('Reverse geocode error: $e');
    }
    return '';
  }

  Future<void> findBestBranchByLocation() async {
    try {
      isLocating(true);
      isLoadingBranches(true);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        
        final resolvedAddr = await reverseGeocode(position.latitude, position.longitude);
        if (resolvedAddr.isNotEmpty) {
          userAddress.value = resolvedAddr;
        }

        // Fetch active delivery zones
        final zones = await supabase.from('delivery_zones').select().eq('is_active', true);
        
        String? matchedBranchId;
        
        // Check Point-in-Polygon
        if (zones.isNotEmpty) {
          final userLatLng = mt.LatLng(position.latitude, position.longitude);
          for (var zone in zones) {
            final geojson = zone['geojson'];
            if (geojson != null && geojson['geometry'] != null) {
              final coords = geojson['geometry']['coordinates'];
              if (coords != null && coords.isNotEmpty) {
                // Leaflet-draw polygon coords are usually [[[lng, lat], [lng, lat], ...]]
                List<mt.LatLng> polygon = [];
                try {
                  for (var point in coords[0]) {
                    // standard GeoJSON is [lng, lat]
                    double lng = point[0].toDouble();
                    double lat = point[1].toDouble();
                    polygon.add(mt.LatLng(lat, lng));
                  }
                  if (mt.PolygonUtil.containsLocation(userLatLng, polygon, false)) {
                    matchedBranchId = zone['branch_id'];
                    break; // found the zone
                  }
                  } catch (e) {
                    print('Error parsing polygon coords: $e');
                  }
              }
            }
          }
        }

        final allBranches = await supabase.from('branches').select().eq('status', 'نشط');
        branches.value = List<Map<String, dynamic>>.from(allBranches);

        if (matchedBranchId != null) {
           final matched = branches.firstWhereOrNull((b) => b['id'] == matchedBranchId);
           if (matched != null) {
             selectedBranch.value = matched;
             isInDeliveryZone.value = true;
           }
        } else {
           isInDeliveryZone.value = false;
           // Default to first branch if out of zone
           if (branches.isNotEmpty) selectedBranch.value = branches.first;
        }
      } else {
        await fetchAllBranches();
      }
    } catch (e) {
      print('Error in smart selection: $e');
      await fetchAllBranches();
    }
  }

  Future<void> updateUserLocation(double lat, double lng, String address) async {
    try {
      isLocating(true);
      isLoadingBranches(true);

      userAddress.value = address;

      // Fetch active delivery zones
      final zones = await supabase.from('delivery_zones').select().eq('is_active', true);
      
      String? matchedBranchId;
      
      // Check Point-in-Polygon
      if (zones.isNotEmpty) {
        final userLatLng = mt.LatLng(lat, lng);
        for (var zone in zones) {
          final geojson = zone['geojson'];
          if (geojson != null && geojson['geometry'] != null) {
            final coords = geojson['geometry']['coordinates'];
            if (coords != null && coords.isNotEmpty) {
              List<mt.LatLng> polygon = [];
              try {
                for (var point in coords[0]) {
                  double lon = point[0].toDouble();
                  double l = point[1].toDouble();
                  polygon.add(mt.LatLng(l, lon));
                }
                if (mt.PolygonUtil.containsLocation(userLatLng, polygon, false)) {
                  matchedBranchId = zone['branch_id'];
                  break; // found the zone
                }
              } catch (e) {
                print('Error parsing polygon coords: $e');
              }
            }
          }
        }
      }

      final allBranches = await supabase.from('branches').select().eq('status', 'نشط');
      branches.value = List<Map<String, dynamic>>.from(allBranches);

      if (matchedBranchId != null) {
         final matched = branches.firstWhereOrNull((b) => b['id'] == matchedBranchId);
         if (matched != null) {
           selectedBranch.value = matched;
           isInDeliveryZone.value = true;
         }
      } else {
         isInDeliveryZone.value = false;
         // Default to first branch if out of zone
         if (branches.isNotEmpty) selectedBranch.value = branches.first;
      }
      
      // Fetch products for the new branch
      await fetchProducts();

    } catch (e) {
      print('Error updating manual location: $e');
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
          .order('created_at', ascending: false);
      if (response.isNotEmpty) {
        banners.value = List<Map<String, dynamic>>.from(response);
      } else {
        banners.value = [];
      }
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
          .order('created_at', ascending: false);
      if (response.isNotEmpty) {
        storyGroups.value = List<Map<String, dynamic>>.from(response);
      } else {
        storyGroups.value = [];
      }
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
          .eq('branch_inventory.branch_id', selectedBranch.value!['id']);
      
      if (response.isNotEmpty) {
        allProducts.value = List<Map<String, dynamic>>.from(response);
        filterProducts();
      } else {
        allProducts.value = [];
        products.value = [];
      }
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

  Future<void> fetchCategories() async {
    try {
      final response = await supabase
          .from('categories')
          .select()
          .order('name', ascending: true);
      if (response.isNotEmpty) {
        categories.value = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }
}
