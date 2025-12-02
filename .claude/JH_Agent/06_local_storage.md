# Local Storage Agent

> Hive 기반 로컬 저장소를 설정하는 에이전트

---

## 역할

1. Hive Box 설정 및 초기화
2. TypeAdapter 생성
3. DataSource 구현

---

## 호출 시점

- 로컬 저장이 필요한 Feature 구현 시
- Supabase 연동 전 로컬 우선 개발 시

---

## Hive 초기화

```dart
// main.dart
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();

  // TypeAdapter 등록
  Hive.registerAdapter(SajuProfileModelAdapter());
  Hive.registerAdapter(GenderAdapter());
  Hive.registerAdapter(ChatSessionModelAdapter());
  Hive.registerAdapter(ChatMessageModelAdapter());

  // Box 열기
  await Hive.openBox<SajuProfileModel>('saju_profiles');
  await Hive.openBox<ChatSessionModel>('chat_sessions');
  await Hive.openBox<ChatMessageModel>('chat_messages');
  await Hive.openBox('settings');  // 설정용 (동적 타입)

  runApp(const ProviderScope(child: MyApp()));
}
```

---

## TypeAdapter 생성

### 방법 1: 수동 작성

```dart
// data/models/saju_profile_model.dart
import 'package:hive/hive.dart';

part 'saju_profile_model.g.dart';

@HiveType(typeId: 0)
class SajuProfileModel extends SajuProfile with HiveObjectMixin {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String displayName;

  @HiveField(2)
  @override
  final DateTime birthDate;

  // ... 모든 필드에 @HiveField 추가

  const SajuProfileModel({...});
}
```

### 방법 2: build_runner 자동 생성

```bash
dart run build_runner build
```

---

## DataSource 구현

```dart
// data/datasources/profile_local_datasource.dart
import 'package:hive/hive.dart';

class ProfileLocalDataSource {
  static const String boxName = 'saju_profiles';

  Box<SajuProfileModel> get _box => Hive.box<SajuProfileModel>(boxName);

  /// 모든 프로필 조회
  List<SajuProfileModel> getAll() {
    return _box.values.toList();
  }

  /// ID로 프로필 조회
  SajuProfileModel? getById(String id) {
    return _box.get(id);
  }

  /// 프로필 저장
  Future<void> save(SajuProfileModel profile) async {
    await _box.put(profile.id, profile);
  }

  /// 프로필 삭제
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// 전체 삭제
  Future<void> clear() async {
    await _box.clear();
  }

  /// 프로필 개수
  int get count => _box.length;
}
```

---

## Provider 연동

```dart
// core/providers/local_storage_provider.dart
@Riverpod(keepAlive: true)
ProfileLocalDataSource profileLocalDataSource(Ref ref) {
  return ProfileLocalDataSource();
}

// features/profile/presentation/providers/profile_provider.dart
@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async {
    final localDataSource = ref.watch(profileLocalDataSourceProvider);
    return localDataSource.getAll();
  }

  Future<void> add(SajuProfile profile) async {
    final localDataSource = ref.read(profileLocalDataSourceProvider);
    final model = SajuProfileModel.fromEntity(profile);
    await localDataSource.save(model);
    ref.invalidateSelf();
  }
}
```

---

## Box 목록

| Box 이름 | 타입 | 용도 |
|----------|------|------|
| saju_profiles | SajuProfileModel | 프로필 저장 |
| chat_sessions | ChatSessionModel | 채팅 세션 |
| chat_messages | ChatMessageModel | 채팅 메시지 |
| settings | dynamic | 앱 설정 (온보딩 완료 등) |

---

## TypeId 관리

| typeId | 클래스 |
|--------|--------|
| 0 | SajuProfileModel |
| 1 | Gender |
| 2 | ChatSessionModel |
| 3 | ChatMessageModel |
| 4 | MessageRole |

---

## 입력

```yaml
entity: SajuProfile
box_name: saju_profiles
type_id: 0
operations:
  - getAll
  - getById
  - save
  - delete
```

---

## 출력

- TypeAdapter 코드 (또는 어노테이션)
- DataSource 클래스
- Provider 연동 코드
- main.dart 초기화 코드
