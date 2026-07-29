import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../notification_center_screen.dart';

class DriverAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic>? driverProfile;
  final bool isOnline;
  final ValueChanged<bool> onToggleOnline;

  const DriverAppBar({
    super.key,
    required this.driverProfile,
    required this.isOnline,
    required this.onToggleOnline,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Icon(LucideIcons.bell, color: Color(0xFF10b981), size: 24),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF10b981).withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isOnline ? 'متصل' : 'أوفلاين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOnline ? const Color(0xFF10b981) : Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: isOnline,
                        activeColor: const Color(0xFF10b981),
                        activeTrackColor: const Color(0xFF10b981).withOpacity(0.3),
                        onChanged: onToggleOnline,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
