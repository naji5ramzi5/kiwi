import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_tracking_controller.dart';
import 'order_tracking_map_screen.dart';
import 'profile/support_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final supabase = Supabase.instance.client;
  late final OrderTrackingController trackingController;
  var orderData = <String, dynamic>{}.obs;
  var orderItems = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    trackingController = Get.isRegistered<OrderTrackingController>()
        ? Get.find<OrderTrackingController>()
        : Get.put(OrderTrackingController(orderId: widget.orderId));
    fetchOrderWithItems();
  }

  String _formatOrderId(String id) {
    final short = id.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '');
    if (short.length > 8) return '#KI-${short.substring(0, 8).toUpperCase()}';
    return '#KI-$short'.toUpperCase();
  }

  Future<void> fetchOrderWithItems() async {
    try {
      isLoading(true);
      final response = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', widget.orderId)
          .single();
      orderData.value = Map<String, dynamic>.from(response);
      final items = response['order_items'] as List? ?? [];
      orderItems.value = List<Map<String, dynamic>>.from(items);
    } catch (e) {
      print('Error fetching order details: $e');
    } finally {
      isLoading(false);
    }
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إلغاء الطلب', style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من إلغاء الطلب؟', style: TextStyle(fontFamily: 'Cairo')),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'سبب الإلغاء (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOrder(reason: reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('تأكيد الإلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder({String reason = ''}) async {
    try {
      await supabase.from('orders').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        if (reason.isNotEmpty) 'cancellation_reason': reason,
      }).eq('id', widget.orderId);

      await supabase.from('order_status_history').insert({
        'order_id': widget.orderId,
        'status': 'cancelled',
        'note': reason.isNotEmpty ? reason : 'ألغاه العميل',
        'changed_by': supabase.auth.currentUser?.id,
      });

      orderData['status'] = 'cancelled';
      orderData.refresh();
      Get.find<CartController>().refreshActiveOrder();
      Get.snackbar('تم الإلغاء', 'تم إلغاء الطلب بنجاح',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إلغاء الطلب: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('تفاصيل الطلب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Cairo')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final status = orderData['status'] ?? 'pending';
        final statusText = trackingController.statusText;
        final totalAmount = orderData['total_amount'] ?? 0;
        final deliveryFee = orderData['delivery_fee'] ?? 0;
        final address = orderData['delivery_address'] ?? '';

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context, status.toString(), statusText, isDark, textSecColor),
              const SizedBox(height: 20),
              _buildOrderNumber(context, isDark, textSecColor),
              const SizedBox(height: 20),
              _buildDeliveryInfo(context, address.toString(), isDark, textColor, textSecColor),
              const SizedBox(height: 20),
              _buildProductsSection(context, isDark, textColor, textSecColor),
              const SizedBox(height: 20),
              _buildInvoiceSummary(context, totalAmount, deliveryFee, isDark, textColor, textSecColor),
              const SizedBox(height: 20),
              _buildTimeline(context, status.toString(), isDark),
              const SizedBox(height: 24),
              _buildActionButtons(context, isDark),
            ],
          ),
        );
      }),
    );
  }

  // ─── 1. Status Card ───
  Widget _buildStatusCard(BuildContext context, String status, String statusText, bool isDark, Color textSecColor) {
    IconData icon;
    Color color;
    switch (status) {
      case 'preparing':
        icon = LucideIcons.clock;
        color = Colors.orange;
        break;
      case 'picked_up':
        icon = LucideIcons.packageCheck;
        color = Colors.indigo;
        break;
      case 'shipped':
        icon = LucideIcons.truck;
        color = Colors.blue;
        break;
      case 'delivered':
        icon = LucideIcons.packageCheck;
        color = AppTheme.primary;
        break;
      case 'cancelled':
        icon = LucideIcons.xCircle;
        color = Colors.red;
        break;
      default:
        icon = LucideIcons.checkCircle2;
        color = Colors.amber;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الطلب',
                  style: TextStyle(fontSize: 12, color: textSecColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Order Number ───
  Widget _buildOrderNumber(BuildContext context, bool isDark, Color textSecColor) {
    final orderNum = _formatOrderId(widget.orderId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.receipt, size: 22, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رقم الطلب', style: TextStyle(fontSize: 11, color: textSecColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(orderNum, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF4ADE80) : AppTheme.primaryDark, fontFamily: 'Cairo', letterSpacing: 1)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.orderId));
              Get.snackbar('تم النسخ', 'تم نسخ رقم الطلب',
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppTheme.primary,
                colorText: Colors.white,
                duration: const Duration(seconds: 1),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.copy, size: 18, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Delivery Info ───
  Widget _buildDeliveryInfo(BuildContext context, String address, bool isDark, Color textColor, Color textSecColor) {
    final profile = Get.find<AuthController>().userProfile();
    final name = profile['full_name']?.toString() ?? 'مستخدم Kiwi';
    final phone = profile['phone']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text('معلومات التوصيل', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(LucideIcons.user, 'المستلم', name, textColor, textSecColor),
          const SizedBox(height: 10),
          _infoRow(LucideIcons.phone, 'رقم الهاتف', phone, textColor, textSecColor),
          const SizedBox(height: 10),
          _infoRow(LucideIcons.mapPin, 'العنوان', address.isNotEmpty ? address : 'بغداد - الكرادة', textColor, textSecColor),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color textColor, Color textSecColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textSecColor),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(fontSize: 12, color: textSecColor, fontFamily: 'Cairo')),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ─── 4. Products ───
  Widget _buildProductsSection(BuildContext context, bool isDark, Color textColor, Color textSecColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.shoppingBag, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text('المنتجات المطلوبة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
              const Spacer(),
              Text('${orderItems.length} أصناف', style: TextStyle(fontSize: 11, color: textSecColor, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 14),
          ...orderItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProductItem(item, isDark, textColor, textSecColor),
          )),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item, bool isDark, Color textColor, Color textSecColor) {
    final name = item['product_name']?.toString() ?? '';
    final qty = item['quantity'] ?? 0;
    final unitPrice = item['unit_price'] ?? 0;
    final totalPrice = item['total_price'] ?? 0;
    final imageUrl = item['image_url']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 52, height: 52,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: isDark ? Colors.grey[850] : Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.primary.withOpacity(0.1),
                child: const Icon(LucideIcons.image, size: 20, color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$qty × $unitPrice د.ع', style: TextStyle(fontSize: 11, color: textSecColor, fontFamily: 'Cairo')),
                  ],
                ),
              ],
            ),
          ),
          Text('$totalPrice د.ع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  // ─── 5. Invoice Summary ───
  Widget _buildInvoiceSummary(BuildContext context, dynamic totalAmount, dynamic deliveryFee, bool isDark, Color textColor, Color textSecColor) {
    final subtotal = (totalAmount is num ? totalAmount.toDouble() : double.tryParse(totalAmount.toString()) ?? 0) -
                     (deliveryFee is num ? deliveryFee.toDouble() : double.tryParse(deliveryFee.toString()) ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.receipt, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text('ملخص الفاتورة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('المجموع الفرعي', '$subtotal د.ع', textColor, textSecColor),
          const SizedBox(height: 8),
          _summaryRow('رسوم التوصيل', '$deliveryFee د.ع', textColor, textSecColor),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي النهائي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
              Text('$totalAmount د.ع', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Cairo')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color textColor, Color textSecColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: textSecColor, fontFamily: 'Cairo')),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
      ],
    );
  }

  // ─── 6. Timeline ───
  Widget _buildTimeline(BuildContext context, String status, bool isDark) {
    final steps = [
      {'label': 'تم استلام الطلب', 'key': 'pending', 'icon': LucideIcons.checkCircle2},
      {'label': 'جاري التجهيز', 'key': 'preparing', 'icon': LucideIcons.clock},
      {'label': 'تم الاستلام من المندوب', 'key': 'picked_up', 'icon': LucideIcons.packageCheck},
      {'label': 'في الطريق', 'key': 'shipped', 'icon': LucideIcons.truck},
      {'label': 'تم التسليم', 'key': 'delivered', 'icon': LucideIcons.packageCheck},
    ];

    final currentIndex = steps.indexWhere((s) => s['key'] == status);
    final activeIndex = currentIndex >= 0 ? currentIndex : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.listChecks, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text('تتبع الطلب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isCompleted = i <= activeIndex;
            final isCurrent = i == activeIndex;
            final isLast = i == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: isCurrent ? 28 : 24,
                          height: isCurrent ? 28 : 24,
                          decoration: BoxDecoration(
                            color: isCompleted ? AppTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            shape: BoxShape.circle,
                            boxShadow: isCurrent ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8)] : null,
                          ),
                          child: Center(
                            child: isCompleted
                              ? Icon(LucideIcons.check, size: isCurrent ? 16 : 14, color: Colors.white)
                              : Icon(step['icon'] as IconData, size: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: i < activeIndex ? AppTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['label'] as String,
                            style: TextStyle(
                              fontSize: isCurrent ? 14 : 13,
                              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                              color: isCompleted ? AppTheme.primary : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              'المرحلة الحالية',
                              style: TextStyle(fontSize: 10, color: AppTheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── 7. Action Buttons ───
  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Get.to(() => OrderTrackingMapScreen(orderId: widget.orderId), transition: Transition.fadeIn),
            icon: const Icon(LucideIcons.map, size: 18),
            label: const Text('تتبع الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.to(() => const SupportScreen(), transition: Transition.fadeIn),
                icon: const Icon(LucideIcons.headphones, size: 16),
                label: const Text('الدعم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(LucideIcons.home, size: 16),
                label: const Text('الرئيسية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        if (orderData['status'] == 'pending') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(),
              icon: const Icon(LucideIcons.xCircle, size: 18, color: Colors.red),
              label: const Text('إلغاء الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
        if (orderData['driver_id'] != null && orderData['status'] == 'shipped') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final driverId = orderData['driver_id'].toString();
                try {
                  final driver = await supabase
                      .from('drivers')
                      .select('phone')
                      .eq('id', driverId)
                      .maybeSingle();
                  final driverPhone = driver?['phone']?.toString() ?? '';
                  if (driverPhone.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: driverPhone));
                    Get.snackbar('تم النسخ', 'تم نسخ رقم المندوب: $driverPhone',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppTheme.primary,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar('غير متاح', 'رقم المندوب غير متوفر حالياً',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                } catch (e) {
                  Get.snackbar('خطأ', 'تعذر الحصول على رقم المندوب',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              icon: const Icon(LucideIcons.phone, size: 18),
              label: const Text('الاتصال بالمندوب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
