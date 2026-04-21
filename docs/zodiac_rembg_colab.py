# -*- coding: utf-8 -*-
"""zodiac_rembg.ipynb

# 이미 생성된 60갑자 WebP → 배경 제거 → 투명 WebP
# 기존 flutter_assets 폴더 구조 그대로 유지
"""

# %% [1] 설치
# !pip install -q rembg onnxruntime Pillow

# %% [2] 업로드
# zodiac_60ganji_assets.zip 을 Colab에 업로드 후 압축 해제
# !unzip -q zodiac_60ganji_assets.zip -d assets

# 또는 Google Drive에서:
# from google.colab import drive
# drive.mount('/content/drive')
# !cp -r "/content/drive/MyDrive/zodiac_60ganji_assets" assets

# %% [3] 배경 제거 (전체 WebP → 투명 WebP) =====================================

from rembg import remove
from PIL import Image
from pathlib import Path
import os

INPUT_DIR = "assets/zodiac"  # ← 압축 해제한 폴더 경로 맞춰서 수정
OUTPUT_DIR = "output"

# 모든 하위 폴더 포함해서 처리 (1x, 1.5x, 2.0x, 3.0x, onboarding/*)
all_webp = sorted(Path(INPUT_DIR).rglob("*.webp"))
print(f"Found {len(all_webp)} webp files")

for i, src in enumerate(all_webp):
    # 원본 폴더 구조 유지
    rel = src.relative_to(INPUT_DIR)
    dst = Path(OUTPUT_DIR) / rel
    dst.parent.mkdir(parents=True, exist_ok=True)

    if dst.exists():
        print(f"[{i+1}/{len(all_webp)}] SKIP {rel}")
        continue

    img = Image.open(src).convert("RGBA")
    result = remove(img)
    result.save(dst, "WEBP", quality=92)
    print(f"[{i+1}/{len(all_webp)}] OK   {rel}")

print(f"\nDone! {OUTPUT_DIR}/")

# %% [4] 미리보기 ==============================================================

import matplotlib.pyplot as plt

# 1x 에셋만 미리보기
preview_files = sorted(Path(OUTPUT_DIR).glob("zodiac_*.webp"))[:12]

if preview_files:
    cols = min(6, len(preview_files))
    rows = (len(preview_files) + cols - 1) // cols
    fig, axes = plt.subplots(rows, cols, figsize=(3*cols, 3*rows))
    if rows == 1: axes = [axes]
    for idx, f in enumerate(preview_files):
        ax = axes[idx // cols][idx % cols] if rows > 1 else axes[idx]
        ax.imshow(Image.open(f))
        ax.set_title(f.stem.replace("zodiac_",""), fontsize=8)
        ax.axis("off")
    plt.suptitle("Background Removed (transparent)", fontsize=14)
    plt.tight_layout()
    plt.show()

# %% [5] ZIP 다운로드 ==========================================================

import shutil
from google.colab import files

shutil.make_archive("zodiac_transparent", "zip", OUTPUT_DIR)
files.download("zodiac_transparent.zip")
