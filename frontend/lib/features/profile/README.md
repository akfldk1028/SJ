# Profile Feature - Domain & Data Layer

## 구현 완료 파일

### Domain Layer

#### Entities
- `domain/entities/gender.dart` - 성별 enum (남자/여자)
- `domain/entities/saju_profile.dart` - 사주 프로필 엔티티 (Freezed)

#### Repositories
- `domain/repositories/profile_repository.dart` - Repository 인터페이스

### Data Layer

#### Models
- `data/models/saju_profile_model.dart` - 프로필 데이터 모델 (JSON/Hive 직렬화)

#### Datasources
- `data/datasources/profile_local_datasource.dart` - Hive 로컬 저장소

#### Repositories
- `data/repositories/profile_repository_impl.dart` - Repository 구현체

### Presentation Layer

#### Providers
- `presentation/providers/profile_provider.dart` - Riverpod 3.0 Providers
  - ProfileRepository Provider
  - ProfileList Notifier (프로필 목록 관리)
  - ActiveProfile Notifier (활성 프로필)
  - ProfileForm Notifier (폼 상태 관리)

---

## 코드 생성 필요

다음 명령어를 실행하여 Freezed와 Riverpod 코드를 생성하세요:

```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

또는 watch 모드로 실행:

```bash
dart run build_runner watch -d
```

---

## 핵심 기능

### 1. SajuProfile Entity
- 생년월일시 정보 저장
- 음력/양력 선택
- 진태양시 보정 (도시별 경도 차이)
- 야자시/조자시 옵션
- 활성 프로필 관리

### 2. ProfileRepository
- CRUD 작업 (생성/조회/수정/삭제)
- 활성 프로필 설정
- 마지막 프로필 삭제 방지 (최소 1개 유지)

### 3. Hive 로컬 저장
- Box 이름: `saju_profiles`
- Map<dynamic, dynamic> 형태로 저장
- TypeAdapter 없이 JSON 방식 사용

### 4. Riverpod Providers
- **profileRepository**: Repository 인스턴스
- **profileListProvider**: 전체 프로필 목록
- **activeProfileProvider**: 현재 활성 프로필
- **profileFormProvider**: 폼 입력 상태 관리

---

## 진태양시 보정

`features/saju_chart/domain/services/true_solar_time_service.dart`의 도시별 경도 데이터를 사용하여 자동으로 시간 보정값을 계산합니다.

```dart
// 예시: 창원 선택 시
final correction = TrueSolarTimeService.getLongitudeCorrectionMinutes('창원');
// 결과: -26분 (동경 135도 기준으로 창원은 서쪽에 위치)
```

지원 도시:
- 서울, 부산, 대구, 인천, 광주, 대전, 울산, 세종, 제주
- 창원, 수원, 성남, 고양, 용인, 청주, 전주, 포항
- 강릉, 춘천, 원주, 제천, 평택, 김해, 진주, 여수, 목포

---

## 다음 단계: Presentation Layer

### 화면 구현 (shadcn_ui 사용)

1. **profile_edit_screen.dart** - 프로필 입력/수정 화면
   - ShadInput: 이름 입력
   - ShadButton: 성별 선택 (토글)
   - ShadSelect: 음력/양력 선택
   - ShadDatePicker: 생년월일
   - TimePicker: 출생시간
   - ShadCheckbox: 시간 모름, 야자시/조자시
   - Autocomplete: 도시 검색

2. **profile_list_screen.dart** - 프로필 목록 화면
   - ShadCard: 프로필 카드
   - ShadButton: 수정/삭제 버튼
   - ShadDialog: 삭제 확인

3. **Widgets**
   - `profile_card.dart` - 프로필 카드 위젯
   - `birth_date_picker.dart` - 생년월일 선택
   - `birth_time_picker.dart` - 출생시간 선택
   - `city_search_field.dart` - 도시 검색
   - `time_correction_banner.dart` - 진태양시 보정 안내

---

## 사용 예시

### 프로필 생성

```dart
// ProfileForm Provider 사용
final formNotifier = ref.read(profileFormProvider.notifier);

// 필드 업데이트
formNotifier.updateDisplayName('박재현');
formNotifier.updateGender(Gender.male);
formNotifier.updateBirthDate(DateTime(1997, 11, 29));
formNotifier.updateBirthTime(483); // 08:03 = 8*60 + 3
formNotifier.updateBirthCity('창원');

// 저장
final profile = await formNotifier.saveProfile();
```

### 프로필 조회

```dart
// 전체 목록
final profilesAsync = ref.watch(profileListProvider);
profilesAsync.when(
  data: (profiles) => ListView.builder(...),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);

// 활성 프로필
final activeAsync = ref.watch(activeProfileProvider);
```

### 프로필 수정

```dart
final formNotifier = ref.read(profileFormProvider.notifier);

// 기존 프로필 로드
formNotifier.loadProfile(existingProfile);

// 필드 수정
formNotifier.updateDisplayName('새 이름');

// 저장 (ID 전달하여 업데이트)
await formNotifier.saveProfile(editingId: existingProfile.id);
```

### 프로필 삭제

```dart
final listNotifier = ref.read(profileListProvider.notifier);
await listNotifier.deleteProfile(profileId);
```

---

## 주의사항

1. **코드 생성 필수**: Freezed와 Riverpod 코드 생성 후 사용 가능
2. **Hive 초기화**: main.dart에서 `Hive.initFlutter()` 호출 필요
3. **마지막 프로필 보호**: 최소 1개의 프로필 유지 (삭제 시 예외 발생)
4. **진태양시 보정**: 도시 선택 시 자동으로 계산 (수동 수정 가능)
5. **활성 프로필**: 한 번에 하나만 활성화 가능 (자동 전환)

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|-----------|
| 2025-12-02 | 0.1 | Domain & Data Layer 구현 완료 |
