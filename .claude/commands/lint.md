# /lint - 구조 및 상태관리 검증 Agent

$ARGUMENTS 기능(또는 전체)의 Flutter 아키텍처 및 Riverpod 패턴 준수 여부를 검증합니다.

## 사용법

```bash
# 특정 기능 검증
/lint profile_input

# 전체 검증
/lint all
```

---

## 검증 항목

### 1. 레이어 의존성 검증

```
✅ 올바른 의존성:
   Presentation → Domain ← Data

❌ 위반 사례:
   - Domain에서 Flutter import
   - Data에서 Presentation import
   - Presentation에서 Data 직접 import
```

**검사 방법:**
```dart
// Domain Layer 검사
lib/features/$ARGUMENTS/domain/**/*.dart
- ❌ import 'package:flutter
- ❌ import 'package:sql
- ❌ import 'package:hive
- ✅ import 'dart:
- ✅ 순수 Dart 코드만

// Data Layer 검사
lib/features/$ARGUMENTS/data/**/*.dart
- ❌ import '../presentation/
- ✅ import '../domain/

// Presentation Layer 검사
lib/features/$ARGUMENTS/presentation/**/*.dart
- ❌ import '../data/
- ✅ import '../domain/
```

---

### 2. 폴더 구조 검증

**필수 구조:**
```
lib/features/$ARGUMENTS/
├── domain/
│   ├── entities/          # 필수
│   └── repositories/      # 필수 (interface)
├── data/
│   ├── models/            # 필수
│   ├── datasources/       # 필수
│   └── repositories/      # 필수 (implementation)
└── presentation/
    ├── providers/         # 필수
    ├── screens/           # 필수
    └── widgets/           # 선택
```

**검사 항목:**
- [ ] domain/entities/ 폴더 존재
- [ ] domain/repositories/ 폴더 존재
- [ ] data/models/ 폴더 존재
- [ ] data/datasources/ 폴더 존재
- [ ] data/repositories/ 폴더 존재
- [ ] presentation/providers/ 폴더 존재
- [ ] presentation/screens/ 폴더 존재

---

### 3. Provider 패턴 검증

**검사 항목:**

#### 3.1 @riverpod 어노테이션
```dart
// ✅ 올바른 사용
@riverpod
class ProfileNotifier extends _$ProfileNotifier { ... }

// ❌ 잘못된 사용 (legacy)
final profileProvider = StateNotifierProvider<...>(...);
```

#### 3.2 Provider 분리 원칙 (SRP)
```dart
// ❌ 하나의 Provider에 여러 책임
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  // UI 상태 + API 호출 + 검증 + 캐시 = 위반
}

// ✅ 책임별 분리
@riverpod  // UI 상태만
class ProfileFormNotifier extends _$ProfileFormNotifier { ... }

@riverpod  // API 호출만
Future<Profile> fetchProfile(...) { ... }
```

#### 3.3 keepAlive vs autoDispose
```dart
// 검사: 용도에 맞는 설정인가?

// ✅ 사용자 프로필 - keepAlive
@Riverpod(keepAlive: true)
class UserProfile extends _$UserProfile { ... }

// ✅ 채팅 메시지 - autoDispose (기본값)
@riverpod
class ChatMessages extends _$ChatMessages { ... }
```

#### 3.4 family Provider 사용
```dart
// 검사: 동적 파라미터가 있을 때 family 사용

// ✅ 올바른 사용
@riverpod
Future<ChatRoom> chatRoom(Ref ref, String roomId) async { ... }

// ❌ 잘못된 사용 (전역에서 roomId 관리)
@riverpod
Future<ChatRoom> chatRoom(Ref ref) async {
  final roomId = ref.watch(currentRoomIdProvider);  // 암시적 의존성
  ...
}
```

#### 3.5 순환 의존성
```dart
// ❌ 순환 참조 감지
// providerA → providerB → providerC → providerA
```

---

### 4. 네이밍 컨벤션 검증

**파일명:**
```
// Entity
✅ saju_profile.dart
❌ SajuProfile.dart, profile.dart

// Repository Interface
✅ profile_repository.dart
❌ i_profile_repository.dart

// Repository Implementation
✅ profile_repository_impl.dart
❌ profile_repository_implementation.dart

// Provider
✅ profile_provider.dart, profile_notifier.dart
❌ profile_state.dart

// Screen
✅ profile_screen.dart, profile_input_screen.dart
❌ profile_page.dart, ProfileScreen.dart
```

**클래스명:**
```
// Entity: PascalCase
✅ SajuProfile, UserProfile

// Repository Interface
✅ ProfileRepository (abstract class)

// Repository Implementation
✅ ProfileRepositoryImpl

// Provider/Notifier
✅ ProfileNotifier, ProfileFormNotifier

// Screen
✅ ProfileScreen, ProfileInputScreen
```

---

### 5. Import 규칙 검증

**순서:**
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. 외부 패키지 (알파벳순)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. 프로젝트 내부 (절대 경로)
import 'package:saju_app/features/profile/domain/entities/saju_profile.dart';
```

**검사 항목:**
- [ ] 상대 경로 `../` 사용 최소화
- [ ] 절대 경로 `package:saju_app/` 사용
- [ ] Import 그룹별 정렬

---

### 6. 에러 처리 패턴 검증

**검사 항목:**
```dart
// ✅ AsyncValue 패턴 사용
state.when(
  data: (data) => ...,
  loading: () => ...,
  error: (e, st) => ...,
);

// ❌ 직접 try-catch만 사용
try {
  final result = await api.fetch();
} catch (e) {
  // 상태 업데이트 없음
}
```

---

## 출력 형식

```
## Lint Report: $ARGUMENTS

### 1. 레이어 의존성 ✅/❌
- Domain 순수성: ✅ (flutter import 없음)
- Data→Presentation 의존: ✅ (위반 없음)
- Presentation→Data 직접 접근: ✅ (위반 없음)

### 2. 폴더 구조 ✅/❌
- 필수 폴더: 7/7 존재
- 누락: 없음

### 3. Provider 패턴 ✅/❌
- @riverpod 사용: ✅ (legacy 패턴 없음)
- SRP 준수: ⚠️ ProfileNotifier가 3개 책임
- keepAlive/autoDispose: ✅
- family 사용: ✅
- 순환 의존성: ✅ (없음)

### 4. 네이밍 컨벤션 ✅/❌
- 파일명: ✅
- 클래스명: ✅

### 5. Import 규칙 ✅/❌
- 상대 경로 사용: ⚠️ 3개 파일
- 정렬: ✅

### 6. 에러 처리 ✅/❌
- AsyncValue 패턴: ✅

---

### 총평
- 통과: 5/6
- 경고: 1 (Provider SRP)
- 실패: 0

### 권장 수정사항
1. ProfileNotifier를 ProfileFormNotifier, ProfileApiNotifier로 분리
2. data/repositories/profile_repo_impl.dart 상대 경로 수정
```

---

## 자동 수정 옵션

```bash
# 검사만 (기본)
/lint profile_input

# 자동 수정 포함
/lint profile_input --fix
```

**--fix 가능 항목:**
- Import 정렬
- 상대 경로 → 절대 경로 변환
- 불필요한 import 제거

**--fix 불가능 (수동 필요):**
- Provider 분리
- 폴더 구조 변경
- 레이어 의존성 위반

---

## 참조 문서

| 문서 | 검증 항목 |
|------|----------|
| `docs/03_architecture.md` | 레이어 의존성, 폴더 구조 |
| `docs/09_state_management.md` | Provider 패턴, 네이밍 |
