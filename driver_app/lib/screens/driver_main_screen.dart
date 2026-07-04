import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'delivery_map_screen.dart';
import 'auth/driver_login_screen.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  final supabase = Supabase.instance.client;
  bool isOnline = true;
  List<Map<String, dynamic>> activeOrders = [];
  List<Map<String, dynamic>> historyOrders = [];
  bool isLoading = true;
  Map<String, dynamic>? driverProfile;
  String avgRating = 'جديد';
  int totalRatings = 0;
  int deliveryCount = 0;
  double totalEarnings = 0;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndOrders();
    _setupRealtime();
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return 'الآن';
    try {
      DateTime date;
      if (createdAt is String) {
        date = DateTime.parse(createdAt);
      } else {
        date = DateTime.parse(createdAt.toString());
      }
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return DateFormat('MM/dd').format(date);
    } catch (e) {
      return 'الآن';
    }
  }

  Future<void> _fetchProfileAndOrders() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final profile = await supabase.from('profiles').select().eq('id', user.id).single();
      setState(() {
        driverProfile = profile;
        isOnline = profile['is_online'] ?? false;
      });
      _fetchRating(user.id);
      _fetchEarnings(user.id);
    }
    await fetchOrders();
    await fetchHistory();
  }

  Future<void> _fetchRating(String driverId) async {
    try {
      final result = await supabase
          .from('driver_ratings')
          .select('rating')
          .eq('driver_id', driverId);
      if (result is List && result.isNotEmpty) {
        final ratings = result.map((e) => (e['rating'] as num).toDouble()).toList();
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        setState(() {
          avgRating = avg.toStringAsFixed(1);
          totalRatings = ratings.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchEarnings(String driverId) async {
    try {
      final delivered = await supabase
          .from('orders')
          .select('delivery_fee')
          .eq('driver_id', driverId)
          .eq('status', 'delivered');
      if (delivered is List) {
        double total = 0;
        for (var o in delivered) {
          total += (o['delivery_fee'] as num?)?.toDouble() ?? 0;
        }
        setState(() {
          deliveryCount = delivered.length;
          totalEarnings = total;
        });
      }
    } catch (_) {}
  }

  void _setupRealtime() {
    supabase.channel('driver-updates').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        fetchOrders();
        fetchHistory();
        if (driverProfile != null) _fetchEarnings(driverProfile!['id']);
      },
    ).subscribe();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await supabase
          .from('orders')
          .select()
          .inFilter('status', ['shipped'])
          .eq('driver_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      setState(() {
        activeOrders = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchHistory() async {
    try {
      final response = await supabase
          .from('orders')
          .select()
          .inFilter('status', ['delivered'])
          .eq('driver_id', supabase.auth.currentUser!.id)
          .order('updated_at', ascending: false)
          .limit(50);
      setState(() {
        historyOrders = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('History error: $e');
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => isOnline = value);
    await supabase.from('profiles').update({'is_online': value}).eq('id', supabase.auth.currentUser!.id);
    if (value) {
      Get.snackbar('أنت متصل الآن 🚀', 'مستعدون لتلقي الطلبات', backgroundColor: const Color(0xFF10b981), colorText: Colors.white, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeTab(),
      _buildEarningsTab(),
      _buildHistoryTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10b981), width: 2),
                      boxShadow: [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.2), blurRadius: 10)],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      backgroundImage: driverProfile?['avatar_url'] != null ? NetworkImage(driverProfile!['avatar_url']) : null,
                      child: driverProfile?['avatar_url'] == null ? const Icon(LucideIcons.user, color: Color(0xFF10b981)) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('أهلاً بك، ${driverProfile?['full_name'] ?? 'كابتن'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(driverProfile?['vehicle_type'] == 'truck' ? LucideIcons.truck : LucideIcons.bike, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(driverProfile?['plate_number'] ?? 'جاهز للانطلاق', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFF10b981).withOpacity(0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(isOnline ? 'متصل' : 'أوفلاين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOnline ? const Color(0xFF10b981) : Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: isOnline,
                            activeColor: const Color(0xFF10b981),
                            activeTrackColor: const Color(0xFF10b981).withOpacity(0.3),
                            onChanged: _toggleOnline,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      body: screens[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF10b981),
        unselectedItemColor: Colors.grey.shade400,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.wallet), label: 'الأرباح'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.clock), label: 'السجل'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        if (!isOnline)
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

        // Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              _buildStatCard('الطلبات المتاحة', activeOrders.length.toString(), LucideIcons.package, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildRatingCard(),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Text('الطلبات الحالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const Spacer(),
              if (isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF10b981),
            onRefresh: () async {
              await fetchOrders();
              await fetchHistory();
            },
            child: _buildOrdersList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF059669)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              const Text('إجمالي الأرباح', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('${totalEarnings.toStringAsFixed(0)} د.ع', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('$deliveryCount طلبات مكتملة', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(LucideIcons.star, color: Color(0xFFF59E0B), size: 28)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('التقييم', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$avgRating / 5 ($totalRatings تقييم)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (historyOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.package, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا يوجد طلبات مكتملة بعد', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: historyOrders.length,
      itemBuilder: (context, index) {
        final order = historyOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.checkCircle, color: Color(0xFF10b981), size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب #${order['id'].toString().substring(0, 5).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(_timeAgo(order['updated_at']), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Text('${order['delivery_fee'] ?? 0} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10b981))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: driverProfile?['avatar_url'] != null ? NetworkImage(driverProfile!['avatar_url']) : null,
                child: driverProfile?['avatar_url'] == null ? const Icon(LucideIcons.user, size: 40, color: Color(0xFF10b981)) : null,
              ),
              const SizedBox(height: 12),
              Text(driverProfile?['full_name'] ?? 'كابتن', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(driverProfile?['email'] ?? '', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(driverProfile?['vehicle_type'] == 'truck' ? 'مركبة شحن' : 'دراجة نارية', style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Column(
            children: [
              _settingsTile(LucideIcons.hash, 'رقم اللوحة', driverProfile?['plate_number'] ?? ''),
              const Divider(),
              _settingsTile(LucideIcons.smartphone, 'رقم الجوال', driverProfile?['phone'] ?? 'غير مضاف'),
              const Divider(),
              _settingsTile(LucideIcons.mail, 'البريد الإلكتروني', driverProfile?['email'] ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await supabase.auth.signOut();
              Get.offAll(() => const DriverLoginScreen());
            },
            icon: const Icon(LucideIcons.logOut, size: 18),
            label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF10b981)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: color)),
                const Spacer(),
                Icon(LucideIcons.trendingUp, size: 16, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(LucideIcons.star, size: 16, color: Color(0xFFF59E0B))),
                const Spacer(),
                Icon(LucideIcons.trendingUp, size: 16, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(avgRating, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                if (totalRatings > 0) ...[
                  const SizedBox(width: 4),
                  Padding(padding: const EdgeInsets.only(bottom: 2), child: Text('/5', style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w600))),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(totalRatings > 0 ? 'التقييم ($totalRatings)' : 'التقييم', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (!isOnline && activeOrders.isEmpty) {
      return ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.2), Center(child: Column(children: [Icon(LucideIcons.coffee, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), Text('استمتع بوقتك! لا توجد طلبات', style: TextStyle(color: Colors.grey.shade500, fontSize: 16))]))]);
    }
    if (activeOrders.isEmpty) {
      return ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.2), Center(child: Column(children: [Icon(LucideIcons.map, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), Text('جاري البحث عن طلبات...', style: TextStyle(color: Colors.grey.shade500, fontSize: 16))]))]);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) => _buildOrderCard(activeOrders[index]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    bool isDelivering = order['status'] == 'shipped';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: isDelivering ? const Color(0xFF10b981).withOpacity(0.3) : Colors.transparent, width: isDelivering ? 2 : 1),
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
                            Text('طلب #${order['id'].toString().substring(0, 5).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(_timeAgo(order['created_at']), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: isDelivering ? const Color(0xFF10b981).withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(isDelivering ? 'قيد التوصيل' : order['status'], style: TextStyle(color: isDelivering ? const Color(0xFF10b981) : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
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
                if (isDelivering) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await supabase.from('orders').update({'status': 'delivered'}).eq('id', order['id']);
                        fetchOrders();
                        Get.snackbar('تم التوصيل 🏆', 'أحسنت عملاً! تمت إضافة الأرباح لرصيدك.', backgroundColor: const Color(0xFF10b981), colorText: Colors.white, margin: const EdgeInsets.all(16));
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
}
