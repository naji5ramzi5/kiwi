"""
This script will search for image-related errors in the codebase.
"""
import os
import re

# The error message to search for
error_pattern = r'ERROR: Cannot read "image\.png" \(this model does not support image input\)'

root_dir = "."

print("=" * 70)
print("Searching for the image.png error message in the codebase")
print("=" * 70)

# Track what we find
files_with_error = []
total_files_checked = 0

for root, dirs, files in os.walk(root_dir):
    # Skip hidden directories and common build directories
    dirs[:] = [d for d in dirs if not d.startswith('.') and 
               d not in ['node_modules', '.git', '__pycache__', 'dist', 'build']]
    
    for file in files:
        # Check relevant file types
        if file.endswith(('.dart', '.py', '.js', '.ts', '.json', '.md', '.txt', '.env')):
            file_path = os.path.join(root, file)
            total_files_checked += 1
            
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # Search for the error message
                    if re.search(error_pattern, content, re.IGNORECASE):
                        files_with_error.append(file_path)
                        print(f"\n{'='*60}")
                        print(f"FOUND ERROR IN: {file_path}")
                        print(f"{'='*60}")
                        
                        # Show lines with the error
                        lines = content.split('\n')
                        for i, line in enumerate(lines):
                            if re.search(error_pattern, line, re.IGNORECASE):
                                # Show context around the error
                                start = max(0, i - 3)
                                end = min(len(lines), i + 4)
                                
                                for j in range(start, end):
                                    marker = ">> " if j == i else "   "
                                    print(f"{marker}{j+1:4d}: {lines[j]}")
                                break
                                
                        print()
                        
            except Exception as e:
                # Skip unreadable files
                continue

print("=" * 70)
print(f"Search complete!")
print(f"Files checked: {total_files_checked}")
print(f"Files containing the error: {len(files_with_error)}")
print("=" * 70)

if files_with_error:
    print("\nSuggested fixes:")
    print("1. Use a vision-capable model (GPT-4 Vision, Claude 3, Gemini Pro Vision)")
    print("2. Convert image to base64 before processing")
    print("3. Use a cloud storage service for images")
    print("4. Implement proper error handling with fallback images")
else:
    print("\nThe error message was not found in the codebase.")
    print("The error might be:")
    print("1. Generated dynamically at runtime")
    print("2. In a file not being checked")
    print("3. In a compiled binary or bundle")
    print("4. In a configuration or environment file")
