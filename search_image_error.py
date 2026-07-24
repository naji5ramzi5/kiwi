# Search for files containing image.png error message
import re

root_dir = "."
pattern = re.compile(r'ERROR: Cannot read "image\.png" \(this model does not support image input\)', re.IGNORECASE)

print("=" * 80)
print("Searching for 'image.png' error message in the codebase...")
print("=" * 80)

for root, dirs, files in os.walk(root_dir):
    # Skip hidden directories
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    
    for file in files:
        # Look for source files that might contain the error
        if file.endswith(('.dart', '.py', '.js', '.ts', '.md', '.txt', '.env')):
            file_path = os.path.join(root, file)
            
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # Check for the error message
                    if pattern.search(content):
                        print(f"\n{'='*60}")
                        print(f"FOUND in: {file_path}")
                        print(f"{'='*60}")
                        
                        # Show context around the error
                        lines = content.split('\n')
                        for i, line in enumerate(lines):
                            if pattern.search(line):
                                # Show the error line and context
                                start = max(0, i - 2)
                                end = min(len(lines), i + 3)
                                
                                for j in range(start, end):
                                    marker = ">> " if j == i else "   "
                                    print(f"{marker}{j+1:4d}: {lines[j]}")
                                break
                                
            except Exception:
                continue

print("\n" + "=" * 80)
print("Search complete")
print("=" * 80)