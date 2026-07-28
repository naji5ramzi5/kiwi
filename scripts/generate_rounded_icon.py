"""
Generate a rounded-corner .ico from the source PNG logo.

Usage:
    pip install Pillow
    python scripts/generate_rounded_icon.py

Output: overwrites branch_pos/windows/runner/resources/app_icon.ico
"""

from PIL import Image, ImageDraw
import os

SOURCE = os.path.join(os.path.dirname(__file__), '..', 'branch_pos', 'assets', 'images', 'logo.png')
OUTPUT = os.path.join(os.path.dirname(__file__), '..', 'branch_pos', 'windows', 'runner', 'resources', 'app_icon.ico')
CORNER_RADIUS = 15  # matches the UI ClipRRect value
ICO_SIZES = [16, 24, 32, 48, 64, 96, 128, 256]

def make_rounded(src_path, radius, target_sizes):
    src = Image.open(src_path).convert('RGBA')
    # create a rounded-corner mask
    frames = []
    for size in sorted(set(target_sizes)):
        img = src.resize((size, size), Image.LANCZOS)
        mask = Image.new('L', (size, size), 0)
        draw = ImageDraw.Draw(mask)
        r = int(radius * (size / max(src.width, 1)))
        draw.rounded_rectangle([(0, 0), (size, size)], radius=r, fill=255)
        result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        result.paste(img, (0, 0), mask)
        frames.append(result)
    return frames

def main():
    if not os.path.exists(SOURCE):
        print(f'Source not found: {SOURCE}')
        return
    frames = make_rounded(SOURCE, CORNER_RADIUS, ICO_SIZES)
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    # Save first frame as ICO (Pillow stores all frames in .ico)
    frames[0].save(OUTPUT, format='ICO', sizes=[(f.width, f.height) for f in frames])
    print(f'Rounded-corner .ico written to: {OUTPUT}')
    print(f'Sizes: {[f.width for f in frames]}')

if __name__ == '__main__':
    main()
