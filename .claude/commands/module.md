# /module - MODULE AGENT

$ARGUMENTS 기능의 코드를 구현합니다.

## 참조 문서

- `docs/02_features/$ARGUMENTS.md` - 기능 명세
- `docs/04_data_models.md` - 데이터 모델
- `docs/05_api_spec.md` - API 명세 (Supabase Edge Functions)
- `docs/09_state_management.md` - Riverpod 3.0 패턴
- `docs/10_widget_tree_optimization.md` - 위젯 최적화

## 구현 순서

### 1. Domain Layer
```dart
// entities/[entity].dart
class Entity {
  final String id;
  // ...
}

// repositories/[feature]_repository.dart (interface)
abstract class FeatureRepository {
  Future<Entity> getById(String id);
  // ...
}
```

### 2. Data Layer
```dart
// models/[entity]_model.dart
class EntityModel extends Entity {
  factory EntityModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

// datasources/[feature]_remote_datasource.dart
class FeatureRemoteDataSource {
  final SupabaseClient client;
  // Supabase 쿼리
}

// repositories/[feature]_repository_impl.dart
class FeatureRepositoryImpl implements FeatureRepository {
  // 구현
}
```

### 3. Presentation Layer
```dart
// providers/[feature]_provider.dart
@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  // Riverpod 3.0 패턴
}

// screens/[feature]_screen.dart
class FeatureScreen extends ConsumerWidget {
  // const 사용, 위젯 분리
}
```

## 코드 규칙

- const 위젯 사용
- 에러 처리 (AsyncValue.error)
- 로딩 상태 처리
- Supabase RLS 고려
