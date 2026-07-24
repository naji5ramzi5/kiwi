import os

# Error message to search for
error_message = 'ERROR: Cannot read "image.png" (this model does not support image input)'

# Root directory to search
root_dir = "C:/Users/IRAQ SOFT/Desktop/kiwi-code"

print(f"Searching for error message in: {root_dir}")
print("=" * 60)

# Track if we found any matches
found_count = 0

# Walk through all files in the directory structure
for root, dirs, files in os.walk(root_dir):
    # Skip hidden directories
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    
    # Check each file
    for file in files:
        # Look for files that might contain the error
        if file.endswith(('.dart', '.py', '.js', '.ts', '.log', '.txt')):
            file_path = os.path.join(root, file)
            
            try:
                # Try to read the file
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                    # Check if the error message is present
                    if error_message in content:
                        found_count += 1
                        print(f"\n{'='*40}")
                        print(f"FOUND in: {file_path}")
                        print(f"{'='*40}")
                        
                        # Show context around the error
                        lines = content.split('\n')
                        for i, line in enumerate(lines):
                            if error_message in line:
                                # Show the error and a few lines before/after
                                start_line = max(0, i - 2)
                                end_line = min(len(lines), i + 3)
                                
                                for j in range(start_line, end_line):
                                    prefix = ">> " if j == i else "   "
                                    print(f"{prefix}{j+1:4d}: {lines[j]}")
                                break
                        
            except Exception as e:
                # Skip files that can't be read
                continue

print("\n" + "=" * 60)
if found_count == 0:
    print("ERROR MESSAGE NOT FOUND in any files!")
else:
    print(f"Total occurrences found: {found_count}")
    print("=" * 60)
    print("\nThis error suggests that the application is trying to read")
    print('an image file using a model that does not support image input.')
    print("Possible causes:")
    print("1. Using a text-only LLM for image analysis")
    print("2. Incorrect configuration or path")
    print("3. Missing dependencies or libraries")
    print("\nSolutions:")
    print("1. Use an image-capable model (e.g., GPT-4 Vision)")
    print("2. Convert the image to base64 or text first")
    print("3. Use the appropriate AI library for vision tasks")
    print("4. Check if the model API supports image input")