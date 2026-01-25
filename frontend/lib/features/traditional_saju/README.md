# 정통사주 (Traditional Saju) Feature

## 개요
평생운세 분석 기능. 사주팔자 기반으로 AI가 종합적인 운세 분석을 제공합니다.

---

## 핵심 구조

### 1. 사주팔자 8글자 (만세력 계산 결과)
```
┌────────────────────────────────────────┐
│    시주    일주    월주    연주        │  ← 전통 순서 (오른쪽→왼쪽 읽음)
├────────────────────────────────────────┤
│    시간    일간    월간    연간        │  ← 천간 (하늘의 기운)
│    시지    일지    월지    연지        │  ← 지지 (땅의 기운)
└────────────────────────────────────────┘
```

**중요**: 8글자 표시는 **AI 응답이 아님!**
- 데이터 소스: 만세력 계산 결과 (`SajuProfile.saju`)
- AI는 각 글자의 **의미 설명**만 제공 (`my_saju_characters`)

### 2. AI 분석 (Phase 분할)
```
Phase 1 (Foundation): 원국, 십성, 합충, 성격, 행운요소
                      + mySajuIntro (일주 설명)
                      + my_saju_characters (8글자 의미)
Phase 2 (Fortune):    재물운, 연애운, 결혼운
Phase 3 (Career):     직업운, 사업운, 건강운
Phase 4 (Timeline):   인생주기, 대운, 최전성기
```

---

## 파일 구조

```
traditional_saju/
├── presentation/
│   ├── screens/
│   │   ├── traditional_saju_screen.dart   # 랜딩 페이지
│   │   └── lifetime_fortune_screen.dart   # 평생운세 메인 화면
│   ├── providers/
│   │   └── lifetime_fortune_provider.dart # 상태 관리 + AI 응답 파싱
│   └── widgets/
└── README.md (이 파일)
```

---

## 데이터 흐름

```
1. 프로필 저장 시
   └── SajuAnalysisService.analyzeOnProfileSave()
       ├── Phase 1 실행 → mySajuIntro, my_saju_characters, wonGuk, sipsung, hapchung, personality, lucky_elements
       ├── Phase 2 실행 → wealth, love, marriage
       ├── Phase 3 실행 → career, business, health
       └── Phase 4 실행 → life_cycles, peak_years, daeun_detail

2. 평생운세 화면 진입 시
   └── LifetimeFortuneProvider
       ├── getCached() → DB에서 캐시 조회 (prompt_version 체크)
       ├── 캐시 히트 → 파싱 후 UI 표시
       └── 캐시 미스 → AI 재생성 트리거
```

---

## 주요 섹션 (UI)

| 섹션 | 데이터 소스 | 설명 |
|------|------------|------|
| 사주팔자 8글자 | `my_saju_characters` | 각 글자 클릭 → 의미 설명 바텀시트 |
| 나의 사주 소개 | `mySajuIntro` | 일주 기반 '나'에 대한 설명 |
| 원국 분석 | `wonGuk_analysis` | 격국, 일간, 오행균형 |
| 십성 분석 | `sipsung_analysis` | 강한/약한 십성, 영향 |
| 합충 분석 | `hapchung_analysis` | 합충형파해 관계 |
| 분야별 운세 | `categories` | 직업/사업/재물/연애/결혼/건강 (광고 잠금) |
| 인생 주기 | `life_cycles` | 청년/중년/후년 (광고 잠금) |
| 대운 | `daeun_detail` | 10년 주기 운의 흐름 |
| 최전성기 | `peak_years` | 인생 황금기 |

---

## 카테고리별 상세 필드 (V9.4)

### CategoryFortuneData → CategoryData 매핑

각 카테고리(직업/사업/재물/연애/결혼/건강)의 DB 필드가 UI에 100% 매핑됨.

#### 공통 필드 (모든 카테고리)
| 필드 | 설명 | UI 위치 |
|------|------|---------|
| `title` | 카테고리 제목 | 칩/헤더 |
| `score` | 점수 (0-100) | 칩/헤더 |
| `reading` | AI 분석 본문 | 펼친 카드 본문 |
| `advice` | 조언 | 조언 박스 (보라색) |
| `cautions` | 주의사항 리스트 | 주의사항 박스 (주황색) |
| `timing` | 타이밍 정보 | 타이밍 섹션 |

#### 직업운 (career)
| 필드 | 설명 |
|------|------|
| `suitableFields` | 적합한 분야 |
| `unsuitableFields` | 피해야 할 분야 |
| `workStyle` | 업무 스타일 |
| `leadershipPotential` | 리더십 잠재력 |

#### 사업운 (business)
| 필드 | 설명 |
|------|------|
| `suitableFields` | 적합한 사업 유형 |
| `strengths` | 성공 요인 |
| `entrepreneurshipAptitude` | 창업 적성 |
| `businessPartnerTraits` | 사업 파트너 특성 |

#### 재물운 (wealth)
| 필드 | 설명 |
|------|------|
| `overallTendency` | 전반적 경향 |
| `earningStyle` | 돈 버는 방식 |
| `spendingTendency` | 소비 성향 |
| `investmentAptitude` | 투자 적성 |

#### 연애운 (love)
| 필드 | 설명 |
|------|------|
| `strengths` | 연애 강점 |
| `weaknesses` | 연애 약점 |
| `datingPattern` | 연애 패턴 |
| `attractionStyle` | 끌리는 유형 |
| `idealPartnerTraits` | 이상형 특성 |

#### 결혼운 (marriage)
| 필드 | 설명 |
|------|------|
| `spousePalaceAnalysis` | 배우자궁 분석 |
| `spouseCharacteristics` | 배우자 특성 |
| `marriedLifeTendency` | 결혼 생활 경향 |

#### 건강운 (health)
| 필드 | 설명 |
|------|------|
| `weaknesses` | 취약 부위 |
| `cautions` | 잠재적 건강 문제 |
| `mentalHealth` | 정신 건강 |
| `lifestyleAdvice` | 생활 습관 조언 |

---

## 프롬프트 버전 관리

위치: `AI/core/ai_constants.dart` → `PromptVersions.sajuBase`

```dart
// 현재 버전
static const String sajuBase = 'V9.5';

// 버전 히스토리
// V8.0: my_saju_characters 추가
// V8.1: 대운 형식 호환성 수정
// V9.0: mySajuIntro.ilju 추가
// V9.1: 캐시 무효화
// V9.2: Phase 1 프롬프트에 mySajuIntro/my_saju_characters 추가
// V9.3: Phase 3 대운 "미상" 문제 해결 (DB 형식/legacy 형식 모두 지원)
// V9.4: 카테고리별 상세 필드 전체 매핑 (DB 필드 100% UI 표시)
// V9.5: Phase maxTokens 대폭 확장 (JSON 잘림 방지)
//       Phase 1: 6000 → 10000
//       Phase 2: 4000 → 8000 (결혼운 잘림 해결)
//       Phase 3: 5000 → 10000
//       Phase 4: 4000 → 8000
```

**중요**: 프롬프트 수정 시 **Phase 프롬프트**도 함께 수정해야 함!
- `saju_base_prompt.dart` → 통합 프롬프트 (현재 미사용)
- `saju_base_phase1_prompt.dart` → **실제 사용됨**
- `saju_base_phase2_prompt.dart`
- `saju_base_phase3_prompt.dart`
- `saju_base_phase4_prompt.dart`

---

## 자주 발생하는 문제

### 1. 8글자가 안 뜸
- **원인**: `my_saju_characters`가 AI 응답에 없음
- **확인**: Supabase에서 `ai_summaries` 테이블 조회
  ```sql
  SELECT content ? 'my_saju_characters' FROM ai_summaries WHERE summary_type = 'saju_base';
  ```
- **해결**: Phase 1 프롬프트에 `my_saju_characters` 스키마 추가

### 2. 새 필드가 적용 안 됨
- **원인**: 캐시된 이전 버전 데이터 사용 중
- **해결**:
  1. `ai_constants.dart`에서 버전 증가
  2. DB에서 이전 버전 캐시 삭제

### 3. Phase 분할 분석 시 필드 누락
- **원인**: `saju_base_prompt.dart`만 수정하고 `phase1~4` 프롬프트는 수정 안 함
- **해결**: Phase 프롬프트에도 동일하게 필드 추가

### 4. 대운에 "미상" 표시됨
- **원인**: Phase 3 프롬프트가 DB 형식(camelCase)을 인식 못함
- **해결**: `_buildDaeunSection`에서 camelCase/snake_case 모두 지원 (V9.3)

### 5. 카테고리 상세 정보가 안 뜸
- **원인**: `CategoryFortuneData`에 해당 필드가 없거나 매핑 안 됨
- **해결**: V9.4에서 전체 필드 매핑 완료
  - Provider: `lifetime_fortune_provider.dart`의 categories 빌드 부분
  - UI: `fortune_category_chip_section.dart`의 `_buildExpandedContent`

### 6. saju_base 데이터가 저장 안 됨 (V9.5 해결)
- **증상**: ai_tasks 테이블에서 task는 completed지만 ai_summaries에 데이터 없음
- **원인**: Phase maxTokens 한도 도달 → JSON 중간에 잘림 → 파싱 실패 → 저장 실패
- **진단**:
  ```sql
  SELECT partial_result->'_parse_error' FROM ai_tasks WHERE task_type = 'saju_analysis' ORDER BY created_at DESC LIMIT 1;
  ```
- **해결**: V9.5에서 Phase maxTokens 대폭 확장
  - Phase 1: 6000 → 10000
  - Phase 2: 4000 → 8000 (결혼운 잘림 해결)
  - Phase 3: 5000 → 10000
  - Phase 4: 4000 → 8000

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `AI/services/saju_analysis_service.dart` | Phase 분할 분석 오케스트레이션 |
| `AI/prompts/saju_base_phase1_prompt.dart` | Phase 1 프롬프트 (기초 분석) |
| `AI/prompts/saju_base_phase2_prompt.dart` | Phase 2 프롬프트 (재물/연애/결혼) |
| `AI/prompts/saju_base_phase3_prompt.dart` | Phase 3 프롬프트 (직업/사업/건강) |
| `AI/prompts/saju_base_phase4_prompt.dart` | Phase 4 프롬프트 (시간축) |
| `AI/core/ai_constants.dart` | 버전 관리 |
| `shared/widgets/fortune_category_chip_section.dart` | 분야별 운세 칩 UI + 상세 표시 |
| `features/traditional_saju/presentation/providers/lifetime_fortune_provider.dart` | CategoryFortuneData 정의 + JSON→객체 파싱 |
