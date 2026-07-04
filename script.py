import os
import re

p = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\screens\home_screen.dart'
content = open(p, encoding='utf-8').read()

match = re.search(r'void _showNotifications\(.*?\}\);', content, re.DOTALL)
if match:
    print(match.group(0))
else:
    print("Not found with simple regex, extracting lines.")
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if "_showNotifications" in line:
            print('\n'.join(lines[i:i+60]))
            break
