# Saju Analysis Data Layer

> 작성: 2024-12-26
> 담당: DK

---

## 파일 구조

```
data/
├── schema.dart      # saju_analyses 테이블 스키마
├── queries.dart     # SELECT 쿼리 (조회)
├── mutations.dart   # INSERT/UPDATE/DELETE (변경)
├── models/          # DB 모델 (SajuAnalysisDbModel)
├── constants/       # 천간/지지, 오행 상수
└── README.md        # 이 파일
```

---

## 사용법

### 1. 쿼리 (조회)

```dart
import 'package:saju_app/features/saju_chart/data/queries.dart';

// 프로필 ID로 사주 분석 조회
final result = await sajuAnalysisQueries.getByProfileId(profileId);

// AI 컨텍스트용 (핵심 데이터만)
final aiData = await sajuAnalysisQueries.getForAiContext(profileId);

// 오행 분포만 조회
final oheng = await sajuAnalysisQueries.getOhengDistribution(profileId);

// 용신만 조회
final yongsin = await sajuAnalysisQueries.getYongsin(profileId);
```

### 2. 뮤테이션 (변경)

```dart
import 'package:saju_app/features/saju_chart/data/mutations.dart';

// 분석 생성 (프로필 생성 시)
final result = await sajuAnalysisMutations.create(analysisModel);

// Upsert (있으면 업데이트, 없으면 생성)
await sajuAnalysisMutations.upsert(analysisModel);

// 부분 업데이트 (특정 필드만)
await sajuAnalysisMutations.updateYongsin(analysisId, yongsinData);
await sajuAnalysisMutations.updateDaeun(analysisId, daeunData);
```

---

## 테이블 스키마

**Supabase 테이블: `saju_analyses`**

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | uuid | PK |
| profile_id | uuid | FK → saju_profiles |
| year_gan/year_ji | text | 년주 (갑자 형식) |
| month_gan/month_ji | text | 월주 |
| day_gan/day_ji | text | 일주 |
| hour_gan/hour_ji | text | 시주 (nullable) |
| corrected_datetime | timestamptz | 진태양시 보정 후 |
| oheng_distribution | jsonb | 오행 분포 |
| day_strength | jsonb | 일간 강약 |
| yongsin | jsonb | 용신 정보 |
| gyeokguk | jsonb | 격국 정보 |
| sipsin_info | jsonb | 십신 정보 |
| jijanggan_info | jsonb | 지장간 정보 |
| sinsal_list | jsonb | 신살 목록 |
| daeun | jsonb | 대운 정보 |
| current_seun | jsonb | 현재 세운 |
| twelve_unsung | jsonb | 12운성 |
| twelve_sinsal | jsonb | 12신살 |

---

## 쿼리 최적화 옵션

### 빠른 로딩 (기본 정보만)
```dart
// 사주 표시에 필요한 최소 데이터만
final basic = await sajuAnalysisQueries.getBasicByProfileId(profileId);
```

### AI 컨텍스트용
```dart
// AI 분석에 필요한 핵심 데이터만
final aiData = await sajuAnalysisQueries.getForAiContext(profileId);
// → id, profile_id, 사주(8글자), oheng, day_strength, yongsin, gyeokguk, sipsin
```

### 전체 데이터
```dart
// 모든 분석 데이터 (화면 상세 표시용)
final full = await sajuAnalysisQueries.getByProfileId(profileId);
```

---

## JSONB 필드 구조

### oheng_distribution (오행 분포)
```json
{
  "wood": 2,
  "fire": 3,
  "earth": 1,
  "metal": 1,
  "water": 1
}
```

### day_strength (일간 강약)
```json
{
  "is_singang": true,
  "score": 65,
  "factors": {
    "deukryeong": true,
    "deukji": false,
    "deukse": true
  }
}
```

### yongsin (용신)
```json
{
  "yongsin": "수(水)",
  "huisin": "금(金)",
  "gisin": "화(火)",
  "gusin": "목(木)"
}
```

---

## AI 연동

AI 모듈 (JH_AI, Jina)은 직접 쿼리 대신 `AIContext` 사용:

```dart
// AI/common/data/ai_context.dart
class AIContext {
  final SajuProfileModel profile;
  final SajuAnalysisDbModel analysis;  // 여기에 포함
  // ...
}

// AI 모듈에서
final context = await ref.read(aiContextProvider.future);
final saju = context.analysis;  // 사주 분석 데이터
final oheng = saju.ohengDistribution;  // 오행
final yongsin = saju.yongsin;  // 용신
```
