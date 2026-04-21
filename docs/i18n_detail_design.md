# 사주 디테일 i18n 설계서

## 현황: 128개 한국어 하드코딩

| 파일 | 개수 | 유형 |
|------|------|------|
| `saju_detail_tabs.dart` | 39 | Map 키(내부) + UI 라벨 |
| `hapchung_service.dart` | 28 | 합충 해석 텍스트 |
| `twelve_sinsal_service.dart` | 22 | 신살 설명 |
| `unsung_service.dart` | 12 | 운성 해석 |
| `gongmang_service.dart` | 10 | 공망 설명 |
| `hapchung_tab.dart` | 9 | UI 라벨 + 설명 |
| `jijanggan_service.dart` | 8 | 지장간 설명 |

## 분류: 3가지 유형

### Type A: Map 키 (내부 데이터 — 번역 불필요) ~55개
```dart
// 예: saju_detail_tabs.dart
'장생': Color(0xFF4CAF50),  // ← 키는 한국어 유지 (내부 lookup)
'역마살': Icons.flight_takeoff_rounded,  // ← 동일
```
→ **변경 없음**. 한국어 `.korean` 값이 내부 키로 사용됨. UI 표시 시만 `SajuI18n.xxx(korean, locale)` 사용 (이미 적용됨).

### Type B: 짧은 라벨 (~25개) → `SajuI18n` 확장
```dart
// hapchung_tab.dart
'$pillar1주 ↔ $pillar2주'  // → pillar1/pillar2는 이미 SajuI18n으로 번역됨, "주" 제거 완료
'삼합의 2글자만 있는 경우로...'  // → saju_chart.json 키 추가
```

### Type C: 긴 설명 텍스트 (~48개) → `saju_detail.json` 신규 파일
```dart
// hapchung_tab.dart - 형/파/해/원진 설명
'무례지형(無禮之刑): 예의 없음으로 인한 형벌...'
'무은지형(無恩之刑): 은혜 없음으로 인한 형벌...'

// jijanggan_service.dart - 십성 해석
'비견: 나와 같은 기운. 독립심, 자존심, 경쟁심이 강함...'

// unsung_service.dart - 12운성 해석
'새로운 시작의 에너지. 무에서 유를 창조하는 힘...'

// twelve_sinsal_service.dart - 12신살 상세
'겁살(劫煞)은 재물 손실과 도난을 주의해야 하는 신살입니다...'

// gongmang_service.dart - 공망 해석
'월지 공망은 부모와 형제를 담당하는 궁이 비어있음을 의미합니다...'
```

## 실행 계획

### Step 1: `saju_detail.json` 생성 (17개 언어)
새 JSON 파일에 ~50개 키 추가:

```json
{
  "hyung_murye": "무례지형(無禮之刑): 예의 없음으로 인한 형벌...",
  "hyung_mueun": "무은지형(無恩之刑): 은혜 없음으로 인한 형벌...",
  "hyung_jise": "지세지형(持勢之刑): 권세를 믿고 함부로 행동...",
  "hyung_ja": "자형(自刑): 스스로를 해치는 형...",
  "pa_desc": "관계의 단절이나 깨짐을 의미합니다...",
  "hae_desc": "서로를 해치는 관계입니다...",
  "wonjin_desc": "원망과 미움의 관계입니다...",
  "halfSamhap_desc": "삼합의 2글자만 있는 경우로...",

  "sipsin_bigyeon_desc": "비견: 나와 같은 기운...",
  "sipsin_geopjae_desc": "겁재: 재물을 빼앗는 기운...",
  ... (10개)

  "unsung_jangSaeng_desc": "새로운 시작의 에너지...",
  "unsung_mogYok_desc": "성장과 학습의 시기...",
  ... (12개)

  "sinsal_yeokma_detail": "역마살은 이동과 변화의 기운...",
  ... (12개)

  "gongmang_wolji_desc": "월지 공망은 부모와 형제를 담당하는 궁이...",
  ... (4개)
}
```

### Step 2: 서비스 레이어 수정 패턴

**Before (현재):**
```dart
// hapchung_tab.dart
if (char1 == '자' && char2 == '묘') {
  return '무례지형(無禮之刑): 예의 없음으로 인한 형벌...';
}
```

**After:**
```dart
// hapchung_tab.dart
if (char1 == '자' && char2 == '묘') {
  return 'saju_detail.hyung_murye'.tr();
}
```

**Before (서비스 — context 없음):**
```dart
// jijanggan_service.dart
SipSin.bigyeon => '비견: 나와 같은 기운. 독립심...',
```

**After (서비스에 locale 전달):**
```dart
// jijanggan_service.dart
SipSin.bigyeon => SajuI18n.sipsinDescription('비견', locale),
```
→ `SajuI18n`에 `sipsinDescription` 메서드 추가 (cheongan_jiji_i18n.dart)

### Step 3: 위젯 수정 (locale 전달)
서비스 호출 시 `locale` 파라미터 추가:
```dart
// Before
final description = JiJangGanService.getSipsinDescription(sipsin);

// After
final locale = context.locale.languageCode;
final description = JiJangGanService.getSipsinDescription(sipsin, locale);
```

## 우선순위

1. **hapchung_tab.dart** (9개) — 사용자가 직접 본 화면
2. **saju_detail_tabs.dart** (Map 키 제외, ~15개 라벨)
3. **jijanggan_service.dart** (8개)
4. **unsung_service.dart** (12개)
5. **twelve_sinsal_service.dart** (22개)
6. **hapchung_service.dart** (28개)
7. **gongmang_service.dart** (10개)

## 핵심 원칙

1. **Map 키는 한국어 유지** — 내부 lookup용, 번역 불필요
2. **UI 표시 텍스트만 i18n** — `.tr()` 또는 `SajuI18n.xxx()`
3. **서비스 레이어**: locale 파라미터 추가하여 `SajuI18n` 사용
4. **위젯 레이어**: `context.locale.languageCode` → 서비스에 전달
5. **saju_detail.json**: 긴 설명 전용 JSON (17개 언어)
