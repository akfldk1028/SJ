# 궁합 채팅 프롬프트 구성 흐름

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `system_prompt_builder.dart` | 시스템 프롬프트 조립 (최종 출력) |
| `chat_provider.dart` (presentation/providers/) | 데이터 로드 + 프롬프트 빌더 호출 |
| `compatibility.md` (assets/prompts/) | 궁합 base prompt (사주명리학 분석 지침) |
| `saju_analysis_repository.dart` (core/repositories/) | saju_analyses 테이블 조회 |
| `compatibility_analysis_service.dart` (AI/services/) | 궁합 점수 계산 (Dart calculator) |
| `saju_chat_shell.dart` (presentation/screens/) | 궁합 채팅 진입점 (인연+ → 2명 선택) |
| `chat_session_provider.dart` (presentation/providers/) | 세션 상태 관리 (pendingParticipantIds) |

## 데이터 흐름 (궁합 채팅)

```
사용자: 2명 선택 (인연+)
    ↓
saju_chat_shell.dart
    → _handleCompatibilityChat()
    → CompatibilitySelection { participantIds: [person1Id, person2Id] }
    ↓
chat_provider.dart :: sendMessage()
    ↓
┌──────────────────────────────────────────────────┐
│  궁합 모드 판별 (chat_provider.dart:727-780)     │
├──────────────────────────────────────────────────┤
│  1차: effectiveParticipantIds (UI에서 직접 전달) │
│  2차: effectiveTargetProfileId (세션 저장값)     │
│  3차: chat_mentions 테이블 자동 복원 ← v8.0 FIX │
│       (두 번째 메시지부터 여기서 복원됨)         │
└──────────────────────────────────────────────────┘
    ↓
    → person1Id = participantIds[0]  (나)
    → person2Id = participantIds[1]  (상대방)
    → isCompatibilityMode = true
    ↓
┌─────────────────────────────────────────────┐
│  데이터 로드 (chat_provider.dart:940-1076)  │
│  (shouldLoadSaju = true 일 때만 실행)       │
├─────────────────────────────────────────────┤
│ 1. Person1 프로필  ← saju_profiles 테이블   │
│ 2. Person1 사주    ← saju_analyses 테이블   │
│ 3. Person2 프로필  ← saju_profiles 테이블   │
│ 4. Person2 사주    ← saju_analyses 테이블   │
│ 5. 궁합 분석       ← compatibility_analyses │
│    (캐시 있으면 재사용, 없으면 Dart 계산)    │
└─────────────────────────────────────────────┘
    ↓
_buildFullSystemPrompt() → SystemPromptBuilder.build()
    ↓
┌─────────────────────────────────────────────────────┐
│  시스템 프롬프트 조립 순서 (system_prompt_builder.dart) │
├─────────────────────────────────────────────────────┤
│  1. 현재 날짜 + 간지                                │
│  2. 페르소나 지시문                                  │
│  3. compatibility.md (base prompt)                   │
│  4. Person1 프로필 ← _addProfileInfo()              │
│     - 이름, 성별, 생년월일, 출생시간, 출생지역, 나이│
│  5. Person1 사주 8글자 ← _addSajuAnalysis()         │
│     - 사주팔자 테이블 (년주/월주/일주/시주)          │
│     - 오행 분포, 글자별 오행                         │
│     - 용신, 신강/신약, 격국, 십성, 신살              │
│  6. AI Summary (GPT-5.2 평생운세 분석 캐시)          │
│  7. Person2 프로필 ← _addTargetProfileInfo()        │
│     - 이름, 성별, 생년월일, 출생시간, 출생지역, 나이│
│  8. Person2 사주 8글자 ← _addSajuAnalysis()         │
│     ⚠️ targetSajuAnalysis가 null이면 안 들어감!     │
│  9. 궁합 분석 결과 ← _addCompatibilityAnalysisResult│
│     - 두 사람 8글자 비교 테이블                      │
│     - 오행 분포 비교                                 │
│     - 종합 점수 / 등급                               │
│     - pair_hapchung (합충형해파원진)                  │
│     - 상세 분석 (오행/합충/용신/신살/에너지)         │
│ 10. 궁합 지시문 (응답 형식 가이드)                   │
│ 11. 마무리 지시문                                    │
└─────────────────────────────────────────────────────┘
    ↓
Gemini 3.0 API 호출 (systemPrompt + userMessage)
```

## 궁합 모드 복원 메커니즘 (v8.0 수정)

### 문제
첫 번째 메시지 이후 `pendingCompatibilitySelection`이 클리어됨.
두 번째 메시지부터 `participantIds: null`, `targetId: null` → 일반 채팅 모드로 전환 → 사주 데이터 미로드 → AI가 상대방 8글자를 지어냄.

### 해결: chat_mentions 자동 복원
```dart
// chat_provider.dart else 분기 (line ~773)
// 명시적 ID가 없으면 chat_mentions에서 궁합 참여자 복원
final mentions = await Supabase.instance.client
    .from('chat_mentions')
    .select('target_profile_id, mention_order')
    .eq('session_id', sessionId)
    .order('mention_order');

if (mentions.length >= 2) {
  person1Id = mentions[0]['target_profile_id'];
  person2Id = mentions[1]['target_profile_id'];
  isCompatibilityMode = true;  // → shouldLoadSaju = true
}
```

### 흐름 (메시지별)
```
[첫 번째 메시지]
  UI → CompatibilitySelection.participantIds → person1Id, person2Id 직접 설정
  → chat_mentions 테이블에 기록됨
  → shouldLoadSaju = true → 사주 데이터 로드 ✅

[두 번째 이후 메시지]
  UI → participantIds: null, targetId: null
  → else 분기 진입
  → chat_mentions 테이블 조회 → person1Id, person2Id 복원
  → isCompatibilityMode = true
  → shouldLoadSaju = true → 사주 데이터 로드 ✅
```

## 참조 DB 테이블

| 테이블 | 용도 | 키 |
|--------|------|----|
| `saju_profiles` | 프로필 (이름, 생년월일, 성별, 출생시간, 출생지역) | `id` |
| `saju_analyses` | 사주 8글자 + 오행 + 용신 + 신살 등 | `profile_id` |
| `compatibility_analyses` | 궁합 분석 캐시 (점수, pair_hapchung) | `from_profile_id` + `to_profile_id` |
| `profile_relations` | 인연 관계 (관계 유형) | `from_profile_id` + `to_profile_id` |
| `chat_mentions` | 채팅에 참여한 프로필 ID 기록 (궁합 복원용) | `session_id` + `mention_order` |

## pair_hapchung 데이터 경로

두 가지 소스에서 가져올 수 있음:

```
1. DB 캐시: compatibility_analyses.pair_hapchung (JSONB)
   → analysis['pair_hapchung']

2. 새로 계산: CompatibilityResult.toJson()
   → analysis['hapchung_details']
```

`system_prompt_builder.dart:496`:
```dart
final pairHapchung = analysis['pair_hapchung'] ?? analysis['hapchung_details'];
```

## 프롬프트에 포함되는 데이터 요약

| 데이터 | 소스 | 프롬프트 함수 |
|--------|------|---------------|
| Person1 이름/성별/생년월일/출생시간/나이 | saju_profiles | `_addProfileInfo()` |
| Person1 사주 8글자 (년주/월주/일주/시주) | saju_analyses | `_addSajuAnalysis()` |
| Person1 오행분포/용신/격국/십성/신살 | saju_analyses | `_addSajuAnalysis()` |
| Person1 AI 평생운세 분석 | saju_analyses.ai_summary | `_addAISummary()` |
| Person2 이름/성별/생년월일/출생시간/나이 | saju_profiles | `_addTargetProfileInfo()` |
| Person2 사주 8글자 (년주/월주/일주/시주) | saju_analyses | `_addSajuAnalysis()` |
| Person2 오행분포/용신/격국/십성/신살 | saju_analyses | `_addSajuAnalysis()` |
| 궁합 종합점수/등급 | compatibility_analyses | `_addCompatibilityAnalysisResult()` |
| 합충형해파원진 (pair_hapchung) | compatibility_analyses | `_addCompatibilityAnalysisResult()` |
| 오행/합충/용신/신살/에너지 상세분석 | compatibility_analyses | `_addCompatibilityAnalysisResult()` |

## 디버그 로그 키워드

| 키워드 | 위치 | 내용 |
|--------|------|------|
| `[SajuAnalysisRepo]` | saju_analysis_repository.dart | DB 조회 성공/실패 + 8글자 |
| `📊 [5] SAJU_ANALYSES` | system_prompt_builder.dart | 프롬프트에 넣는 8글자 확인 |
| `[Person2] 사주: 있음/없음` | chat_provider.dart | targetSajuAnalysis null 여부 |
| `[DEBUG] 프롬프트 검증` | chat_provider.dart | 프롬프트에 Person2 정보 포함 여부 |
| `✅ chat_mentions에서 궁합 자동 복원` | chat_provider.dart | 두 번째 메시지 궁합 복원 성공 |
| `📝 일반 채팅 모드` | chat_provider.dart | 궁합 복원 실패 (chat_mentions 없음) |
| `shouldLoadSaju` | chat_provider.dart | 사주 데이터 로드 여부 결정값 |
| `[_ChatContent] build` | saju_chat_shell.dart | 세션/타겟 프로필 ID 상태 |

## 흔한 문제

### AI가 상대방 8글자를 지어냄
**원인**: `targetSajuAnalysis`가 null → Person2 사주 섹션이 프롬프트에 안 들어감
**확인**: 콘솔에서 `[Person2] 사주: 없음` 또는 `[SajuAnalysisRepo] ⚠️ 데이터 없음`
**해결**: saju_analyses 테이블에 해당 profile_id 행이 있는지 확인, RLS 정책 확인

### 두 번째 메시지에서 일반 채팅 모드로 전환됨
**원인**: `pendingCompatibilitySelection`이 첫 메시지 후 클리어 → participantIds null
**확인**: 콘솔에서 `📝 일반 채팅 모드 (궁합 아님)`, `shouldLoadSaju: false`
**해결**: v8.0에서 chat_mentions 자동 복원 추가로 수정됨. `✅ chat_mentions에서 궁합 자동 복원` 로그 확인.
만약 chat_mentions에 데이터가 없다면 첫 메시지에서 mentions 저장이 실패한 것 → chat_mentions INSERT 로직 확인.

### shouldLoadSaju가 false
**조건**: `isFirstMessageInSession || isCompatibilityMode || person2Id != null` 중 하나라도 true여야 함
**확인**: 위 3개 값 모두 false이면 사주 데이터를 아예 안 읽음
**해결**: 궁합 채팅이면 isCompatibilityMode가 true인지 확인 (chat_mentions 복원 로그 체크)
