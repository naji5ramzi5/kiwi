import os
p = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\screens\order_tracking_map_screen.dart'
content = open(p, encoding='utf-8').read()

import_str = "import 'package:url_launcher/url_launcher.dart';\n"
if "package:url_launcher/url_launcher.dart" not in content:
    content = content.replace("import 'package:get/get.dart';", "import 'package:get/get.dart';\n" + import_str)

# Constructor
src_construct = """class OrderTrackingMapScreen extends StatefulWidget {
  const OrderTrackingMapScreen({super.key});"""

dst_construct = """class OrderTrackingMapScreen extends StatefulWidget {
  final bool hasActiveOrder;
  const OrderTrackingMapScreen({super.key, this.hasActiveOrder = true});"""
content = content.replace(src_construct, dst_construct)


src_build = """  @override
  Widget build(BuildContext context) {"""

dst_build = """  @override
  Widget build(BuildContext context) {
    if (!widget.hasActiveOrder) {
      return Scaffold(
        appBar: AppBar(title: const Text('تتبع الطلب', style: TextStyle(fontFamily: 'Cairo')), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('لا يوجد طلب نشط حالياً', style: TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('قم بإتمام طلب جديد لتتبعه هنا.', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
            ],
          ),
        ),
      );
    }"""
content = content.replace(src_build, dst_build)


# Buttons
src_buttons = """                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.message_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),"""

dst_buttons = """                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse("tel://07886443032")),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.call, color: Colors.blue, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse("https://wa.me/07886443032")),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                            ),
                          ),
                        ],
                      ),"""
content = content.replace(src_buttons, dst_buttons)

open(p, 'w', encoding='utf-8').write(content)
