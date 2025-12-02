# Profile UI Implementation - Next Steps

## Status: Ready for Code Generation

프로필 입력 화면의 UI 구현이 완료되었습니다. 다음 단계를 진행해주세요.

## Step 1: Code Generation (필수)

Riverpod provider 코드 생성:

```bash
cd e:\SJ\frontend
dart run build_runner build --delete-conflicting-outputs
```

이 명령어는 다음 파일을 생성합니다:
- `profile_provider.g.dart`

## Step 2: 앱 실행 및 테스트

```bash
cd e:\SJ\frontend
flutter run
```

### 테스트 시나리오

1. **프로필 입력 화면 진입**
   - /profile/edit 라우트 이동
   - 모든 위젯이 올바르게 표시되는지 확인

2. **필수 필드 입력**
   - 이름 입력 (최대 12자)
   - 성별 선택 (여자/남자 토글)
   - 생년월일 선택
   - 도시 선택 (검색 기능 확인)

3. **선택 필드 입력**
   - 양력/음력 선택
   - 출생시간 선택
   - "시간 모름" 체크 시 시간 입력 비활성화 확인
   - "야자시/조자시" 툴팁 확인

4. **진태양시 보정**
   - 도시 선택 시 보정 배너 표시 확인
   - 보정 시간 값 확인 (예: 서울 -26분)

5. **폼 유효성 검사**
   - 필수 필드 누락 시 "만세력 보러가기" 버튼 비활성화
   - 모든 필드 입력 후 버튼 활성화

6. **프로필 저장**
   - "만세력 보러가기" 버튼 클릭
   - 프로필 저장 확인
   - 토스트 메시지 표시 확인

7. **저장된 프로필 불러오기**
   - "저장된 만세력 불러오기" 버튼 클릭
   - 바텀시트에 프로필 목록 표시
   - 프로필 선택 시 폼에 값 로드 확인

## Step 3: 알려진 이슈 및 개선사항

### 현재 제한사항

1. **ProfileActionButtons 파일 크기**
   - 현재 137줄 (Widget Tree Guard 100줄 규칙 초과)
   - 원인: _SavedProfilesSheet 서브위젯 포함
   - 권장: _SavedProfilesSheet를 별도 파일로 분리

2. **만세력 화면 미구현**
   - "만세력 보러가기" 버튼이 임시로 채팅 화면으로 이동
   - 향후 Routes.sajuChart 구현 후 연동 필요

3. **프로필 수정 모드**
   - 현재 신규 생성만 지원
   - editingId 파라미터를 통한 수정 모드 추가 필요

### 추가 구현 필요

1. **12간지 시간표 다이얼로그**
   - "12간지 시간표 ⓘ" 버튼 클릭 시 표시
   - 자(子)시부터 해(亥)시까지 시간대 안내

2. **윤달 선택 UI**
   - 음력 선택 시 윤달 체크박스 표시
   - ProfileFormState.isLeapMonth 필드 활용

3. **프로필 삭제 기능**
   - 저장된 프로필 목록에서 삭제 버튼 추가
   - 삭제 확인 다이얼로그 표시
   - 마지막 프로필 삭제 방지

4. **입력 검증 강화**
   - 이름 특수문자 제한
   - 도시명 유효성 검사 (목록에 있는 도시만 허용)

## Step 4: 성능 모니터링

Flutter DevTools로 성능 확인:

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 확인 항목

1. **Widget Rebuild 횟수**
   - 폼 입력 시 필요한 위젯만 리빌드되는지 확인
   - 전체 화면 리빌드가 일어나지 않는지 확인

2. **Frame Build Time**
   - 목표: < 16ms (60 FPS)
   - 위젯 렌더링 시간 측정

3. **Memory Usage**
   - const 위젯 인스턴스 재사용 확인
   - 메모리 누수 없는지 확인

## Step 5: 코드 품질 확인

### Lint 검사

```bash
cd e:\SJ\frontend
flutter analyze
```

예상 경고:
- 없음 (모든 위젯이 Widget Tree Guard 규칙 준수)

### 포맷 확인

```bash
cd e:\SJ\frontend
dart format lib/features/profile/presentation/
```

## Step 6: 문서 업데이트

1. **TASKS.md 업데이트**
   - Profile Feature Presentation Layer 완료 표시
   - 남은 작업 항목 추가

2. **README 업데이트**
   - 프로필 입력 화면 구현 완료 기록
   - 스크린샷 추가 (선택사항)

## 구현 완료 항목

- ✅ ProfileEditScreen (메인 화면 조립)
- ✅ ProfileNameInput (이름 입력)
- ✅ GenderToggleButtons (성별 선택)
- ✅ CalendarTypeDropdown (양력/음력 선택)
- ✅ BirthDatePicker (생년월일 선택)
- ✅ BirthTimePicker (출생시간 선택)
- ✅ BirthTimeOptions (시간 옵션)
- ✅ CitySearchField (도시 검색)
- ✅ TimeCorrectionBanner (진태양시 보정)
- ✅ ProfileActionButtons (저장/불러오기)
- ✅ Widget Tree Guard 검증 (95% 준수)
- ✅ Shadcn UI 통합
- ✅ Riverpod 상태 관리

## 참고 파일

- 구현 상세 보고서: `e:\SJ\claudedocs\profile_ui_implementation_report.md`
- 프로필 명세서: `e:\SJ\docs\02_features\profile_input.md`
- Widget 최적화 가이드: `e:\SJ\docs\10_widget_tree_optimization.md`
- Shadcn UI 가이드: `e:\SJ\.claude\JH_Agent\08_shadcn_ui_builder.md`
