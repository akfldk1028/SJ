"""Upload zodiac animal images to Supabase Storage bucket 'zodiac-animals'"""

import os
import requests
from pathlib import Path

SUPABASE_URL = "https://kfciluyxkomskyxjaeat.supabase.co"
SUPABASE_KEY = "sb_publishable_BeKozV2EEX18nI8VgCC7dw_zxThHlTN"
BUCKET = "zodiac-animals"

BASE_DIR = Path(r"D:\Data\20_Flutter\01_SJ\frontend\docs\zodiac_60ganji_transparent\zodiac")

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "image/webp",
}


def upload_file(local_path: Path, storage_path: str):
    """Upload a single file to Supabase Storage"""
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{storage_path}"

    with open(local_path, "rb") as f:
        data = f.read()

    # Try upload (upsert)
    resp = requests.post(
        url,
        headers={**HEADERS, "x-upsert": "true"},
        data=data,
    )

    if resp.status_code in (200, 201):
        return True
    else:
        print(f"    ERR {resp.status_code}: {resp.text[:100]}")
        return False


def main():
    # 1x base images (128px) → root of bucket
    base_files = sorted(BASE_DIR.glob("zodiac_*.webp"))
    print(f"[1/2] Uploading {len(base_files)} base images (1x)...")

    ok, fail = 0, 0
    for i, f in enumerate(base_files):
        print(f"  [{i+1}/{len(base_files)}] {f.name}...", end=" ", flush=True)
        if upload_file(f, f.name):
            print("OK")
            ok += 1
        else:
            fail += 1
    print(f"  Base: {ok} OK, {fail} FAIL\n")

    # 2.0x onboarding images (512px) → large/ folder
    large_dir = BASE_DIR / "onboarding" / "2.0x"
    if large_dir.exists():
        large_files = sorted(large_dir.glob("zodiac_*.webp"))
        print(f"[2/2] Uploading {len(large_files)} large images (onboarding 512px)...")

        ok2, fail2 = 0, 0
        for i, f in enumerate(large_files):
            storage_name = f.name.replace("_large", "")  # zodiac_fire_horse_large.webp → zodiac_fire_horse.webp
            print(f"  [{i+1}/{len(large_files)}] large/{storage_name}...", end=" ", flush=True)
            if upload_file(f, f"large/{storage_name}"):
                print("OK")
                ok2 += 1
            else:
                fail2 += 1
        print(f"  Large: {ok2} OK, {fail2} FAIL\n")

    print("Done!")
    print(f"Public URL: {SUPABASE_URL}/storage/v1/object/public/{BUCKET}/zodiac_fire_horse.webp")


if __name__ == "__main__":
    main()
