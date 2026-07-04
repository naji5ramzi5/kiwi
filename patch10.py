import os
p = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\controllers\cart_controller.dart'
content = open(p, encoding='utf-8').read()

if "var isCountingDown = false.obs;" not in content:
    content = content.replace("var isPlacingOrder = false.obs;", "var isPlacingOrder = false.obs;\n  var isCountingDown = false.obs;")
    open(p, 'w', encoding='utf-8').write(content)
