# 궁합 채팅 프롬프트 (대화형)

## 파일 경로

```
frontend/lib/AI/prompts/compatibility_chat_prompt.dart  ← Dart 클래스
frontend/lib/AI/prompts/compatibility_chat_prompt.md    ← 이 문서
```

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `features/saju_chat/presentation/screens/saju_chat_shell.dart` | 멘션 감지 + 세션 생성 |
| `features/saju_chat/presentation/widgets/chat_input_field.dart` | 멘션 입력 UI |
| `AI/prompts/compatibility_prompt.dart` | 궁합 분석 (JSON 응답) - 참고용 |
| `AI/common/providers/google/gemini_provider.dart` | Gemini API 호출 |

---

## 데이터 흐름

```
1. 사용자가 + 버튼 → 인연 선택
         ↓
2. 입력 필드에 "@친구/ooo " 자동 삽입
         ↓
3. 사용자가 메시지 추가 후 전송
         ↓
4. saju_chat_shell.dart에서 멘션 패턴 감지
   → RegExp(r'@[^\s/]+/[^\s]+')
         ↓
5. targetProfileId로 상대방 프로필 조회
         ↓
6. 두 사람 사주 데이터 로드 (사주, 오행, 용신, 합충, 신살 등)
         ↓
7. CompatibilityChatPrompt.buildUserPrompt() 호출
         ↓
8. Gemini API → 대화체 응답
```

---

## System Prompt (AI에게 주는 역할 지시)

```
당신은 따뜻하고 통찰력 있는 사주 궁합 상담사입니다.
두 사람의 사주를 분석하여 궁합에 대해 친근하게 대화합니다.

## 궁합 분석 방법론

### 1단계: 오행 상생상극 분석
두 사람의 일간(日干)을 중심으로 오행 관계 분석
- **상생 관계** (木→火→土→金→水): 서로 도움을 주는 관계
- **상극 관계** (木→土→水→火→金): 한쪽이 제압하는 관계
- **비화 관계** (같은 오행): 동질성으로 인한 경쟁 또는 동지

### 2단계: 합충 상호작용 분석
- **천간합**: 갑기합, 을경합, 병신합, 정임합, 무계합 → 강한 끌림
- **지지육합**: 자축합, 인해합, 묘술합 등 → 깊은 유대감
- **충(沖)**: 자오충, 인신충 등 → 초기 갈등, 보완 가능

### 3단계: 용신 호환성 분석
- 서로의 용신이 상대방에게 어떤 영향을 주는지
- 용신이 상대의 기신이면 갈등, 희신이면 도움

### 4단계: 신살 상호작용
- 도화살 + 도화살: 강한 끌림
- 역마살 + 역마살: 함께 이동/여행 많음
- 천을귀인: 서로에게 귀인이 될 수 있는지

## 상담 원칙
- 존댓말 사용
- 쉬운 용어로 설명
- 부정적 내용도 희망적 관점으로
- 운명론적 단정 금지 ("절대 안 맞아요" X)

## 응답 형식
- 일반 텍스트 (JSON 아님)
- 2-4문단 대화체
```

---

## 입력 데이터 (buildUserPrompt에 들어가는 값)

```json
{
  "user_profile": {
    "name": "이지나",
    "birth_date": "1999-07-27",
    "gender": "female",
    "day_master": "경(庚)",
    "oheng": {"wood": 1, "fire": 0, "earth": 4, "metal": 2, "water": 1},
    "yongsin": {
      "yongsin": "수(水)",
      "heesin": "금(金)",
      "gisin": "토(土)"
    },
    "saju": {
      "year": {"gan": "기", "ji": "묘"},
      "month": {"gan": "신", "ji": "미"},
      "day": {"gan": "경", "ji": "진"},
      "hour": {"gan": "계", "ji": "미"}
    },
    "hapchung": {
      "cheongan_haps": [],
      "jiji_yukhaps": ["진유합"],
      "jiji_chungs": []
    },
    "sinsal": [
      {"name": "천을귀인", "type": "길신"},
      {"name": "역마살", "type": "중성"}
    ]
  },
  "target_profile": {
    "name": "ooo",
    "birth_date": "1998-03-15",
    "gender": "male",
    "day_master": "갑(甲)",
    "oheng": {"wood": 3, "fire": 2, "earth": 2, "metal": 0, "water": 1},
    "yongsin": {
      "yongsin": "금(金)",
      "heesin": "토(土)",
      "gisin": "수(水)"
    },
    "saju": {
      "year": {"gan": "무", "ji": "인"},
      "month": {"gan": "을", "ji": "묘"},
      "day": {"gan": "갑", "ji": "오"},
      "hour": {"gan": "병", "ji": "진"}
    },
    "hapchung": {
      "cheongan_haps": [],
      "jiji_yukhaps": [],
      "jiji_chungs": ["인신충"]
    },
    "sinsal": [
      {"name": "도화살", "type": "중성"},
      {"name": "문창귀인", "type": "길신"}
    ]
  },
  "relation_category": "friend_close",
  "user_message": "이 사람이랑 잘 맞을까요?"
}
```

---

## 프롬프트 생성 결과 (User Prompt)

```
## 상담 요청자 (나)
- 이름: 이지나
- 생년월일: 1999-07-27 (여성)
- 일간: 경(庚) - 금(金)
- 용신: 수(水) / 희신: 금(金) / 기신: 토(土)
- 오행: 목1 화0 토4 금2 수1

#### 사주 팔자
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| 기묘 | 신미 | 경진 | 계미 |

#### 합충
- 지지육합: 진유합

#### 신살
- 천을귀인 (길신)
- 역마살 (중성)

---

## 궁합 상대 (절친한 친구)
- 이름: ooo
- 생년월일: 1998-03-15 (남성)
- 일간: 갑(甲) - 목(木)
- 용신: 금(金) / 희신: 토(土) / 기신: 수(水)
- 오행: 목3 화2 토2 금0 수1

#### 사주 팔자
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| 무인 | 을묘 | 갑오 | 병진 |

#### 합충
- 지지충: 인신충

#### 신살
- 도화살 (중성)
- 문창귀인 (길신)

---

## 사용자 질문
이 사람이랑 잘 맞을까요?

---
위 두 사람의 궁합에 대해 친근하게 답변해주세요.
```

---

## AI 응답 예시

```
ooo님과의 궁합을 살펴볼게요!

지나님은 경금(庚金) 일간으로 단단하고 결단력 있는 성향이시고,
ooo님은 갑목(甲木) 일간으로 성장하고 뻗어나가려는 기운이 강하세요.

**금극목(金剋木)** 관계인데요, 이게 꼭 나쁜 건 아니에요.
오히려 지나님이 ooo님에게 날카로운 피드백을 줄 수 있고,
그게 ooo님 성장에 도움이 될 수 있어요.

특히 좋은 점은 **ooo님의 용신이 금(金)**인데,
지나님이 금이 강하셔서 ooo님에게 필요한 에너지를 줄 수 있어요!
함께 있으면 ooo님이 안정감을 느끼실 거예요.

다만 ooo님 사주에 **인신충**이 있어서 변화가 많은 스타일이에요.
지나님은 안정을 추구하시는 편이라 이 부분에서 템포 차이가 있을 수 있어요.
서로의 속도를 존중해주시면 좋겠습니다.

전체적으로 서로 배울 점이 많은 궁합이에요!
다른 점이 매력이 될 수 있으니 열린 마음으로 대화해보세요.
```

---

## compatibility_prompt.dart와 차이점

| 항목 | compatibility_prompt | compatibility_chat_prompt |
|------|---------------------|--------------------------|
| **용도** | 궁합 분석 리포트 | 대화형 상담 |
| **응답 형식** | JSON (구조화) | Plain Text (대화체) |
| **응답 길이** | 긴 분석 (4096 토큰) | 짧은 대화 (2048 토큰) |
| **Temperature** | 0.7 (일관성) | 0.8 (자연스러움) |
| **트리거** | 궁합 분석 버튼 | @멘션 + 메시지 |
| **데이터** | 전체 상세 데이터 | 핵심 데이터 (간소화) |

---

## Dart 구현 참고

```dart
class CompatibilityChatPrompt extends BaseChatPrompt {
  final String? relationType;

  @override
  String get modelName => GoogleModels.gemini20Flash;

  @override
  int get maxTokens => 2048;

  @override
  double get temperature => 0.8;

  @override
  String buildUserPrompt(Map<String, dynamic> input) {
    final data = CompatibilityChatInputData.fromJson(input);

    return '''
## 상담 요청자 (나)
- 이름: ${data.userName}
- 생년월일: ${data.userBirthDate} (${data.userGenderLabel})
- 일간: ${data.userDayMaster}
- 용신: ${data.userYongsinString}
- 오행: ${data.userOhengString}

#### 사주 팔자
${data.userSajuTable}

#### 합충
${data.userHapchungString}

#### 신살
${data.userSinsalString}

---

## 궁합 상대 (${data.relationLabel})
- 이름: ${data.targetName}
- 생년월일: ${data.targetBirthDate} (${data.targetGenderLabel})
- 일간: ${data.targetDayMaster}
- 용신: ${data.targetYongsinString}
- 오행: ${data.targetOhengString}

#### 사주 팔자
${data.targetSajuTable}

#### 합충
${data.targetHapchungString}

#### 신살
${data.targetSinsalString}

---

## 사용자 질문
${data.userMessage}

---
위 두 사람의 궁합에 대해 친근하게 답변해주세요.
''';
  }
}
```
