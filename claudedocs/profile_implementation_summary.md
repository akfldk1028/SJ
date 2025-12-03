# Profile Feature 구현 요약 - Domain & Data Layer

## 작업 완료 (2025-12-02)

### 생성된 파일 목록

#### 1. Domain Layer (4개 파일)

```
features/profile/domain/
├── entities/
│   ├── gender.dart                  # 성별 enum
│   └── saju_profile.dart           # 사주 프로필 엔티티 (Freezed)
└── repositories/
    └── profile_repository.dart     # Repository 인터페이스
```

**gender.dart**
- Gender enum (male/female)
- 한글 표시명 제공 (남자/여자)
- JSON 직렬화를 위한 fromString() 메서드

**saju_profile.dart**
- 사주 프로필의 핵심 도메인 모델
- Freezed를 사용한 불변 객체
- 13개 필드: id, displayName, gender, birthDate, isLunar, isLeapMonth, birthTimeMinutes, birthTimeUnknown, useYaJasi, birthCity, timeCorrection, createdAt, updatedAt, isActive
- 헬퍼 메서드: birthTimeFormatted, birthDateFormatted, calendarTypeLabel, timeCorrectionLabel
- 유효성 검증 로직 (isValid getter)

**profile_repository.dart**
- Repository 패턴 인터페이스
- 메서드: getAll(), getById(), getActive(), save(), update(), delete(), setActive(), count(), clear()

#### 2. Data Layer (3개 파일)

```
features/profile/data/
├── models/
│   └── saju_profile_model.dart     # 데이터 모델 (JSON/Hive)
├── datasources/
│   └── profile_local_datasource.dart  # Hive 로컬 저장소
└── repositories/
    └── profile_repository_impl.dart   # Repository 구현체
```

**saju_profile_model.dart**
- SajuProfile entity를 확장한 데이터 모델
- Freezed + json_serializable 사용
- Hive 저장을 위한 Map 변환 메서드 (toHiveMap, fromHiveMap)
- Entity 변환 메서드 (toEntity, fromEntity)

**profile_local_datasource.dart**
- Hive Box 이름: `saju_profiles`
- Map<dynamic, dynamic> 형태로 저장 (TypeAdapter 불필요)
- CRUD 구현: getAll(), getById(), getActive(), save(), update(), delete()
- 활성 프로필 관리: setActive(), deactivateAll()
- Box 초기화 및 생명주기 관리

**profile_repository_impl.dart**
- ProfileRepository 인터페이스 구현
- LocalDataSource를 사용한 데이터 접근
- 비즈니스 로직:
  - 마지막 프로필 삭제 방지 (최소 1개 유지)
  - 프로필 삭제 시 자동으로 다른 프로필 활성화
  - updatedAt 자동 갱신

#### 3. Presentation Layer (1개 파일)

```
features/profile/presentation/
└── providers/
    └── profile_provider.dart       # Riverpod 3.0 Providers
```

**profile_provider.dart**
- **profileRepository**: Repository 인스턴스 Provider
- **ProfileList**: 프로필 목록 관리 Notifier
  - 메서드: refresh(), createProfile(), updateProfile(), deleteProfile(), setActiveProfile()
- **ActiveProfile**: 활성 프로필 Notifier
  - 메서드: refresh()
- **ProfileFormState**: 폼 상태 클래스
  - 필드 검증 (isValid getter)
  - 진태양시 보정 계산 (calculateTimeCorrection)
- **ProfileForm**: 폼 상태 관리 Notifier
  - 필드 업데이트 메서드 (updateDisplayName, updateGender, etc.)
  - 프로필 저장/수정 (saveProfile)
  - 폼 초기화 (loadProfile, reset)

#### 4. 문서 및 스크립트

```
frontend/lib/features/profile/README.md  # 구현 가이드
build_profile.bat                         # 코드 생성 스크립트 (Windows)
claudedocs/profile_implementation_summary.md  # 이 문서
```

---

## 핵심 구현 내용

### 1. MVVM 아키텍처

```
Domain Layer (비즈니스 로직)
    ↓
Data Layer (데이터 접근)
    ↓
Presentation Layer (UI + 상태관리)
```

### 2. 진태양시 보정

`features/saju_chart/domain/services/true_solar_time_service.dart` 활용
- 25개 도시의 경도 데이터 사용
- 자동으로 분 단위 보정값 계산
- 예: 창원 = -26분, 포항 = -23분

```dart
final correction = TrueSolarTimeService.getLongitudeCorrectionMinutes('창원');
// 결과: -26분
```

### 3. Hive 로컬 저장

- Box 이름: `saju_profiles`
- TypeAdapter 대신 Map으로 직렬화 (빌드 문제 회피)
- DateTime은 millisecondsSinceEpoch로 저장
- 자동 초기화 및 재사용

### 4. Riverpod 3.0 패턴

```dart
// @riverpod annotation 사용
@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async { ... }
}

// 사용 예시
final profilesAsync = ref.watch(profileListProvider);
```

### 5. Freezed 불변 객체

```dart
@freezed
class SajuProfile with _$SajuProfile {
  const factory SajuProfile({ ... }) = _SajuProfile;
}
```

---

## 다음 단계: Presentation Layer (UI)

### 구현 필요 화면

#### 1. profile_edit_screen.dart
- 프로필 입력/수정 화면
- shadcn_ui 컴포넌트 사용:
  - ShadInput: 이름 입력 (최대 12자)
  - ShadButton: 성별 토글 (여자/남자)
  - ShadSelect: 음력/양력 드롭다운
  - ShadDatePicker: 생년월일 선택
  - TimePicker: 출생시간 (HH:mm)
  - ShadCheckbox: 시간 모름, 야자시/조자시
  - Autocomplete: 도시 검색 (25개)

#### 2. profile_list_screen.dart
- 프로필 관리 화면 (설정 메뉴에서 진입)
- shadcn_ui 컴포넌트:
  - ShadCard: 프로필 카드
  - ShadButton: 수정/삭제 버튼
  - ShadDialog: 삭제 확인 팝업

#### 3. Widgets

```
presentation/widgets/
├── profile_card.dart              # 프로필 카드
├── birth_date_picker.dart         # 생년월일 선택기
├── birth_time_picker.dart         # 출생시간 선택기
├── city_search_field.dart         # 도시 검색
├── time_correction_banner.dart    # 진태양시 보정 안내
└── gender_toggle_buttons.dart     # 성별 토글
```

### Widget Tree Optimization (필수)

`.claude/JH_Agent/00_widget_tree_guard.md` 가이드 준수:
- const 생성자/인스턴스화
- ListView.builder 사용
- 위젯 100줄 이하로 분리
- setState 범위 최소화

---

## 코드 생성 방법

### 1. Windows 스크립트 사용

```bash
# 프로젝트 루트에서 실행
build_profile.bat
```

### 2. 수동 실행

```bash
cd frontend

# 의존성 설치
flutter pub get

# 코드 생성
dart run build_runner build --delete-conflicting-outputs

# 또는 watch 모드
dart run build_runner watch -d
```

---

## 사용 예시

### 프로필 생성

```dart
class ProfileEditScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formNotifier = ref.read(profileFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('프로필 만들기')),
      body: Column(
        children: [
          ShadInput(
            onChanged: (value) => formNotifier.updateDisplayName(value),
          ),
          // ... 다른 입력 필드

          ShadButton(
            onPressed: () async {
              try {
                final profile = await formNotifier.saveProfile();
                // 성공 처리
              } catch (e) {
                // 에러 처리
              }
            },
            child: Text('저장하기'),
          ),
        ],
      ),
    );
  }
}
```

### 프로필 목록 표시

```dart
class ProfileListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profileListProvider);

    return profilesAsync.when(
      data: (profiles) => ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return ShadCard(
            child: ProfileCard(profile: profile),
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### 프로필 수정

```dart
final formNotifier = ref.read(profileFormProvider.notifier);

// 기존 프로필 로드
formNotifier.loadProfile(existingProfile);

// 필드 수정
formNotifier.updateDisplayName('새 이름');
formNotifier.updateBirthCity('서울');

// 저장 (업데이트)
await formNotifier.saveProfile(editingId: existingProfile.id);
```

### 프로필 삭제

```dart
final listNotifier = ref.read(profileListProvider.notifier);

try {
  await listNotifier.deleteProfile(profileId);
  // 성공
} catch (e) {
  // "최소 1개의 프로필이 필요합니다" 에러 처리
}
```

### 활성 프로필 전환

```dart
final listNotifier = ref.read(profileListProvider.notifier);
await listNotifier.setActiveProfile(newProfileId);
```

---

## 주요 비즈니스 로직

### 1. 마지막 프로필 삭제 방지

```dart
// ProfileRepositoryImpl.delete()
if (count <= 1) {
  throw Exception('최소 1개의 프로필이 필요합니다.');
}
```

### 2. 활성 프로필 자동 전환

프로필 삭제 시, 삭제된 프로필이 활성 프로필이었다면 자동으로 다른 프로필 활성화

```dart
final activeProfile = await _localDatasource.getActive();
if (activeProfile == null) {
  final profiles = await _localDatasource.getAll();
  if (profiles.isNotEmpty) {
    await _localDatasource.setActive(profiles.first.id);
  }
}
```

### 3. updatedAt 자동 갱신

```dart
final updatedProfile = profile.copyWith(
  updatedAt: DateTime.now(),
);
```

### 4. 폼 유효성 검증

```dart
bool get isValid {
  // 필수 필드 체크
  if (displayName.isEmpty || displayName.length > 12) return false;
  if (gender == null) return false;
  if (birthDate == null) return false;
  if (birthCity.isEmpty) return false;

  // 생년월일 범위 (1900년 ~ 현재)
  if (birthDate!.year < 1900 || birthDate!.isAfter(DateTime.now())) return false;

  // 출생시간 범위 (0~1439분)
  if (!birthTimeUnknown && birthTimeMinutes != null) {
    if (birthTimeMinutes! < 0 || birthTimeMinutes! > 1439) return false;
  }

  return true;
}
```

---

## 데이터 모델 상세

### SajuProfile Entity

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| id | String | O | UUID v4 |
| displayName | String | O | 최대 12자 |
| gender | Gender | O | male/female |
| birthDate | DateTime | O | 양력 기준 저장 |
| isLunar | bool | O | 음력 여부 |
| isLeapMonth | bool | X | 음력 윤달 (기본: false) |
| birthTimeMinutes | int? | X | 0~1439 |
| birthTimeUnknown | bool | O | 시간 모름 (기본: false) |
| useYaJasi | bool | O | 야자시 (기본: true) |
| birthCity | String | O | 도시명 (25개 중 선택) |
| timeCorrection | int | O | 분 단위 (자동 계산) |
| createdAt | DateTime | O | 생성 일시 |
| updatedAt | DateTime | O | 수정 일시 |
| isActive | bool | O | 활성 프로필 (기본: false) |

### Hive 저장 형식

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "displayName": "박재현",
  "gender": "male",
  "birthDate": 880732800000,
  "isLunar": false,
  "isLeapMonth": false,
  "birthTimeMinutes": 483,
  "birthTimeUnknown": false,
  "useYaJasi": true,
  "birthCity": "창원",
  "timeCorrection": -26,
  "createdAt": 1733140800000,
  "updatedAt": 1733140800000,
  "isActive": true
}
```

---

## 참고 문서

- `e:\SJ\docs\02_features\profile_input.md` - 기능 명세서
- `e:\SJ\docs\10_widget_tree_optimization.md` - Widget 최적화 가이드
- `e:\SJ\.claude\JH_Agent\00_widget_tree_guard.md` - Widget 검증 규칙
- `e:\SJ\.claude\JH_Agent\08_shadcn_ui_builder.md` - shadcn_ui 사용법
- `features/saju_chart/domain/services/true_solar_time_service.dart` - 진태양시 계산

---

## 테스트 권장 사항

### Unit Tests

```dart
// profile_repository_test.dart
test('마지막 프로필 삭제 시 예외 발생', () async {
  // ...
  expect(() => repository.delete(profileId), throwsException);
});

test('활성 프로필 설정 시 다른 프로필 비활성화', () async {
  // ...
  final activeProfile = await repository.getActive();
  expect(activeProfile?.id, equals(newProfileId));
});
```

### Widget Tests

```dart
// profile_edit_screen_test.dart
testWidgets('필수 필드 미입력 시 저장 버튼 비활성화', (tester) async {
  // ...
  expect(find.byType(ShadButton).isEnabled, isFalse);
});
```

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2025-12-02 | 0.1 | Domain & Data Layer 구현 완료 | Claude |

---

## 다음 작업 (Presentation Layer)

1. [ ] profile_edit_screen.dart 구현
2. [ ] profile_list_screen.dart 구현
3. [ ] Widget 컴포넌트 분리 (const 최적화)
4. [ ] 도시 검색 자동완성
5. [ ] 진태양시 보정 안내 배너
6. [ ] 삭제 확인 Dialog
7. [ ] go_router 라우팅 설정
8. [ ] Widget Tree Guard 검증
9. [ ] 에러 처리 및 사용자 피드백
10. [ ] 접근성 (Accessibility) 검증
