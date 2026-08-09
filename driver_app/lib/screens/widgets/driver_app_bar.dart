import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../notification_center_screen.dart';

class DriverAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic>? driverProfile;
  final bool isOnline;
  final ValueChanged<bool> onToggleOnline;
  final String? branchName;

  const DriverAppBar({
    super.key,
    required this.driverProfile,
    required this.isOnline,
    required this.onToggleOnline,
    this.branchName,
  });

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context) {
    final vehicleIcon = driverProfile?['vehicle_type'] == 'truck'
        ? LucideIcons.truck
        : driverProfile?['vehicle_type'] == 'car'
            ? LucideIcons.car
            : driverProfile?['vehicle_type'] == 'van'
                ? LucideIcons.bus
                : LucideIcons.bike;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B7A4B), Color(0xFF12A36D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0B7A4B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.white, Color(0xFFD1FAE5)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF0F172A),
                      backgroundImage: driverProfile?['avatar_url'] != null
                          ? NetworkImage(driverProfile!['avatar_url'])
                          : null,
                      child: driverProfile?['avatar_url'] == null
                          ? const Icon(LucideIcons.user,
                              color: Colors.white, size: 26)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? const Color(0xFF34D399)
                            : const Color(0xFF9CA3AF),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'أهلاً بك',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xD9FFFFFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            driverProfile?['full_name'] ?? 'كابتن',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(vehicleIcon,
                              size: 13, color: const Color(0xFFD1FAE5)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              driverProfile?['plate_number'] ??
                                  'جاهز للانطلاق',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (branchName != null) ...[
                            Container(
                              width: 1,
                              height: 12,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              color: Colors.white.withOpacity(0.35),
                            ),
                            const Icon(LucideIcons.store,
                                size: 12, color: Color(0xFFD1FAE5)),
                            const SizedBox(width: 4),
                            Text(
                              branchName!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationCenterScreen()),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  child: const Icon(LucideIcons.bell,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFFFDE68A).withOpacity(0.22)
                      : Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isOnline
                        ? const Color(0xFFFDE047)
                        : Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOnline ? 'متصل' : 'أوفلاين',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: const Color(0xFFFDE68A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: isOnline,
                        activeColor: const Color(0xFF34D399),
                        activeTrackColor: const Color(0xFF0B7A4B),
                        inactiveThumbColor: const Color(0xFF9CA3AF),
                        inactiveTrackColor: Colors.white.withOpacity(0.35),
                        onChanged: onToggleOnline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}