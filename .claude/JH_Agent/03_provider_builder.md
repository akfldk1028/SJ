# Provider Builder Agent

> Riverpod 3.0 Provider를 생성하는 에이전트

---

## 역할

1. @riverpod 어노테이션 기반 Provider 코드 생성
2. AsyncNotifier 패턴으로 비동기 상태 관리
3. 올바른 ref 사용 패턴 적용

---

## 호출 시점

- 새 Feature의 상태 관리 구현 시
- 기존 Provider 추가/수정 시

---

## Provider 유형

### 1. 단순 값 Provider

```dart
@riverpod
String greeting(Ref ref) {
  return 'Hello';
}
```

### 2. 비동기 Provider (데이터 조회)

```dart
@riverpod
Future<List<SajuProfile>> profileList(Ref ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getAll();
}
```

### 3. AsyncNotifier (CRUD 작업)

```dart
@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async {
    return await _fetchProfiles();
  }

  Future<List<SajuProfile>> _fetchProfiles() async {
    final repository = ref.read(profileRepositoryProvider);
    return await repository.getAll();
  }

  Future<void> add(SajuProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).save(profile);
      return await _fetchProfiles();
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).delete(id);
      return await _fetchProfiles();
    });
  }
}
```

### 4. 파라미터 Provider (Family)

```dart
@riverpod
Future<SajuChart?> sajuChart(Ref ref, String profileId) async {
  final repository = ref.watch(sajuChartRepositoryProvider);
  return await repository.getByProfileId(profileId);
}
```

### 5. 상태 클래스 Provider (freezed)

```dart
// chat_state.dart
@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    String? activeChatId,
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isSending,
    String? error,
  }) = _ChatState;
}

// chat_provider.dart
@riverpod
class Chat extends _$Chat {
  @override
  ChatState build() {
    return const ChatState();
  }

  void startNewChat() {
    state = const ChatState();
  }

  Future<void> sendMessage(String message) async {
    state = state.copyWith(isSending: true, error: null);

    try {
      // ... send logic
      state = state.copyWith(
        messages: [...state.messages, newMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }
}
```

---

## 입력

```yaml
provider_name: profileList
type: async_notifier          # simple | async | async_notifier | family
entity: SajuProfile
operations:
  - getAll
  - add
  - delete
```

---

## 생성 템플릿

```dart
// features/{feature}/presentation/providers/{provider}_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{provider}_provider.g.dart';

@riverpod
class {ProviderName} extends _${ProviderName} {
  @override
  Future<{ReturnType}> build() async {
    // TODO: implement initial fetch
  }

  // TODO: add methods
}
```

---

## ref 사용 규칙

| 상황 | 메서드 | 이유 |
|------|--------|------|
| build() 내 | ref.watch() | 의존성 변경 시 리빌드 |
| 메서드 내 | ref.read() | 일회성 읽기, 리빌드 방지 |
| 다른 Provider 무효화 | ref.invalidate() | 강제 리프레시 |
| 자기 자신 무효화 | ref.invalidateSelf() | 데이터 새로고침 |

---

## 출력

- Provider 파일 생성
- part 파일 자동 생성 안내 (`dart run build_runner build`)
- UI 연동 예시 코드

---

## 주의사항

- keepAlive: true는 앱 전역 상태에만 사용
- AutoDispose가 기본값 (화면 벗어나면 dispose)
