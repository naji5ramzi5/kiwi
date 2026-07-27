import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildAppInfo(),
                        const SizedBox(height: 20),
                        _buildCompanyCard(),
                        const SizedBox(height: 16),
                        _buildCreditsCard(),
                        const SizedBox(height: 16),
                        _buildLinksCard(context),
                        const SizedBox(height: 16),
                        _buildLicenseCard(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(LucideIcons.info, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حول التطبيق',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker),
            ),
            const SizedBox(height: 2),
            Text(
              'معلومات التطبيق والشركة',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              LucideIcons.leaf,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kiwi POS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'نظام نقطة البيع المتقدم',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'الإصدار 2.1.0 (Build 2026.07)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard() {
    return _buildSectionCard(
      title: 'معلومات الشركة',
      icon: LucideIcons.building2,
      iconColor: AppTheme.info,
      child: Column(
        children: [
          _buildInfoRow('الشركة', 'Kiwi Technologies Inc.'),
          const SizedBox(height: 12),
          _buildInfoRow('الموقع', 'بغداد، العراق'),
          const SizedBox(height: 12),
          _buildInfoRow('البريد الإلكتروني', 'support@kiwi-pos.com'),
          const SizedBox(height: 12),
          _buildInfoRow('الموقع الإلكتروني', 'www.kiwi-pos.com'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCreditsCard() {
    return _buildSectionCard(
      title: 'شكر وتقدير',
      icon: LucideIcons.heart,
      iconColor: AppTheme.error,
      child: Column(
        children: [
          _buildCreditItem('flutter', 'Flutter', 'إطار عمل واجهة المستخدم'),
          const SizedBox(height: 10),
          _buildCreditItem('supabase', 'Supabase', 'البنية التحتية للخلفية'),
          const SizedBox(height: 10),
          _buildCreditItem('get_x', 'GetX', 'إدارة الحالة وتنقل'),
          const SizedBox(height: 10),
          _buildCreditItem('lucide', 'Lucide Icons', 'مجموعة الأيقونات'),
        ],
      ),
    );
  }

  Widget _buildCreditItem(String icon, String name, String description) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryLighter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.code2, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    return _buildSectionCard(
      title: 'روابط مفيدة',
      icon: LucideIcons.externalLink,
      iconColor: AppTheme.accent,
      child: Column(
        children: [
          _buildLinkItem(
            LucideIcons.globe,
            'الموقع الإلكتروني',
            'www.kiwi-pos.com',
            () => _launchUrl('https://www.kiwi-pos.com'),
          ),
          const SizedBox(height: 10),
          _buildLinkItem(
            LucideIcons.lifeBuoy,
            'الدعم الفني',
            'support@kiwi-pos.com',
            () => _launchUrl('mailto:support@kiwi-pos.com'),
          ),
          const SizedBox(height: 10),
          _buildLinkItem(
            LucideIcons.bookOpen,
            'التوثيق',
            'docs.kiwi-pos.com',
            () => _launchUrl('https://docs.kiwi-pos.com'),
          ),
          const SizedBox(height: 10),
          _buildLinkItem(
            LucideIcons.github,
            'GitHub',
            'github.com/kiwi-pos',
            () => _launchUrl('https://github.com/kiwi-pos'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              const Spacer(),
              Icon(LucideIcons.chevronLeft, size: 18, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseCard() {
    return _buildSectionCard(
      title: 'الرخصة',
      icon: LucideIcons.fileText,
      iconColor: AppTheme.secondary,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MIT License',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDarker),
            ),
            const SizedBox(height: 10),
            Text(
              'Copyright (c) 2026 Kiwi Technologies Inc.\n\n'
              'يُمنح بموجب هذه الرخصة لجميع الأشخاص_FREE使用权_الحق في الحصول على نسخة '
              'من هذا البرنامج وجميع ملفات التوثيق المرتبطة به، دون تقييد، بما في ذلك '
              'دون حدود الحقوق لاستخدام النسخ والنسخ والدمج والتعديل والتوزيع.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              '© 2026 Kiwi Technologies Inc. جميع الحقوق محفوظة.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
