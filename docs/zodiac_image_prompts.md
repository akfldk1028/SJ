# Zodiac Animal Image Prompts (Nano Banana / Gemini)

> 12간지 수호동물 캐릭터 이미지 생성 가이드
> Tool: Google Gemini (Nano Banana Pro) 또는 Midjourney Niji

---

## Image Size Guide

### 생성 사이즈
| 용도 | 생성 해상도 | 비율 | 비고 |
|------|-----------|------|------|
| **마스터 원본** | **1024x1024** | 1:1 | Gemini 기본, 모든 용도 소스 |
| 온보딩 캐릭터 | 1024x1024 | 1:1 | 중앙 배치, 투명 배경 |
| 채팅 아바타 | 512x512 | 1:1 | 원형 크롭 대비 |

### Flutter 에셋 구조
```
frontend/assets/images/zodiac/
├── 1.5x/          (hdpi)
│   ├── zodiac_rat.webp      (192x192)
│   ├── zodiac_ox.webp
│   └── ...
├── 2.0x/          (xhdpi)
│   ├── zodiac_rat.webp      (256x256)
│   └── ...
├── 3.0x/          (xxhdpi)
│   ├── zodiac_rat.webp      (384x384)
│   └── ...
├── zodiac_rat.webp           (128x128, 기본 1x)
├── zodiac_ox.webp
└── ...

frontend/assets/images/zodiac/onboarding/
├── 2.0x/
│   └── zodiac_rat_large.webp  (512x512)
├── 3.0x/
│   └── zodiac_rat_large.webp  (768x768)
└── zodiac_rat_large.webp      (256x256, 기본 1x)
```

### 변환 방법
```bash
# 1024x1024 원본 → Flutter 에셋 (ImageMagick)
for f in *.png; do
  name="${f%.png}"
  magick "$f" -resize 128x128 "${name}.webp"
  magick "$f" -resize 192x192 "1.5x/${name}.webp"
  magick "$f" -resize 256x256 "2.0x/${name}.webp"
  magick "$f" -resize 384x384 "3.0x/${name}.webp"
done
```

---

## Style Guide

### Nano Banana 3D Chibi 스타일 핵심
- **비율**: 2등신 (머리:몸 = 1:1)
- **질감**: 광택 비닐 토이 / Pop Mart 피규어
- **렌더링**: 3D C4D, 소프트 스튜디오 조명
- **눈**: 크고 반짝이는 애니메이션 눈 (눈 하이라이트 필수)
- **색상**: 파스텔 + 비비드 악센트
- **배경**: 단색 또는 투명 (나중에 앱에서 오행 그라데이션 합성)
- **포즈**: 정면 또는 3/4 각도, 친근한 포즈

### 오행별 색상 테마 (배경/악센트)
| 오행 | 색 | Hex | 동물 |
|------|-----|-----|------|
| 목(Wood) | 에메랄드 그린 | #4CAF50 | 호랑이, 토끼 |
| 화(Fire) | 코랄 레드 | #F44336 | 뱀, 말 |
| 토(Earth) | 앰버 옐로우 | #FF9800 | 용, 양, 개, 소 |
| 금(Metal) | 실버 화이트 | #E0E0E0 | 원숭이, 닭 |
| 수(Water) | 딥 블루 | #2196F3 | 쥐, 돼지 |

---

## Base Prompt Template

> 모든 동물에 공통 적용. `[ANIMAL_DESC]` 부분만 교체.

```
A cute 3D chibi [ANIMAL] character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. [ANIMAL_DESC].
Soft studio lighting, C4D 3D render, pastel color palette with
[ELEMENT_COLOR] accent. Solid [BG_COLOR] background.
Centered composition, front-facing, friendly welcoming pose with
one paw/hand raised in greeting. High quality, clean edges,
professional character design, mascot style.
```

---

## 12 Animal Prompts

### 1. Rat (쥐) zodiac_rat
```
A cute 3D chibi mouse character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Small round ears, long thin tail,
soft grey fur with white belly, holding a tiny golden coin, clever
curious expression with tilted head.
Soft studio lighting, C4D 3D render, pastel color palette with
deep blue accent. Solid light blue background.
Centered composition, front-facing, friendly welcoming pose with
one paw raised in greeting. High quality, clean edges,
professional character design, mascot style.
```

### 2. Ox (소) zodiac_ox
```
A cute 3D chibi baby ox character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Small curved horns, sturdy body,
brown and white spotted fur, wearing a tiny flower crown, gentle
determined expression with warm smile.
Soft studio lighting, C4D 3D render, pastel color palette with
amber yellow accent. Solid warm cream background.
Centered composition, front-facing, friendly welcoming pose with
one hoof raised in greeting. High quality, clean edges,
professional character design, mascot style.
```

### 3. Tiger (호랑이) zodiac_tiger
```
A cute 3D chibi baby tiger character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Bold orange fur with black stripes,
white chest fluff, tiny fangs peeking out, confident playful expression,
wearing a small red cape.
Soft studio lighting, C4D 3D render, pastel color palette with
emerald green accent. Solid mint green background.
Centered composition, front-facing, brave heroic pose with
one paw raised. High quality, clean edges,
professional character design, mascot style.
```

### 4. Rabbit (토끼) zodiac_rabbit
```
A cute 3D chibi bunny character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Long floppy ears, fluffy white
and pink fur, holding a small cherry blossom branch, sweet gentle
expression with soft blush on cheeks.
Soft studio lighting, C4D 3D render, pastel color palette with
emerald green accent. Solid soft pink background.
Centered composition, front-facing, delicate pose with
both paws together. High quality, clean edges,
professional character design, mascot style.
```

### 5. Dragon (용) zodiac_dragon
```
A cute 3D chibi baby dragon character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Small wings on back, tiny horns,
golden-green iridescent scales, fluffy mane, proud confident expression,
small flame hovering above one claw.
Soft studio lighting, C4D 3D render, pastel color palette with
amber gold accent. Solid warm yellow background.
Centered composition, front-facing, majestic pose with
one claw raised proudly. High quality, clean edges,
professional character design, mascot style.
```

### 6. Snake (뱀) zodiac_snake
```
A cute 3D chibi snake character in Pop Mart blind box figurine style.
2-head-tall proportions (coiled body with upright head), big sparkly
anime eyes with highlights, glossy vinyl toy texture. Elegant purple
and silver scales, small crown-like marking on head, tiny forked tongue
peeking out playfully, mysterious wise expression with gentle smile.
Soft studio lighting, C4D 3D render, pastel color palette with
coral red accent. Solid lavender background.
Centered composition, front-facing, graceful coiled pose with
head tilted curiously. High quality, clean edges,
professional character design, mascot style.
```

### 7. Horse (말) zodiac_horse
```
A cute 3D chibi pony character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Flowing red-brown mane and tail,
white star marking on forehead, strong little hooves, energetic joyful
expression, wearing a tiny scarf blowing in the wind.
Soft studio lighting, C4D 3D render, pastel color palette with
coral red accent. Solid warm orange background.
Centered composition, front-facing, dynamic running pose with
one hoof raised high. High quality, clean edges,
professional character design, mascot style.
```

### 8. Sheep (양) zodiac_sheep
```
A cute 3D chibi lamb character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Fluffy curly white wool, tiny
curved horns with flower decoration, pink inner ears, dreamy artistic
expression, holding a small paintbrush.
Soft studio lighting, C4D 3D render, pastel color palette with
amber yellow accent. Solid soft peach background.
Centered composition, front-facing, gentle creative pose.
High quality, clean edges, professional character design, mascot style.
```

### 9. Monkey (원숭이) zodiac_monkey
```
A cute 3D chibi monkey character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Golden-brown fur, peach face,
curly tail, mischievous playful grin, wearing a tiny crown tilted to
the side, juggling a small star.
Soft studio lighting, C4D 3D render, pastel color palette with
silver white accent. Solid light grey background.
Centered composition, front-facing, playful energetic pose with
arms spread wide. High quality, clean edges,
professional character design, mascot style.
```

### 10. Rooster (닭) zodiac_rooster
```
A cute 3D chibi baby rooster character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Bright red comb, colorful
tail feathers in rainbow gradient, golden beak, proud upright posture,
confident honest expression.
Soft studio lighting, C4D 3D render, pastel color palette with
silver white accent. Solid light gold background.
Centered composition, front-facing, proud standing pose with
chest puffed out. High quality, clean edges,
professional character design, mascot style.
```

### 11. Dog (개) zodiac_dog
```
A cute 3D chibi puppy character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Fluffy golden retriever-style fur,
floppy ears, wagging tail, loyal happy expression with tongue slightly
out, wearing a tiny heart-shaped collar tag.
Soft studio lighting, C4D 3D render, pastel color palette with
amber yellow accent. Solid warm brown background.
Centered composition, front-facing, eager loyal pose with
one paw raised for handshake. High quality, clean edges,
professional character design, mascot style.
```

### 12. Pig (돼지) zodiac_pig
```
A cute 3D chibi piglet character in Pop Mart blind box figurine style.
2-head-tall proportions, rounded body, big sparkly anime eyes with
highlights, glossy vinyl toy texture. Soft pink skin, curly tail,
round snout with rosy cheeks, cheerful generous expression, holding
a small four-leaf clover, wearing tiny overalls.
Soft studio lighting, C4D 3D render, pastel color palette with
deep blue accent. Solid soft pink background.
Centered composition, front-facing, happy welcoming pose with
both arms open wide. High quality, clean edges,
professional character design, mascot style.
```

---

## Consistency Checklist

생성 시 모든 동물에 공통 적용:

- [ ] 1024x1024 정사각형
- [ ] 2등신 비율 일관
- [ ] 눈 스타일 동일 (큰 반짝이 애니메이션 눈)
- [ ] 광택 비닐 토이 질감 통일
- [ ] 소프트 스튜디오 조명 동일
- [ ] 정면 또는 3/4 각도 통일
- [ ] 배경 단색 (나중에 제거/교체 용이)
- [ ] 캐릭터 크기 프레임 내 70-80% 차지
- [ ] PNG 투명배경 버전 별도 저장

## Generation Tool

**권장: Google Gemini (Nano Banana Pro)**
- Google AI Studio에서 직접 생성
- 프롬프트 앞에 특별한 prefix 불필요 (일반 텍스트 입력)

**대안: Midjourney Niji 6**
```
/imagine [prompt above] --ar 1:1 --niji 6 --style cute
```

**대안: DALL-E 3**
- 위 프롬프트 그대로 사용 가능
- "I NEED the output to be exactly 1024x1024" 추가

---

## Sources
- [Nano Banana 3D Chibi Guide (Skywork)](https://skywork.ai/blog/nano-banana-3d-chibi-image-generation-10-practical-prompts-and-professional-application-guide/)
- [Nano Banana Prompt Templates (Fotor)](https://www.fotor.com/blog/nano-banana-model-prompts/)
- [Nano Banana 3D Figurines (banananano.ai)](https://banananano.ai/3dfigurines)
- [Flutter Image Assets Guide](https://docs.flutter.dev/ui/assets/assets-and-images)
- [Awesome Nano Banana (GitHub)](https://github.com/JimmyLv/awesome-nano-banana)
