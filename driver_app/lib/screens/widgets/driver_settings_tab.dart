import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/driver_login_screen.dart';

class DriverSettingsTab extends StatelessWidget {
  final Map<String, dynamic>? driverProfile;
  final String? branchName;
  final String? joinedAt;
  final int employeeTotalDeliveries;
  final bool isOnline;
  final double totalEarnings;
  final int dailyDeliveries;
  final int monthlyDeliveries;
  final double todayEarnings;
  final double monthlyEarnings;

  const DriverSettingsTab({
    super.key,
    required this.driverProfile,
    this.branchName,
    this.joinedAt,
    this.employeeTotalDeliveries = 0,
    this.isOnline = false,
    this.totalEarnings = 0,
    this.dailyDeliveries = 0,
    this.monthlyDeliveries = 0,
    this.todayEarnings = 0,
    this.monthlyEarnings = 0,
  });

  String _resolvePhone() {
    final profilePhone = driverProfile?['phone'];
    if (profilePhone != null && profilePhone.toString().isNotEmpty) return profilePhone.toString();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metaPhone = user.userMetadata?['phone'];
      if (metaPhone != null && metaPhone.toString().isNotEmpty) return metaPhone.toString();
      if (user.phone != null && user.phone!.isNotEmpty) return user.phone!;
    }
    return '';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'غير محددة';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF10b981).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.circleDot, size: 14, color: isOnline ? const Color(0xFF10b981) : Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'متصل الآن' : 'غير متصل',
                      style: TextStyle(color: isOnline ? const Color(0xFF10b981) : Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  driverProfile?['vehicle_type'] == 'truck'
                      ? 'شاحنة'
                      : driverProfile?['vehicle_type'] == 'car'
                          ? 'سيارة'
                          : driverProfile?['vehicle_type'] == 'van'
                              ? 'فان'
                              : 'دراجة نارية',
                  style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard('بيانات الموظف', Column(children: [
          _settingsTile(LucideIcons.building2, 'الفرع', branchName ?? 'غير محدد'),
          const Divider(),
          _settingsTile(LucideIcons.hash, 'رقم اللوحة', driverProfile?['plate_number'] ?? ''),
          const Divider(),
          _settingsTile(LucideIcons.smartphone, 'رقم الجوال', _resolvePhone()),
          const Divider(),
          _settingsTile(LucideIcons.mail, 'البريد الإلكتروني', driverProfile?['email'] ?? ''),
          const Divider(),
          _settingsTile(LucideIcons.calendarDays, 'تاريخ الانضمام', _formatDate(joinedAt)),
          const Divider(),
          _settingsTile(LucideIcons.packageCheck, 'إجمالي عمليات التوصيل', '$employeeTotalDeliveries'),
          const Divider(),
          _settingsTile(
            LucideIcons.shieldCheck,
            'حالة الحساب',
            driverProfile?['is_approved'] == true ? 'مقبول ✅' : 'بانتظار الموافقة ⏳',
          ),
        ])),
        const SizedBox(height: 16),
        _sectionCard('الأرباح',
          _earningsTile(dailyDeliveries, monthlyDeliveries, employeeTotalDeliveries, totalEarnings, todayEarnings, monthlyEarnings),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
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

  Widget _sectionCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _earningsTile(int daily, int monthly, int total, double amount, double todayAmount, double monthlyAmount) {
    return Row(
      children: [
        Expanded(
          child: _statBox('توصيلات اليوم', '$daily', const Color(0xFF10b981)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statBox('توصيلات الشهر', '$monthly', const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statBox('إجمالي التوصيلات', '$total', const Color(0xFF8B5CF6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statBox('الأرباح اليوم', '${todayAmount.toStringAsFixed(0)} د.ع', const Color(0xFF10b981)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statBox('الأرباح الشهر', '${monthlyAmount.toStringAsFixed(0)} د.ع', const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statBox('إجمالي الأرباح', '${amount.toStringAsFixed(0)} د.ع', const Color(0xFFF59E0B)),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
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
          Text(value.isNotEmpty ? value : 'غير مضاف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: value.isNotEmpty ? Colors.black : Colors.grey.shade400)),
        ],
      ),
    );
  }
}