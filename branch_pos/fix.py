lines = open('pubspec.yaml', 'r').readlines()[:107]
lines.extend([
    'flutter_icons:\n',
    '  windows:\n',
    '    generate: true\n',
    '    image_path: "C:/Users/IRAQ SOFT/Desktop/fresh-app/image/fresh-r.png"\n',
    '    icon_size: 256\n'
])
open('pubspec.yaml', 'w').writelines(lines)
