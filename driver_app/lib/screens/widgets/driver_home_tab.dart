import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  final Map<String, int> _countdowns = {};
  final Map<String, Timer> _timers = {};

  @override
  void initState() {
    super.initState();
    _startCountdowns();
  }

  @override
  void didUpdateWidget(DriverHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startCountdowns();
  }

  void _startCountdowns() {
    for (final order in widget.activeOrders) {
      final id = order['id'].toString();
      if ((order['status'] == 'assigned' || order['status'] == 'pending' || order['status'] == 'preparing') && !_timers.containsKey(id)) {
        _countdowns[id] = 30;
        _timers[id] = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) { timer.cancel(); return; }
          final remaining = (_countdowns[id] ?? 0) - 1;
          if (remaining <= 0) {
            timer.cancel();
            _timers.remove(id);
            _countdowns.remove(id);
            _autoRejectOrder(id);
          } else {
            setState(() => _countdowns[id] = remaining);
          }
        });
      }
    }
    // Clean up timers for orders no longer in the list
    final activeIds = widget.activeOrders.map((o) => o['id'].toString()).toSet();
    _timers.removeWhere((id, timer) {
      if (!activeIds.contains(id)) {
        timer.cancel();
        return true;
      }
      return false;
    });
    _countdowns.removeWhere((id, _) => !activeIds.contains(id));
  }

  Future<void> _autoRejectOrder(String orderId) async {
    try {
      // Release order back to branch
      await Supabase.instance.client.rpc('release_order_from_delivery', params: {'p_order_id': orderId});
      widget.onRefresh();
      if (mounted) {
        Get.snackbar('انتهت المهلة', 'تم إرجاع الطلب للفرع لعدم الرد',
            backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      }
    } catch (_) {
      // Fallback: reset order
      try {
        await Supabase.instance.client.from('orders').update({
          'assigned_delivery_id': null,
          'driver_id': null,
          'status': 'ready',
          'assigned_at': null,
        }).eq('id', orderId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
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
    bool isNew = order['status'] == 'assigned' || order['status'] == 'pending' || order['status'] == 'preparing';
    final orderId = order['id'].toString();
    final countdown = _countdowns[orderId];
    final bool showAcceptReject = order['status'] == 'assigned';

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
          if (isNew && countdown != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: countdown <= 10 ? Colors.red.shade50 : Colors.orange.shade50,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: countdown <= 10 ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'وقت القبول: $countdown ثانية',
                    style: TextStyle(
                      color: countdown <= 10 ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
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
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(() => DeliveryMapScreen(order: order)),
                      icon: Icon(isDelivering ? LucideIcons.map : LucideIcons.navigation, size: 18),
                      label: Text(isDelivering ? 'عرض الخريطة' : 'استلام الطلب'),
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
                        onPressed: () async {
                          await Supabase.instance.client.from('orders').update({'status': 'delivered'}).eq('id', order['id']);
                          widget.onRefresh();
                          Get.snackbar('تم التوصيل', 'أحسنت عملاً! تمت إضافة الأرباح لرصيدك.', backgroundColor: const Color(0xFF10b981), colorText: Colors.white, margin: const EdgeInsets.all(16));
                        },
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
