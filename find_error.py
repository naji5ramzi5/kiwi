import os
import re
import sys

root_dir = "."
error_msg = 'ERROR: Cannot read "image.png" (this model does not support image input)'
pattern = re.compile(re.escape(error_msg))

print(f"Searching for error message: {error_msg}")
print("=" * 60)

found_files = []

for root, dirs, files in os.walk(root_dir):
    # Skip hidden directories
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    
    for file in files:
        if file.endswith(('.dart', '.py', '.js', '.ts')):
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                    for i, line in enumerate(f, 1):
                        if pattern.search(line):
                            found_files.append((path, i, line.strip()))
            except Exception as e:
                continue

if found_files:
    print(f"Found {len(found_files)} occurrence(s):")
    for path, line_num, line_content in found_files:
        print(f"\nFile: {path}")
        print(f"Line {line_num}: {line_content}")
else:
    print("No files found containing the error message")