import os
import re

p = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\screens\home_screen.dart'
content = open(p, encoding='utf-8').read()

src_state = """class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.put(HomeController());
  final ScrollController _scrollController = ScrollController();
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  bool _isScrolled = false;
  final RxBool hasNewNotification = true.obs;
  final RxInt notificationCount = 3.obs;"""

dst_state = """class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.put(HomeController());
  final ScrollController _scrollController = ScrollController();
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  bool _isScrolled = false;
  final RxBool hasNewNotification = true.obs;
  final RxInt notificationCount = 3.obs;
  final RxList<Map<String, String>> notifications = <Map<String, String>>[
    {'title': 'المندوب في الطريق!', 'body': 'المندوب على بُعد 5 دقائق منك', 'time': '5 دقائق'},
    {'title': '✅ تم تأكيد طلبك', 'body': 'طلبك #1032 قيد التجهيز في الفرع', 'time': '20 دقيقة'},
    {'title': '🎁 عرض خاص لك!', 'body': 'خصم 15% على الخضروات الطازجة اليوم فقط', 'time': 'أمس'},
  ].obs;"""

content = content.replace(src_state, dst_state)

src_shownotif = """  void _showNotifications(BuildContext context) {
    hasNewNotification.value = false;
    notificationCount.value = 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإشعارات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 20,
                        color: isDark ? Colors.white70 : AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildNotificationItem(
                    'المندوب في الطريق!',
                    'المندوب على بُعد 5 دقائق منك',
                    '5 دقائق',
                    isDark,
                  ),
                  _buildNotificationItem(
                    '✅ تم تأكيد طلبك',
                    'طلبك #1032 قيد التجهيز في الفرع',
                    '20 دقيقة',
                    isDark,
                  ),
                  _buildNotificationItem(
                    '🎁 عرض خاص لك!',
                    'خصم 15% على الخضروات الطازجة اليوم فقط',
                    'أمس',
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }"""

dst_shownotif = """  void _showNotifications(BuildContext context) {
    hasNewNotification.value = false;
    notificationCount.value = 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإشعارات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                Row(
                  children: [
                    Obx(() {
                      if (notifications.isEmpty) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () {
                          notifications.clear();
                        },
                        child: Text('مسح الكل', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                      );
                    }),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 20,
                            color: isDark ? Colors.white70 : AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(() {
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bellOff, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('لا توجد إشعارات', style: TextStyle(fontSize: 18, color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _buildNotificationItem(
                      notif['title']!,
                      notif['body']!,
                      notif['time']!,
                      isDark,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }"""

content = content.replace(src_shownotif, dst_shownotif)
open(p, 'w', encoding='utf-8').write(content)
