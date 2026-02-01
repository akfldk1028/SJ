# 페르소나 추적 시스템 (chat_sessions DB)

## 개요

채팅 세션 생성 시 사용자가 선택한 페르소나를 `chat_sessions` 테이블에 정확히 기록한다.
페르소나는 계속 추가될 예정이므로 이 규칙을 반드시 따를 것.

---

## 페르소나 분류 (3종)

| 분류 | canAdjustMbti | mbtiQuadrant | 예시 |
|------|:---:|:---:|------|
| **MBTI 페르소나** | false | 자체 고정값 | nfSensitive(NF), ntAnalytic(NT), sfFriendly(SF), stRealistic(ST) |
| **특수 캐릭터** | false | **null** | babyMonk, saOngJiMa, sewerSaju |
| **레거시 basePerson** | true | Provider에서 읽기 | basePerson (UI에서 숨김) |

---

## DB 저장 규칙

### chat_sessions 테이블

| 컬럼 | MBTI 페르소나 | 특수 캐릭터 | basePerson |
|------|:---:|:---:|:---:|
| `chat_persona` | `'ntAnalytic'` 등 | `'sewerSaju'` 등 | `'basePerson'` |
| `mbti_quadrant` | `'NT'` 등 (페르소나에서 파생) | **NULL** | `'NF'`/`'NT'`/`'SF'`/`'ST'` |

### 핵심 원칙

```
MBTI 페르소나 → mbti_quadrant = persona.mbtiQuadrant (자체 값)
특수 캐릭터   → mbti_quadrant = NULL (MBTI 무관)
basePerson   → mbti_quadrant = mbtiQuadrantNotifierProvider (사용자 선택)
```

**절대 하면 안 되는 것**: `ref.read(mbtiQuadrantNotifierProvider)`를 무조건 읽어서 저장.
이전 페르소나의 stale MBTI 값이 저장되는 버그 발생함. (예: ntAnalytic + NF)

---

## 코드: _resolveCurrentMbtiQuadrant()

`saju_chat_shell.dart`에 정의된 헬퍼. 세션 생성 시 반드시 이걸 사용.

```dart
MbtiQuadrant? _resolveCurrentMbtiQuadrant() {
  final currentPersona = ref.read(chatPersonaNotifierProvider);
  if (currentPersona.isMbtiPersona) {
    return currentPersona.mbtiQuadrant;  // 자체 값 (절대 stale 안 됨)
  } else if (currentPersona.canAdjustMbti) {
    return ref.read(mbtiQuadrantNotifierProvider);  // basePerson만
  }
  return null;  // 특수 캐릭터
}
```

---

## 세션 생성 호출 위치 (5곳)

모두 `_resolveCurrentMbtiQuadrant()` 또는 동일 인라인 로직 사용해야 함.

| # | 메서드 | 파일 위치 | 설명 |
|---|--------|----------|------|
| 1 | `_initializeSession()` (세션 없음) | saju_chat_shell.dart | 첫 진입 시 기본 세션 생성 |
| 2 | `_initializeSession()` (타입 불일치) | saju_chat_shell.dart | 다른 chatType으로 진입 시 |
| 3 | `_autoInsertMention()` | saju_chat_shell.dart | 인연 관계도에서 진입 |
| 4 | `_handleNewChat()` | saju_chat_shell.dart | "새 대화" 버튼 |
| 5 | `_ChatContent` onSendMessage | saju_chat_shell.dart | 세션 없이 메시지 전송 시 |

---

## 페르소나 변경 시 동기화

사용자가 UI에서 페르소나를 변경하면 (페르소나 선택기 탭):

```dart
// 1. 페르소나 변경
ref.read(chatPersonaNotifierProvider.notifier).setPersona(persona);

// 2. MBTI Provider도 동기화 (MBTI 페르소나인 경우)
if (persona.mbtiQuadrant != null) {
  ref.read(mbtiQuadrantNotifierProvider.notifier).setQuadrant(persona.mbtiQuadrant!);
}

// 3. 현재 세션 업데이트 (정확한 mbtiQuadrant 전달)
ref.read(chatSessionNotifierProvider.notifier).updateCurrentSessionPersona(
  chatPersona: persona,
  mbtiQuadrant: persona.isMbtiPersona
      ? persona.mbtiQuadrant
      : persona.canAdjustMbti
          ? ref.read(mbtiQuadrantNotifierProvider)
          : null,
);
```

---

## 새 페르소나 추가 시 체크리스트

1. **`chat_persona.dart`에 enum 값 추가**
   - `displayName`, `icon`, `emoji`, `description` 등 채우기
   - `type` getter에서 `mbtiPersona` or `specialCharacter` 분류
   - `mbtiQuadrant` getter: MBTI 페르소나면 해당 값, 특수 캐릭터면 `null` 반환
   - `personaId`: PersonaRegistry ID 매핑
   - `fromString()`: 문자열 역변환 추가

2. **`persona_registry.dart`에 페르소나 등록**
   - `personaId`에 해당하는 프롬프트/설정 등록

3. **DB 추적 자동 동작 확인**
   - `_resolveCurrentMbtiQuadrant()`가 새 페르소나를 올바르게 처리하는지 검증
   - MBTI 페르소나: `isMbtiPersona == true`, `mbtiQuadrant != null`
   - 특수 캐릭터: `isMbtiPersona == false`, `canAdjustMbti == false`, `mbtiQuadrant == null`

4. **Supabase 확인 쿼리**
   ```sql
   SELECT chat_persona, mbti_quadrant, COUNT(*)
   FROM chat_sessions
   GROUP BY chat_persona, mbti_quadrant
   ORDER BY chat_persona;
   ```

---

## 2026-02-01 보정 기록

기존 불일치 데이터 수동 보정:

```sql
-- ntAnalytic + NF → NT (1건)
UPDATE chat_sessions SET mbti_quadrant = 'NT'
WHERE chat_persona = 'ntAnalytic' AND mbti_quadrant != 'NT';

-- sewerSaju + ST/NT → NULL (3건)
UPDATE chat_sessions SET mbti_quadrant = NULL
WHERE chat_persona IN ('babyMonk', 'saOngJiMa', 'sewerSaju', 'scenarioWriter')
AND mbti_quadrant IS NOT NULL;
```

보정 후 결과:

| chat_persona | mbti_quadrant | 건수 |
|---|---|---|
| basePerson | NF | 3 |
| basePerson | NT | 3 |
| nfSensitive | NF | 13 |
| ntAnalytic | NT | 2 |
| sewerSaju | NULL | 3 |
| NULL (구버전) | NULL | 29 |
