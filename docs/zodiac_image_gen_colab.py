# -*- coding: utf-8 -*-
"""zodiac_60ganji_gen.ipynb

# 60갑자 수호동물 이미지 생성기
# 12동물 × 5오행 = 60장
# Dong Hyeon Kim
"""

# %% [1] Setup ================================================================
# %pip install -U -q "google-genai>=1.40.0"

from google.colab import userdata

GOOGLE_API_KEY = userdata.get('GOOGLE_API_KEY')

from google import genai
from google.genai import types
from IPython.display import display, Markdown
import pathlib, os, time

client = genai.Client(api_key=GOOGLE_API_KEY)
MODEL_ID = "gemini-2.5-flash-image"

def display_response(response):
  for part in response.parts:
    if part.text:
      display(Markdown(part.text))
    elif image := part.as_image():
      image.show()

def save_image(response, path):
  for part in response.parts:
    if image := part.as_image():
      image.save(path)

os.makedirs("zodiac", exist_ok=True)

# %% [2] 60갑자 데이터 =========================================================
#
# 천간(5색):  목=푸른  화=붉은  토=황금  금=흰  수=검은
# 지지(12동물): 쥐 소 호랑이 토끼 용 뱀 말 양 원숭이 닭 개 돼지
#
# 총 60조합: 푸른쥐, 붉은쥐, ... 검은돼지

ELEMENTS = {
    "wood":  {"ko": "푸른",  "en": "Blue",
              "color_desc": "blue-green jade-colored fur/scales with subtle emerald glow, green-tinted accessories"},
    "fire":  {"ko": "붉은",  "en": "Red",
              "color_desc": "fiery crimson and scarlet fur/scales with warm flame-like glow, red-tinted accessories"},
    "earth": {"ko": "황금",  "en": "Golden",
              "color_desc": "rich golden and amber fur/scales with warm earthy glow, gold-tinted accessories"},
    "metal": {"ko": "흰",    "en": "White",
              "color_desc": "pure white and silver fur/scales with cool metallic sheen, silver accessories"},
    "water": {"ko": "검은",  "en": "Black",
              "color_desc": "deep black and midnight blue fur/scales with cool aquatic glow, dark blue accessories"},
}

ANIMALS = [
    {"id": "rat",     "animal": "mouse",        "desc": "Small round ears, long thin tail, holding a tiny golden coin, clever curious expression with tilted head."},
    {"id": "ox",      "animal": "baby ox",       "desc": "Small curved horns, sturdy body, wearing a tiny flower crown, gentle determined expression with warm smile."},
    {"id": "tiger",   "animal": "baby tiger",    "desc": "Bold stripes, white chest fluff, tiny fangs peeking out, confident playful expression, wearing a small cape."},
    {"id": "rabbit",  "animal": "bunny",         "desc": "Long floppy ears, fluffy fur, holding a small cherry blossom branch, sweet gentle expression with soft blush on cheeks."},
    {"id": "dragon",  "animal": "baby dragon",   "desc": "Small wings on back, tiny horns, fluffy mane, proud confident expression, small flame hovering above one claw."},
    {"id": "snake",   "animal": "snake",         "desc": "Elegant scales, small crown-like marking on head, tiny forked tongue peeking out playfully, mysterious wise expression. Coiled body with upright head."},
    {"id": "horse",   "animal": "pony",          "desc": "Flowing mane and tail, star marking on forehead, strong little hooves, energetic joyful expression, wearing a tiny scarf blowing in the wind."},
    {"id": "sheep",   "animal": "lamb",          "desc": "Fluffy curly wool, tiny curved horns with flower decoration, pink inner ears, dreamy artistic expression, holding a small paintbrush."},
    {"id": "monkey",  "animal": "monkey",        "desc": "Peach face, curly tail, mischievous playful grin, wearing a tiny crown tilted to the side, juggling a small star."},
    {"id": "rooster", "animal": "baby rooster",  "desc": "Bright comb, colorful tail feathers, golden beak, proud upright posture, confident honest expression."},
    {"id": "dog",     "animal": "puppy",         "desc": "Fluffy fur, floppy ears, wagging tail, loyal happy expression with tongue slightly out, wearing a tiny heart-shaped collar tag."},
    {"id": "pig",     "animal": "piglet",        "desc": "Curly tail, round snout with rosy cheeks, cheerful generous expression, holding a small four-leaf clover, wearing tiny overalls."},
]

BASE_PROMPT = """An ultra-cute kawaii 3D chibi {animal} character in Pop Mart blind box figurine style.
2-head-tall proportions, very rounded soft body, extremely big sparkly anime eyes with star-shaped highlights, glossy vinyl toy texture, strong blush on cheeks.
The character has {color_desc}.
{desc}
Soft pastel color palette, soft dreamy studio lighting, C4D 3D render. Pure white background.
Centered composition, front-facing, adorable friendly welcoming pose.
High quality, clean edges, professional character design, cute mascot style.
Single character only, no text, no watermark, no shadow on background."""

# 전체 조합 생성
ALL_COMBOS = []
for elem_key, elem in ELEMENTS.items():
    for a in ANIMALS:
        ALL_COMBOS.append({
            "filename": f"zodiac_{elem_key}_{a['id']}.png",  # zodiac_fire_horse.png
            "label": f"{elem['ko']} {a['id']}",               # 붉은 horse
            "element": elem_key,
            "animal": a,
            "prompt": BASE_PROMPT.format(
                animal=a["animal"],
                color_desc=elem["color_desc"],
                desc=a["desc"],
            ),
        })

print(f"Total combos: {len(ALL_COMBOS)}")
for e_key in ELEMENTS:
    names = [c['animal']['id'] for c in ALL_COMBOS if c['element'] == e_key]
    print(f"  {ELEMENTS[e_key]['ko']:3s}({e_key:5s}): {', '.join(names)}")

# %% [3] 프롬프트 확인 =========================================================

review_element = "fire"  # @param ["wood", "fire", "earth", "metal", "water"]
review_animal = "horse"   # @param ["rat","ox","tiger","rabbit","dragon","snake","horse","sheep","monkey","rooster","dog","pig"]

combo = next(c for c in ALL_COMBOS if c['element'] == review_element and c['animal']['id'] == review_animal)
print(f"=== {combo['filename']} ===")
print(combo['prompt'])

# %% [4] 전체 생성 (60장) ======================================================
# 이미 있는 파일은 SKIP, rate limit 대비 2초 간격

results = {}
total = len(ALL_COMBOS)

for i, combo in enumerate(ALL_COMBOS):
    out_path = f"zodiac/{combo['filename']}"

    if os.path.exists(out_path):
        print(f"[{i+1:2d}/{total}] SKIP  {combo['filename']}")
        results[combo['filename']] = "SKIP"
        continue

    print(f"[{i+1:2d}/{total}] GEN   {combo['filename']}...", end=" ", flush=True)

    try:
        response = client.models.generate_content(
            model=MODEL_ID,
            contents=combo['prompt'],
            config=types.GenerateContentConfig(
                response_modalities=['Image'],
            )
        )
        save_image(response, out_path)

        if os.path.exists(out_path):
            print("OK")
            results[combo['filename']] = "OK"
        else:
            print("WARN (no image)")
            results[combo['filename']] = "WARN"

    except Exception as e:
        print(f"ERR: {e}")
        results[combo['filename']] = f"ERR"

    time.sleep(2)

# 결과
print("\n" + "=" * 50)
ok = sum(1 for v in results.values() if v == "OK")
skip = sum(1 for v in results.values() if v == "SKIP")
fail = total - ok - skip
print(f"OK: {ok}  SKIP: {skip}  FAIL: {fail}")

# %% [5] 실패 재시도 ==========================================================

failed = [k for k, v in results.items() if v not in ("OK", "SKIP")]

if not failed:
    print("All done!")
else:
    print(f"Retrying {len(failed)}...")
    for fname in failed:
        combo = next(c for c in ALL_COMBOS if c['filename'] == fname)
        out_path = f"zodiac/{fname}"
        try:
            response = client.models.generate_content(
                model=MODEL_ID,
                contents=combo['prompt'],
                config=types.GenerateContentConfig(response_modalities=['Image'])
            )
            save_image(response, out_path)
            display_response(response)
            print(f"  OK: {fname}")
        except Exception as e:
            print(f"  FAIL: {fname} — {e}")
        time.sleep(3)

# %% [6] 특정 오행만 생성 (부분 실행용) =========================================

target_element = "fire"  # @param ["wood", "fire", "earth", "metal", "water"]

subset = [c for c in ALL_COMBOS if c['element'] == target_element]
print(f"Generating {ELEMENTS[target_element]['ko']}({target_element}) — {len(subset)} animals")

for i, combo in enumerate(subset):
    out_path = f"zodiac/{combo['filename']}"
    if os.path.exists(out_path):
        print(f"  [{i+1}/{len(subset)}] SKIP {combo['filename']}")
        continue

    print(f"  [{i+1}/{len(subset)}] GEN  {combo['filename']}...", end=" ", flush=True)
    try:
        response = client.models.generate_content(
            model=MODEL_ID,
            contents=combo['prompt'],
            config=types.GenerateContentConfig(response_modalities=['Image'])
        )
        save_image(response, out_path)
        print("OK")
        display_response(response)
    except Exception as e:
        print(f"ERR: {e}")
    time.sleep(2)

# %% [7] Chat 수정 (개별 보정) =================================================

import PIL

edit_file = "zodiac/zodiac_fire_horse.png"  # @param {type:"string"}
edit_prompt = "Keep the same character design but make the red color more vivid and fiery. Bigger sparkly eyes."  # @param {type:"string"}

chat = client.chats.create(model=MODEL_ID)
response = chat.send_message([edit_prompt, PIL.Image.open(edit_file)])
display_response(response)
save_image(response, edit_file)

# %% [8] 미리보기: 오행별 5×12 그리드 ==========================================

from PIL import Image as PILImage
import matplotlib.pyplot as plt

fig, axes = plt.subplots(5, 12, figsize=(24, 11))
fig.suptitle("60갑자 — 12동물 × 5오행", fontsize=16, y=0.98)

elem_order = ["wood", "fire", "earth", "metal", "water"]
animal_ids = [a['id'] for a in ANIMALS]

for row, elem in enumerate(elem_order):
    for col, aid in enumerate(animal_ids):
        ax = axes[row][col]
        path = f"zodiac/zodiac_{elem}_{aid}.png"
        if os.path.exists(path):
            ax.imshow(PILImage.open(path))
        if row == 0:
            ax.set_title(aid, fontsize=8)
        if col == 0:
            ax.set_ylabel(f"{ELEMENTS[elem]['ko']}\n({elem})", fontsize=9, rotation=0, labelpad=40)
        ax.axis("off")

plt.tight_layout(rect=[0.05, 0, 1, 0.96])
plt.savefig("zodiac/60ganji_preview.png", dpi=150, bbox_inches="tight")
plt.show()

# %% [9] 배경 제거 (rembg) → 투명 PNG ==========================================
# !pip install -q rembg[gpu] onnxruntime-gpu  # GPU 있으면
# !pip install -q rembg onnxruntime           # CPU만

from rembg import remove
from PIL import Image as PILImage
import glob

os.makedirs("zodiac_transparent", exist_ok=True)

src_files = sorted(glob.glob("zodiac/zodiac_*.png"))
print(f"Removing background from {len(src_files)} images...")

for i, src_path in enumerate(src_files):
    name = pathlib.Path(src_path).stem
    out_path = f"zodiac_transparent/{name}.png"

    if os.path.exists(out_path):
        print(f"  [{i+1}/{len(src_files)}] SKIP {name}")
        continue

    img = PILImage.open(src_path)
    result = remove(img)
    result.save(out_path)
    print(f"  [{i+1}/{len(src_files)}] OK   {name}")

print("Background removal complete! → zodiac_transparent/")

# %% [10] Flutter 에셋 리사이즈 (투명 PNG → WebP) ===============================

FLUTTER_SIZES = {"": 128, "1.5x": 192, "2.0x": 256, "3.0x": 384}
ONBOARDING_SIZES = {"": 256, "2.0x": 512, "3.0x": 768}

for src_path in sorted(glob.glob("zodiac_transparent/zodiac_*.png")):
    name = pathlib.Path(src_path).stem  # zodiac_fire_horse
    img = PILImage.open(src_path)

    # 채팅 아바타
    for suffix, size in FLUTTER_SIZES.items():
        out_dir = f"flutter_assets/zodiac/{suffix}" if suffix else "flutter_assets/zodiac"
        os.makedirs(out_dir, exist_ok=True)
        img.resize((size, size), PILImage.LANCZOS).save(f"{out_dir}/{name}.webp", "WEBP", quality=90)

    # 온보딩 대형
    for suffix, size in ONBOARDING_SIZES.items():
        out_dir = f"flutter_assets/zodiac/onboarding/{suffix}" if suffix else "flutter_assets/zodiac/onboarding"
        os.makedirs(out_dir, exist_ok=True)
        img.resize((size, size), PILImage.LANCZOS).save(f"{out_dir}/{name}_large.webp", "WEBP", quality=92)

print("Flutter assets ready! (transparent WebP)")
print("  Avatar:     flutter_assets/zodiac/{1x,1.5x,2.0x,3.0x}/zodiac_{element}_{animal}.webp")
print("  Onboarding: flutter_assets/zodiac/onboarding/{1x,2.0x,3.0x}/zodiac_{element}_{animal}_large.webp")

# %% [10] ZIP 다운로드 =========================================================

import shutil
from google.colab import files

shutil.make_archive("zodiac_60ganji_assets", "zip", "flutter_assets")
files.download("zodiac_60ganji_assets.zip")
