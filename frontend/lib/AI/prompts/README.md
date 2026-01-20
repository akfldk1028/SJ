# AI 프롬프트 모듈

● 로그를 확인했습니다:

  1. 프로필 분석 대상이 "이지나"로 정확히 나옵니다 (line 132)
  2. 하지만 Edge Function이 WORKER_LIMIT 오류로 실패했습니다 - Supabase 컴퓨팅 리소스 부족

  현재 구현 흐름 정리:
  프로필 생성:
    └─> GPT-5.2 백그라운드 실행 (fire-and-forget) ✅

  채팅 시작:
    └─> _ensureAiSummary 호출
         └─> DB에서 캐시 확인
              └─> sajuOrigin이 null이면?
                   └─> GPT-5.2 동기 실행 (대기)
                   └─> 완료 후 채팅 진행

  사용자가 말한 "비동기로 해야하고"가 채팅에서도 fire-and-forget을 의미하는 건지 확인이 필요합니다. 현재 구현은 채팅에서 saju_origin이 없으면 GPT-5.2가 완료될 때까지 로딩 상태로 대기합니다.

  Supabase Edge Function 오류부터 해결해야 테스트가 가능합니다. 이건 Supabase 콘솔에서 확인이 필요합니다.

● supabase - Get project logs (MCP)(service: "edge-function")
  ⎿  {
       "result": [
         {
     … +1102 lines (ctrl+o to expand)

● Edge Function 로그 확인 결과:
  - ai-openai (GPT-5.2): 계속 546 오류 (WORKER_LIMIT - 컴퓨팅 리소스 부족)
  - ai-gemini: 정상 작동 (200)

  최신 앱 출력을 확인하겠습니다.

● Read(C:\Users\SOGANG1\AppData\Local\Temp\claude\D--Data-20-Flutter-01-SJ\tasks\bdc102a.output)
  ⎿  Read 100 lines

● 로그 확인 결과:

  분석 대상 확인:
  - 이름: 이지나 ✅ (정확함)
  - 생년월일: 1999년 7월 27일
  - 사주 팔자: 기묘 신미 경진 (시주 미상)

  문제점:
  - ai-openai Edge Function이 WORKER_LIMIT 오류로 실패 (Supabase 무료 플랜 제한)
  - GPT-5.2 호출이 150초 후 타임아웃

  현재 구현 흐름 정리:

  1. 프로필 생성 시:
     └─> GPT-5.2 백그라운드 실행 (fire-and-forget)
     └─> 화면 멈추지 않음 ✅

  2. 채팅 시작 시 (_ensureAiSummary):
     └─> DB에서 캐시 확인
     └─> sajuOrigin 있음 → 바로 채팅 진행
     └─> sajuOrigin 없음 → GPT-5.2 실행 & 대기 (로딩 표시)
         └─> 완료 후 채팅 진행

  사용자가 말한 "비동기로 해야하고"가 정확히 어떤 의미인지 확인이 필요합니다:
  - 현재 구현: 채팅에서 saju_origin 없으면 GPT-5.2 완료까지 로딩 상태로 대기
  - 다른 옵션: 채팅도 fire-and-forget으로 하고 saju_origin 없이 진행?

  Supabase WORKER_LIMIT 오류는 Edge Function 리소스 한계입니다. 무료 플랜에서는 동시 실행 제한이 있습니다.


## 개요

사주명리학 분석을 위한 AI 프롬프트 템플릿 모듈입니다.
`saju_analyses` 테이블의 데이터를 AI 모델에 전달하기 위한 프롬프트로 변환합니다.


  데이터 흐름 다이어그램

  [신규 사용자]
      ↓
  [프로필 생성] → Splash에서 saju_base 없음 감지
      ↓
  [백그라운드 GPT-5.2 호출] (Fire-and-forget)
      ↓
  [saju_origin 추출 + content에 추가]
      ↓
  [ai_summaries DB 저장] (summary_type='saju_base')
      ↓
  [Gemini 채팅 시작]
      ↓
  [AiSummaryService.getCachedSummary()] → saju_origin 파싱
      ↓
  [chat_provider._buildFullSystemPrompt()]
      ↓
  [첫 메시지: sajuOrigin 전체 포함]
  [이후 메시지: 히스토리 참조]

  결론: 코드 흐름은 올바르게 구현되어 있습니다.

  실제 테스트로 검증해 보겠습니다.




## 파일 구조

```
frontend/lib/AI/prompts/
├── README.md                       # 이 문서
├── FORTUNE_PROMPTS_DESIGN.md       # 운세 프롬프트 통합 설계
├── prompt_template.dart            # 프롬프트 템플릿 기본 클래스 + SajuInputData
├── saju_base_prompt.dart           # 평생 사주 분석 (GPT-5.2)
├── saju_base_prompt.md             # 평생 사주 프롬프트 설계 문서
├── daily_fortune_prompt.dart       # 일운 분석 (Gemini 3.0 Flash)
├── daily_fortune_prompt.md         # 일운 프롬프트 설계 문서
├── compatibility_prompt.dart       # 궁합 분석 - JSON (Gemini) v4.1
├── compatibility_chat_prompt.dart  # 궁합 채팅 - 대화형 (Gemini) v4.1
└── compatibility_chat_prompt.md    # 궁합 채팅 프롬프트 설계 문서
```

### 운세 프롬프트 (별도 폴더)
```
frontend/lib/AI/fortune/
├── monthly/PROMPT_DESIGN.md        # 이번달 운세 프롬프트 설계
├── yearly_2025/PROMPT_DESIGN.md    # 2025 회고운세 v3.1
└── yearly_2026/PROMPT_DESIGN.md    # 2026 신년운세 v5.1
```

---

## 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Supabase Database                              │
├─────────────────────────────────────────────────────────────────────────┤
│  saju_profiles              saju_analyses                               │
│  ├── display_name           ├── year_gan, year_ji (년주)                │
│  ├── birth_date             ├── month_gan, month_ji (월주)              │
│  ├── birth_time_minutes     ├── day_gan, day_ji (일주)                  │
│  ├── gender                 ├── hour_gan, hour_ji (시주)                │
│  └── is_lunar               ├── oheng_distribution (오행 분포)          │
│                             ├── day_strength (신강/신약)                │
│                             ├── yongsin (용신)                          │
│                             ├── gyeokguk (격국)                         │
│                             ├── sipsin_info (십신)                      │
│                             ├── twelve_unsung (12운성)                  │
│                             ├── twelve_sinsal (신살)                    │
│                             ├── gilseong (길성)                         │
│                             ├── hapchung (합충형파해)                   │
│                             └── daeun (대운)                            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │  AiQueries.convertToInputData │
                    │  (queries.dart)               │
                    └───────────────────────────────┘
                                    │
                                    ▼
                         ┌─────────────────┐
                         │  SajuInputData  │
                         │  (Dart 클래스)  │
                         └─────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
         ┌─────────────────────┐        ┌─────────────────────┐
         │  SajuBasePrompt     │        │  DailyFortunePrompt │
         │  (GPT-5.2)          │        │  (Gemini 3.0 Flash) │
         │  평생 사주 분석     │        │  오늘의 운세        │
         └─────────────────────┘        └─────────────────────┘
                    │                               │
                    ▼                               ▼
         ┌─────────────────────┐        ┌─────────────────────┐
         │  ai-openai EF       │        │  ai-gemini EF       │
         │  (Edge Function)    │        │  (Edge Function)    │
         └─────────────────────┘        └─────────────────────┘
                    │                               │
                    ▼                               ▼
         ┌─────────────────────────────────────────────────────┐
         │                   ai_summaries                      │
         │  summary_type = 'saju_base' | 'daily_fortune'       │
         └─────────────────────────────────────────────────────┘
```

---

## 프롬프트 비교

| 구분 | SajuBasePrompt | DailyFortunePrompt | CompatibilityPrompt |
|------|----------------|-------------------|---------------------|
| **목적** | 평생 사주 심층 분석 | 오늘의 운세 | 궁합 분석 |
| **모델** | GPT-5.2 (OpenAI) | Gemini 3.0 Flash | Gemini 2.0 Flash |
| **토큰** | 4096 | 2048 | 4096 |
| **Temperature** | 0.7 | 0.8 | 0.7 |
| **캐시** | 무기한 | 24시간 | 30일 |
| **비용** | ~$0.03/회 | ~$0.001/회 | ~$0.002/회 |
| **속도** | 5-10초 | 1-2초 | 2-3초 |
| **데이터** | saju_analyses | saju_analyses | saju_analyses + **pair_hapchung** |

### v4.1 궁합 분석 특징
- **100% Supabase 데이터**: AI가 사주 계산하지 않음
- **pair_hapchung 지원**: compatibility_analyses 테이블의 두 사람 간 합충 분석 데이터 활용
- **_buildTargetCalculationInstructions 제거**: 불필요한 AI 계산 로직 삭제

---

## saju_analyses 컬럼 → 프롬프트 매핑

| DB 컬럼 | SajuInputData 필드 | 프롬프트 섹션 |
|---------|-------------------|--------------|
| `year_gan`, `year_ji` | `saju['year_gan']`, `saju['year_ji']` | 사주 팔자 |
| `month_gan`, `month_ji` | `saju['month_gan']`, `saju['month_ji']` | 사주 팔자 |
| `day_gan`, `day_ji` | `saju['day_gan']`, `saju['day_ji']` | 사주 팔자, 일간 |
| `hour_gan`, `hour_ji` | `saju['hour_gan']`, `saju['hour_ji']` | 사주 팔자 |
| `oheng_distribution` | `oheng` | 오행 분포 |
| `day_strength` | `dayStrength` | 신강/신약 |
| `yongsin` | `yongsin` | 용신 정보 |
| `gyeokguk` | `gyeokguk` | 격국 |
| `sipsin_info` | `sipsinInfo` | 십신 배치 |
| `twelve_unsung` | `twelveUnsung` | 12운성 |
| `twelve_sinsal` | `sinsal` | 신살 |
| `gilseong` | `gilseong` | 길성 |
| `hapchung` | `hapchung` | 합충형파해 |
| `daeun` | `daeun` | 대운 |

---

## 실제 DB 데이터 예시

### saju_profiles (사용자 프로필)

```json
{
  "display_name": "이지나",
  "birth_date": "1999-07-27",
  "birth_time_minutes": 900,
  "gender": "female",
  "is_lunar": false
}
```

### saju_analyses (사주 분석 결과)

```json
{
  "year_gan": "기(己)",
  "year_ji": "묘(卯)",
  "month_gan": "신(辛)",
  "month_ji": "미(未)",
  "day_gan": "경(庚)",
  "day_ji": "진(辰)",
  "hour_gan": "계(癸)",
  "hour_ji": "미(未)",

  "oheng_distribution": {
    "금(金)": 2,
    "목(木)": 1,
    "수(水)": 1,
    "토(土)": 4,
    "화(火)": 0
  },

  "day_strength": {
    "level": "태강(太强)",
    "score": 75,
    "isStrong": true,
    "monthScore": 20,
    "bigeopScore": 10,
    "inseongScore": 20,
    "exhaustionScore": 6
  },

  "yongsin": {
    "yongsin": "수(水)",
    "heesin": "금(金)",
    "gisin": "토(土)",
    "gusin": "목(木)",
    "hansin": "화(火)",
    "method": "억부법(抑扶法)",
    "reason": "신강 사주 - 인성 과다로 식상(수)으로 설기"
  },

  "gyeokguk": {
    "name": "정인격(正印格)",
    "reason": "월지 정기(기)가 정인",
    "strength": 43,
    "isSpecial": false
  },

  "sipsin_info": {
    "yearGan": "정인(正印)",
    "yearJi": "정재(正財)",
    "monthGan": "겁재(劫財)",
    "monthJi": "정인(正印)",
    "dayJi": "편인(偏印)",
    "hourGan": "상관(傷官)",
    "hourJi": "정인(正印)"
  },

  "twelve_unsung": [
    {"pillar": "년주", "jiji": "묘", "unsung": "태(胎)", "strength": 5, "fortuneType": "평"},
    {"pillar": "월주", "jiji": "미", "unsung": "관대(冠帶)", "strength": 8, "fortuneType": "길"},
    {"pillar": "일주", "jiji": "진", "unsung": "양(養)", "strength": 6, "fortuneType": "평"},
    {"pillar": "시주", "jiji": "미", "unsung": "관대(冠帶)", "strength": 8, "fortuneType": "길"}
  ],

  "twelve_sinsal": [
    {"pillar": "년지", "jiji": "묘", "sinsal": "장성(將星)", "fortuneType": "길"},
    {"pillar": "월지", "jiji": "미", "sinsal": "화개(華蓋)", "fortuneType": "길흉혼합"},
    {"pillar": "일지", "jiji": "진", "sinsal": "반안(攀鞍)", "fortuneType": "길"},
    {"pillar": "시지", "jiji": "미", "sinsal": "화개(華蓋)", "fortuneType": "길흉혼합"}
  ],

  "gilseong": null,

  "hapchung": {
    "cheongan_haps": [],
    "cheongan_chungs": [],
    "jiji_samhaps": [
      {"pillars": ["년", "월"], "jijis": ["묘", "미"], "result_oheng": "목", "is_full": false},
      {"pillars": ["년", "시"], "jijis": ["묘", "미"], "result_oheng": "목", "is_full": false}
    ],
    "jiji_yukhaps": [],
    "jiji_banghaps": [],
    "jiji_chungs": [],
    "jiji_hyungs": [],
    "jiji_pas": [],
    "jiji_haes": [
      {"pillar1": "년", "pillar2": "일", "ji1": "묘", "ji2": "진"}
    ],
    "wonjins": [],
    "total_haps": 2,
    "total_chungs": 0,
    "total_negatives": 1,
    "has_relations": true
  },

  "daeun": {
    "startAge": 4,
    "isForward": true,
    "list": [
      {"order": 1, "pillar": "임(壬)신(申)", "startAge": 4, "endAge": 13},
      {"order": 2, "pillar": "계(癸)유(酉)", "startAge": 14, "endAge": 23},
      {"order": 3, "pillar": "갑(甲)술(戌)", "startAge": 24, "endAge": 33},
      {"order": 4, "pillar": "을(乙)해(亥)", "startAge": 34, "endAge": 43},
      {"order": 5, "pillar": "병(丙)자(子)", "startAge": 44, "endAge": 53},
      {"order": 6, "pillar": "정(丁)축(丑)", "startAge": 54, "endAge": 63},
      {"order": 7, "pillar": "무(戊)인(寅)", "startAge": 64, "endAge": 73},
      {"order": 8, "pillar": "기(己)묘(卯)", "startAge": 74, "endAge": 83},
      {"order": 9, "pillar": "경(庚)진(辰)", "startAge": 84, "endAge": 93},
      {"order": 10, "pillar": "신(辛)사(巳)", "startAge": 94, "endAge": 103}
    ]
  }
}
```

---

## 풀 프롬프트 예시

### 1. 평생 사주 분석 (GPT-5.2)

위 DB 데이터가 GPT-5.2에 전달되는 **실제 프롬프트**:

#### System Prompt

```
당신은 수십 년 경력의 사주명리학 전문가입니다.
다음 원칙을 따르세요:

## 분석 원칙
1. 용신(用神)을 중심으로 통변
2. 오행의 균형과 흐름 파악
3. 신강/신약에 따른 해석
4. 합충형파해 작용력 분석
5. 12운성과 신살의 실제적 영향

## 해석 스타일
- 전문적이되 이해하기 쉬운 설명
- 부정적 요소도 건설적으로 표현
- 구체적이고 실용적인 조언
- 미신적 표현 배제

## 응답 형식
반드시 JSON 형식으로 구조화된 분석을 반환하세요.
```

#### User Prompt

```
## 기본 정보
- 이름: 이지나
- 생년월일: 1999년 7월 27일
- 출생시간: 15:00
- 성별: 여성
- 역법: 양력

## 사주 팔자

| 구분 | 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|------|
| 천간 | 기 | 신 | 경 | 계 |
| 지지 | 묘 | 미 | 진 | 미 |

일간(Day Master): 경(庚)

## 오행 분포
- 목(木): 1
- 화(火): 0
- 토(土): 4
- 금(金): 2
- 수(水): 1

## 용신 정보
- 용신(用神): 수(水)
- 희신(喜神): 금(金)
- 기신(忌神): 토(土)
- 구신(仇神): 목(木)
- 한신(閑神): 화(火)
- 선정 방법: 억부법(抑扶法)
- 선정 근거: 신강 사주 - 인성 과다로 식상(수)으로 설기

## 신강/신약
- 판정: 태강(太强) (신강)
- 점수: 75
- 월령 점수: 20
- 비겁 점수: 10
- 인성 점수: 20
- 소진 점수: 6

## 격국
- 격국명: 정인격(正印格)
- 판정 근거: 월지 정기(기)가 정인
- 강도: 43
- 특별격 여부: 일반격

## 십신 배치
- 년간: 정인(正印)
- 년지: 정재(正財)
- 월간: 겁재(劫財)
- 월지: 정인(正印)
- 일지: 편인(偏印)
- 시간: 상관(傷官)
- 시지: 정인(正印)

## 12운성
- 년주(묘): 태(胎) [평]
- 월주(미): 관대(冠帶) [길]
- 일주(진): 양(養) [평]
- 시주(미): 관대(冠帶) [길]

## 신살
- 년지(묘): 장성(將星) [길]
- 월지(미): 화개(華蓋) [길흉혼합]
- 일지(진): 반안(攀鞍) [길]
- 시지(미): 화개(華蓋) [길흉혼합]

## 합충형파해

### 지지 삼합
- 년-월 묘미 반합 (목)
- 년-시 묘미 반합 (목)

### 지지 해
- 년-일 묘진 해

### 요약
- 총 합: 2개
- 총 충: 0개
- 총 부정적 관계: 1개

## 대운 (4세 시작, 순행)
1. 4~13세: 임(壬)신(申)
2. 14~23세: 계(癸)유(酉)
3. 24~33세: 갑(甲)술(戌)
4. 34~43세: 을(乙)해(亥)
5. 44~53세: 병(丙)자(子)
6. 54~63세: 정(丁)축(丑)
7. 64~73세: 무(戊)인(寅)
8. 74~83세: 기(己)묘(卯)
9. 84~93세: 경(庚)진(辰)
10. 94~103세: 신(辛)사(巳)

---

위 사주 정보를 종합하여 평생 사주 분석을 JSON 형식으로 제공해주세요.

반드시 아래 스키마를 따라주세요:

{
  "summary": {
    "keywords": ["성격 키워드 3-5개"],
    "one_line": "한 문장 요약"
  },
  "personality": {
    "strengths": ["강점 3-5개"],
    "weaknesses": ["약점 2-3개"],
    "description": "상세 성격 설명"
  },
  "career": {
    "suitable_fields": ["적합 직종 3-5개"],
    "unsuitable_fields": ["부적합 직종 2-3개"],
    "advice": "직업/진로 조언"
  },
  "wealth": {
    "tendency": "재물운 성향",
    "advice": "재물 관련 조언"
  },
  "relationships": {
    "tendency": "대인관계 성향",
    "marriage": "결혼운/배우자운",
    "advice": "관계 조언"
  },
  "health": {
    "weak_organs": ["취약 장기/부위"],
    "advice": "건강 조언"
  },
  "luck_cycle": {
    "current_daeun": "현재 대운 분석",
    "upcoming": "앞으로의 운세 흐름"
  },
  "advice": {
    "overall": "종합 조언",
    "yongsin_usage": "용신 활용법"
  }
}
```

---

### 2. 일운 분석 (Gemini 3.0 Flash)

#### System Prompt

```
당신은 친근하고 긍정적인 사주 상담사입니다. 오늘의 운세를 재미있고 실용적으로 안내해주세요.

## 원칙
1. 긍정적이고 희망적인 톤 유지
2. 구체적이고 실천 가능한 조언
3. 간결하고 핵심적인 내용
4. 일상에 적용할 수 있는 팁

## 응답 형식
JSON 형식으로 구조화된 일운을 반환하세요.
```

#### User Prompt

```
## 대상 정보
- 이름: 이지나
- 생년월일: 1999년 7월 27일
- 성별: 여성
- 일간: 경

## 사주 팔자
| 구분 | 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|------|
| 천간 | 기 | 신 | 경 | 계 |
| 지지 | 묘 | 미 | 진 | 미 |

## 오행 분포
- 목(木): 1
- 화(火): 0
- 토(土): 4
- 금(金): 2
- 수(水): 1

## 용신 정보
용신: 수(水), 희신: 금(金), 기신: 토(土), 구신: 목(木)

## 신강/신약
태강(太强) (점수: 75, 요인: 득령, 득시, 득세)

## 격국
정인격(正印格) (일반격) - 월지 정기(기)가 정인

## 12운성
년주: 태(胎), 월주: 관대(冠帶), 일주: 양(養), 시주: 관대(冠帶)

## 신살
년지: 장성(將星)(길), 월지: 화개(華蓋)(길흉혼합), 일지: 반안(攀鞍)(길), 시지: 화개(華蓋)(길흉혼합)

## 합충형파해
지지 삼합: 년-월 묘미 반합 (목), 년-시 묘미 반합 (목) | 지지 해: 년-일 묘진 해

## 대운
현재 대운: 갑(甲)술(戌) (24세 ~ 33세)

## 오늘 날짜
2024년 12월 30일 (월요일)

---

위 사주 정보를 종합하여 오늘 2024년 12월 30일의 운세를 JSON 형식으로 알려주세요.

반드시 아래 스키마를 따라주세요:

{
  "date": "2024년 12월 30일",
  "overall_score": 75,
  "overall_message": "오늘의 한마디 메시지",
  "categories": {
    "work": {
      "score": 80,
      "message": "업무/학업 관련 운세",
      "tip": "실천 팁"
    },
    "love": {
      "score": 70,
      "message": "연애/인간관계 운세",
      "tip": "실천 팁"
    },
    "wealth": {
      "score": 65,
      "message": "재물/금전 운세",
      "tip": "실천 팁"
    },
    "health": {
      "score": 85,
      "message": "건강 운세",
      "tip": "실천 팁"
    }
  },
  "lucky": {
    "color": "오늘의 행운 색",
    "number": 7,
    "time": "오후 2-4시",
    "direction": "동쪽"
  },
  "caution": "오늘 주의할 점 한 문장",
  "affirmation": "오늘의 긍정 확언"
}

점수는 0-100 사이로 설정해주세요.
```

---

## 관련 파일

| 파일 | 설명 |
|------|------|
| `../core/ai_constants.dart` | 모델명, 토큰 제한, 캐시 만료 상수 |
| `../data/queries.dart` | DB → SajuInputData 변환 |
| `../data/mutations.dart` | AI 결과 저장 |
| `../services/ai_api_service.dart` | Edge Function 호출 |
| `../../supabase/functions/ai-openai/` | OpenAI Edge Function |
| `../../supabase/functions/ai-gemini/` | Gemini Edge Function |
