import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/driver_login_screen.dart';

class DriverSettingsTab extends StatelessWidget {
  final Map<String, dynamic>? driverProfile;

  const DriverSettingsTab({super.key, required this.driverProfile});

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
}
