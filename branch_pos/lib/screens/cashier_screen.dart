import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

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
      // Check if there is an exact barcode match
      final exactMatchIndex = _products.indexWhere((p) => p.barcode?.toLowerCase() == query);
      if (exactMatchIndex >= 0) {
        final product = _products[exactMatchIndex];
        _addToCart(product);
        // Clear search controller immediately to prepare for next scan
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

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد البيع'),
        content: Text('المجموع: ${_total.toStringAsFixed(0)} د.ع\nطريقة الدفع: $_paymentMethod'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('تأكيد')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCheckingOut = true);
    try {
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
        id: UniqueKey().toString(),
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
      await _invoiceService.printDirect(invoice);

      setState(() {
        _cart.clear();
        _discount = 0.0;
        _customerName = null;
      });

      Get.snackbar('نجاح', 'تم إتمام البيع بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إتمام البيع: $e');
    } finally {
      setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة الكاشير'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Barcode area
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الباركود...',
                      prefixIcon: const Icon(LucideIcons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.scan),
                  onPressed: () => Get.snackbar('باركود', 'امسح الباركود باستخدام الماسح الضوئي'),
                  tooltip: 'مسح الباركود',
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
                          ? const Center(child: Text('لا توجد منتجات'))
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
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

                // Divider
                Container(width: 1, color: Colors.grey[300]),

                // Cart Panel (right)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Cart header
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.teal[50],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('السلة (${_cart.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: Colors.red),
                              onPressed: _cart.isEmpty ? null : () => setState(() => _cart.clear()),
                            ),
                          ],
                        ),
                      ),

                      // Cart items
                      Expanded(
                        child: _cart.isEmpty
                            ? const Center(child: Text('السلة فارغة', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: _cart.length,
                                itemBuilder: (context, index) {
                                  final item = _cart[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(item.name, style: const TextStyle(fontSize: 13)),
                                      subtitle: Text('${item.price.toStringAsFixed(0)} د.ع / ${item.unit}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 18),
                                            onPressed: () => _updateQuantity(index, -1),
                                          ),
                                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 18),
                                            onPressed: () => _updateQuantity(index, 1),
                                          ),
                                          Text('${item.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                            onPressed: () => _removeFromCart(index),
                                          ),
                                        ],
                                      ),
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
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع الفرعي:', style: TextStyle(fontSize: 14)),
                                Text('${_subtotal.toStringAsFixed(0)} د.ع', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                            if (_discount > 0) Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الخصم:', style: TextStyle(fontSize: 14, color: Colors.red)),
                                Text('-${_discount.toStringAsFixed(0)} د.ع', style: const TextStyle(fontSize: 14, color: Colors.red)),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                Text('${_total.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Discount input
                            Row(
                              children: [
                                const Text('خصم: '),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: '0',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                                  ),
                                ),
                                const Spacer(),
                                DropdownButton<String>(
                                  value: _paymentMethod,
                                  items: ['نقداً', 'بطاقة', 'محفظة'].map((m) =>
                                    DropdownMenuItem(value: m, child: Text(m))).toList(),
                                  onChanged: (v) => setState(() => _paymentMethod = v ?? 'نقداً'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                icon: _isCheckingOut
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                    : const Icon(LucideIcons.receipt),
                                label: Text(_isCheckingOut ? 'جاري...' : 'إتمام البيع (${_total.toStringAsFixed(0)} د.ع)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                onPressed: _isCheckingOut ? null : _checkout,
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
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.package, size: 40))
                    : const Center(child: Icon(LucideIcons.package, size: 40, color: Colors.grey)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text('${product.defaultPrice.toStringAsFixed(0)} د.ع', style: TextStyle(fontSize: 11, color: Colors.teal[700], fontWeight: FontWeight.bold)),
                    Text('المخزون: ${product.stockQuantity?.toStringAsFixed(0) ?? "0"}', style: TextStyle(fontSize: 9, color: hasStock ? Colors.grey : Colors.red)),
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
