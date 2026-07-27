import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../theme/app_theme.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({Key? key}) : super(key: key);

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final SupabaseService _supabase = SupabaseService();
  final AuthController _auth = Get.find();
  final InvoiceService _invoiceService = InvoiceService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final List<CartItem> _cart = [];
  bool _isLoading = true;
  bool _isCheckingOut = false;
  double _discount = 0.0;
  String _paymentMethod = 'نقداً';
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      final exactMatchIndex = _products.indexWhere((p) => p.barcode?.toLowerCase() == query);
      if (exactMatchIndex >= 0) {
        final product = _products[exactMatchIndex];
        _addToCart(product);
        _searchController.clear();
        return;
      }
    }

    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((p) =>
            p.name.toLowerCase().contains(query) ||
            (p.barcode?.toLowerCase().contains(query) ?? false)
        ).toList();
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _supabase.getProducts(
        branchId: _auth.currentBranchId.value,
      );
      setState(() {
        _products = products;
        _filteredProducts = List.from(products);
      });
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل المنتجات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((c) => c.productId == product.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(
          id: UniqueKey().toString(),
          productId: product.id,
          name: product.name,
          price: product.defaultPrice,
          unit: product.unit,
        ));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _cart[index].quantity + delta;
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = newQty;
      }
    });
  }

  double get _subtotal => _cart.fold(0.0, (sum, item) => sum + item.total);
  double get _total => _subtotal - _discount;

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      Get.snackbar('تنبيه', 'السلة فارغة');
      return;
    }

    setState(() => _isCheckingOut = true);
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult == ConnectivityResult.none;

      if (isOffline) {
        final orderId = DateTime.now().millisecondsSinceEpoch.toString();
        final itemsJson = jsonEncode(_cart.map((c) => {
          'product_id': c.productId,
          'name': c.name,
          'price': c.price,
          'quantity': c.quantity,
          'unit': c.unit,
          'total': c.total,
        }).toList());

        await DatabaseService().saveOfflineOrder({
          'id': orderId,
          'branch_id': _auth.currentBranchId.value,
          'created_by': _auth.supabase.auth.currentUser?.id ?? '',
          'total_amount': _total,
          'items_json': itemsJson,
          'is_synced': 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        setState(() {
          _cart.clear();
          _discount = 0.0;
          _customerName = null;
        });

        Get.snackbar('تم الحفظ محلياً', 'سيتم رفع البيانات عند عودة الإنترنت',
          backgroundColor: AppTheme.warning,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final order = await _supabase.createOrder(
        branchId: _auth.currentBranchId.value,
        createdBy: _auth.supabase.auth.currentUser?.id ?? '',
        items: List.from(_cart),
        total: _total,
        paymentMethod: _paymentMethod,
        customerName: _customerName,
        discount: _discount,
      );

      final invoice = Invoice(
        orderId: order['id'],
        branchId: _auth.currentBranchId.value,
        branchName: _auth.currentBranchName.value,
        items: _cart.map((c) => InvoiceItem(
          productId: c.productId,
          name: c.name,
          price: c.price,
          quantity: c.quantity,
          unit: c.unit,
        )).toList(),
        subtotal: _subtotal,
        discount: _discount,
        total: _total,
        paymentMethod: _paymentMethod,
        customerName: _customerName,
        cashierName: 'مدير ${_auth.currentBranchName.value}',
      );

      await _supabase.saveInvoice(invoice);

      setState(() {
        _cart.clear();
        _discount = 0.0;
        _customerName = null;
      });

      Get.snackbar('نجاح', 'تم إتمام البيع بنجاح',
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      try {
        await _invoiceService.printDirect(invoice);
      } catch (printError) {
        debugPrint('Print error (non-critical): $printError');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إتمام البيع: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 8));
    } finally {
      setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.monitor, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('شاشة الكاشير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const Spacer(),
                // Search bar
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'بحث بالاسم أو الباركود...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(LucideIcons.search, size: 18, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      autofocus: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLighter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.scan, size: 18, color: AppTheme.primary),
                  ),
                  onPressed: () => Get.snackbar('باركود', 'امسح الباركود باستخدام الماسح الضوئي'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLighter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.refreshCw, size: 18, color: AppTheme.primary),
                  ),
                  onPressed: _loadProducts,
                  tooltip: 'تحديث المنتجات',
                ),
              ],
            ),
          ),

          // Main area: Products + Cart
          Expanded(
            child: Row(
              children: [
                // Products Grid (left)
                Expanded(
                  flex: 3,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.package, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('لا توجد منتجات', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _ProductCard(
                                  product: product,
                                  onTap: () => _addToCart(product),
                                );
                              },
                            ),
                ),

                // Cart Panel (right)
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(-4, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Cart header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.05),
                              AppTheme.primary.withOpacity(0.02),
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(color: AppTheme.primary.withOpacity(0.1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.shoppingCart, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'سلة المشتريات (${_cart.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Spacer(),
                            if (_cart.isNotEmpty)
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.trash2, color: AppTheme.error, size: 16),
                                ),
                                onPressed: () => setState(() => _cart.clear()),
                                tooltip: 'تفريغ السلة',
                              ),
                          ],
                        ),
                      ),

                      // Cart items
                      Expanded(
                        child: _cart.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.shoppingCart, size: 48, color: Colors.grey.shade200),
                                    const SizedBox(height: 12),
                                    Text('السلة فارغة', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('اضغط على منتج لإضافته', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _cart.length,
                                itemBuilder: (context, index) {
                                  final item = _cart[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.price.toStringAsFixed(0)} د.ع / ${item.unit}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildQtyButton(
                                              icon: LucideIcons.minus,
                                              onTap: () => _updateQuantity(index, -1),
                                              color: Colors.grey.shade300,
                                            ),
                                            Container(
                                              width: 36,
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            _buildQtyButton(
                                              icon: LucideIcons.plus,
                                              onTap: () => _updateQuantity(index, 1),
                                              color: AppTheme.primary,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.total.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _removeFromCart(index),
                                          child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Totals + Checkout
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('المجموع الفرعي:', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                                Text('${_subtotal.toStringAsFixed(0)} د.ع', style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
                              ],
                            ),
                            if (_discount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الخصم:', style: TextStyle(fontSize: 14, color: AppTheme.error)),
                                  Text('-${_discount.toStringAsFixed(0)} د.ع', style: const TextStyle(fontSize: 14, color: AppTheme.error)),
                                ],
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Colors.grey.shade200),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                ShaderMask(
                                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                                  child: Text(
                                    '${_total.toStringAsFixed(0)} د.ع',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Discount input
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.percent, size: 16, color: Colors.grey.shade400),
                                  const SizedBox(width: 8),
                                  Text('خصم:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: '0',
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _paymentMethod,
                                        isDense: true,
                                        items: ['نقداً', 'بطاقة', 'محفظة'].map((m) =>
                                          DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                                        onChanged: (v) => setState(() => _paymentMethod = v ?? 'نقداً'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Checkout button
                            Container(
                              decoration: BoxDecoration(
                                gradient: _cart.isEmpty ? null : AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _cart.isEmpty ? [] : AppTheme.buttonShadow,
                              ),
                              child: ElevatedButton.icon(
                                icon: _isCheckingOut
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                    : const Icon(LucideIcons.receipt, color: Colors.white),
                                label: Text(
                                  _isCheckingOut ? 'جاري المعالجة...' : 'إتمام البيع (${_total.toStringAsFixed(0)} د.ع)',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: (_isCheckingOut || _cart.isEmpty) ? null : _checkout,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({required IconData icon, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasStock = (product.stockQuantity ?? 0) > 0;
    return GestureDetector(
      onTap: hasStock ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasStock ? Colors.grey.shade100 : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(LucideIcons.package, size: 36, color: Colors.grey.shade300),
                          ))
                      : Center(child: Icon(LucideIcons.package, size: 36, color: Colors.grey.shade300)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${product.defaultPrice.toStringAsFixed(0)} د.ع',
                          style: const TextStyle(fontSize: 12, color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (!hasStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.errorLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('نفذ', style: TextStyle(fontSize: 9, color: AppTheme.error, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'المخزون: ${product.stockQuantity?.toStringAsFixed(0) ?? "0"}',
                      style: TextStyle(fontSize: 9, color: hasStock ? Colors.grey.shade500 : AppTheme.error),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
