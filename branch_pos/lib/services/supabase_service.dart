import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/invoice.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final supabase = Supabase.instance.client;

  // ─── Products ───────────────────────────────────────────
  Future<List<Product>> getProducts({String? branchId, String? search}) async {
    // Use LEFT JOIN (not inner) so products show even without inventory record
    dynamic query = supabase
        .from('products')
        .select('*, inventory(stock_quantity)')
        .eq('is_active', true);

    if (branchId != null) {
      query = query.contains('allowed_branches', [branchId]);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,barcode.ilike.%$search%');
    }
    final data = await query.order('name');
    return (data as List).map((e) => Product.fromJson({
      ...e,
      'stock_quantity': e['inventory'] != null && (e['inventory'] as List).isNotEmpty
          ? (e['inventory'] as List).first['stock_quantity']
          : 0,
    })).toList();
  }

  // ─── Inventory ──────────────────────────────────────────
  Future<void> updateStock(String branchId, String productId, double quantity) async {
    await supabase.from('inventory').upsert({
      'branch_id': branchId,
      'product_id': productId,
      'stock_quantity': quantity,
    }, onConflict: 'branch_id,product_id');
  }

  Future<double> getStock(String branchId, String productId) async {
    final data = await supabase
        .from('inventory')
        .select('stock_quantity')
        .eq('branch_id', branchId)
        .eq('product_id', productId)
        .maybeSingle();
    return (data?['stock_quantity'] ?? 0).toDouble();
  }

  // ─── Orders ─────────────────────────────────────────────
  Future<Map<String, dynamic>> createOrder({
    required String branchId,
    required String createdBy,
    required List<CartItem> items,
    required double total,
    required String paymentMethod,
    String? customerName,
    double discount = 0,
    double tax = 0,
  }) async {
    // Insert order
    final orderData = await supabase.from('orders').insert({
      'branch_id': branchId,
      'total_amount': total,
      'status': 'pending',
      'delivery_address': 'بيع مباشر في الفرع',
      'payment_method': paymentMethod,
      'customer_name_manual': customerName ?? 'زبون نقدي',
    }).select().single();

    final orderId = orderData['id'];

    // Insert order items
    final orderItems = items.map((item) => {
      'order_id': orderId,
      'product_id': item.productId,
      'product_name': item.name,
      'quantity': item.quantity,
      'unit_price': item.price,
      'total_price': item.total,
    }).toList();

    await supabase.from('order_items').insert(orderItems);

    // Deduct inventory for each item
    for (final item in items) {
      final currentStock = await getStock(branchId, item.productId);
      final newStock = currentStock - item.quantity;
      if (newStock >= 0) {
        await updateStock(branchId, item.productId, newStock);
      }
    }

    return orderData;
  }

  // ─── Invoices ───────────────────────────────────────────
  Future<void> saveInvoice(Invoice invoice) async {
    await supabase.from('invoices').insert(invoice.toJson());
  }

  Future<List<Invoice>> getInvoices(String branchId) async {
    final data = await supabase
        .from('invoices')
        .select('*')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => Invoice.fromJson(e)).toList();
  }

  // ─── Stock Entry / Purchases ────────────────────────────
  Future<void> addStockEntry(String branchId, String productId, double quantity, double unitPrice, String userId) async {
    // Update inventory only (purchase header + items are created by purchases_screen)
    final currentStock = await getStock(branchId, productId);
    await updateStock(branchId, productId, currentStock + quantity);
  }

  // ─── FCM Tokens ─────────────────────────────────────────
  Future<void> registerFcmToken(String userId, String token) async {
    await supabase.from('user_fcm_tokens').upsert({
      'user_id': userId,
      'token': token,
      'device_type': 'web',
    }, onConflict: 'user_id,token');
  }
}
