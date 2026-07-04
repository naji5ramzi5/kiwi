import os
p = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\screens\cart\cart_screen.dart'
content = open(p, encoding='utf-8').read()

src = "      body: Obx(() {"
dst = "      body: Obx(() {\n        return PopScope(\n          canPop: !cartController.isCountingDown.value,\n          child: Builder(builder: (context) {"

src2 = """              ),
            ),
          ],
        );
      }),
    );"""

dst2 = """              ),
            ),
          ],
        );
          }),
        );
      }),
    );"""

if "PopScope" not in content:
    content = content.replace(src, dst)
    content = content.replace(src2, dst2)
    open(p, 'w', encoding='utf-8').write(content)
