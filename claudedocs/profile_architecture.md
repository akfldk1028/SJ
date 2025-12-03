# Profile Feature Architecture

## 전체 구조 (MVVM + Clean Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    Screens (UI)                        │  │
│  │  - ProfileEditScreen (shadcn_ui)                       │  │
│  │  - ProfileListScreen                                   │  │
│  └────────────────────────────────────────────────────────┘  │
│                          ▲                                   │
│                          │ watch/read                        │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Riverpod Providers                        │  │
│  │  - profileRepositoryProvider                           │  │
│  │  - profileListProvider (Notifier)                      │  │
│  │  - activeProfileProvider (Notifier)                    │  │
│  │  - profileFormProvider (Notifier)                      │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬─────────────────────────────┘
                                │ uses
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                   Entities                             │  │
│  │  - Gender (enum)                                       │  │
│  │  - SajuProfile (Freezed)                               │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Repository Interface                      │  │
│  │  - ProfileRepository (abstract)                        │  │
│  │    * getAll(), getById(), getActive()                  │  │
│  │    * save(), update(), delete()                        │  │
│  │    * setActive(), count(), clear()                     │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬─────────────────────────────┘
                                │ implements
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │            Repository Implementation                   │  │
│  │  - ProfileRepositoryImpl                               │  │
│  │    + Business logic (최소 1개 유지, 자동 활성화 등)      │  │
│  └────────────────────────────────────────────────────────┘  │
│                          ▲                                   │
│                          │ uses                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                  Data Models                           │  │
│  │  - SajuProfileModel (Freezed + JSON)                   │  │
│  │    + toEntity() / fromEntity()                         │  │
│  │    + toHiveMap() / fromHiveMap()                       │  │
│  └────────────────────────────────────────────────────────┘  │
│                          ▲                                   │
│                          │ uses                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │               Data Sources                             │  │
│  │  - ProfileLocalDatasource (Hive)                       │  │
│  │    + init(), getAll(), getById()                       │  │
│  │    + save(), update(), delete()                        │  │
│  │    + setActive(), deactivateAll()                      │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬─────────────────────────────┘
                                │ stores in
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                  Local Storage (Hive)                        │
│                                                              │
│  Box Name: "saju_profiles"                                   │
│  Type: Box<Map<dynamic, dynamic>>                            │
│  Format: JSON-like Map (no TypeAdapter)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 데이터 흐름 (Data Flow)

### 1. 프로필 생성 (Create)

```
User Input (ProfileEditScreen)
    │
    ├─> ProfileFormProvider.updateDisplayName()
    ├─> ProfileFormProvider.updateGender()
    ├─> ProfileFormProvider.updateBirthDate()
    ├─> ProfileFormProvider.updateBirthCity()
    │     └─> TrueSolarTimeService.getLongitudeCorrectionMinutes()
    │           └─> Auto-calculate timeCorrection
    │
    └─> ProfileFormProvider.saveProfile()
          │
          ├─> Validation (isValid check)
          │
          ├─> Create SajuProfile entity (with UUID)
          │
          ├─> ProfileRepository.save()
          │     │
          │     └─> ProfileRepositoryImpl
          │           │
          │           ├─> SajuProfileModel.fromEntity()
          │           │
          │           └─> ProfileLocalDatasource.save()
          │                 │
          │                 └─> Hive Box.add() or Box.putAt()
          │
          └─> Invalidate Providers
                ├─> profileListProvider.refresh()
                └─> activeProfileProvider.refresh()
```

### 2. 프로필 조회 (Read)

```
Widget builds
    │
    └─> ref.watch(profileListProvider)
          │
          └─> ProfileList.build()
                │
                └─> ProfileRepository.getAll()
                      │
                      └─> ProfileRepositoryImpl
                            │
                            └─> ProfileLocalDatasource.getAll()
                                  │
                                  ├─> Hive Box iteration
                                  │
                                  ├─> SajuProfileModel.fromHiveMap()
                                  │
                                  ├─> Sort by createdAt (desc)
                                  │
                                  └─> Convert to entities
                                        │
                                        └─> Return List<SajuProfile>
```

### 3. 프로필 수정 (Update)

```
Edit Button Pressed
    │
    └─> Navigate to ProfileEditScreen (with profileId)
          │
          ├─> Load existing profile
          │     └─> ProfileFormProvider.loadProfile(profile)
          │
          ├─> User edits fields
          │
          └─> ProfileFormProvider.saveProfile(editingId: id)
                │
                ├─> profile.copyWith(updatedAt: now)
                │
                └─> ProfileRepository.update()
                      │
                      └─> ProfileRepositoryImpl
                            │
                            └─> ProfileLocalDatasource.update()
                                  │
                                  └─> Hive Box.putAt()
```

### 4. 프로필 삭제 (Delete)

```
Delete Button Pressed
    │
    ├─> Show Confirmation Dialog
    │
    └─> ProfileList.deleteProfile(id)
          │
          └─> ProfileRepository.delete()
                │
                └─> ProfileRepositoryImpl
                      │
                      ├─> Check count (must keep ≥1)
                      │     └─> throw if count <= 1
                      │
                      ├─> ProfileLocalDatasource.delete()
                      │     └─> Hive Box.deleteAt()
                      │
                      └─> Auto-activate another profile if needed
                            │
                            ├─> getActive() returns null?
                            │
                            └─> setActive(profiles.first.id)
```

### 5. 활성 프로필 전환 (Set Active)

```
Profile Card Selected
    │
    └─> ProfileList.setActiveProfile(id)
          │
          └─> ProfileRepository.setActive()
                │
                └─> ProfileRepositoryImpl
                      │
                      └─> ProfileLocalDatasource.setActive()
                            │
                            ├─> deactivateAll()
                            │     └─> Set all isActive = false
                            │
                            └─> Set target isActive = true
```

---

## Provider 의존성 그래프

```
profileRepositoryProvider
    │
    ├─> ProfileLocalDatasource
    │     └─> Hive Box<Map>
    │
    └─> ProfileRepositoryImpl


profileListProvider
    │
    └─> depends on: profileRepositoryProvider
          │
          └─> Manages: List<SajuProfile>


activeProfileProvider
    │
    └─> depends on: profileRepositoryProvider
          │
          └─> Manages: SajuProfile?


profileFormProvider
    │
    ├─> depends on: profileRepositoryProvider
    │
    └─> Manages: ProfileFormState
          ├─> displayName: String
          ├─> gender: Gender?
          ├─> birthDate: DateTime?
          ├─> isLunar: bool
          ├─> isLeapMonth: bool
          ├─> birthTimeMinutes: int?
          ├─> birthTimeUnknown: bool
          ├─> useYaJasi: bool
          ├─> birthCity: String
          └─> timeCorrection: int
```

---

## 상태 관리 패턴

### AsyncValue 패턴 (Riverpod)

```dart
// Provider 정의
@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async {
    // 초기 데이터 로드
    return await ref.read(profileRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(profileRepositoryProvider).getAll();
    });
  }
}

// Widget에서 사용
ref.watch(profileListProvider).when(
  data: (profiles) => ListView(...),     // 데이터 있을 때
  loading: () => CircularProgressIndicator(),  // 로딩 중
  error: (err, stack) => ErrorWidget(),   // 에러 발생
);
```

### Notifier 패턴 (Form State)

```dart
// Provider 정의
@riverpod
class ProfileForm extends _$ProfileForm {
  @override
  ProfileFormState build() {
    return const ProfileFormState();  // 초기 상태
  }

  void updateDisplayName(String value) {
    state = state.copyWith(displayName: value);  // 불변 업데이트
  }
}

// Widget에서 사용
final formState = ref.watch(profileFormProvider);
final formNotifier = ref.read(profileFormProvider.notifier);

formNotifier.updateDisplayName('새 이름');
```

---

## 진태양시 보정 연동

```
ProfileFormProvider
    │
    └─> updateBirthCity(String city)
          │
          └─> TrueSolarTimeService.getLongitudeCorrectionMinutes(city)
                │
                ├─> cityLongitude[city] ?? cityLongitude['default']
                │
                ├─> (standardLongitude - longitude) * 4
                │     └─> 135 - 128.68 = 6.32
                │           └─> 6.32 * 4 = 25.28 ≈ -26분
                │
                └─> state.copyWith(
                      birthCity: city,
                      timeCorrection: correction,
                    )
```

**지원 도시 (25개)**
```
서울, 부산, 대구, 인천, 광주
대전, 울산, 세종, 제주, 창원
수원, 성남, 고양, 용인, 청주
전주, 포항, 강릉, 춘천, 원주
제천, 평택, 김해, 진주, 여수
목포
```

---

## 비즈니스 규칙 (Business Rules)

### 1. 프로필 최소 개수 유지

```dart
// ProfileRepositoryImpl.delete()
if (count <= 1) {
  throw Exception('최소 1개의 프로필이 필요합니다.');
}
```

**이유**: 앱은 항상 활성 프로필이 필요하므로 마지막 프로필 삭제 방지

### 2. 활성 프로필 자동 전환

```dart
// ProfileRepositoryImpl.delete()
await _localDatasource.delete(id);

final activeProfile = await _localDatasource.getActive();
if (activeProfile == null) {
  final profiles = await _localDatasource.getAll();
  if (profiles.isNotEmpty) {
    await _localDatasource.setActive(profiles.first.id);
  }
}
```

**이유**: 활성 프로필 삭제 시 자동으로 다음 프로필 활성화

### 3. 단일 활성 프로필 보장

```dart
// ProfileLocalDatasource.setActive()
await deactivateAll();  // 모든 프로필 비활성화
map['isActive'] = true;  // 지정된 프로필만 활성화
```

**이유**: 동시에 여러 프로필이 활성화되면 안 됨

### 4. updatedAt 자동 갱신

```dart
// ProfileRepositoryImpl.update()
final updatedProfile = profile.copyWith(
  updatedAt: DateTime.now(),
);
```

**이유**: 수정 시간 자동 추적

---

## 파일 구조 트리

```
features/profile/
├── domain/
│   ├── entities/
│   │   ├── gender.dart
│   │   └── saju_profile.dart
│   └── repositories/
│       └── profile_repository.dart
│
├── data/
│   ├── models/
│   │   └── saju_profile_model.dart
│   ├── datasources/
│   │   └── profile_local_datasource.dart
│   └── repositories/
│       └── profile_repository_impl.dart
│
└── presentation/
    ├── providers/
    │   └── profile_provider.dart
    ├── screens/
    │   ├── profile_edit_screen.dart      # TODO
    │   └── profile_list_screen.dart      # TODO
    └── widgets/                           # TODO
        ├── profile_card.dart
        ├── birth_date_picker.dart
        ├── birth_time_picker.dart
        ├── city_search_field.dart
        ├── time_correction_banner.dart
        └── gender_toggle_buttons.dart
```

---

## 에러 처리 전략

### Repository Layer

```dart
try {
  await repository.delete(id);
} catch (e) {
  if (e.toString().contains('최소 1개')) {
    // 마지막 프로필 삭제 시도
    showErrorDialog('마지막 프로필은 삭제할 수 없습니다.');
  } else {
    // 기타 에러
    showErrorDialog('삭제 중 오류가 발생했습니다.');
  }
}
```

### Form Validation

```dart
Future<void> saveProfile() async {
  final formState = ref.read(profileFormProvider);

  if (!formState.isValid) {
    if (formState.displayName.isEmpty) {
      showError('이름을 입력해주세요');
    } else if (formState.displayName.length > 12) {
      showError('이름은 12자 이내로 입력해주세요');
    } else if (formState.gender == null) {
      showError('성별을 선택해주세요');
    }
    // ...
    return;
  }

  // Save logic
}
```

### AsyncValue Error Handling

```dart
ref.watch(profileListProvider).when(
  data: (profiles) => ProfileList(profiles),
  loading: () => LoadingSpinner(),
  error: (error, stack) {
    // Log error
    print('Error loading profiles: $error');

    // Show user-friendly message
    return ErrorMessage(
      message: '프로필을 불러오는 중 오류가 발생했습니다.',
      retry: () => ref.refresh(profileListProvider),
    );
  },
);
```

---

## 테스트 전략

### Unit Tests (Repository)

```dart
test('프로필 생성 및 조회', () async {
  final profile = createTestProfile();
  await repository.save(profile);

  final retrieved = await repository.getById(profile.id);
  expect(retrieved, equals(profile));
});

test('마지막 프로필 삭제 방지', () async {
  final profile = createTestProfile();
  await repository.save(profile);

  expect(
    () => repository.delete(profile.id),
    throwsException,
  );
});
```

### Widget Tests

```dart
testWidgets('필수 필드 미입력 시 저장 버튼 비활성화', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: ProfileEditScreen(),
    ),
  );

  final saveButton = find.byType(ShadButton);
  expect(tester.widget<ShadButton>(saveButton).enabled, isFalse);
});
```

### Integration Tests

```dart
testWidgets('프로필 생성 플로우', (tester) async {
  // 1. 화면 진입
  await tester.pumpWidget(App());
  await tester.tap(find.text('프로필 추가'));

  // 2. 필드 입력
  await tester.enterText(find.byType(ShadInput).first, '테스트');
  await tester.tap(find.text('남자'));

  // 3. 저장
  await tester.tap(find.text('저장하기'));
  await tester.pumpAndSettle();

  // 4. 검증
  expect(find.text('테스트'), findsOneWidget);
});
```

---

## 성능 최적화

### 1. Const 위젯 사용

```dart
// 모든 정적 위젯은 const로 선언
const DisclaimerBanner()
const SizedBox(height: 16)
const Text('프로필 만들기')
```

### 2. ListView.builder

```dart
// 프로필 목록 렌더링
ListView.builder(
  itemCount: profiles.length,
  itemBuilder: (context, index) {
    return ProfileCard(
      key: ValueKey(profiles[index].id),  // Key로 상태 보존
      profile: profiles[index],
    );
  },
)
```

### 3. Provider 범위 최소화

```dart
// 전체 리빌드 방지
Consumer(
  builder: (context, ref, child) {
    final formState = ref.watch(profileFormProvider);
    return SaveButton(enabled: formState.isValid);
  },
)
```

### 4. Freezed Copyable

```dart
// 불변 업데이트 (효율적인 메모리 사용)
state = state.copyWith(displayName: newName);
```

---

## 보안 고려사항

### 1. 민감 정보 저장

현재: Hive (암호화 없음)
향후: 중요 정보는 flutter_secure_storage 사용 고려

### 2. 입력 검증

```dart
// 이름 길이 제한
if (displayName.length > 12) return false;

// 날짜 범위 제한
if (birthDate.year < 1900 || birthDate.isAfter(now)) return false;
```

### 3. SQL Injection 방지

Hive 사용으로 SQL Injection 위험 없음 (NoSQL)

---

## 마이그레이션 전략

### 향후 Supabase 연동 시

```dart
// Repository 인터페이스는 그대로 유지
// 구현체만 교체

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDatasource _localDatasource;
  final ProfileRemoteDatasource _remoteDatasource;  // 추가

  // Offline-first 전략
  @override
  Future<List<SajuProfile>> getAll() async {
    try {
      final remote = await _remoteDatasource.getAll();
      await _localDatasource.syncWith(remote);  // 로컬 캐시 동기화
      return remote;
    } catch (e) {
      // 네트워크 오류 시 로컬 데이터 사용
      return await _localDatasource.getAll();
    }
  }
}
```

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2025-12-02 | 0.1 | 아키텍처 다이어그램 작성 | Claude |
