import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Colors.orangeAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                'غير مصرح بالدخول',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هذا التطبيق مخصص للمدراء وموظفي التشغيل فقط',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout),
                label: Text(
                  'تسجيل الخروج',
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}