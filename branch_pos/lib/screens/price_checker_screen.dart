import 'dart:async';
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
  final _focusNode = FocusNode();
  final _supabase = Supabase.instance.client;
  final _authController = Get.find<AuthController>();
  Map<String, dynamic>? _product;
  bool _loading = false;
  String? _error;
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus so the barcode scanner input goes directly into the field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _barcodeController.addListener(_onBarcodeChanged);
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    _barcodeController.removeListener(_onBarcodeChanged);
    _barcodeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onBarcodeChanged() {
    // Barcode scanners type fast + press Enter. Auto-trigger on 3+ chars with small delay
    final text = _barcodeController.text.trim();
    if (text.length >= 3) {
      _clearTimer?.cancel();
      _clearTimer = Timer(const Duration(milliseconds: 400), () {
        if (_barcodeController.text.trim() == text) {
          _lookupBarcode(text);
        }
      });
    }
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
        _barcodeController.clear();
        _focusNode.requestFocus();
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

      // Auto-clear display after 15 seconds so next customer scan is fresh
      _clearTimer?.cancel();
      _clearTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) setState(() => _product = null);
      });

      // Clear barcode field and keep focus for next scan
      _barcodeController.clear();
      _focusNode.requestFocus();
    } catch (e) {
      setState(() { _error = 'خطأ في البحث: $e'; _loading = false; });
      _barcodeController.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: const Color(0xFF111A2E),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.scan, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('شاشة عرض السعر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _authController.currentBranchName.value,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Barcode input (auto-focused, hidden style)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2440),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A3A5F)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.scanLine, size: 28, color: Color(0xFF60A5FA)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _barcodeController,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'امسح الباركود هنا...',
                          hintStyle: TextStyle(color: Color(0xFF5A6A8F), fontSize: 18),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _lookupBarcode,
                        textInputAction: TextInputAction.search,
                        cursorColor: AppTheme.primaryLight,
                      ),
                    ),
                    if (_barcodeController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _barcodeController.clear();
                          _focusNode.requestFocus();
                        },
                        child: const Icon(LucideIcons.x, color: Color(0xFF5A6A8F), size: 22),
                      ),
                  ],
                ),
              ),

              // Main display area
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
                    : _error != null
                        ? _buildErrorDisplay()
                        : _product != null
                            ? _buildProductDisplay()
                            : _buildWaitingDisplay(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2440),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A3A5F), width: 2),
            ),
            child: const Icon(LucideIcons.scan, size: 120, color: Color(0xFF3B4A70)),
          ),
          const SizedBox(height: 40),
          const Text(
            'امسح الباركود لعرض السعر',
            style: TextStyle(fontSize: 32, color: Color(0xFF5A6A8F), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertTriangle, size: 120, color: Color(0xFFEF4444)),
          const SizedBox(height: 32),
          Text(
            _error!,
            style: const TextStyle(fontSize: 40, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'المنتج غير موجود أو الباركود غير مسجل',
            style: TextStyle(fontSize: 18, color: Color(0xFF9CA3AF)),
          ),
        ],
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

    final arabicUnit = unit.isNotEmpty ? unit : _defaultUnitName(unitType);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: const Color(0xFF111A2E),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.2),
              blurRadius: 60,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(imageUrl, width: 140, height: 140, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(color: const Color(0xFF1A2440), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(LucideIcons.package, size: 60, color: Color(0xFF3B4A70)),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(color: const Color(0xFF1A2440), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(LucideIcons.package, size: 60, color: Color(0xFF3B4A70)),
                  ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          '/$arabicUnit',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(color: Color(0xFF2A3A5F)),
            const SizedBox(height: 24),
            Text(
              '${price.toStringAsFixed(0)} د.ع',
              style: const TextStyle(
                fontSize: 110,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryLight,
                height: 1,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'السعر لكل $arabicUnit',
              style: const TextStyle(fontSize: 22, color: Color(0xFF8B9BB8)),
            ),
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
