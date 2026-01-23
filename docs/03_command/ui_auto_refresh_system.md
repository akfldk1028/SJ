# UI 자동 갱신 시스템 (2026-01-23)

## 문제 상황

사용자가 프로필을 저장하면 AI 분석이 시작되지만, 분석이 완료되어도 UI가 자동으로 갱신되지 않는 문제가 있었음.

### 근본 원인

1. **중복 분석 방지 로직**: `analyzeOnProfileSave()`가 여러 곳에서 호출됨
   - `profile_provider.dart` (동기 호출)
   - `daily_fortune_provider.dart` (비동기 + 콜백)

2. **콜백 무시**: 첫 번째 호출이 분석을 시작하면, 두 번째 호출은 "이미 분석 중"으로 **스킵**됨
   - 두 번째 호출의 `onComplete` 콜백이 등록되지 않아 UI 갱신 불가

```
// 문제의 코드 (수정 전)
if (_analyzingProfiles.contains(profileId)) {
  print('이미 분석 중: $profileId (스킵)');
  return const ProfileAnalysisResult(); // 콜백 무시!
}
```

---

## 해결 방법

### 1. 대기 콜백 목록 추가

```dart
/// 분석 완료 시 호출할 콜백 목록 (프로필별)
static final Map<String, List<void Function(ProfileAnalysisResult)>>
    _pendingCallbacks = {};
```

### 2. 이미 분석 중이면 콜백만 등록

```dart
if (_analyzingProfiles.contains(profileId)) {
  print('이미 분석 중: $profileId (콜백 등록)');
  if (onComplete != null) {
    _pendingCallbacks.putIfAbsent(profileId, () => []);
    _pendingCallbacks[profileId]!.add(onComplete);
  }
  return const ProfileAnalysisResult();
}
```

### 3. 두 가지 알림 메서드

```dart
/// 중간 완료 알림 (콜백 유지) - Fortune, saju_base 각각 완료 시
void _notifyPendingCallbacks(String profileId, ProfileAnalysisResult result)

/// 최종 완료 알림 (콜백 제거) - 모든 분석 완료 시
void _callAllPendingCallbacks(String profileId, ProfileAnalysisResult result)
```

---

## AI 분석 흐름 및 UI 갱신 시점

```
analyzeOnProfileSave() 호출
      │
      ├─→ 콜백 등록 (_pendingCallbacks에 추가)
      │
      ▼
_runBothAnalyses() 시작
      │
      ├─→ Fortune 분석 시작 (fire-and-forget)
      │         │
      │         └─→ Fortune 완료 시:
      │              _notifyPendingCallbacks() 호출
      │              → UI 갱신 (콜백 유지) ⭐
      │
      ├─→ saju_base 분석 시작 (await)
      │         │
      │         └─→ saju_base 완료 시:
      │              _notifyPendingCallbacks() 호출
      │              → UI 갱신 (콜백 유지) ⭐
      │
      ▼
_runBothAnalyses() 반환
      │
      ▼
_callAllPendingCallbacks() 호출
      → UI 갱신 (콜백 제거) ⭐
```

---

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `saju_analysis_service.dart` | 콜백 관리 및 알림 로직 |
| `daily_fortune_provider.dart` | UI 갱신 콜백 등록 (`ref.invalidateSelf()`) |
| `profile_provider.dart` | 분석 트리거 |
| `fortune_summary_card.dart` | UI 위젯 (provider watch) |

---

## 로그 확인 포인트

```
[SajuAnalysisService] 이미 분석 중: xxx (콜백 등록)
[SajuAnalysisService] 대기 콜백 등록: N개
[SajuAnalysisService] 📢 Fortune 완료 → 대기 콜백 알림 (즉시 UI 갱신!)
[SajuAnalysisService] 대기 콜백 N개 알림 (유지)
[SajuAnalysisService] 📢 saju_base 완료 → 대기 콜백 알림 (즉시 UI 갱신!)
[SajuAnalysisService] 대기 콜백 N개 최종 호출 (제거)
```

---

## 주의사항

1. **콜백은 여러 번 호출됨**: Fortune 완료, saju_base 완료, 최종 완료 시 각각 호출
2. **콜백에서 `ref.invalidateSelf()`만 호출**: 여러 번 호출해도 안전함
3. **static 변수 사용**: `_analyzingProfiles`, `_pendingCallbacks`는 앱 전체에서 공유됨
4. **`_isAnalyzing` 리셋 조건**: `result.sajuBase != null`일 때만 리셋 (saju_base 완료 시점)
   - Fortune 완료 시: sajuBase가 null → 리셋 안 함 (중복 트리거 방지)
   - saju_base 완료 시: sajuBase 설정됨 → 리셋 (다음 분석 가능)

---

## 콜백 호출 순서 및 결과값

| 시점 | 콜백 결과 | `_isAnalyzing` |
|------|----------|----------------|
| Fortune 완료 | `{dailyFortune: success}` | 유지 (true) |
| saju_base 완료 | `{sajuBase: result}` | **리셋 (false)** |
| 최종 완료 | `{sajuBase: result}` | 유지 (이미 false) |
