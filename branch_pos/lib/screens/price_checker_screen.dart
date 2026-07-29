import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class PriceCheckerScreen extends StatefulWidget {
  const PriceCheckerScreen({super.key});

  @override
  State<PriceCheckerScreen> createState() => _PriceCheckerScreenState();
}

class _PriceCheckerScreenState extends State<PriceCheckerScreen> {
  final _barcodeController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _authController = Get.find<AuthController>();
  Map<String, dynamic>? _product;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _lookupBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; _product = null; });

    try {
      final branchId = _authController.currentBranchId.value;

      // Fetch product by barcode
      final response = await _supabase
          .from('products')
          .select()
          .eq('barcode', barcode.trim())
          .maybeSingle();

      if (response == null) {
        setState(() { _error = 'المنتج غير موجود'; _loading = false; });
        return;
      }

      final product = Map<String, dynamic>.from(response);

      // Fetch branch-specific price if available
      if (branchId.isNotEmpty) {
        final bp = await _supabase
            .from('branch_product_prices')
            .select('price')
            .eq('branch_id', branchId)
            .eq('product_id', product['id'])
            .maybeSingle();
        if (bp != null) {
          product['price'] = bp['price'];
        }
      }

      setState(() { _product = product; _loading = false; });
    } catch (e) {
      setState(() { _error = 'خطأ في البحث: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Price Checker', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF065f46),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Barcode search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFf3f4f6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFd1d5db)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.scan, size: 28, color: Color(0xFF6b7280)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _barcodeController,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: 'امسح الباركود أو أدخل الرقم...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: _lookupBarcode,
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _lookupBarcode(_barcodeController.text),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065f46),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.search, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Results area
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.scan, size: 80, color: Color(0xFFd1d5db)),
                                const SizedBox(height: 16),
                                Text(_error!, style: const TextStyle(fontSize: 24, color: Color(0xFFef4444), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        : _product != null
                            ? _buildProductDisplay()
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.scan, size: 80, color: Color(0xFFd1d5db)),
                                    const SizedBox(height: 16),
                                    const Text('امسح الباركود لفحص السعر', style: TextStyle(fontSize: 20, color: Color(0xFF9ca3af))),
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDisplay() {
    final p = _product!;
    final name = p['name'] ?? '';
    final price = (p['price'] ?? 0).toDouble();
    final unit = p['unit'] ?? '';
    final unitType = p['unit_type'] ?? 'kilogram';
    final imageUrl = p['image_url'] as String?;
    final barcode = p['barcode'] as String?;

    final arabicUnit = unit.isNotEmpty ? unit : _defaultUnitName(unitType);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFFf9fafb),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFe5e7eb), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, width: 200, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 200, height: 200, color: const Color(0xFFe5e7eb), child: const Icon(LucideIcons.image, size: 64, color: Color(0xFF9ca3af)))),
              )
            else
              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(color: const Color(0xFFe5e7eb), borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.image, size: 64, color: Color(0xFF9ca3af)),
              ),
            const SizedBox(height: 24),
            Text(name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('${price.toStringAsFixed(0)} د.ع', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF065f46))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFe0f2fe), borderRadius: BorderRadius.circular(12)),
              child: Text('/$arabicUnit', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF0369a1))),
            ),
            if (barcode != null && barcode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Barcode: $barcode', style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
            ],
          ],
        ),
      ),
    );
  }

  String _defaultUnitName(String unitType) {
    switch (unitType) {
      case 'kilogram': return 'كيلو';
      case 'gram': return 'غرام';
      case 'piece': return 'حبة';
      case 'unit': return 'قطعة';
      case 'box': return 'علبة';
      case 'carton': return 'كرتونة';
      case 'pack': return 'باكيت';
      case 'bottle': return 'قنينة';
      case 'can': return 'علبة معدنية';
      case 'bag': return 'كيس';
      case 'tray': return 'صينية';
      case 'bundle': return 'ربطة';
      case 'sack': return 'شوال';
      case 'liter': return 'لتر';
      case 'milliliter': return 'ميليلتر';
      default: return unitType;
    }
  }
}
