# /module - MODULE AGENT

$ARGUMENTS 기능의 코드를 구현합니다.

## 참조 문서

- `docs/02_features/$ARGUMENTS.md` - 기능 명세
- `docs/04_data_models.md` - 데이터 모델
- `docs/05_api_spec.md` - API 명세 (Supabase Edge Functions)
- `docs/09_state_management.md` - **Riverpod 3.0 패턴, Provider 설계 원칙**
- `docs/10_widget_tree_optimization.md` - 위젯 최적화
- `docs/03_architecture.md` - **레이어 의존성 규칙**

---

## 구현 순서

### 1. Domain Layer (순수 Dart만)

```dart
// entities/[entity].dart
/// ⚠️ 주의: 순수 Dart만 사용!
/// import 'package:flutter/...' 금지!
/// import 'package:sql/...' 금지!
class Entity {
  final String id;
  // ...

  const Entity({required this.id});
}

// repositories/[feature]_repository.dart (interface)
/// ⚠️ abstract class로 정의
/// 구현은 data/repositories/에서
abstract class FeatureRepository {
  Future<Entity> getById(String id);
  Future<void> save(Entity entity);
}
```

### 2. Data Layer (외부 의존성 허용)

```dart
// models/[entity]_model.dart
import '../../domain/entities/[entity].dart';

/// Entity를 상속하고 JSON 변환 추가
class EntityModel extends Entity {
  const EntityModel({required super.id});

  factory EntityModel.fromJson(Map<String, dynamic> json) {
    return EntityModel(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id};
}

// datasources/[feature]_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureRemoteDataSource {
  final SupabaseClient _client;

  FeatureRemoteDataSource(this._client);

  Future<Map<String, dynamic>> fetch(String id) async {
    final response = await _client
        .from('table_name')
        .select()
        .eq('id', id)
        .single();
    return response;
  }
}

// repositories/[feature]_repository_impl.dart
import '../../domain/entities/[entity].dart';
import '../../domain/repositories/[feature]_repository.dart';
import '../datasources/[feature]_remote_datasource.dart';
import '../models/[entity]_model.dart';

/// ⚠️ Domain의 Repository interface를 implements
class FeatureRepositoryImpl implements FeatureRepository {
  final FeatureRemoteDataSource _remoteDataSource;

  FeatureRepositoryImpl(this._remoteDataSource);

  @override
  Future<Entity> getById(String id) async {
    final json = await _remoteDataSource.fetch(id);
    return EntityModel.fromJson(json);
  }
}
```

### 3. Presentation Layer (Flutter/Riverpod)

```dart
// providers/[feature]_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/[entity].dart';
import '../../domain/repositories/[feature]_repository.dart';

part '[feature]_provider.g.dart';

/// ⚠️ 주의: Domain만 의존!
/// import '../data/...' 금지!
/// Repository는 DI로 주입받음

@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  FutureOr<Entity?> build() async {
    return null;
  }

  Future<void> load(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(featureRepositoryProvider);
      return repo.getById(id);
    });
  }
}

// screens/[feature]_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/[feature]_provider.dart';

class FeatureScreen extends ConsumerWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureNotifierProvider);

    return state.when(
      data: (data) => _buildContent(data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _buildError(e),
    );
  }
}
```

---

## Provider 설계 원칙 (필수)

### 1. 단일 책임 원칙 (SRP)
```dart
// ❌ 잘못된 예: 하나의 Provider에 여러 책임
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  // UI 상태 + API 호출 + 검증 + 캐시 = 위반!
}

// ✅ 올바른 예: 책임별 분리
@riverpod
class ProfileFormNotifier extends _$ProfileFormNotifier {
  // UI 폼 상태만 관리
}

@riverpod
Future<Profile> fetchProfile(Ref ref, String id) {
  // API 호출만
}

@riverpod
bool isProfileValid(Ref ref) {
  // 검증 로직만
}
```

### 2. Provider 분리 기준
| 분리 필요 | 분리 불필요 |
|-----------|-------------|
| API 호출 + UI 상태 | 단순 CRUD |
| 폼 입력 + 제출 로직 | 파생 상태 |
| 여러 화면에서 사용 | 단일 화면 전용 |

### 3. keepAlive vs autoDispose
```dart
// 앱 전역 상태 (로그인 유지) → keepAlive
@Riverpod(keepAlive: true)
class UserProfile extends _$UserProfile { ... }

// 화면 이탈 시 정리 필요 → autoDispose (기본값)
@riverpod
class ChatMessages extends _$ChatMessages { ... }
```

### 4. family Provider
```dart
// 동적 파라미터가 있을 때만 family 사용
@riverpod
Future<ChatRoom> chatRoom(Ref ref, String roomId) async { ... }

// ❌ 전역 상태로 파라미터 관리하지 말 것
@riverpod
Future<ChatRoom> chatRoom(Ref ref) async {
  final roomId = ref.watch(currentRoomIdProvider);  // 암시적 의존성
}
```

---

## 에러/로딩 처리 패턴

### AsyncValue 필수 사용
```dart
// Provider
@riverpod
class DataNotifier extends _$DataNotifier {
  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => fetchData());
  }
}

// Widget
ref.watch(dataProvider).when(
  data: (data) => DataWidget(data),
  loading: () => const LoadingWidget(),
  error: (e, st) => ErrorWidget(e),
);
```

### Optimistic Update (선택)
```dart
Future<void> updateProfile(Profile newProfile) async {
  final previous = state.valueOrNull;

  // 1. 즉시 UI 업데이트
  state = AsyncData(newProfile);

  try {
    // 2. 서버 반영
    await repository.update(newProfile);
  } catch (e) {
    // 3. 실패 시 롤백
    state = AsyncData(previous!);
    rethrow;
  }
}
```

---

## 코드 검증 체크리스트

구현 완료 후 아래 항목 확인:

```
### 레이어 의존성
- [ ] Domain: 순수 Dart만 (flutter import 없음)
- [ ] Data → Domain 의존만 (Presentation 금지)
- [ ] Presentation → Domain 의존만 (Data 직접 접근 금지)

### Provider 패턴
- [ ] @riverpod 어노테이션 사용 (legacy 패턴 금지)
- [ ] 단일 책임 원칙 준수
- [ ] keepAlive/autoDispose 용도에 맞게 사용
- [ ] family는 동적 파라미터 있을 때만
- [ ] 순환 의존성 없음

### 에러/로딩 처리
- [ ] AsyncValue.guard() 사용
- [ ] state.when() 패턴 사용
- [ ] 에러 시 사용자 피드백 제공

### 네이밍 컨벤션
- [ ] 파일: snake_case.dart
- [ ] 클래스: PascalCase
- [ ] Provider: [feature]Provider, [feature]Notifier
- [ ] Repository: [Feature]Repository (interface), [Feature]RepositoryImpl
```

---

## 출력 형식

```
## MODULE Report: $ARGUMENTS

### Domain Layer
- entities/[entity].dart ✅
- repositories/[feature]_repository.dart ✅

### Data Layer
- models/[entity]_model.dart ✅
- datasources/[feature]_remote_datasource.dart ✅
- repositories/[feature]_repository_impl.dart ✅

### Presentation Layer
- providers/[feature]_provider.dart ✅
- screens/[feature]_screen.dart ✅

### 검증 결과
- 레이어 의존성: ✅
- Provider 패턴: ✅
- 에러/로딩 처리: ✅
- 네이밍 컨벤션: ✅

### 다음 단계
→ /test $ARGUMENTS (테스트 작성)
```
