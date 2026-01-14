# Persona Selector (페르소나 선택기)

> **작성**: 2026-01-14
> **담당**: JH_AI

---

## 개요

MBTI 4축 기반 AI 캐릭터(페르소나) 선택 시스템

사용자가 성향을 먼저 선택하면, 해당 성향에 맞는 페르소나들을 추천합니다.

---

## 위젯 트리

```
PersonaSelectorSheet (BottomSheet)
├── 핸들바
├── 제목 "AI PERSONA Setting"
├── MbtiAxisSelector (4축 좌표계)
│   ├── CustomPainter (_MbtiAxisPainter)
│   │   ├── 배경 사각형
│   │   ├── 십자 축 (N-S, F-T)
│   │   ├── 축 레이블 (N, S, F, T)
│   │   ├── 분면 하이라이트
│   │   └── 선택 포인트 (드래그 가능)
│   └── GestureDetector (터치/드래그)
├── PersonaQuadrantGrid (분면별 4x4 그리드)
│   ├── 분면 제목 (예: "감성형")
│   └── GridView.builder
│       └── _PersonaGridItem × N
│           ├── 이모지 (28px)
│           └── 이름 (10px)
└── "특별한 페르소나" 버튼 (전체 보기 토글)


PersonaHorizontalList (채팅 화면 상단)
├── 설정 아이콘 (MBTI 선택기 열기)
└── ListView.builder (가로 스크롤)
    └── _PersonaCircleItem × N
        ├── 원형 배경
        └── 이모지
```

---

## MBTI 4분면

```
        N (직관)
        │
   NF   │   NT
 (감성형) │ (분석형)
        │
F ──────┼────── T
        │
   SF   │   ST
 (친근형) │ (현실형)
        │
        S (감각)
```

---

## 페르소나 목록

### NF - 감성형 (따뜻, 공감)

| 이모지 | 이름 | ID | 설명 |
|--------|------|-----|------|
| 👵 | 점순이 할머니 | grandma | 따뜻하고 정감있는 말투 |
| 👶 | 아기동자 | babyMonk | 반말과 팩폭, 꼬마도사 |
| 👴 | 새옹지마 할배 | saOngJiMa | 긍정 재해석 전문가 |

### NT - 분석형 (논리, 체계)

| 이모지 | 이름 | ID | 설명 |
|--------|------|-----|------|
| 🧙 | 청운 도사 | master | 위엄있고 철학적인 말투 |
| 📜 | 명리의 서 | bookOfSaju | 살아있는 사주 고서 |
| 🔮 | AI 상담사 | professional | 전문적이고 정중한 말투 |

### SF - 친근형 (유쾌, 친근)

| 이모지 | 이름 | ID | 설명 |
|--------|------|-----|------|
| 🐱 | 복돌이 | cute | 귀엽고 친근한 말투 |
| 😱 | 하꼬무당(장비장군) | newbieShaman | 장비장군이 오셨다 |

### ST - 현실형 (직설, 스토리)

| 이모지 | 이름 | ID | 설명 |
|--------|------|-----|------|
| 🗣️ | 송작가 | scenarioWriter | 사주 스토리텔러 |

---

## 사용법

### 1. 채팅 화면 상단에 가로 리스트

```dart
import 'package:frontend/features/saju_chat/presentation/widgets/persona_selector/persona_selector.dart';

PersonaHorizontalList(
  currentPersona: currentPersona,
  onPersonaSelected: (persona) {
    ref.read(personaNotifierProvider.notifier).setPersona(persona);
  },
  onSettingsTap: () {
    // MBTI 선택기 열기
    PersonaSelectorSheet.show(context, currentPersona);
  },
)
```

### 2. MBTI 선택기 열기

```dart
final selected = await PersonaSelectorSheet.show(context, currentPersona);
if (selected != null) {
  ref.read(personaNotifierProvider.notifier).setPersona(selected);
}
```

### 3. 분면별 페르소나 가져오기

```dart
// NF 분면 페르소나 목록
final nfPersonas = AiPersona.getByQuadrant(MbtiQuadrant.NF);
// → [grandma, babyMonk, saOngJiMa]
```

---

## 파일 구조

```
persona_selector/
├── persona_selector.dart          # 모듈 exports
├── mbti_axis_selector.dart        # 4축 좌표계 위젯
├── persona_horizontal_list.dart   # 가로 원형 리스트
├── persona_selector_sheet.dart    # 메인 BottomSheet
└── README.md                      # 이 파일
```

---

## 색상 (분면별)

| 분면 | 색상 | Hex |
|------|------|-----|
| NF | 빨강 (감성) | #E63946 |
| NT | 파랑 (분석) | #457B9D |
| SF | 초록 (친근) | #2A9D8F |
| ST | 주황 (현실) | #F4A261 |

---

## 관련 파일

- `domain/models/ai_persona.dart` - AiPersona enum, MbtiQuadrant enum
- `providers/persona_provider.dart` - Hive 저장 상태 관리
- `AI/jina/personas/` - PersonaBase 상세 프롬프트
