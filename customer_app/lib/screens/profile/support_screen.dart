import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  final String supportPhone = '07886443032';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final cardBg = isDark ? const Color(0xFF1E291F) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('الدعم الفني', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF86EFAC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF22C55E).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipOval(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          'assets/images/kwi.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(LucideIcons.headphones, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'كيف يمكننا مساعدتك؟',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نحن هنا لخدمتك على مدار الساعة طوال أيام الأسبوع',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // WhatsApp Support - Primary
            _buildWhatsAppCard(context, cardBg, textColor, isDark),
            const SizedBox(height: 16),

            // Contact Methods
            Text(
              'طرق التواصل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context, cardBg, textColor, textSecColor, isDark,
              icon: Icons.phone,
              color: Colors.blue,
              title: 'اتصال هاتفي',
              subtitle: supportPhone,
              onTap: () => launchUrl(Uri.parse('tel://$supportPhone')),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context, cardBg, textColor, textSecColor, isDark,
              icon: Icons.email,
              color: Colors.orange,
              title: 'البريد الإلكتروني',
              subtitle: 'support@kiwi.iq',
              onTap: () => launchUrl(Uri.parse('mailto:support@kiwi.iq')),
            ),
            const SizedBox(height: 16),

            // App info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معلومات التطبيق',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(context, 'الإصدار', '1.0.0'),
                  const SizedBox(height: 6),
                  _buildInfoRow(context, 'آخر تحديث', 'يونيو 2026'),
                  const SizedBox(height: 6),
                  _buildInfoRow(context, 'المطور', 'Kiwi Team'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 24/7 Availability
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.clock, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'الدعم الفني متاح 24/7',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A), fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppCard(BuildContext context, Color cardBg, Color textColor, bool isDark) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://wa.me/$supportPhone?text=مرحباً، أحتاج إلى المساعدة في تطبيق Kiwi.')),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF86EFAC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF22C55E).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/whatsapp.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.chat, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تواصل مع الدعم الفني',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'الرد خلال دقائق عبر واتساب',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, Color cardBg, Color textColor, Color textSecColor, bool isDark, {
    required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: textSecColor, fontFamily: 'Cairo')),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary, fontFamily: 'Cairo')),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary, fontFamily: 'Cairo')),
      ],
    );
  }
}