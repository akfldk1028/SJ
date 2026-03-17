# Daily Fortune 프로필 변경 테스트

> 테스트 날짜: 2026-02-04 (KST)
> 목적: 프로필 이름 변경 시 기존 daily_fortune 데이터 유지 여부 확인

---

## 🔴 이슈 1: Daily Fortune 무한 반복 문제

### 증상
- 핸드폰에서 daily_fortune 화면 진입 시 데이터가 나왔다가 다시 로딩으로 돌아감
- 무한 반복 현상

### 원인 분석 (Step-by-Step)

**1단계: Provider 구조 확인**
```
dailyFortuneProvider (daily_fortune_provider.dart)
├─ ref.keepAlive() → 탭 이동 시 상태 유지
├─ activeProfileProvider.watch → 프로필 변경 감지
├─ _analyzedToday (static Set) → 중복 분석 방지
└─ _currentlyAnalyzing (static Set) → 현재 분석 중 추적
```

**2단계: 무한 루프 가능 시나리오**
```
1. build() 호출 → 캐시 미스 → _triggerAnalysisIfNeeded() 호출
2. 분석 시작 → _currentlyAnalyzing.add()
3. 분석 완료 → ref.invalidateSelf() 호출
4. build() 재호출 → 캐시 히트해야 하는데...
   ⚠️ 만약 캐시 조회 실패 또는 content가 null이면?
5. 다시 분석 트리거 → 무한 반복
```

**3단계: 의심 포인트**
- `aiQueries.getDailyFortune()` 쿼리가 실패하거나 null 반환
- `prompt_version` 필터로 인해 캐시 미스
- 네트워크 불안정으로 인한 간헐적 실패
- `ref.invalidateSelf()` 호출 후 race condition

**4단계: 로그 확인 필요**
```dart
// daily_fortune_provider.dart:233
final result = await aiQueries.getDailyFortune(activeProfile.id, today);
// ← 이 결과가 계속 실패하면 무한 루프
```

### 해결 방안 (검토 필요)
1. **캐시 히트 실패 시 재시도 제한** - 최대 N회만 시도
2. **에러 상태 구분** - 분석 실패 vs 분석 중 vs 데이터 없음
3. **디바운스 추가** - 연속 호출 방지

---

## 🟡 이슈 2: 프로필 수정 시 캘린더 데이터 정책

### 현재 동작
```
프로필 이름 변경 시:
1. saju_profiles.display_name 업데이트
2. v31 트리거 → ai_summaries.profile_display_name 동기화
3. 기존 데이터는 profile_id FK로 연결되어 유지됨
```

### 문제점
캘린더에서 과거 운세를 볼 때:
- **현재**: 프로필 수정 전 데이터도 새 이름으로 표시됨
- **사용자 기대**: 그 날짜에 봤던 이름/생년월일로 보고 싶을 수 있음

### 정책 옵션

| 옵션 | 설명 | 장점 | 단점 |
|------|------|------|------|
| A. 현행 유지 | display_name만 sync | 단순함 | 과거 맥락 손실 |
| B. 스냅샷 저장 | ai_summaries에 생성 시점 프로필 정보 저장 | 완전한 이력 | 데이터 중복 |
| C. 이력 테이블 | saju_profiles_history 테이블 추가 | 추적 가능 | 복잡도 증가 |

### 현재 캘린더 동작 분석
```dart
// calendar_screen.dart:426
// dailyFortuneDatesProvider → aiQueries.getDailyFortuneDates(activeProfile.id)
// → profile_id 기준으로 조회 (display_name 무관)

// calendar_screen.dart:408
// dailyFortuneForDateProvider(selectedDay)
// → profile_id + target_date로 조회
```

**결론**: 현재 구조에서 프로필 수정해도 **데이터는 유지됨**.
다만 **display_name이 바뀌면** 과거 기록도 새 이름으로 보임.

---

## 테스트 시나리오

### 현재 상태 (변경 전)

| 항목 | 값 |
|------|-----|
| user_id | `29efeaf9-b8fe-4eb3-91f0-fc153c50fb2c` |
| profile_id | `db7ad2bf-5ed6-4eaa-b12e-a41d6949dddf` |
| 현재 display_name | `불재현` |
| 프로필 생성일 | 2026-02-03 17:49:09 KST |
| 프로필 수정일 | 2026-02-04 02:52:21 KST |

### 현재 ai_summaries 데이터

| summary_type | target_date | profile_display_name | created_kst |
|--------------|-------------|---------------------|-------------|
| daily_fortune | 2026-02-04 | 불재현 | 2026-02-04 02:52:44 |
| yearly_fortune_2026 | - | 불재현 | 2026-02-04 02:54:44 |
| yearly_fortune_2025 | - | 불재현 | 2026-02-04 02:55:05 |
| monthly_fortune | - | 불재현 | 2026-02-04 02:56:45 |
| saju_base | - | 불재현 | 2026-02-04 03:15:27 |

**총 5개 레코드**

---

## 테스트 계획

### Step 1: 2월 5일 daily_fortune 생성 확인
- [ ] 2026-02-05 00:00 KST 이후 daily_fortune 조회
- [ ] target_date = '2026-02-05' 레코드 생성 확인

### Step 2: 프로필 이름 변경
- [ ] `불재현` → 새 이름으로 변경
- [ ] 변경 시간 기록: ________________

### Step 3: 변경 후 확인
- [ ] ai_summaries의 profile_display_name 변경 확인
- [ ] 기존 daily_fortune (2/4, 2/5) 데이터 유지 확인
- [ ] v31 트리거 정상 동작 확인

---

## 테스트 결과 (2월 5일 작성 예정)

### 변경 전 스냅샷

```sql
-- 이 쿼리로 확인
SELECT
  id,
  summary_type,
  target_date,
  profile_display_name,
  created_at AT TIME ZONE 'Asia/Seoul' as created_kst
FROM ai_summaries
WHERE profile_id = 'db7ad2bf-5ed6-4eaa-b12e-a41d6949dddf'
ORDER BY created_at;
```

### 변경 후 스냅샷

(테스트 후 작성)

---

## 예상 결과

v31 트리거가 정상 동작한다면:
1. 모든 ai_summaries의 `profile_display_name`이 새 이름으로 변경됨
2. 기존 데이터(daily_fortune 등)는 **삭제되지 않음**
3. profile_id FK 연결은 유지됨

---

## 관련 문서

- [db_schema_integrated.md](./db_schema_integrated.md) - v31 트리거 문서
- 트리거 함수: `sync_user_display_name()`

---

## 🛠️ 에뮬레이터 실행 명령어 (Step-by-Step)

### 1. 터미널 열기
VS Code에서 `Ctrl + `` 또는 `Terminal > New Terminal`

### 2. 프로젝트 경로로 이동
```bash
cd e:\SJ\frontend
```

### 3. Flutter 의존성 확인
```bash
flutter pub get
```

### 4. 연결된 디바이스 확인
```bash
flutter devices
```

예상 출력:
```
Android SDK built for x86 (mobile) • emulator-5554 • android-x64 • Android 11 (API 30)
```

### 5. 에뮬레이터 실행 (이미 실행 중이면 스킵)

**방법 A: Android Studio에서**
- Android Studio > Tools > Device Manager > ▶ 실행

**방법 B: 명령어로**
```bash
# 사용 가능한 에뮬레이터 목록
emulator -list-avds

# 특정 에뮬레이터 실행 (예시)
emulator -avd Pixel_4_API_30
```

### 6. Flutter 앱 실행
```bash
# 디버그 모드 실행
flutter run

# 또는 특정 디바이스 지정
flutter run -d emulator-5554
```

### 7. Hot Reload / Hot Restart
- **Hot Reload**: 터미널에서 `r` 키
- **Hot Restart**: 터미널에서 `R` 키 (대문자)

### 8. 로그 확인 (별도 터미널)
```bash
# 모든 로그
flutter logs

# 또는 특정 태그만 필터링
adb logcat | grep -E "DailyFortune|flutter"
```

### 9. 앱 종료
- 터미널에서 `q` 키

---

## 디버깅 명령어

### Daily Fortune 관련 로그만 보기
```bash
adb logcat | grep "DailyFortune"
```

### Supabase 쿼리 로그
```bash
adb logcat | grep -E "supabase|ai_summaries"
```

### 전체 경로 요약
```
e:\SJ\frontend\          ← Flutter 프로젝트 루트
├── lib\                  ← Dart 소스코드
├── android\              ← Android 네이티브
├── ios\                  ← iOS 네이티브
└── pubspec.yaml          ← 의존성 정의
```
