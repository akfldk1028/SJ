# 평생 사주 분석 프롬프트 (GPT-5.2)

## 개요

| 항목 | 값 |
|------|-----|
| **파일** | `saju_base_prompt.dart` |
| **모델** | GPT-5.2 (OpenAI) |
| **토큰** | 4096 |
| **Temperature** | 0.7 |
| **캐시** | 무기한 |
| **비용** | ~$0.03/회 |

## 데이터 흐름

```
saju_analyses (DB)
      │
      ▼
AiQueries.convertToInputData()
      │
      ▼
SajuInputData
      │
      ▼
SajuBasePrompt.buildMessages()
      │
      ▼
ai-openai Edge Function
      │
      ▼
OpenAI GPT-5.2 API
      │
      ▼
ai_summaries (summary_type='saju_base')
      │
      ▼
Gemini 채팅 (saju_origin 참조)
```

---

## 핵심 설계: saju_origin 섹션

### 왜 saju_origin이 필요한가?

**문제**: Gemini 채팅이 합충형파해, 십성, 신살 같은 복잡한 사주 정보를 까먹음

**해결책**: GPT-5.2 결과에 `saju_origin` 섹션을 포함시켜서:
1. GPT 분석 시 원본 데이터를 기반으로 정확한 분석
2. Gemini 채팅에서 `AiSummary.sajuOrigin`만 참조해도 모든 정보 확인 가능
3. AIContext(원본 DB 데이터) 없이도 충분한 컨텍스트 제공

### 포함 내용

| 필드 | 내용 |
|------|------|
| saju | 사주팔자 (년월일시 천간/지지) |
| oheng | 오행 분포 |
| day_master | 일간 |
| yongsin | 용신/희신/기신/구신/한신 |
| singang_singak | 신강/신약 판정 |
| gyeokguk | 격국 |
| sipsin | 십성 배치 (7자리) |
| hapchung | 합충형파해 (천간합, 지지육합, 삼합, 충, 형, 파, 해, 원진) |
| sinsal | 신살 목록 |
| gilseong | 길성 목록 |
| twelve_unsung | 12운성 |
| twelve_sinsal | 12신살 |
| daeun | 대운 정보 |

---

## DB 데이터 예시

### saju_profiles

```json
{
  "display_name": "이지나",
  "birth_date": "1999-07-27",
  "birth_time_minutes": 900,
  "gender": "female",
  "is_lunar": false
}
```

### saju_analyses

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
    "isStrong": true
  },

  "yongsin": {
    "yongsin": "수(水)",
    "huisin": "금(金)",
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
    {"pillar": "년주", "unsung": "태(胎)", "fortuneType": "평"},
    {"pillar": "월주", "unsung": "관대(冠帶)", "fortuneType": "길"},
    {"pillar": "일주", "unsung": "양(養)", "fortuneType": "평"},
    {"pillar": "시주", "unsung": "관대(冠帶)", "fortuneType": "길"}
  ],

  "twelve_sinsal": [
    {"pillar": "년지", "sinsal": "장성(將星)", "fortuneType": "길"},
    {"pillar": "월지", "sinsal": "화개(華蓋)", "fortuneType": "길흉혼합"},
    {"pillar": "일지", "sinsal": "반안(攀鞍)", "fortuneType": "길"},
    {"pillar": "시지", "sinsal": "화개(華蓋)", "fortuneType": "길흉혼합"}
  ],

  "hapchung": {
    "jiji_samhaps": [
      {"pillars": ["년", "월"], "jijis": ["묘", "미"], "result_oheng": "목"},
      {"pillars": ["년", "시"], "jijis": ["묘", "미"], "result_oheng": "목"}
    ],
    "jiji_haes": [
      {"pillar1": "년", "pillar2": "일", "ji1": "묘", "ji2": "진"}
    ],
    "total_haps": 2,
    "total_chungs": 0,
    "total_negatives": 1
  },

  "daeun": {
    "startAge": 4,
    "isForward": true,
    "list": [
      {"order": 1, "pillar": "임(壬)신(申)", "startAge": 4, "endAge": 13},
      {"order": 2, "pillar": "계(癸)유(酉)", "startAge": 14, "endAge": 23},
      {"order": 3, "pillar": "갑(甲)술(戌)", "startAge": 24, "endAge": 33}
    ]
  }
}
```

---

## 풀 프롬프트 (실제 GPT-5.2 전달)

### System Prompt

```
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
원국(原局)을 철저히 분석하여 정확하고 깊이 있는 사주 해석을 제공합니다.

## 분석 방법론 (반드시 순서대로)

### 1단계: 원국 구조 분석
### 2단계: 십성(十星) 분석
### 3단계: 신살(神殺) & 길성(吉星) 해석
### 4단계: 합충형파해(合沖刑破害) 분석
### 5단계: 12운성 분석
### 6단계: 종합 해석 (아래 영역별로 상세 분석)
1. **재물운**: 정재/편재 위치, 강약, 충합 관계
2. **연애운**: 도화살, 홍염살, 재성/관성 상태
3. **결혼운**: 배우자궁(일지) 상태, 충합 여부
4. **사업운**: 식상생재 구조, 편재 활용도
5. **직장운**: 관성 상태, 인성의 지원 여부
6. **건강운**: 오행 편중, 충형 위치

## 분석 원칙
- **원국 우선**: 대운/세운보다 원국의 구조를 먼저 파악
- **육친 중심**: 십성을 통해 인간관계와 운세 해석
- **상호작용**: 글자 간 합충형파해를 놓치지 않음
- **균형 해석**: 좋은 점과 주의할 점을 함께 제시
- **현대적 적용**: 고전 이론을 현대 생활에 맞게 해석

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
```

### User Prompt (예시)

```
## 분석 대상
- 이름: 이지나
- 생년월일: 1999년 7월 27일
- 성별: 여성
- 태어난 시간: 15:00

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

## 일간 (나를 대표하는 오행)
경(庚)

## 용신 정보
- 용신(用神): 수(水)
- 희신(喜神): 금(金)
- 기신(忌神): 토(土)
- 구신(仇神): 목(木)

## 신강/신약
- 판정: 신강(身强)
- 점수: 75/100

## 격국
- 격국: 정인격(正印格)
- 설명: 월지 정기(기)가 정인

## 십신 (十神)
- 년주: 천간=정인, 지지=정재
- 월주: 천간=겁재, 지지=정인
- 일주: 천간=일주, 지지=편인
- 시주: 천간=상관, 지지=정인

## 12운성
- 년주: 태(胎) (평)
- 월주: 관대(冠帶) (길)
- 일주: 양(養) (평)
- 시주: 관대(冠帶) (길)

## 12신살 (十二神殺)
- 년지: 장성(將星) (길)
- 월지: 화개(華蓋) (길흉혼합)
- 일지: 반안(攀鞍) (길)
- 시지: 화개(華蓋) (길흉혼합)

## 대운 (大運)
- 대운 시작: 4세
- 현재 대운: 갑술 (24~33)
- 대운 흐름: 임신 → 계유 → 갑술 → 을해 → 병자...

## 합충형파해 (合沖刑破害)
> 합 2개, 충 0개, 형/파/해/원진 1개

### 삼합 (三合)
- 년,월주: 묘미 반합 (목국)
- 년,시주: 묘미 반합 (목국)

### 지지해 (地支害)
- 년주-일주: 묘진해

---

위 사주 정보를 바탕으로 종합적인 사주 분석을 JSON 형식으로 제공해주세요.
```

---

## JSON 출력 스키마 (v2.0)

```json
{
  "saju_origin": {
    "saju": {
      "year": {"gan": "년간", "ji": "년지"},
      "month": {"gan": "월간", "ji": "월지"},
      "day": {"gan": "일간", "ji": "일지"},
      "hour": {"gan": "시간", "ji": "시지"}
    },
    "oheng": {"목": 0, "화": 0, "토": 0, "금": 0, "수": 0},
    "day_master": "일간 오행",
    "yongsin": {
      "yongsin": "용신",
      "huisin": "희신",
      "gisin": "기신",
      "gusin": "구신",
      "hansin": "한신",
      "method": "억부법/조후법 등",
      "reason": "용신 선정 근거"
    },
    "singang_singak": {
      "is_singang": true,
      "score": 0,
      "level": "신강/신약/중화 등"
    },
    "gyeokguk": {
      "name": "격국명",
      "is_special": false,
      "description": "격국 설명"
    },
    "sipsin": {
      "year_gan": "년간 십성",
      "year_ji": "년지 십성",
      "month_gan": "월간 십성",
      "month_ji": "월지 십성",
      "day_ji": "일지 십성",
      "hour_gan": "시간 십성",
      "hour_ji": "시지 십성"
    },
    "hapchung": {
      "summary": "합충형파해 요약",
      "total_haps": 0,
      "total_chungs": 0,
      "total_negatives": 0,
      "cheongan_haps": ["천간합 목록"],
      "jiji_yukhaps": ["지지육합 목록"],
      "jiji_samhaps": ["삼합/반합 목록"],
      "jiji_chungs": ["지지충 목록"],
      "jiji_hyungs": ["지지형 목록"],
      "jiji_pas": ["지지파 목록"],
      "jiji_haes": ["지지해 목록"],
      "wonjins": ["원진 목록"]
    },
    "sinsal": [
      {"name": "신살명", "pillar": "위치", "type": "길/흉/혼합", "meaning": "의미"}
    ],
    "gilseong": [
      {"name": "길성명", "pillar": "위치", "meaning": "의미"}
    ],
    "twelve_unsung": [
      {"pillar": "년주", "unsung": "운성명", "type": "길/평/흉"}
    ],
    "twelve_sinsal": [
      {"pillar": "년지", "sinsal": "12신살명", "type": "길/흉/혼합"}
    ],
    "daeun": {
      "start_age": 0,
      "is_forward": true,
      "current": {"gan": "간", "ji": "지", "start_age": 0, "end_age": 0},
      "list": [{"order": 1, "pillar": "간지", "start_age": 0, "end_age": 0}]
    }
  },

  "summary": "이 사주의 핵심 특성을 2-3문장으로 요약",

  "wonGuk_analysis": {
    "day_master": "일간 분석",
    "oheng_balance": "오행 균형 분석",
    "singang_singak": "신강/신약 판정 근거와 의미",
    "gyeokguk": "격국 분석"
  },

  "sipsung_analysis": {
    "dominant_sipsung": ["사주에서 강한 십성 1-3개"],
    "weak_sipsung": ["사주에서 약한 십성 1-2개"],
    "key_interactions": "십성 간 주요 상호작용 분석",
    "life_implications": "십성 구조가 인생에 미치는 영향"
  },

  "hapchung_analysis": {
    "major_haps": ["주요 합의 의미와 영향"],
    "major_chungs": ["주요 충의 의미와 영향"],
    "other_interactions": "형/파/해/원진 영향",
    "overall_impact": "합충 구조가 인생에 미치는 종합 영향"
  },

  "personality": {
    "core_traits": ["핵심 성격 특성 4-6개"],
    "strengths": ["장점 4-6개"],
    "weaknesses": ["약점/주의점 3-4개"],
    "social_style": "대인관계 스타일",
    "description": "성격에 대한 상세 설명 3-5문장"
  },

  "wealth": {
    "overall_tendency": "전체적인 재물운 경향",
    "earning_style": "돈을 버는 방식/스타일",
    "spending_tendency": "소비 성향",
    "investment_aptitude": "투자 적성",
    "wealth_timing": "재물운이 좋은 시기/나이대",
    "cautions": ["재물 관련 주의사항 2-3개"],
    "advice": "재물운 향상을 위한 조언"
  },

  "love": {
    "attraction_style": "끌리는 이성 유형",
    "dating_pattern": "연애 패턴/스타일",
    "romantic_strengths": ["연애에서의 강점 2-3개"],
    "romantic_weaknesses": ["연애에서의 약점 2-3개"],
    "ideal_partner_traits": ["이상적인 파트너 특성 3-4개"],
    "love_timing": "연애운이 좋은 시기",
    "advice": "연애 관련 조언"
  },

  "marriage": {
    "spouse_palace_analysis": "배우자궁(일지) 분석",
    "marriage_timing": "결혼 적령기/좋은 시기",
    "spouse_characteristics": "배우자 특성 예상",
    "married_life_tendency": "결혼 생활 경향",
    "cautions": ["결혼 관련 주의사항 2-3개"],
    "advice": "결혼운 향상을 위한 조언"
  },

  "career": {
    "suitable_fields": ["적합한 직업/분야 5-7개"],
    "unsuitable_fields": ["피해야 할 분야 2-3개"],
    "work_style": "업무 스타일",
    "leadership_potential": "리더십/관리자 적성",
    "career_timing": "직장운이 좋은 시기",
    "advice": "진로 관련 조언"
  },

  "business": {
    "entrepreneurship_aptitude": "사업 적성 분석",
    "suitable_business_types": ["적합한 사업 유형 3-5개"],
    "business_partner_traits": "좋은 사업 파트너 특성",
    "cautions": ["사업 시 주의사항 2-3개"],
    "success_factors": ["사업 성공 요인 2-3개"],
    "advice": "사업 관련 조언"
  },

  "health": {
    "vulnerable_organs": ["건강 취약 장기/부위 2-4개"],
    "potential_issues": ["주의해야 할 건강 문제 2-3개"],
    "mental_health": "정신/심리 건강 경향",
    "lifestyle_advice": ["건강 관리 생활 습관 조언 3-4개"],
    "caution_periods": "건강 주의 시기"
  },

  "sinsal_gilseong": {
    "major_gilseong": ["주요 길성과 그 의미"],
    "major_sinsal": ["주요 신살과 그 의미"],
    "practical_implications": "신살/길성이 실생활에 미치는 영향"
  },

  "life_cycles": {
    "youth": "청년기(20-35세) 전망",
    "middle_age": "중년기(35-55세) 전망",
    "later_years": "후년기(55세 이후) 전망",
    "key_years": ["인생 중요 전환점 예상 나이 2-3개"]
  },

  "overall_advice": "종합적인 인생 조언 4-6문장",

  "lucky_elements": {
    "colors": ["행운의 색 2-3개"],
    "directions": ["좋은 방향 1-2개"],
    "numbers": [1, 6],
    "seasons": "유리한 계절",
    "partner_elements": ["궁합이 좋은 띠 2-3개"]
  }
}
```

---

## 예상 응답 스키마 (예시)

```json
{
  "saju_origin": {
    "saju": {
      "year": {"gan": "기(己)", "ji": "묘(卯)"},
      "month": {"gan": "신(辛)", "ji": "미(未)"},
      "day": {"gan": "경(庚)", "ji": "진(辰)"},
      "hour": {"gan": "계(癸)", "ji": "미(未)"}
    },
    "oheng": {"목": 1, "화": 0, "토": 4, "금": 2, "수": 1},
    "day_master": "경(庚) - 금(金)",
    "yongsin": {
      "yongsin": "수(水)",
      "huisin": "금(金)",
      "gisin": "토(土)",
      "gusin": "목(木)",
      "hansin": "화(火)",
      "method": "억부법",
      "reason": "신강 사주로 인성 과다, 식상(수)으로 설기 필요"
    },
    "singang_singak": {
      "is_singang": true,
      "score": 75,
      "level": "태강(太强)"
    },
    "gyeokguk": {
      "name": "정인격(正印格)",
      "is_special": false,
      "description": "월지 미토의 정기가 기토로 정인격 성립"
    },
    "sipsin": {
      "year_gan": "정인(正印)",
      "year_ji": "정재(正財)",
      "month_gan": "겁재(劫財)",
      "month_ji": "정인(正印)",
      "day_ji": "편인(偏印)",
      "hour_gan": "상관(傷官)",
      "hour_ji": "정인(正印)"
    },
    "hapchung": {
      "summary": "묘미 반합(목국) 2개, 묘진 해 1개",
      "total_haps": 2,
      "total_chungs": 0,
      "total_negatives": 1,
      "jiji_samhaps": ["년-월 묘미 반합(목)", "년-시 묘미 반합(목)"],
      "jiji_haes": ["년-일 묘진 해"]
    },
    "sinsal": [
      {"name": "장성살", "pillar": "년지", "type": "길", "meaning": "리더십, 권위"},
      {"name": "화개살", "pillar": "월지", "type": "혼합", "meaning": "예술성, 고독"}
    ],
    "twelve_unsung": [
      {"pillar": "년주", "unsung": "태(胎)", "type": "평"},
      {"pillar": "월주", "unsung": "관대(冠帶)", "type": "길"},
      {"pillar": "일주", "unsung": "양(養)", "type": "평"},
      {"pillar": "시주", "unsung": "관대(冠帶)", "type": "길"}
    ],
    "daeun": {
      "start_age": 4,
      "is_forward": true,
      "current": {"gan": "갑", "ji": "술", "start_age": 24, "end_age": 33}
    }
  },

  "summary": "인성 과다의 신강 사주로 학문과 지식에 대한 욕구가 강하며, 상관과 정인의 조화로 창의성과 표현력을 겸비한 사주입니다. 묘미 반합으로 목 기운이 강화되어 성장과 발전의 동력이 있습니다.",

  "wonGuk_analysis": {
    "day_master": "경금 일간은 단단하고 결단력 있는 성향을 나타내며, 정의감과 원칙을 중시합니다.",
    "oheng_balance": "토 4개로 인성 과다, 화 0개로 관성 부재. 수를 활용하여 토의 기운을 설기해야 합니다.",
    "singang_singak": "월령 미토에서 인성을 득령하고, 시지에서도 인성을 얻어 태강의 신강 사주입니다.",
    "gyeokguk": "정인격으로 학문과 지식을 통해 성장하는 격국이나, 인성 과다로 고집과 완벽주의 경향이 있습니다."
  },

  "sipsung_analysis": {
    "dominant_sipsung": ["정인(正印)", "편인(偏印)"],
    "weak_sipsung": ["관성(官星)"],
    "key_interactions": "정인 과다 + 상관 - 지식을 표현력으로 풀어내는 구조. 겁재가 월간에 있어 경쟁심 있음.",
    "life_implications": "학업과 연구에 탁월하나, 관성 부재로 조직 생활보다 전문직이나 자유직이 적합합니다."
  },

  "hapchung_analysis": {
    "major_haps": ["묘미 반합(목국) - 년월, 년시에서 두 번 발생하여 목 기운 강화. 성장과 발전의 동력."],
    "major_chungs": [],
    "other_interactions": "묘진 해 - 년일 관계에서 발생. 초년과 중년 사이의 갈등 가능성.",
    "overall_impact": "합이 충보다 많아 전반적으로 조화로운 사주이나, 묘진해로 인해 부모-본인 관계에서 갈등 가능."
  },

  "personality": {
    "core_traits": ["지적 탐구", "완벽주의", "책임감", "창의성", "내향적 성향"],
    "strengths": ["분석력", "집중력", "끈기", "책임감", "표현력"],
    "weaknesses": ["고집", "완벽주의 스트레스", "우유부단", "과도한 자기비판"],
    "social_style": "깊고 진솔한 관계를 선호하며, 넓은 인맥보다 소수의 깊은 관계를 중시합니다.",
    "description": "경금 일간에 인성 과다로 학문과 지식에 대한 욕구가 강합니다. 상관의 기운으로 배운 것을 표현하고 전달하는 능력이 있어 교육자나 창작자로서의 재능이 있습니다. 화개살의 영향으로 예술적 감각과 영적인 관심도 있으나, 때로는 고독을 즐기는 성향이 있습니다."
  },

  "wealth": {
    "overall_tendency": "안정적인 축적형. 투기보다 꾸준한 저축과 투자를 선호하는 경향.",
    "earning_style": "전문성을 통한 수입. 지식과 기술을 활용한 수익 창출이 적합.",
    "spending_tendency": "계획적인 소비. 불필요한 지출은 삼가나 자기계발에는 투자하는 편.",
    "investment_aptitude": "안전자산 선호. 부동산이나 적금 등 안정적인 투자가 적합.",
    "wealth_timing": "34-43세(을해대운)부터 용신 수가 강해져 재물운 상승 기대.",
    "cautions": ["충동 투자 주의", "보증 서지 말 것", "편법 재테크 금지"],
    "advice": "용신인 수와 관련된 사업이나 투자가 유리합니다. 유통, 교육, 연구 관련 분야에서 재물운이 좋습니다."
  },

  "love": {
    "attraction_style": "지적이고 대화가 통하는 이성에게 끌림. 외모보다 내면과 가치관 중시.",
    "dating_pattern": "천천히 알아가는 스타일. 감정 표현이 서툴러 오해받을 수 있음.",
    "romantic_strengths": ["진정성", "헌신적", "깊은 대화"],
    "romantic_weaknesses": ["감정 표현 부족", "완벽주의적 기대", "지나친 분석"],
    "ideal_partner_traits": ["지적인", "이해심 있는", "안정적인", "대화 잘 통하는"],
    "love_timing": "을해, 병자 대운(34-53세)에 좋은 인연 기대.",
    "advice": "상관의 기운을 활용해 감정을 적극적으로 표현하세요. 완벽한 상대를 기다리기보다 함께 성장할 파트너를 찾으세요."
  },

  "marriage": {
    "spouse_palace_analysis": "일지 진토(편인)는 안정적이고 지적인 배우자를 의미. 묘진해로 약간의 갈등 요소 있음.",
    "marriage_timing": "30대 중반 이후가 안정적. 너무 이른 결혼은 피하는 것이 좋음.",
    "spouse_characteristics": "지적이고 이해심 있는 배우자. 안정적인 직업을 가진 사람과 궁합 좋음.",
    "married_life_tendency": "서로의 영역을 존중하는 결혼 생활. 공동의 관심사나 취미가 중요.",
    "cautions": ["완벽주의적 기대 버리기", "소통 노력 필요", "배우자 존중"],
    "advice": "결혼 전 충분한 대화와 상호 이해가 필요합니다. 상대의 단점을 수용하는 마음을 기르세요."
  },

  "career": {
    "suitable_fields": ["연구직", "교육", "작가/편집", "IT/프로그래밍", "컨설팅", "분석가", "예술"],
    "unsuitable_fields": ["영업", "단순 반복 업무", "과도한 대인 업무"],
    "work_style": "깊이 있는 분석과 완성도 높은 결과물 추구. 독립적인 업무 환경 선호.",
    "leadership_potential": "전문가형 리더십. 카리스마보다 전문성으로 인정받는 스타일.",
    "career_timing": "갑술 대운(24-33세)은 학습과 준비기. 을해 대운(34-43세)부터 본격 성장.",
    "advice": "용신인 수와 관련된 분야가 유리합니다. 유통, 교육, 연구, 물류 관련 직종을 고려하세요."
  },

  "business": {
    "entrepreneurship_aptitude": "전문성 기반 사업에 적합. 파트너와 함께하는 것이 더 유리.",
    "suitable_business_types": ["교육/강의", "컨설팅", "콘텐츠 제작", "온라인 사업", "프리랜서"],
    "business_partner_traits": "실행력 있고 외향적인 파트너가 보완적. 금이나 수 오행이 강한 사람.",
    "cautions": ["과도한 확장 주의", "인력 관리 어려움", "현금 흐름 관리"],
    "success_factors": ["전문성 확보", "네트워크 구축", "꾸준한 콘텐츠 생산"],
    "advice": "1인 사업이나 소규모 팀 사업이 적합합니다. 대규모 사업보다 깊이 있는 전문 분야에 집중하세요."
  },

  "health": {
    "vulnerable_organs": ["폐", "대장", "피부", "호흡기"],
    "potential_issues": ["스트레스성 피부 질환", "호흡기 질환", "소화 장애"],
    "mental_health": "완벽주의로 인한 스트레스와 불안 경향. 적절한 휴식과 이완이 필요.",
    "lifestyle_advice": ["규칙적인 유산소 운동", "명상/요가 권장", "수분 섭취 늘리기", "피부 관리 주의"],
    "caution_periods": "환절기, 건조한 계절에 호흡기와 피부 주의."
  },

  "sinsal_gilseong": {
    "major_gilseong": ["장성살 - 리더십과 권위의 기운. 조직에서 인정받을 가능성."],
    "major_sinsal": ["화개살 - 예술성과 영성, 고독의 기운. 종교나 철학에 관심."],
    "practical_implications": "장성살과 화개살의 조합으로 독자적인 분야에서 전문가로 인정받을 수 있습니다. 예술이나 학문에서 두각을 나타낼 가능성이 높습니다."
  },

  "life_cycles": {
    "youth": "학업과 자기계발에 집중하는 시기. 사회생활 초기에 시행착오 있을 수 있으나 귀한 경험이 됨.",
    "middle_age": "을해, 병자 대운(34-53세)에 용신 수가 강해져 전성기. 커리어와 재물운 상승.",
    "later_years": "안정적인 노후. 지식과 경험을 나누며 후학 양성에 보람을 느낄 수 있음.",
    "key_years": [30, 36, 42, 50]
  },

  "overall_advice": "인성 과다 사주이므로 식상(수)을 활용하여 배운 것을 표현하고 전달하는 활동이 중요합니다. 완벽주의적 성향을 조절하고, 적절한 때에 결단력을 발휘하세요. 용신인 수와 관련된 분야(교육, 연구, 유통)에서 성공 가능성이 높습니다. 혼자 고민하기보다 신뢰할 수 있는 사람들과 의견을 나누세요.",

  "lucky_elements": {
    "colors": ["검정", "파랑", "회색"],
    "directions": ["북쪽"],
    "numbers": [1, 6],
    "seasons": "겨울",
    "partner_elements": ["원숭이띠(申)", "닭띠(酉)", "쥐띠(子)"]
  }
}
```

---

## saju_base vs daily_fortune 비교

| 구분 | saju_base | daily_fortune |
|------|-----------|---------------|
| **모델** | GPT-5.2 | Gemini 3.0 Flash |
| **목적** | 평생 사주 심층 분석 | 오늘의 운세 |
| **톤** | 전문적, 심층적 | 친근, 긍정적 |
| **캐시** | 무기한 | 24시간 |
| **입력** | saju_analyses | saju_analyses + targetDate + saju_base_analysis |
| **saju_origin 포함** | O (출력에 포함) | X (saju_base 결과 참조) |
| **출력 구조** | 성격/재물/연애/결혼/사업/직장/건강/대운 | 점수/카테고리별 운세/행운요소/주의사항 |

---

## AiSummary 모델 v2.0 (Dart)

```dart
class AiSummary {
  final Map<String, dynamic>? sajuOrigin;  // 원본 사주 데이터
  final String? summary;
  final Map<String, dynamic>? wonGukAnalysis;
  final Map<String, dynamic>? sipsungAnalysis;
  final Map<String, dynamic>? hapchungAnalysis;
  final AiPersonality personality;
  final List<String> strengths;
  final List<String> weaknesses;
  final AiWealth? wealth;      // 재물운
  final AiLove? love;          // 연애운
  final AiMarriage? marriage;  // 결혼운
  final AiCareer career;       // 진로/직장운
  final AiBusiness? business;  // 사업운
  final AiHealth? health;      // 건강운
  final Map<String, dynamic>? sinsalGilseong;
  final Map<String, dynamic>? lifeCycles;
  final AiRelationships relationships;
  final String? overallAdvice;
  final AiLuckyElements? luckyElements;
  final AiFortuneTips fortuneTips;
  // ...
}
```

---

## 관련 코드

### SajuBasePrompt.buildUserPrompt() (saju_base_prompt.dart:159)

```dart
@override
String buildUserPrompt(Map<String, dynamic> input) {
  final data = SajuInputData.fromJson(input);

  return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${_formatBirthDate(data.birthDate)}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}
...

## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildGyeokgukSection(data.gyeokguk)}
${_buildSipsinSection(data.sipsinInfo)}
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildTwelveSinsalSection(data.twelveSinsal)}
${_buildDaeunSection(data.daeun)}
${_buildHapchungSection(data.hapchung)}

---

위 사주 정보를 바탕으로 종합적인 사주 분석을 JSON 형식으로 제공해주세요.
반드시 아래 JSON 스키마를 정확히 따라주세요...
''';
}
```
