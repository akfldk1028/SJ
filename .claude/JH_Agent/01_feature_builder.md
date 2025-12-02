# Feature Builder Agent

> Feature 모듈을 MVVM 구조로 생성하는 에이전트

---

## 역할

새 Feature 폴더와 기본 파일 구조를 자동 생성

---

## 호출 시점

- 새 기능 구현 시작 시
- `features/{feature_name}/` 폴더 생성 필요할 때

---

## 생성 구조

```
features/{feature_name}/
├── data/
│   ├── datasources/
│   │   ├── {feature}_local_datasource.dart
│   │   └── {feature}_remote_datasource.dart  (필요시)
│   ├── models/
│   │   └── {entity}_model.dart
│   └── repositories/
│       └── {feature}_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── {entity}.dart
│   └── repositories/
│       └── {feature}_repository.dart
└── presentation/
    ├── providers/
    │   └── {feature}_provider.dart
    ├── screens/
    │   └── {feature}_screen.dart
    └── widgets/
        └── (기능별 위젯들)
```

---

## 입력 파라미터

```yaml
feature_name: profile          # 폴더명
entities:                      # 생성할 Entity 목록
  - SajuProfile
  - Gender (enum)
has_remote: false              # Remote DataSource 필요 여부
has_local: true                # Local DataSource (Hive) 필요 여부
```

---

## 생성 템플릿

### Entity 템플릿

```dart
// domain/entities/{entity}.dart
class {Entity} {
  final String id;
  // ... fields

  const {Entity}({
    required this.id,
    // ... required fields
  });
}
```

### Model 템플릿

```dart
// data/models/{entity}_model.dart
class {Entity}Model extends {Entity} {
  const {Entity}Model({
    required super.id,
    // ... fields
  });

  factory {Entity}Model.fromJson(Map<String, dynamic> json) {
    return {Entity}Model(
      id: json['id'] as String,
      // ... mapping
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // ... mapping
    };
  }
}
```

### Repository Interface 템플릿

```dart
// domain/repositories/{feature}_repository.dart
abstract class {Feature}Repository {
  Future<List<{Entity}>> getAll();
  Future<{Entity}?> getById(String id);
  Future<void> save({Entity} entity);
  Future<void> delete(String id);
}
```

### Provider 템플릿 (Riverpod 3.0)

```dart
// presentation/providers/{feature}_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{feature}_provider.g.dart';

@riverpod
class {Feature}List extends _${Feature}List {
  @override
  Future<List<{Entity}>> build() async {
    // TODO: implement
    return [];
  }
}
```

---

## 출력

- 생성된 파일 목록
- 다음 단계 안내 (Entity 필드 정의, Provider 구현 등)

---

## 주의사항

- 생성 후 반드시 **00_widget_tree_guard** 검증 거칠 것
- docs/02_features/{feature}.md 문서 참조
