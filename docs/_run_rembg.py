from rembg import remove
from PIL import Image
from pathlib import Path

INPUT_DIR = Path(r"D:\Data\20_Flutter\01_SJ\frontend\docs\zodiac_60ganji_assets\zodiac")
OUTPUT_DIR = Path(r"D:\Data\20_Flutter\01_SJ\frontend\docs\zodiac_60ganji_transparent\zodiac")

all_webp = sorted(INPUT_DIR.rglob("*.webp"))
print(f"Found {len(all_webp)} webp files")

for i, src in enumerate(all_webp):
    rel = src.relative_to(INPUT_DIR)
    dst = OUTPUT_DIR / rel
    dst.parent.mkdir(parents=True, exist_ok=True)

    if dst.exists():
        print(f"[{i+1}/{len(all_webp)}] SKIP {rel}")
        continue

    img = Image.open(src).convert("RGBA")
    result = remove(img)
    result.save(dst, "WEBP", quality=92)
    print(f"[{i+1}/{len(all_webp)}] OK   {rel}")

print(f"\nDone! -> {OUTPUT_DIR}")
