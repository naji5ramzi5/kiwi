import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:convert';
import '../utils/turf_helper.dart';

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
  var userLat = 0.0.obs;
  var userLng = 0.0.obs;
  var isInDeliveryZone = true.obs;

  // Delivery zone config for the selected branch
  var deliveryFee = 2500.0.obs;
  var minOrderAmount = 0.0.obs;
  var isLoadingDeliveryZone = false.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(
      searchQuery,
      (_) => filterProducts(),
      time: const Duration(milliseconds: 300),
    );

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

  Future<void> refreshAll() async {
    await Future.wait([
      fetchProducts(),
      fetchBanners(),
      fetchStoryGroups(),
      fetchCategories(),
    ]);
  }

  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=ar',
        ),
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'KiwiApp/1.0');
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final json = jsonDecode(content);
        final address = json['address'];
        if (address != null) {
          final street = address['road'] ?? address['pedestrian'] ?? '';
          final area = address['suburb'] ?? address['neighbourhood'] ?? address['subdivision'] ?? address['quarter'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? '';
          final governorate = address['state'] ?? address['governorate'] ?? address['region'] ?? '';
          final streetStr = street.toString();
          final areaStr = area.toString();
          final cityStr = city.toString();
          final governorateStr = governorate.toString();
          final parts = <String>[];
          if (streetStr.isNotEmpty) parts.add(streetStr);
          if (areaStr.isNotEmpty && areaStr != streetStr) parts.add(areaStr);
          if (cityStr.isNotEmpty && cityStr != areaStr) parts.add(cityStr);
          if (governorateStr.isNotEmpty && governorateStr != cityStr) parts.add(governorateStr);
          final fullAddress = parts.isNotEmpty ? parts.join('، ') : (json['display_name']?.toString() ?? '');
          return {
            'street': streetStr,
            'area': areaStr,
            'city': cityStr,
            'governorate': governorateStr,
            'fullAddress': fullAddress,
          };
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return {'street': '', 'area': '', 'city': '', 'governorate': '', 'fullAddress': ''};
  }

  Future<void> findBestBranchByLocation() async {
    try {
      isLocating(true);
      isLoadingBranches(true);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final resolvedAddr = await reverseGeocode(
          position.latitude,
          position.longitude,
        );
        if (resolvedAddr['fullAddress']!.isNotEmpty) {
          userAddress.value = resolvedAddr['fullAddress']!;
          userLat.value = position.latitude;
          userLng.value = position.longitude;
        }

        // Fetch active delivery zones
        final zones = await supabase
            .from('delivery_zones')
            .select()
            .eq('is_active', true);

        String? matchedBranchId;

        // Check Point-in-Polygon
        if (zones.isNotEmpty) {
          final userPoint = [position.longitude.toDouble(), position.latitude.toDouble()];
          for (var zone in zones) {
            final geojson = zone['geojson'];
            if (geojson == null) continue;
            try {
              final polygons = _parseDeliveryZoneGeojson(geojson as Map<String, dynamic>);
              if (polygons != null && TurfHelper.pointInAnyPolygon(userPoint, polygons)) {
                matchedBranchId = zone['branch_id'];
                break;
              }
            } catch (e) {
              debugPrint('Error parsing polygon coords: $e');
            }
          }
        }

        final allBranches = await supabase
            .from('branches')
            .select()
            .eq('status', 'نشط');
        branches.value = List<Map<String, dynamic>>.from(allBranches);

        if (matchedBranchId != null) {
          final matched = branches.firstWhereOrNull(
            (b) => b['id'] == matchedBranchId,
          );
          if (matched != null) {
            selectedBranch.value = matched;
            isInDeliveryZone.value = true;
            fetchDeliveryZone();
          }
        } else {
          isInDeliveryZone.value = false;
          // Default to first branch if out of zone
          if (branches.isNotEmpty) {
            selectedBranch.value = branches.first;
            fetchDeliveryZone();
          }
        }
      } else {
        await fetchAllBranches();
        fetchDeliveryZone();
      }
    } catch (e) {
      debugPrint('Error in smart selection: $e');
      await fetchAllBranches();
    } finally {
      isLocating(false);
      isLoadingBranches(false);
    }
  }

  Future<void> updateUserLocation(
    double lat,
    double lng,
    String address,
  ) async {
    try {
      isLocating(true);
      isLoadingBranches(true);

      userAddress.value = address;
      userLat.value = lat;
      userLng.value = lng;

      // Fetch active delivery zones
      final zones = await supabase
          .from('delivery_zones')
          .select()
          .eq('is_active', true);

      String? matchedBranchId;

      // Check Point-in-Polygon
      if (zones.isNotEmpty) {
        final userPoint = [lng, lat];
        for (var zone in zones) {
          final geojson = zone['geojson'];
          if (geojson == null) continue;
          try {
            final polygons = _parseDeliveryZoneGeojson(geojson as Map<String, dynamic>);
            if (polygons != null && TurfHelper.pointInAnyPolygon(userPoint, polygons)) {
              matchedBranchId = zone['branch_id'];
              break;
            }
          } catch (e) {
            debugPrint('Error parsing polygon coords: $e');
          }
        }
      }

      final allBranches = await supabase
          .from('branches')
          .select()
          .eq('status', 'نشط');
      branches.value = List<Map<String, dynamic>>.from(allBranches);

      if (matchedBranchId != null) {
        final matched = branches.firstWhereOrNull(
          (b) => b['id'] == matchedBranchId,
        );
          if (matched != null) {
            selectedBranch.value = matched;
            isInDeliveryZone.value = true;
            fetchDeliveryZone();
          }
        } else {
          isInDeliveryZone.value = false;
          // Default to first branch if out of zone
          if (branches.isNotEmpty) {
            selectedBranch.value = branches.first;
            fetchDeliveryZone();
          }
        }

        // Fetch products for the new branch
        await fetchProducts();
    } catch (e) {
      debugPrint('Error updating manual location: $e');
    } finally {
      isLocating(false);
      isLoadingBranches(false);
    }
  }

  Future<void> fetchAllBranches() async {
    try {
      final response = await supabase
          .from('branches')
          .select()
          .eq('status', 'نشط');
      branches.value = List<Map<String, dynamic>>.from(response);
      if (branches.isNotEmpty && selectedBranch.value == null) {
        selectedBranch.value = branches.first;
      }
    } catch (e) {
      debugPrint('Error fetching branches: $e');
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
      debugPrint('Error fetching banners: $e');
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
      debugPrint('Error fetching stories: $e');
    } finally {
      isLoadingStories(false);
    }
  }

  Future<void> fetchProducts() async {
    if (selectedBranch.value == null) {
      isLoadingProducts(false);
      return;
    }

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
      debugPrint('Error fetching products: $e');
    } finally {
      isLoadingProducts(false);
    }
  }

  void changeBranch(Map<String, dynamic> branch) {
    selectedBranch.value = branch;
    fetchProducts();
    fetchDeliveryZone();
  }

  /// Fetches the active delivery zone for the currently selected branch and
  /// exposes [deliveryFee] and [minOrderAmount]. Falls back to defaults if no
  /// matching zone is found.
  Future<void> fetchDeliveryZone() async {
    final branchId = selectedBranch.value?['id'];
    if (branchId == null) return;
    try {
      isLoadingDeliveryZone(true);
      final response = await supabase
          .from('delivery_zones')
          .select()
          .eq('branch_id', branchId)
          .eq('is_active', true)
          .limit(1);
      if (response.isNotEmpty) {
        final zone = response.first as Map<String, dynamic>;
        deliveryFee.value = (zone['delivery_fee'] as num?)?.toDouble() ?? 2500.0;
        minOrderAmount.value =
            (zone['min_order'] as num?)?.toDouble() ?? 0.0;
      } else {
        deliveryFee.value = 2500.0;
        minOrderAmount.value = 0.0;
      }
    } catch (e) {
      debugPrint('Error fetching delivery zone: $e');
    } finally {
      isLoadingDeliveryZone(false);
    }
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
      debugPrint('Error fetching categories: $e');
    }
  }

  /// Extracts polygon coordinates from GeoJSON (handles Feature, Polygon, MultiPolygon).
  /// Returns a list of polygons `[[[lng, lat], ...]]` or null on failure.
  List<List<List<List<double>>>>? _parseDeliveryZoneGeojson(Map<String, dynamic> geojson) {
    try {
      dynamic coords;
      String? geomType;

      if (geojson['type'] == 'Feature' && geojson['geometry'] != null) {
        coords = geojson['geometry']['coordinates'];
        geomType = geojson['geometry']['type'];
      } else {
        coords = geojson['coordinates'];
        geomType = geojson['type'];
      }

      if (coords is! List || coords.isEmpty) return null;

      if (geomType == 'MultiPolygon') {
        // MultiPolygon: [[[[lng,lat],...]],[[[lng,lat],...]]]
        return (coords as List).cast<List<List<List<double>>>>();
      }

      // Polygon: [[[lng,lat],...]]
      return [coords as List<List<List<double>>>];
    } catch (_) {
      return null;
    }
  }
}
