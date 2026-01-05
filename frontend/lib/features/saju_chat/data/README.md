# Saju Chat Data Layer

> 작성: 2024-12-26
> 담당: DK

---

## 파일 구조

```
data/
├── schema.dart        # 테이블 스키마 (sessions + messages)
├── queries.dart       # SELECT 쿼리
├── mutations.dart     # INSERT/UPDATE/DELETE
├── models/            # Freezed 데이터 모델
├── datasources/       # Gemini REST API, OpenAI API
└── README.md          # 이 파일
```

---

## 사용법

### 1. 세션 쿼리

```dart
import 'package:saju_app/features/saju_chat/data/queries.dart';

// 프로필의 세션 목록
final sessions = await chatSessionQueries.getAllByProfileId(profileId);

// 최근 세션
final latest = await chatSessionQueries.getLatestByProfileId(profileId);

// 타입별 세션 (오늘 운세, 연애, 재물 등)
final loveChats = await chatSessionQueries.getByChatType(profileId, 'love');
```

### 2. 메시지 쿼리

```dart
// 세션의 메시지 목록
final messages = await chatMessageQueries.getAllBySessionId(sessionId);

// 최근 N개 메시지 (역순)
final recent = await chatMessageQueries.getRecentBySessionId(sessionId, limit: 20);

// 토큰 사용량 합계
final tokens = await chatMessageQueries.getTotalTokensUsed(sessionId);
```

### 3. 세션 뮤테이션

```dart
import 'package:saju_app/features/saju_chat/data/mutations.dart';

// 새 세션 생성
final session = await chatSessionMutations.create(sessionModel);

// 제목 변경
await chatSessionMutations.updateTitle(sessionId, '새 제목');

// 삭제 (메시지도 함께 삭제)
await chatSessionMutations.delete(sessionId);
```

### 4. 메시지 뮤테이션

```dart
// 메시지 생성
await chatMessageMutations.create(messageModel);

// 사용자 + AI 응답 동시 저장
await chatMessageMutations.createPair(userMsg, aiMsg);

// 스트리밍 완료 후 내용 업데이트
await chatMessageMutations.updateContent(
  messageId,
  finalContent,
  tokensUsed: 150,
);
```

---

## 테이블 스키마

### chat_sessions

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | uuid | PK |
| profile_id | uuid | FK → saju_profiles |
| title | text | 세션 제목 |
| chat_type | text | 채팅 타입 (general, today, love...) |
| message_count | int | 메시지 수 |
| last_message_preview | text | 마지막 메시지 미리보기 |
| created_at | timestamptz | 생성일 |
| updated_at | timestamptz | 수정일 |

### chat_messages

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | uuid | PK |
| session_id | uuid | FK → chat_sessions (CASCADE) |
| content | text | 메시지 내용 |
| role | text | user / assistant / system |
| status | text | sending / sent / error |
| tokens_used | int | AI 토큰 사용량 (nullable) |
| suggested_questions | jsonb | 후속 질문 (nullable) |
| created_at | timestamptz | 생성일 |

---

## 채팅 타입 (ChatType)

| 타입 | 설명 |
|------|------|
| general | 일반 대화 |
| today | 오늘의 운세 |
| love | 연애운 |
| career | 직장/사업운 |
| finance | 재물운 |
| health | 건강운 |

---

## AI 연동 패턴

### 스트리밍 응답 저장

```dart
// 1. sending 상태로 먼저 저장
final result = await chatMessageMutations.create(
  ChatMessageModel(
    sessionId: sessionId,
    content: '',  // 빈 내용
    role: 'assistant',
    status: 'sending',
  ),
);

// 2. 스트리밍 진행...
// 3. 완료 후 업데이트
await chatMessageMutations.updateContent(
  result.data!.id,
  accumulatedContent,
  tokensUsed: geminiResponse.tokensUsed,
);
```

### AI 컨텍스트용 대화 조회

```dart
// 최근 10개 대화 (AI 컨텍스트 전달용)
final context = await chatMessageQueries.getForAiContext(sessionId, limit: 10);
```

---

## 관련 AI 모듈

### Edge Function 기반 (권장 - 2025-12-30 추가)

API 키가 Supabase Secrets에만 저장되어 보안이 강화된 버전

- `lib/features/saju_chat/data/datasources/gemini_edge_datasource.dart`
  - ai-gemini Edge Function 호출
  - 토큰 사용량 추적
  - API 키 서버 보관 (보안 강화)

- `lib/features/saju_chat/data/datasources/openai_edge_datasource.dart`
  - ai-openai Edge Function 호출
  - GPT-5.2 사주 분석
  - API 키 서버 보관 (보안 강화)

- `lib/features/saju_chat/data/datasources/saju_chat_edge_datasource.dart`
  - saju-chat Edge Function 호출
  - 사주 컨텍스트 기반 대화
  - Quota 체크 (일일 토큰 제한)
  - 토큰 사용량 DB 자동 저장

### 직접 API 호출 (레거시 - 개발용)

- `lib/features/saju_chat/data/datasources/gemini_rest_datasource.dart`
  - Gemini 3.0 REST API 직접 호출
  - 스트리밍 응답
  - ⚠️ API 키가 .env에 포함 (보안 취약)

- `lib/features/saju_chat/data/datasources/openai_datasource.dart`
  - GPT-5.2 Responses API 직접 호출
  - ⚠️ API 키가 .env에 포함 (보안 취약)
