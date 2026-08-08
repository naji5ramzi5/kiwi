import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../delivery_map_screen.dart';

String orderShort(String id) => id.length >= 5 ? id.substring(0, 5) : id;

class DriverHomeTab extends StatefulWidget {
  final bool isOnline;
  final bool isLoading;
  final List<Map<String, dynamic>> activeOrders;
  final String avgRating;
  final int totalRatings;
  final VoidCallback onRefresh;
  final int dailyDeliveries;
  final int monthlyDeliveries;

  const DriverHomeTab({
    super.key,
    required this.isOnline,
    required this.isLoading,
    required this.activeOrders,
    required this.avgRating,
    required this.totalRatings,
    required this.onRefresh,
    this.dailyDeliveries = 0,
    this.monthlyDeliveries = 0,
  });

  @override
  State<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends State<DriverHomeTab> {
  Future<void> _claimOrder(Map<String, dynamic> order) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final emp = await Supabase.instance.client
          .from('delivery_employees')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (emp == null) {
        Get.snackbar('تنبيه', 'لا يوجد سجل مندوب مرتبط بحسابك',
            backgroundColor: Colors.orange, colorText: Colors.white, margin: const EdgeInsets.all(16));
        return;
      }
      await Supabase.instance.client.rpc('assign_order_to_delivery', params: {
        'p_order_id': order['id'],
        'p_employee_id': emp['id'],
      });
      widget.onRefresh();
      Get.snackbar('تم الاستلام', 'تم إسناد الطلب إليك، توجه إلى الفرع للتجهيز.',
          backgroundColor: const Color(0xFF10b981), colorText: Colors.white, margin: const EdgeInsets.all(16));
    } catch (e) {
      Get.snackbar('فشل الاستلام', 'تعذر إسناد الطلب: $e',
          backgroundColor: Colors.red, colorText: Colors.white, margin: const EdgeInsets.all(16));
    }
  }

  Future<void> _confirmDelivery(Map<String, dynamic> order) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 60);

    if (picked == null) {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('تأكيد التسليم'),
          content: const Text('لم يتم التقاط صورة إثبات التوصيل. هل تريد تأكيد التسليم بدون صورة؟'),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('تأكيد بدون صورة')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    double? lat;
    double? lng;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    String? proofUrl;
    if (picked != null) {
      try {
        final fileName = 'proof_${order['id']}.jpg';
        await Supabase.instance.client.storage.from('delivery_proofs').upload(fileName, File(picked.path));
        proofUrl = Supabase.instance.client.storage.from('delivery_proofs').getPublicUrl(fileName);
      } catch (e) {
        debugPrint('Proof upload failed: $e');
      }
    }

    try {
      await Supabase.instance.client.rpc('confirm_delivery', params: {
        'p_order_id': order['id'],
        'p_photo_url': proofUrl,
        'p_latitude': lat,
        'p_longitude': lng,
      });
    } catch (e) {
      debugPrint('confirm_delivery RPC failed, falling back: $e');
      if (proofUrl != null) {
        await Supabase.instance.client.from('orders').update({'proof_image': proofUrl}).eq('id', order['id']);
      }
      await Supabase.instance.client.from('orders').update({'status': 'delivered'}).eq('id', order['id']);
    }
    widget.onRefresh();
    Get.snackbar('عمل ممتاز!', 'تم إنهاء الطلب وتسليمه للعميل بنجاح', backgroundColor: const Color(0xFF10b981), colorText: Colors.white, margin: const EdgeInsets.all(16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!widget.isOnline)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle), child: const Icon(LucideIcons.moon, color: Colors.orange, size: 20)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أنت في وضع الاستراحة', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      Text('فعل الاتصال لتلقي طلبات جديدة', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildStatCard('الطلبات الحالية', widget.activeOrders.length.toString(), LucideIcons.package, const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _buildStatCard('توصيل اليوم', widget.dailyDeliveries.toString(), LucideIcons.calendarCheck, const Color(0xFF10b981)),
              const SizedBox(width: 12),
              _buildStatCard('توصيل الشهر', widget.monthlyDeliveries.toString(), LucideIcons.trendingUp, const Color(0xFF8B5CF6)),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              const Text('الطلبات الحالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const Spacer(),
              if (widget.isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF10b981),
            onRefresh: () async => widget.onRefresh(),
            child: _buildOrdersList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    if (!widget.isOnline && widget.activeOrders.isEmpty) {
      return ListView(children: [SizedBox(height: 300), Center(child: Column(children: [Icon(LucideIcons.coffee, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), Text('استمتع بوقتك! لا توجد طلبات', style: TextStyle(color: Colors.grey.shade500, fontSize: 16))]))]);
    }
    if (widget.activeOrders.isEmpty) {
      return ListView(children: [SizedBox(height: 300), Center(child: Column(children: [Icon(LucideIcons.map, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), Text('جاري البحث عن طلبات...', style: TextStyle(color: Colors.grey.shade500, fontSize: 16))]))]);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
      itemCount: widget.activeOrders.length,
      itemBuilder: (context, index) => _buildOrderCard(widget.activeOrders[index]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    bool isDelivering = order['status'] == 'shipped';
    bool isAssigned = order['status'] == 'picked_up';
    bool isNew = order['status'] == 'assigned' || order['status'] == 'pending' || order['status'] == 'preparing' || order['status'] == 'prepared' || order['status'] == 'ready';
    final orderId = order['id'].toString();
    final bool showAcceptReject = order['status'] == 'assigned';
    // Unassigned order in the driver's zone that can be claimed directly.
    final bool isZoneNew = (order['driver_id'] == null) &&
        (order['status'] == 'pending' ||
            order['status'] == 'preparing' ||
            order['status'] == 'prepared' ||
            order['status'] == 'ready');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(
          color: isDelivering || isAssigned
              ? const Color(0xFF10b981).withOpacity(0.3)
              : isNew
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.transparent,
          width: isDelivering || isAssigned || isNew ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.packageOpen, color: Color(0xFF1F2937), size: 20)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('طلب #${orderShort(orderId).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(_timeAgo(order['created_at']), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDelivering || isAssigned
                            ? const Color(0xFF10b981).withOpacity(0.1)
                            : showAcceptReject
                                ? Colors.blue.withOpacity(0.1)
                                : isNew
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        showAcceptReject
                            ? 'بانتظار القبول'
                            : isDelivering
                                ? 'في الطريق'
                                : isAssigned
                                    ? 'تم الاستلام من الفرع'
                                    : isNew
                                        ? 'طلب جديد'
                                        : order['status'],
                        style: TextStyle(
                          color: isDelivering || isAssigned
                              ? const Color(0xFF10b981)
                              : showAcceptReject
                                  ? Colors.blue
                                  : isNew
                                      ? Colors.orange
                                      : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.mapPin, color: Colors.redAccent, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(order['delivery_address'] ?? 'عنوان العميل', style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.4))),
                  ],
                ),
              ],
            ),
          ),

          // Accept/Reject buttons for assigned orders
          if (showAcceptReject)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.rpc('release_order_from_delivery', params: {'p_order_id': orderId});
                        widget.onRefresh();
                        Get.snackbar('تم الرفض', 'تم إرجاع الطلب للفرع', backgroundColor: Colors.orange, colorText: Colors.white, margin: const EdgeInsets.all(16));
                      },
                      icon: const Icon(LucideIcons.xCircle, size: 18),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.rpc('accept_delivery_order', params: {
                          'p_order_id': orderId,
                          'p_employee_id': order['assigned_delivery_id'],
                        });
                        widget.onRefresh();
                        Get.snackbar('تم القبول', 'تم قبول الطلب، توجه إلى الفرع لاستلامه', backgroundColor: const Color(0xFF10b981), colorText: Colors.white, margin: const EdgeInsets.all(16));
                      },
                      icon: const Icon(LucideIcons.checkCircle, size: 18),
                      label: const Text('قبول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!showAcceptReject)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
              child: isZoneNew
                  // Unassigned order in the driver's zone: single claim button
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _claimOrder(order);
                        },
                        icon: const Icon(LucideIcons.hand, size: 18),
                        label: const Text('استلام الطلب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  : Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(() => DeliveryMapScreen(order: order)),
                      icon: Icon(isDelivering ? LucideIcons.map : LucideIcons.navigation, size: 18),
                      label: Text(isDelivering ? 'عرض الخريطة' : 'بدء التوصيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (isAssigned) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Supabase.instance.client
                              .from('orders')
                              .update({'status': 'shipped'})
                              .eq('id', order['id']);
                          widget.onRefresh();
                          Get.snackbar(
                            'تم الاستلام',
                            'تم تأكيد استلام الطلب من الفرع، يمكنك البدء بالتوصيل.',
                            backgroundColor: const Color(0xFF10b981),
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(16),
                          );
                        },
                        icon: const Icon(LucideIcons.packageCheck, size: 18),
                        label: const Text('تأكيد الاستلام من الفرع'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10b981),
                          side: const BorderSide(color: Color(0xFF10b981)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  if (isDelivering) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async => _confirmDelivery(order),
                        icon: const Icon(LucideIcons.checkCircle, size: 18),
                        label: const Text('إنهاء'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10b981),
                          side: const BorderSide(color: Color(0xFF10b981)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: color)),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return 'الآن';
    try {
      DateTime date = createdAt is String ? DateTime.parse(createdAt) : DateTime.parse(createdAt.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return '${date.month}/${date.day}';
    } catch (e) {
      return 'الآن';
    }
  }
}
