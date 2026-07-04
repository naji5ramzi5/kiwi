import os

# Fix favorites_controller.dart
p1 = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\controllers\favorites_controller.dart'
content1 = open(p1, encoding='utf-8').read()
src1 = "ever(authController.rxIsLoggedIn, (bool loggedIn) {"
dst1 = "ever(authController.currentUser, (user) {"
content1 = content1.replace(src1, dst1)
src1_2 = "if (loggedIn) {"
dst1_2 = "if (user != null) {"
content1 = content1.replace(src1_2, dst1_2)
open(p1, 'w', encoding='utf-8').write(content1)

# Fix order_tracking_map_screen.dart
p2 = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\screens\order_tracking_map_screen.dart'
content2 = open(p2, encoding='utf-8').read()

src2 = """class _DropPin extends StatelessWidget {
  const _DropPin();

  @override
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
    }
    return Column("""

dst2 = """class _DropPin extends StatelessWidget {
  const _DropPin();

  @override
  Widget build(BuildContext context) {
    return Column("""

# But the file might have encoding issues with Arabic letters. I will do a regex replacement that matches the pattern.
import re

content2 = re.sub(
    r'class _DropPin extends StatelessWidget \{\s*const _DropPin\(\);\s*@override\s*Widget build\(BuildContext context\) \{.*?return Column\(',
    r'class _DropPin extends StatelessWidget {\n  const _DropPin();\n\n  @override\n  Widget build(BuildContext context) {\n    return Column(',
    content2, flags=re.DOTALL
)

open(p2, 'w', encoding='utf-8').write(content2)

print("Files fixed.")
