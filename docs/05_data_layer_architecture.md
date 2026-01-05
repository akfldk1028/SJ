# Data Layer Architecture

> 작성: 2024-12-26
> 작성자: DK
> 대상: 전체 팀 (JH_BE, JH_AI, Jina, SH)

---

## 1. 개요

이 문서는 **Queries/Mutations 패턴**을 사용한 데이터 레이어 아키텍처를 설명합니다.
React Query 스타일의 패턴을 Flutter/Riverpod에 적용하여 **타입 안전성**, **오프라인 지원**, **유지보수성**을 확보했습니다.

---

## 2. 폴더 구조

```
frontend/lib/
├── core/
│   └── data/
│       ├── query_result.dart    # 쿼리 결과 타입
│       ├── base_query.dart      # 기본 쿼리/뮤테이션 클래스
│       └── data.dart            # barrel export
│
├── features/
│   ├── profile/data/
│   │   ├── schema.dart          # 테이블 스키마
│   │   ├── queries.dart         # SELECT 쿼리
│   │   ├── mutations.dart       # INSERT/UPDATE/DELETE
│   │   └── README.md
│   │
│   ├── saju_chart/data/
│   │   ├── schema.dart
│   │   ├── queries.dart
│   │   ├── mutations.dart
│   │   └── README.md
│   │
│   └── saju_chat/data/
│       ├── schema.dart
│       ├── queries.dart
│       ├── mutations.dart
│       └── README.md
│
└── AI/
    └── common/
        └── data/
            ├── ai_context.dart      # AI 데이터 컨테이너
            ├── ai_data_provider.dart # Riverpod Provider
            └── README.md
```

---

## 3. QueryResult 패턴

모든 데이터베이스 작업은 `QueryResult<T>` 를 반환합니다.

```dart
sealed class QueryResult<T> {
  // 성공
  factory QueryResult.success(T data) = QuerySuccess;

  // 실패 (에러)
  factory QueryResult.failure(String message) = QueryFailure;

  // 오프라인 (캐시 데이터)
  factory QueryResult.offline(T? cachedData) = QueryOffline;
}
```

### 사용 예시

```dart
final result = await profileQueries.getById(profileId);

// 패턴 매칭
switch (result) {
  case QuerySuccess(:final data):
    print('프로필: ${data.displayName}');
  case QueryOffline(:final cachedData):
    print('오프라인 - 캐시: $cachedData');
  case QueryFailure(:final message):
    print('에러: $message');
}

// 또는 간단히
if (result.isSuccess) {
  final profile = result.data!;
}
```

---

## 4. 팀별 사용 가이드

### 4.1 JH_BE (Supabase 담당)

**테이블 변경 시:**
1. SQL 마이그레이션 작성
2. 해당 feature의 `schema.dart` 업데이트
3. `queries.dart`, `mutations.dart` 수정
4. 팀에 알림

**스키마 파일 예시:**
```dart
// features/profile/data/schema.dart
const String profilesTable = 'saju_profiles';

abstract class ProfileColumns {
  static const String id = 'id';
  static const String displayName = 'display_name';
  // ...
}
```

### 4.2 JH_AI (GPT-5.2 분석)

**데이터 접근:**
```dart
import 'package:saju_app/AI/common/data/data.dart';

class GptAnalysisService {
  final Ref ref;

  Future<String> analyze(String profileId) async {
    // AIContext 로드
    final context = await ref.read(aiContextBasicProvider(profileId).future);
    if (context == null) throw Exception('데이터 없음');

    // 프롬프트 생성
    final prompt = '''
사주 분석 대상:
${context.basicInfoForPrompt}

사주팔자: ${context.sajuPalza}
용신: ${context.yongsinOheng ?? '미정'}
''';

    // GPT 호출
    return await gptProvider.analyze(prompt);
  }
}
```

### 4.3 Jina (Gemini 3.0 대화)

**대화 컨텍스트 포함:**
```dart
import 'package:saju_app/AI/common/data/data.dart';

class GeminiChatService {
  final Ref ref;

  Stream<String> chat(String profileId, String sessionId, String message) async* {
    // 대화 포함 컨텍스트 로드
    final context = await ref.read(
      aiContextWithChatProvider(profileId, sessionId).future,
    );

    // 이전 대화 요약
    final history = context.conversationSummary;

    // Gemini 스트리밍
    yield* geminiProvider.chatStream(systemPrompt, message);
  }
}
```

### 4.4 SH (UI/UX)

**화면에서 데이터 사용:**
```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 프로필 조회 (비동기)
    final profileAsync = ref.watch(profileProvider(profileId));

    return profileAsync.when(
      data: (profile) => Text(profile.displayName),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('오류: $e'),
    );
  }
}
```

---

## 5. 주요 쿼리/뮤테이션 목록

### Profile

| 함수 | 설명 |
|------|------|
| `profileQueries.getAllByUserId(userId)` | 사용자의 모든 프로필 |
| `profileQueries.getById(id)` | ID로 단일 조회 |
| `profileQueries.getPrimaryByUserId(userId)` | 기본 프로필 |
| `profileMutations.create(profile, userId)` | 생성 |
| `profileMutations.update(profile, userId)` | 업데이트 |
| `profileMutations.setPrimary(id, userId)` | 기본 설정 |

### Saju Analysis

| 함수 | 설명 |
|------|------|
| `sajuAnalysisQueries.getByProfileId(profileId)` | 전체 분석 |
| `sajuAnalysisQueries.getForAiContext(profileId)` | AI용 핵심 데이터 |
| `sajuAnalysisQueries.getYongsin(profileId)` | 용신만 |
| `sajuAnalysisMutations.upsert(analysis)` | 생성/업데이트 |
| `sajuAnalysisMutations.updateDaeun(id, daeun)` | 대운 업데이트 |

### Chat

| 함수 | 설명 |
|------|------|
| `chatSessionQueries.getAllByProfileId(profileId)` | 세션 목록 |
| `chatMessageQueries.getAllBySessionId(sessionId)` | 메시지 목록 |
| `chatSessionMutations.create(session)` | 세션 생성 |
| `chatMessageMutations.createPair(user, ai)` | 대화 쌍 저장 |

---

## 6. 오프라인 지원

### 쿼리
- Supabase 연결 없으면 `QueryResult.offline(cachedData)` 반환
- Hive 캐시 데이터 사용 가능

### 뮤테이션
- 오프라인 시 `QueryResult.failure('오프라인 상태')` 반환
- 저장 작업은 온라인에서만 가능

---

## 7. 코드 생성

Riverpod Provider 사용 시 코드 생성 필요:

```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

또는 watch 모드:
```bash
dart run build_runner watch -d
```

---

## 8. 관련 문서

- `docs/04_data_models.md` - 데이터 모델 상세
- `docs/09_state_management.md` - Riverpod 가이드
- `features/*/data/README.md` - 각 feature별 상세
- `AI/common/data/README.md` - AI 데이터 접근
