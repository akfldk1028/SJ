# Phase 59: 인연 추가 로직 흐름도

> 작성일: 2026-02-04
> 버전: Phase 59
> 상태: 구현 완료

---

## 1. 개요

Phase 59는 **채팅 중 인연(참가자)을 자유롭게 추가/변경할 수 있는 시스템**입니다.
모든 시나리오에서 참가자가 `chat_mentions` 테이블에 저장되며, 앱 재시작 시에도 복원됩니다.

### 지원 시나리오

| # | 시나리오 | 예시 |
|---|---------|------|
| 1 | 일반 채팅 (멘션 없음) | "오늘 운세 알려줘" |
| 2 | 처음부터 2명 궁합 (나 포함) | 나 + 하위 궁합 |
| 3 | 처음부터 나 제외 궁합 | 하위 + 종환 궁합 |
| 4 | 중간에 인연 추가 | 나+하위 채팅 중 → 종환 추가 |
| 5 | **중간에 "나" 추가** | 하위+종환 채팅 중 → 나 추가 |
| 6 | 텍스트 멘션 3명+ | @친구/하위 @친구/종환 @가족/어머니 |
| 7 | 앱 재시작 → 세션 복원 | 전체 참가자 + AI 컨텍스트 복원 |
| 8 | 대화 중 인연 등록 후 멘션 | 새 인연 등록 → 바로 멘션 가능 |

---

## 2. 파일 구조 및 역할

```
saju_chat/
├── presentation/
│   ├── widgets/
│   │   ├── relation_selector_sheet.dart   # [UI] 인연 선택 바텀시트
│   │   └── mention_send_handler.dart      # [파싱] 멘션 텍스트 → ID 변환
│   └── providers/
│       └── chat_provider.dart             # [오케스트레이터] sendMessage() 진입점
└── data/
    └── services/
        ├── participant_resolver.dart       # [참가자 결정] 병합/저장 핵심 로직
        ├── compatibility_data_loader.dart  # [데이터 로드] 프로필/사주 로드
        └── session_restore_service.dart    # [복원] 앱 재시작 시 세션 복원
```

---

## 3. 전체 데이터 흐름

```
사용자 입력 (텍스트 or UI 선택)
        │
        ▼
┌─────────────────────────┐
│  relation_selector_sheet │  UI에서 인연 선택 시
│  → CompatibilitySelection│  participantIds, includesOwner 결정
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  mention_send_handler    │  텍스트 멘션 파싱 or UI 선택값 전달
│  → MentionSendParams     │  targetProfileId, participantIds 결정
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  chat_provider           │  sendMessage() 호출
│  → ParticipantResolver   │  참가자 결정 위임
│  → CompatibilityDataLoader│ 프로필/사주 로드
│  → SystemPromptBuilder   │  AI 프롬프트 생성
│  → Gemini Edge Function  │  AI 응답 스트리밍
└─────────────────────────┘
```

---

## 4. ParticipantResolver 핵심 로직

**파일**: `participant_resolver.dart`

가장 중요한 파일. 3단계 분기 + 병합 로직으로 모든 시나리오를 처리합니다.

### 4.1 분기 구조

```dart
resolve() {
  // 1단계: 분기 결정
  if (effectiveParticipantIds.length >= 2) {
    // 분기 A: 궁합 모드 (2명 이상)
    // → person1, person2 설정 + chat_mentions 저장
  } else if (targetProfileId != null) {
    // 분기 B: 하위 호환 (단일 target)
    // → chat_mentions에서 기존 참가자 복원
  } else {
    // 분기 C: 자동 복원
    // → chat_mentions에서 궁합 복원 시도
  }

  // 2단계: 단일 멘션 처리
  if (!isCompatibilityMode && person2Id == null && participants.length == 1) {
    person2Id = participants[0];  // 개인 사주 모드
  }

  // 3단계: 참가자 병합 (중간 추가)
  if (!alreadySaved && effectiveParticipantIds != null) {
    existing = DB에서 기존 chat_mentions 조회;
    newIds = effectiveParticipantIds - existing;
    if (newIds.isNotEmpty) {
      merged = [...existing, ...newIds];
      DB에 merged 저장;
    }
  }
}
```

### 4.2 병합 예시

```
[첫 메시지] 하위 + 종환 궁합
  → chat_mentions: [하위ID, 종환ID]

[두 번째 메시지] "나" 추가
  → effectiveParticipantIds: [나ID]
  → 분기 C 진입: chat_mentions 복원 → person1=하위, person2=종환
  → 병합: existing=[하위, 종환] + new=[나] = [하위, 종환, 나]
  → chat_mentions 업데이트: [하위ID, 종환ID, 나ID]

[세 번째 메시지] 추가 멘션 없음
  → 분기 C 진입: chat_mentions 복원 → person1=하위, person2=종환, extra=[나]
  → 병합 스킵 (newIds 없음)
```

---

## 5. "나 제외" 모드 판별

### 판별 위치 (2곳에서 동일한 로직)

| 파일 | 용도 |
|------|------|
| `compatibility_data_loader.dart:275-289` | sendMessage 시 |
| `session_restore_service.dart:164-168` | 앱 재시작 복원 시 |

### 판별 로직

```dart
// "나"가 person1, person2, 또는 추가 참가자에 있으면 "나 포함"
final ownerIncluded =
    (ownerId == person1Id) ||
    (ownerId == person2Id) ||
    (ownerId != null && extraMentionIds.contains(ownerId));

isThirdPartyCompatibility = !ownerIncluded;
```

> **Phase 59 핵심 수정**: `extraMentionIds.contains(ownerId)` 조건 추가.
> "나"가 3번째 이후 참가자로 추가된 경우에도 "나 포함"으로 인식.

---

## 6. relation_selector_sheet UI 동작

### 선택 가능 상태

| 선택 수 | "나" 포함 | 결과 | 버튼 텍스트 |
|---------|----------|------|------------|
| 0명 | - | 비활성화 | "인연을 선택해주세요" |
| 1명 | O | 나를 채팅에 추가 | "나를 대화에 추가" |
| 1명 | X | 개인 사주 모드 | "이 사람의 사주 보기" |
| 2명 | - | 궁합 분석 | "2명 궁합 분석 시작" |

### CompatibilitySelection.participantIds 계산

```dart
List<String> get participantIds {
  final ids = relations.map((r) => r.toProfileId).toList();
  if (includesOwner && ownerProfileId != null && !ids.contains(ownerProfileId)) {
    return [ownerProfileId!, ...ids];  // "나"를 맨 앞에 추가
  }
  return ids;
}
```

- "나"만 선택 → `relations=[]`, `includesOwner=true` → `[나ID]`
- "나" + 하위 → `relations=[하위]`, `includesOwner=true` → `[나ID, 하위ID]`
- 하위 + 종환 → `relations=[하위, 종환]`, `includesOwner=false` → `[하위ID, 종환ID]`

---

## 7. chat_mentions 테이블 구조

```sql
CREATE TABLE chat_mentions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  UUID NOT NULL REFERENCES chat_sessions(id),
  target_profile_id UUID NOT NULL REFERENCES saju_profiles(id),
  mention_order INT NOT NULL DEFAULT 0,  -- 순서 보장
  created_at  TIMESTAMPTZ DEFAULT now()
);
```

- `mention_order`: 0=person1, 1=person2, 2+=추가참가자
- 병합 시 기존 삭제 후 전체 재저장 (순서 유지)

---

## 8. MentionSendHandler 멘션 파싱

### 우선순위

```
1. pendingCompatibilitySelection (UI 시트에서 선택)
2. 텍스트 내 @카테고리/이름 패턴 파싱
3. fallbackTargetProfileId (세션 기본값)
```

### "나 제외" 텍스트 감지

```dart
// 다음 조건 중 하나라도 만족하면 "나 제외" 모드
final isThirdPartyMode =
    text.contains('[나 제외]') ||
    text.contains('나 제외') ||
    (allMentions.length >= 2 && !hasOwnerMention);
```

### 캐시 무효화 (Phase 58)

```dart
// 대화 중 인연 등록 후 바로 멘션할 때 필수
ref.invalidate(relationListProvider(activeProfileId));
```

---

## 9. SessionRestoreService 복원 흐름

앱이 백그라운드→포그라운드 또는 재시작될 때:

```
1. chat_mentions DB 조회 → person1, person2, 추가참가자 복원
2. 각 참가자 프로필/사주분석 로드
3. 궁합 분석 결과 캐시 로드
4. AI Summary DB 캐시 로드 (Phase 59: 메모리 캐시 비어있으므로)
5. "나 포함/제외" 판별 (extraParticipantIds도 체크)
6. SystemPromptBuilder로 완전한 프롬프트 생성
```

---

## 10. 주의사항

### 저장 책임: ParticipantResolver만 담당

chat_mentions 저장은 **ParticipantResolver에서만** 수행합니다.
chat_provider.dart나 다른 곳에서 중복 저장하면 병합된 리스트가 덮어쓰이므로 절대 금지.

### DB 라운드트립 최적화

`alreadySaved` 플래그로 첫 분기(2명+)에서 저장 후 병합 블록의 불필요한 DB 조회를 방지합니다.

### 관계 유형 (relationType) 조회

궁합 분석 시 `profile_relations` 테이블에서 양방향 검색:
```dart
// SessionRestoreService.findRelationType()
// from→to 검색 후 없으면 to→from 검색
```
