import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/driver_login_screen.dart';
import '../main.dart';

class ApprovalWaitingScreen extends StatefulWidget {
  const ApprovalWaitingScreen({super.key});

  @override
  State<ApprovalWaitingScreen> createState() => _ApprovalWaitingScreenState();
}

class _ApprovalWaitingScreenState extends State<ApprovalWaitingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _checkApprovalPeriodically();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkApprovalPeriodically() async {
    final supabase = Supabase.instance.client;
    supabase.channel('public:profiles').onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: supabase.auth.currentUser!.id),
      callback: (payload) {
        if (payload.newRecord['is_approved'] == true) {
          Get.offAll(() => const DriverApp());
        }
      },
    ).subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.2), blurRadius: 30, spreadRadius: 10)],
                      ),
                      child: const Icon(LucideIcons.clock, size: 80, color: Color(0xFF10b981)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text('جاري معالجة طلبك ⏳', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                  const SizedBox(height: 16),
                  Text(
                    'أهلاً بك في عائلة Fresh! طلب انضمامك قيد المراجعة من قبل الإدارة. ستتمكن من استلام الطلبات فور الموافقة على حسابك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
