import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_tracking_controller.dart';
import 'order_tracking_map_screen.dart';
import 'profile/support_screen.dart';
import 'widgets/order_timeline_widget.dart';
import 'widgets/order_products_and_invoice.dart';

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
  var branchName = ''.obs;
  var isGeneratingInvoice = false.obs;

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

      final branchId = response['branch_id']?.toString();
      if (branchId != null && branchId.isNotEmpty) {
        try {
          final branch = await supabase
              .from('branches')
              .select('name')
              .eq('id', branchId)
              .maybeSingle();
          if (branch != null) branchName.value = branch['name']?.toString() ?? '';
        } catch (_) {}
      }
    } catch (e) {
      print('Error fetching order details: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> _downloadInvoice() async {
    try {
      isGeneratingInvoice(true);
      final doc = pw.Document();
      final orderNum = _formatOrderId(widget.orderId);
      final createdAt = orderData['created_at']?.toString() ?? '';
      final dateText = createdAt.length >= 10 ? createdAt.substring(0, 10) : '';
      final total = (orderData['total_amount'] is num)
          ? (orderData['total_amount'] as num).toDouble()
          : double.tryParse(orderData['total_amount'].toString()) ?? 0;
      final deliveryFee = (orderData['delivery_fee'] is num)
          ? (orderData['delivery_fee'] as num).toDouble()
          : double.tryParse(orderData['delivery_fee'].toString()) ?? 0;
      final discount = (orderData['discount_amount'] is num)
          ? (orderData['discount_amount'] as num).toDouble()
          : double.tryParse(orderData['discount_amount'].toString()) ?? 0;
      final subtotal = total - deliveryFee + discount;

      doc.addPage(
        pw.Page(
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.cairoRegular(),
            bold: await PdfGoogleFonts.cairoBold(),
          ),
          build: (context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('order_invoice'.tr, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Kiwi', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text('order_number'.trParams({'number': orderNum})),
                  pw.Text('date_label'.trParams({'date': dateText})),
                  if (branchName.value.isNotEmpty) pw.Text('branch_label'.trParams({'name': branchName.value})),
                  pw.SizedBox(height: 16),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  pw.Text('products'.tr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...orderItems.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${item['product_name'] ?? ''}  (${item['quantity'] ?? 0} × ${item['unit_price'] ?? 0})',
                          ),
                        ),
                        pw.Text('${item['total_price'] ?? 0} ${'currency_iqd'.tr}'),
                      ],
                    ),
                  )),
                  pw.SizedBox(height: 8),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  _invoiceRow('subtotal'.tr, '$subtotal ${'currency_iqd'.tr}'),
                  _invoiceRow('delivery_fee'.tr, '$deliveryFee ${'currency_iqd'.tr}'),
                  if (discount > 0) _invoiceRow('discount'.tr, '- $discount ${'currency_iqd'.tr}'),
                  pw.SizedBox(height: 8),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  _invoiceRow('final_total'.tr, '$total ${'currency_iqd'.tr}', isBold: true),
                ],
              ),
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'invoice_${orderNum.replaceAll('#', '')}.pdf',
      );
    } catch (e) {
      Get.snackbar('error'.tr, 'invoice_failed'.trParams({'error': e.toString()}),
        backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16));
    } finally {
      isGeneratingInvoice(false);
    }
  }

  pw.Widget _invoiceRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('cancel_order'.tr, style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('cancel_order_confirm'.tr, style: TextStyle(fontFamily: 'Cairo')),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'cancellation_reason_hint'.tr,
                hintStyle: TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('go_back'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOrder(reason: reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('confirm_cancellation'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder({String reason = ''}) async {
    try {
      // Fetch order items and branch to restock
      String? branchId = orderData['branch_id']?.toString();
      List<Map<String, dynamic>> items = [];
      try {
        final fetched = await supabase
            .from('order_items')
            .select('product_id, quantity')
            .eq('order_id', widget.orderId);
        items = List<Map<String, dynamic>>.from(fetched as List? ?? []);
      } catch (e) {
        print('Warning: could not fetch order items for restock: $e');
      }

      await supabase.from('orders').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        if (reason.isNotEmpty) 'cancellation_reason': reason,
      }).eq('id', widget.orderId);

      // Restore stock that was decremented when the order was placed
      if (branchId != null && branchId.isNotEmpty) {
        try {
          for (final item in items) {
            final productId = item['product_id'];
            final qty = (item['quantity'] as num?)?.toInt() ?? 0;
            if (qty > 0) {
              await supabase.rpc(
                'increment_branch_inventory',
                params: {
                  'p_branch_id': branchId,
                  'p_product_id': productId,
                  'p_quantity': qty,
                },
              );
            }
          }
        } catch (stockErr) {
          print('Warning: restock failed: $stockErr');
        }
      }

      // Audit trail for this cancellation is handled automatically by the
      // trg_log_order_status_change DB trigger (it logs old_status,
      // new_status, changed_by = current user via auth.uid()).

      orderData['status'] = 'cancelled';
      orderData.refresh();
      Get.find<CartController>().refreshActiveOrder();
      Get.snackbar('cancelled'.tr, 'order_cancelled_success'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      Get.snackbar('error'.tr, 'cancel_order_failed'.trParams({'error': e.toString()}),
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
        title: Text('order_details_title'.tr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Cairo')),
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
              OrderProductsSection(items: orderItems, isDark: isDark, textColor: textColor, textSecColor: textSecColor),
              const SizedBox(height: 20),
              OrderInvoiceSummary(totalAmount: totalAmount, deliveryFee: deliveryFee, isDark: isDark, textColor: textColor, textSecColor: textSecColor),
              const SizedBox(height: 20),
              OrderTimelineWidget(status: status.toString(), isDark: isDark),
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
                  'order_status_label'.tr,
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
                Text('order_number_label'.tr, style: TextStyle(fontSize: 11, color: textSecColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(orderNum, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? AppTheme.primaryBright : AppTheme.primaryDark, fontFamily: 'Cairo', letterSpacing: 1)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.orderId));
              Get.snackbar('copied'.tr, 'order_number_copied'.tr,
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
    final name = profile['full_name']?.toString() ?? 'default_user_name'.tr;
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
              Text('delivery_info'.tr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(LucideIcons.user, 'recipient'.tr, name, textColor, textSecColor),
          const SizedBox(height: 10),
          _infoRow(LucideIcons.phone, 'phone_number'.tr, phone, textColor, textSecColor),
          const SizedBox(height: 10),
          _infoRow(LucideIcons.mapPin, 'address_label'.tr, address.isNotEmpty ? address : 'default_address'.tr, textColor, textSecColor),
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

  // ─── 7. Action Buttons ───
  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Get.to(() => OrderTrackingMapScreen(orderId: widget.orderId), transition: Transition.fadeIn),
            icon: const Icon(LucideIcons.map, size: 18),
            label: Text('track_order'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
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
        Obx(() => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isGeneratingInvoice.value ? null : () => _downloadInvoice(),
            icon: isGeneratingInvoice.value
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : const Icon(LucideIcons.download, size: 18),
            label: Text('download_invoice'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        )),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.to(() => const SupportScreen(), transition: Transition.fadeIn),
                icon: const Icon(LucideIcons.headphones, size: 16),
                label: Text('support'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
                label: Text('home'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
              label: Text('cancel_order'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red)),
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
                    Get.snackbar('copied'.tr, 'driver_number_copied'.trParams({'phone': driverPhone}),
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppTheme.primary,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar('not_available'.tr, 'driver_number_unavailable'.tr,
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                } catch (e) {
                  Get.snackbar('error'.tr, 'get_driver_number_failed'.tr,
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              icon: const Icon(LucideIcons.phone, size: 18),
              label: Text('contact_driver'.tr, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
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
