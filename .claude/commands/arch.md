# /arch - ARCHITECTURE AGENT

$ARGUMENTS 기능의 폴더 구조를 생성하고 레이어 의존성 규칙을 검증합니다.

## 참조 문서

- `docs/03_architecture.md` - 폴더 구조 패턴, **레이어 의존성 규칙**
- `docs/09_state_management.md` - Riverpod 3.0 패턴

---

## 1. 레이어 의존성 규칙 (필수 준수)

```
┌─────────────────────────────────────────────────────┐
│                 의존성 방향                          │
│                                                     │
│   Presentation ───→ Domain ←─── Data               │
│       (UI)          (핵심)      (구현)              │
│                                                     │
│   Domain은 아무것도 의존하지 않음 (순수 Dart)         │
└─────────────────────────────────────────────────────┘
```

### Domain Layer (순수성 보장)
```dart
// ✅ 허용
import 'dart:async';
import 'dart:convert';

// ❌ 금지
import 'package:flutter/...';      // Flutter 의존 금지
import 'package:sql/...';     // 외부 서비스 금지
import 'package:hive/...';         // 저장소 구현 금지
import '../data/...';              // Data Layer 금지
import '../presentation/...';      // Presentation 금지
```

### Data Layer
```dart
// ✅ 허용
import '../domain/entities/...';
import '../domain/repositories/...';
import 'package:supabase_flutter/...';
import 'package:hive/...';

// ❌ 금지
import '../presentation/...';      // Presentation 의존 금지
```

### Presentation Layer
```dart
// ✅ 허용
import '../domain/entities/...';
import '../domain/repositories/...';
import 'package:flutter/...';
import 'package:flutter_riverpod/...';

// ❌ 금지
import '../data/...';              // Data 직접 접근 금지
// (Repository는 DI로 주입받음)
```

---

## 2. 생성 구조

```
lib/features/$ARGUMENTS/
├── domain/                        # 순수 Dart만
│   ├── entities/
│   │   └── [entity].dart          # 비즈니스 객체
│   └── repositories/
│       └── [feature]_repository.dart  # Interface (abstract)
├── data/                          # 외부 의존성 허용
│   ├── models/
│   │   └── [entity]_model.dart    # JSON 변환, extends Entity
│   ├── datasources/
│   │   └── [feature]_remote_datasource.dart  # Supabase
│   └── repositories/
│       └── [feature]_repository_impl.dart    # implements Repository
└── presentation/                  # Flutter/Riverpod
    ├── providers/
    │   └── [feature]_provider.dart  # @riverpod
    ├── screens/
    │   └── [feature]_screen.dart    # ConsumerWidget
    └── widgets/                     # 재사용 위젯
```

---

## 3. 실행 내용

### Step 1: 폴더 구조 생성
```bash
# 모든 필수 폴더 생성
lib/features/$ARGUMENTS/
├── domain/entities/
├── domain/repositories/
├── data/models/
├── data/datasources/
├── data/repositories/
├── presentation/providers/
├── presentation/screens/
└── presentation/widgets/
```

### Step 2: 템플릿 파일 생성

**domain/entities/[entity].dart:**
```dart
/// $ARGUMENTS Entity
///
/// 주의: 이 파일은 순수 Dart만 사용합니다.
/// Flutter, 외부 패키지 import 금지!
class [Entity] {
  final String id;
  // TODO: 필드 추가

  const [Entity]({required this.id});
}
```

**domain/repositories/[feature]_repository.dart:**
```dart
import '../entities/[entity].dart';

/// $ARGUMENTS Repository Interface
///
/// 주의: abstract class로 정의
/// 구현은 data/repositories/에서
abstract class [Feature]Repository {
  Future<[Entity]> fetch(String id);
  Future<void> save([Entity] entity);
}
```

**data/repositories/[feature]_repository_impl.dart:**
```dart
import '../../domain/entities/[entity].dart';
import '../../domain/repositories/[feature]_repository.dart';
import '../datasources/[feature]_remote_datasource.dart';

/// $ARGUMENTS Repository 구현체
///
/// Domain의 Repository interface를 구현
class [Feature]RepositoryImpl implements [Feature]Repository {
  final [Feature]RemoteDataSource _remoteDataSource;

  [Feature]RepositoryImpl(this._remoteDataSource);

  @override
  Future<[Entity]> fetch(String id) async {
    // TODO: 구현
  }
}
```

**presentation/providers/[feature]_provider.dart:**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/[entity].dart';
import '../../domain/repositories/[feature]_repository.dart';

part '[feature]_provider.g.dart';

/// $ARGUMENTS Provider
///
/// 주의: Domain만 의존, Data 직접 import 금지!
/// Repository는 DI로 주입받음
@riverpod
class [Feature]Notifier extends _$[Feature]Notifier {
  @override
  FutureOr<[Entity]?> build() async {
    // TODO: 초기화 로직
    return null;
  }
}
```

### Step 3: 의존성 검증
```
생성 후 자동 검증:
- [ ] Domain에 Flutter import 없음
- [ ] Domain에 외부 패키지 import 없음
- [ ] Data에 Presentation import 없음
- [ ] Presentation에 Data 직접 import 없음
```

---

## 4. 검증 체크리스트

구조 생성 완료 후 아래 항목 확인:

```
### 폴더 구조
- [ ] domain/entities/ 존재
- [ ] domain/repositories/ 존재
- [ ] data/models/ 존재
- [ ] data/datasources/ 존재
- [ ] data/repositories/ 존재
- [ ] presentation/providers/ 존재
- [ ] presentation/screens/ 존재

### 의존성 규칙
- [ ] Domain Layer: 순수 Dart만 (flutter import 없음)
- [ ] Data → Domain 의존 (역방향 없음)
- [ ] Presentation → Domain 의존 (Data 직접 접근 없음)
- [ ] Repository: Interface는 Domain, Impl은 Data

### 네이밍
- [ ] Entity: snake_case.dart, PascalCase 클래스
- [ ] Repository Interface: [feature]_repository.dart
- [ ] Repository Impl: [feature]_repository_impl.dart
- [ ] Provider: [feature]_provider.dart
- [ ] Screen: [feature]_screen.dart
```

---

## 5. 출력

```
## ARCH Report: $ARGUMENTS

### 생성된 구조
lib/features/$ARGUMENTS/
├── domain/
│   ├── entities/         ✅ Created
│   └── repositories/     ✅ Created
├── data/
│   ├── models/           ✅ Created
│   ├── datasources/      ✅ Created
│   └── repositories/     ✅ Created
└── presentation/
    ├── providers/        ✅ Created
    ├── screens/          ✅ Created
    └── widgets/          ✅ Created

### 생성 파일 (N개)
- domain/entities/[entity].dart (템플릿)
- domain/repositories/[feature]_repository.dart (템플릿)
- data/models/[entity]_model.dart (템플릿)
- data/datasources/[feature]_remote_datasource.dart (템플릿)
- data/repositories/[feature]_repository_impl.dart (템플릿)
- presentation/providers/[feature]_provider.dart (템플릿)
- presentation/screens/[feature]_screen.dart (템플릿)

### 의존성 검증
- Domain 순수성: ✅
- Layer 의존 방향: ✅

### 다음 단계
→ /module $ARGUMENTS (코드 구현)
```
