import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
        title: Text('about_app_title'.tr, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withOpacity(0.15), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/kwi.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, size: 50, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Kiwi', style: TextStyle(fontSize: 32, 
                            fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo', letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('version_label'.tr, style: TextStyle(fontSize: 13, color: textSecColor, fontFamily: 'Cairo')),
            const SizedBox(height: 32),

            // Mission
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.leaf, size: 20, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Text('our_mission'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'mission_desc'.tr,
                    style: TextStyle(fontSize: 14, color: textSecColor, height: 1.7, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Services
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.shoppingBag, size: 20, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Text('our_services'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _serviceItem('fresh_products_daily'.tr, 'fresh_products_daily_desc'.tr),
                  _serviceItem('fast_delivery'.tr, 'fast_delivery_desc'.tr),
                  _serviceItem('competitive_prices'.tr, 'competitive_prices_desc'.tr),
                  _serviceItem('bulk_trucks'.tr, 'bulk_delivery_desc'.tr),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel://07886443032')),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.phone, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text('07886443032', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontFamily: 'Cairo')),
                    const SizedBox(width: 8),
                    Text('for_contact_support'.tr, style: TextStyle(fontSize: 12, color: textSecColor, fontFamily: 'Cairo')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'Cairo')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('privacy_policy'.tr, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('privacy_intro'.tr, 'privacy_intro_body'.tr),
            _section('info_collect_title'.tr, 'info_collect_body'.tr),
            _section('how_we_use_title'.tr, 'how_we_use_body'.tr),
            _section('info_protection_title'.tr, 'info_protection_body'.tr),
            _section('info_sharing_title'.tr, 'info_sharing_body'.tr),
            _section('children_privacy_title'.tr, 'children_privacy_body'.tr),
            _section('policy_amendments_title'.tr, 'policy_amendments_body'.tr),
            _section('contact_us'.tr, 'contact_us_body'.tr),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    final isDark = Get.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1F2937), fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary, height: 1.7, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }
}