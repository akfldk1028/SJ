# Flutter 상태관리 가이드 (2024-2025)

> 만톡 앱을 위한 상태관리 전략 및 최신 트렌드 분석

---

## 1. 2025년 상태관리 트렌드 요약

### 1.1 주요 선택지
| 솔루션 | 버전 | 적합한 규모 | 특징 |
|--------|------|-------------|------|
| **Riverpod 3.0** | 3.0.0 (2024.10) | 중~대규모 | 타입 안전, 코드 생성, 최신 권장 |
| **Bloc/Cubit** | 9.x | 대규모/엔터프라이즈 | 엄격한 구조, 예측 가능 |
| **Signals** | 6.x (신규) | 소~중규모 | 네이티브 반응형, 경량 |
| **GetX** | 4.x | 소~중규모 | 올인원, 보일러플레이트 최소 |
| **Provider** | 6.x | 소규모 | 입문용, 단순함 |

### 1.2 만톡 앱 선택: **Riverpod 3.0**

선택 이유:
- 중규모 앱에 최적 (만톡은 5-10개 주요 화면)
- 코드 생성으로 보일러플레이트 최소화
- Supabase와의 비동기 연동에 적합 (AsyncNotifier)
- 테스트 용이성
- 2024년 10월 출시된 최신 버전

---

## 2. Riverpod 3.0 핵심 변경사항

### 2.1 주요 업데이트 (2024.10)

| 기능 | 설명 |
|------|------|
| **Unified Ref** | `Ref<T>` 제네릭 불필요, 단순히 `Ref` 사용 |
| **@riverpod 매크로** | 코드 생성 간소화, 보일러플레이트 감소 |
| **Pause/Resume** | 리스너 수동 일시정지/재개 지원 |
| **Mutations** | 상태 변경 로직 분리 지원 |
| **Offline Persistence** | 로컬 캐싱 지원 (실험적) |
| **AutoDispose 기본값** | 코드 생성 시 자동 dispose가 기본 |
| **Generic Provider** | 타입 파라미터 지원 |

### 2.2 Riverpod 2.x → 3.0 변경점

```dart
// Riverpod 2.x (이전)
@riverpod
Example example(ExampleRef ref) {  // ExampleRef 필요
  return Example();
}

// Riverpod 3.0 (현재)
@riverpod
Example example(Ref ref) {  // 단순히 Ref
  return Example();
}
```

---

## 3. Riverpod 3.0 설정 (만톡 앱)

### 3.1 패키지 설치
```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

dev_dependencies:
  riverpod_generator: ^3.0.0
  build_runner: ^2.4.0
  riverpod_lint: ^3.0.0  # 린트 규칙
```

### 3.2 코드 생성 실행
```bash
dart run build_runner watch -d
```

### 3.3 앱 설정
```dart
// main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(...);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

---

## 4. 만톡 앱 Provider 설계

### 4.1 Provider 구조
```
lib/
├── core/
│   └── providers/
│       ├── supabase_provider.dart    # Supabase 클라이언트
│       └── auth_provider.dart        # 인증 상태
│
└── features/
    ├── profile/
    │   └── providers/
    │       ├── profile_provider.dart     # 프로필 목록
    │       └── active_profile_provider.dart
    │
    ├── saju_chart/
    │   └── providers/
    │       ├── saju_chart_provider.dart  # 사주 차트
    │       └── saju_summary_provider.dart
    │
    └── saju_chat/
        └── providers/
            ├── chat_provider.dart        # 채팅 상태
            ├── chat_sessions_provider.dart
            └── chat_messages_provider.dart
```

### 4.2 Supabase Provider
```dart
// core/providers/supabase_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_provider.g.dart';

@Riverpod(keepAlive: true)  // 앱 생명주기 동안 유지
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

@Riverpod(keepAlive: true)
GoTrueClient supabaseAuth(Ref ref) {
  return ref.watch(supabaseClientProvider).auth;
}

@riverpod
Stream<AuthState> authState(Ref ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
}

@riverpod
User? currentUser(Ref ref) {
  ref.watch(authStateProvider);  // 인증 상태 변경 감지
  return ref.watch(supabaseClientProvider).auth.currentUser;
}
```

### 4.3 프로필 Provider (AsyncNotifier)
```dart
// features/profile/providers/profile_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_provider.g.dart';

@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async {
    final supabase = ref.watch(supabaseClientProvider);

    final response = await supabase
        .from('saju_profiles')
        .select()
        .order('created_at', ascending: false);

    return response.map((e) => SajuProfileModel.fromJson(e)).toList();
  }

  // 프로필 추가
  Future<void> addProfile(SajuProfile profile) async {
    final supabase = ref.read(supabaseClientProvider);

    await supabase.from('saju_profiles').insert(profile.toJson());

    ref.invalidateSelf();  // 목록 새로고침
    await future;  // 새 데이터 대기
  }

  // 프로필 삭제
  Future<void> deleteProfile(String profileId) async {
    final supabase = ref.read(supabaseClientProvider);

    await supabase.from('saju_profiles').delete().eq('id', profileId);

    ref.invalidateSelf();
    await future;
  }
}

// 활성 프로필
@riverpod
class ActiveProfile extends _$ActiveProfile {
  @override
  SajuProfile? build() {
    final profiles = ref.watch(profileListProvider).valueOrNull;
    return profiles?.firstWhereOrNull((p) => p.isActive);
  }

  void setActive(SajuProfile profile) {
    state = profile;
  }
}
```

### 4.4 채팅 Provider
```dart
// features/saju_chat/providers/chat_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

// 채팅 상태
@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    String? activeChatId,
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isSending,
    String? error,
  }) = _ChatState;
}

@riverpod
class Chat extends _$Chat {
  @override
  ChatState build() {
    return const ChatState();
  }

  // 메시지 전송
  Future<void> sendMessage(String message) async {
    final profileId = ref.read(activeProfileProvider)?.id;
    if (profileId == null) return;

    state = state.copyWith(isSending: true, error: null);

    // 사용자 메시지 즉시 표시 (Optimistic Update)
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      chatId: state.activeChatId ?? '',
      role: MessageRole.user,
      content: message,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
    );

    try {
      final supabase = ref.read(supabaseClientProvider);

      // Edge Function 호출
      final response = await supabase.functions.invoke(
        'saju-chat',
        body: {
          'chatId': state.activeChatId,
          'profileId': profileId,
          'message': message,
        },
      );

      final data = response.data['data'];

      // AI 응답 추가
      final aiMessage = ChatMessage(
        id: data['messageId'],
        chatId: data['chatId'],
        role: MessageRole.assistant,
        content: data['content'],
        suggestedQuestions: List<String>.from(data['suggestedQuestions'] ?? []),
        createdAt: DateTime.parse(data['createdAt']),
      );

      state = state.copyWith(
        activeChatId: data['chatId'],
        messages: [...state.messages, aiMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  // 새 채팅 시작
  void startNewChat() {
    state = const ChatState();
  }

  // 기존 채팅 로드
  Future<void> loadChat(String chatId) async {
    final supabase = ref.read(supabaseClientProvider);

    final response = await supabase
        .from('chat_messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    final messages = response
        .map((e) => ChatMessageModel.fromJson(e))
        .toList();

    state = ChatState(
      activeChatId: chatId,
      messages: messages,
    );
  }
}

// 채팅 세션 목록
@riverpod
Future<List<ChatSession>> chatSessions(Ref ref, String profileId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('chat_sessions')
      .select()
      .eq('profile_id', profileId)
      .order('last_message_at', ascending: false);

  return response.map((e) => ChatSessionModel.fromJson(e)).toList();
}
```

### 4.5 사주 차트 Provider
```dart
// features/saju_chart/providers/saju_chart_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saju_chart_provider.g.dart';

@riverpod
Future<SajuChart?> sajuChart(Ref ref, String profileId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('saju_charts')
      .select()
      .eq('profile_id', profileId)
      .maybeSingle();

  if (response == null) return null;
  return SajuChartModel.fromJson(response);
}

@riverpod
Future<SajuSummary?> sajuSummary(Ref ref, String profileId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('saju_summaries')
      .select()
      .eq('profile_id', profileId)
      .maybeSingle();

  if (response == null) return null;
  return SajuSummaryModel.fromJson(response);
}

// 사주 계산 트리거
@riverpod
class SajuCalculator extends _$SajuCalculator {
  @override
  AsyncValue<SajuChart?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> calculate(String profileId) async {
    state = const AsyncValue.loading();

    try {
      final supabase = ref.read(supabaseClientProvider);

      final response = await supabase.functions.invoke(
        'calculate-saju',
        body: {'profileId': profileId},
      );

      final chart = SajuChartModel.fromJson(response.data['data']);

      // 관련 provider 무효화
      ref.invalidate(sajuChartProvider(profileId));
      ref.invalidate(sajuSummaryProvider(profileId));

      state = AsyncValue.data(chart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

---

## 5. UI에서 Provider 사용

### 5.1 ConsumerWidget 사용
```dart
// features/saju_chat/presentation/screens/saju_chat_screen.dart
class SajuChatScreen extends ConsumerWidget {
  const SajuChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(activeProfile?.displayName ?? '만톡'),
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: ListView.builder(
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),

          // 로딩 표시
          if (chatState.isSending)
            const LinearProgressIndicator(),

          // 입력 필드
          ChatInputField(
            onSend: (message) {
              ref.read(chatProvider.notifier).sendMessage(message);
            },
          ),
        ],
      ),
    );
  }
}
```

### 5.2 AsyncValue 처리
```dart
class ProfileListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profileListProvider);

    return profilesAsync.when(
      data: (profiles) => ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) => ProfileCard(profile: profiles[index]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('오류: $error'),
            ElevatedButton(
              onPressed: () => ref.invalidate(profileListProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.3 ref.listen 사용 (사이드 이펙트)
```dart
class SomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 에러 발생 시 스낵바 표시
    ref.listen(chatProvider.select((s) => s.error), (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next)),
        );
      }
    });

    return ...;
  }
}
```

---

## 6. 대안 비교: Signals vs Riverpod vs Bloc

### 6.1 성능 벤치마크 (2024)
| 측정 항목 | Riverpod | Bloc | GetX |
|----------|----------|------|------|
| 최대 CPU 사용률 | 6.7% | 6.1% | 5.8% |
| 평균 FPS | 60 | 60 | 60 |
| 최대 프레임 시간 | 17ms | 11ms | 15ms |
| 평균 프레임 시간 | 1.5ms | 3ms | 2ms |

> 성능은 비슷하며, 아키텍처 선호도에 따라 선택

### 6.2 Flutter Signals (신규)

Signals는 2024년에 등장한 새로운 상태관리 방식:

```dart
// signals 패키지 사용 예시
import 'package:signals/signals_flutter.dart';

class CounterWidget extends StatelessWidget {
  final counter = signal(0);  // 반응형 값

  @override
  Widget build(BuildContext context) {
    return Watch((context) => Text('${counter.value}'));  // 자동 리빌드
  }
}
```

**Signals 특징:**
- 경량화, 최소 오버헤드
- 네이티브 반응형 시스템
- MVP/단순 앱에 적합
- 아직 생태계 성숙 중

**만톡에 적합하지 않은 이유:**
- 비동기 지원 제한적
- Supabase 연동 패턴 부족
- 대규모 상태에 검증 부족

### 6.3 언제 무엇을 선택?

| 앱 유형 | 추천 |
|---------|------|
| MVP, 프로토타입, 카운터 앱 | setState, Signals |
| 성장 중인 앱 (만톡) | **Riverpod 3.0** |
| 엔터프라이즈, 규제 앱 | Bloc/Cubit |
| 빠른 개발, 올인원 | GetX (유지보수 주의) |

---

## 7. 만톡 앱 최종 권장사항

### 7.1 Riverpod 3.0 선택 이유
1. **코드 생성**: `@riverpod` 어노테이션으로 보일러플레이트 최소화
2. **타입 안전**: 컴파일 타임 에러 검출
3. **비동기 최적화**: AsyncNotifier로 Supabase 연동 용이
4. **테스트 용이**: ProviderContainer.test() 지원
5. **Offline Persistence**: 캐싱 지원 (실험적)

### 7.2 폴더 구조 권장
```
lib/
├── core/
│   └── providers/          # 앱 전역 Provider
│
└── features/
    └── {feature}/
        └── providers/      # 기능별 Provider
```

### 7.3 코드 생성 명령어
```bash
# 개발 중 (watch 모드)
dart run build_runner watch -d

# 빌드 전 (일회성)
dart run build_runner build --delete-conflicting-outputs
```

---

## 참고 자료

- [Riverpod 3.0 공식 문서](https://riverpod.dev/docs/whats_new)
- [Riverpod Code Generation](https://riverpod.dev/docs/concepts/about_code_generation)
- [Flutter State Management 2025 비교](https://www.creolestudios.com/flutter-state-management-tool-comparison/)
- [Riverpod vs Bloc 비교](https://somniosoftware.com/blog/riverpod-vs-bloc-which-one-is-better-in-2024)
- [Flutter Signals 패키지](https://pub.dev/packages/signals)
- [State Management Benchmark](https://medium.com/@yurinovicow/flutter-breaking-benchmark-taboo-802530fe1a03)

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2025-12-01 | 0.1 | 초안 작성 - Riverpod 3.0 기반 | - |
