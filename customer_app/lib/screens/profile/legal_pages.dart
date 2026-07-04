import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
        title: Text('عن التطبيق', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 20)),
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
            Text('الإصدار 1.0.0', style: TextStyle(fontSize: 13, color: textSecColor, fontFamily: 'Cairo')),
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
                      Text('رسالتنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'في Kiwi، نسعى لتقديم أفضل تجربة تسوق للمواد الغذائية الطازجة بأعلى جودة وأسرع توصيل. نؤمن بأن الطعام الطازج هو حق للجميع، ونعمل على توصيله من المزرعة إلى مطبخك بأفضل الأسعار.',
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
                      Text('خدماتنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _serviceItem('منتجات طازجة يومياً', 'نوفر أجود أنواع الخضروات والفواكه واللحوم الطازجة يومياً'),
                  _serviceItem('توصيل سريع', 'نوصل طلبك لباب المنزل في أسرع وقت ممكن'),
                  _serviceItem('أسعار تنافسية', 'أفضل الأسعار مع عروض وخصومات مستمرة'),
                  _serviceItem('شاحنات الجملة', 'خدمة توصيل الطلبات الكبيرة بأسعار خاصة'),
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
                    Text('للتواصل والدعم', style: TextStyle(fontSize: 12, color: textSecColor, fontFamily: 'Cairo')),
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
        title: Text('سياسة الخصوصية', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 20)),
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
            _section('مقدمة', 'نحن في تطبيق Kiwi نلتزم بحماية خصوصيتك. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية معلوماتك الشخصية عند استخدامك لتطبيقنا وخدماتنا.'),
            _section('المعلومات التي نجمعها', 'نقوم بجمع المعلومات التالية:\n\n• الاسم الكامل ورقم الهاتف عند إنشاء الحساب\n• عنوان التوصيل والموقع الجغرافي\n• سجل الطلبات والتفضيلات\n• معلومات الدفع (يتم معالجتها بشكل آمن)\n• بيانات استخدام التطبيق لتحسين الخدمة'),
            _section('كيف نستخدم معلوماتك', 'نستخدم معلوماتك للأغراض التالية:\n\n• معالجة الطلبات وتوصيلها\n• تحسين تجربة المستخدم\n• التواصل معك بخصوص الطلبات\n• إرسال العروض والتحديثات (بموافقتك)\n• تحليل الأداء وتحسين الخدمات'),
            _section('حماية المعلومات', 'نتخذ إجراءات أمنية صارمة لحماية بياناتك الشخصية، بما في ذلك التشفير والتخزين الآمن على خوادم محمية، مع تقييد الوصول إلى المعلومات المصرح لهم فقط.'),
            _section('مشاركة المعلومات', 'لا نقوم بمشاركة معلوماتك الشخصية مع أطراف ثالثة إلا في الحالات التالية:\n\n• مع شركاء التوصيل لإتمام الطلبات\n• للامتثال للقوانين واللوائح\n• بحماية حقوقنا القانونية'),
            _section('خصوصية الأطفال', 'تطبيق Kiwi غير موجه للأطفال دون سن 18 عاماً. لا نقوم عمداً بجمع معلومات من الأطفال.'),
            _section('التعديلات على السياسة', 'قد نقوم بتحديث سياسة الخصوصية هذه من وقت لآخر. سنقوم بإشعارك بأي تغييرات جوهرية عبر البريد الإلكتروني أو إشعار داخل التطبيق.'),
            _section('اتصل بنا', 'إذا كان لديك أي استفسار حول سياسة الخصوصية، يمكنك التواصل معنا:\n\n• هاتف: 07886443032\n• واتساب: 07886443032\n• بريد إلكتروني: support@kiwi.iq'),
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