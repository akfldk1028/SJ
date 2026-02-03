# Changelog v0.1.0+21

> 2026-02-03 | Phase 59-60 버그 수정

---

## Phase 59: 멘션 파싱 & 궁합 분석 수정

### 문제점
1. 대화 중 새 인연 등록 후 멘션 시 AI가 인식 못함
2. `isThirdPartyCompatibility`가 person1만 체크
3. 참가자 2명 초과 시 truncation (`.take(2)`)
4. 참가자 추가 시 병합 리스트 덮어쓰기
5. 앱 재시작 시 AI Summary 캐시 누락

### 수정 파일

#### `compatibility_data_loader.dart`
```dart
// Before: person1만 체크
bool isThirdPartyCompatibility = person1Id != ownerId;

// After: person1 OR person2 중 하나라도 "나"이면 "나 포함" 모드
final ownerIncluded = (ownerId == person1Id) || (ownerId == person2Id);
bool isThirdPartyCompatibility = !ownerIncluded;
```

#### `mention_send_handler.dart`
```dart
// Before: 2명으로 제한
participantIds = foundIds.take(2).toList();

// After: 3명 이상 참가자 지원
participantIds = foundIds;  // .take(2) 제거
```

#### `participant_resolver.dart`
- `_saveMergedParticipants()` 메서드 추가
- 기존 참가자 + 새 참가자 병합 로직
- 첫 메시지에서 2명+ 참가자 저장

```dart
// 참가자 추가 모드 (기존 궁합 세션에 1명씩 추가)
if (newIds.isNotEmpty) {
  final mergedIds = [...existingIds, ...newIds];
  await _saveMergedParticipants(sessionId, mergedIds);
}
```

#### `session_restore_service.dart`
```dart
// Phase 59: 앱 재시작 시 DB에서 AI Summary 캐시 로드
if (aiSummary == null && activeProfile.id != null) {
  aiSummary = await AiSummaryService.getCachedSummary(activeProfile.id);
}

// isThirdPartyCompatibility 양쪽 체크
final ownerIncluded = (activeProfile.id == person1Id) || (activeProfile.id == person2Id);
isThirdPartyCompatibility = !ownerIncluded;
```

#### `chat_provider.dart`
```dart
// Before: 여기서 chat_mentions 저장 → 병합 리스트 덮어씀
await _saveChatMentions(sessionId, effectiveParticipantIds);

// After: ParticipantResolver에서 처리하므로 제거
// chat_mentions: ParticipantResolver에서 이미 저장됨
```

#### `mention_send_handler.dart` (캐시 무효화)
```dart
// Phase 58: 대화 도중 인연 등록 후 멘션 시 캐시 무효화
ref.invalidate(relationListProvider(activeProfileId));
```

---

## Phase 60: Daily Fortune 중복 실행 방지

### 문제점
탭 이동 시마다 AI 분석 재실행 (하루 1회만 실행되어야 함)

### 수정 파일

#### `daily_fortune_provider.dart`

**1. Static Set 기반 추적**
```dart
/// 오늘 이미 분석을 시도한 프로필 ID (한국 날짜 기준)
/// key: "profileId_yyyy-MM-dd"
static final Set<String> _analyzedToday = {};

/// 현재 분석 중인 프로필 ID
static final Set<String> _currentlyAnalyzing = {};
```

**2. keepAlive로 Provider 상태 유지**
```dart
@override
Future<DailyFortuneData?> build() async {
  ref.keepAlive();  // 탭 이동 시에도 Provider 상태 유지
  ...
}
```

**3. 빠른 반환 조건 (DB 쿼리 전 체크)**
```dart
// 1. 현재 분석 중이면 바로 null 반환
if (_currentlyAnalyzing.contains(activeProfile.id)) {
  return null;
}

// 2. FortuneCoordinator에서 분석 중이면 폴링 시작
if (FortuneCoordinator.isAnalyzing(activeProfile.id)) {
  _analyzedToday.add(analyzedKey);
  _waitForCoordinatorCompletion(activeProfile.id);
  return null;
}
```

**4. 메모리 누수 방지**
```dart
/// 이전 날짜 항목 정리
static void _cleanupOldEntries(DateTime today) {
  final todaySuffix = '${today.year}-${today.month...}-${today.day...}';
  _analyzedToday.removeWhere((key) => !key.endsWith(todaySuffix));
}
```

**5. 수동 새로고침 시 플래그 리셋**
```dart
Future<void> refresh() async {
  final activeProfile = await ref.read(activeProfileProvider.future);
  if (activeProfile != null) {
    final today = KoreaDateUtils.today;
    final analyzedKey = _getAnalyzedKey(activeProfile.id, today);
    _analyzedToday.remove(analyzedKey);
    _currentlyAnalyzing.remove(activeProfile.id);
  }
  ref.invalidateSelf();
}
```

### 동작 흐름

```
[탭 이동 시나리오]
홈 탭 → 채팅 탭 → 홈 탭 복귀
  ↓
build() 재실행
  ↓
_currentlyAnalyzing 체크 → false
  ↓
FortuneCoordinator.isAnalyzing() → false
  ↓
DB 캐시 확인 → 히트
  ↓
데이터 반환 ✅ (분석 재실행 없음)
```

---

## Edge Function: ai-gemini v30

### 문제점
```
TypeError: supabase.from(...).insert(...).catch is not a function
```

### 수정
```typescript
// Before (v29): Supabase JS v2에서 .catch() 체이닝 불가
await supabase.from("chat_error_logs").insert({...}).catch(() => {});

// After (v30): try/catch 블록으로 변경
try {
  await supabase.from("chat_error_logs").insert({...});
} catch (logError) {
  console.warn("[ai-gemini v30] Failed to log truncation:", logError);
}
```

---

## 버전 정보

| 항목 | 값 |
|------|-----|
| 앱 버전 | 0.1.0+21 |
| Edge Function | ai-gemini v30 (v55) |
| 빌드 파일 | app-release.aab (56.3MB) |

---

## 테스트 체크리스트

### Phase 59
- [ ] 대화 중 새 인연 등록 → 멘션 → AI 인식
- [ ] "나 제외" 궁합 (제3자 두 명)
- [ ] 3명 이상 참가자 궁합
- [ ] 2명 시작 → 1명 추가
- [ ] 앱 재시작 → 세션 복원 → AI 컨텍스트 유지

### Phase 60
- [ ] 홈 → 채팅 → 홈 복귀 시 분석 재실행 없음
- [ ] 하루 1회만 분석 실행
- [ ] 수동 새로고침 시 재분석
- [ ] 자정(KST) 이후 새 분석 실행
