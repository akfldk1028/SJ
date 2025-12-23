# 만톡 (Mantok) 팀 구성

## 팀원

| 이니셜 | 역할 | 담당 영역 |
|--------|------|----------|
| **DK** | 총괄 + 광고 | 프로젝트 관리, 광고 모듈, 인터페이스 |
| **JH_BE** | Supabase | DB, Edge Functions, 인증 |
| **JH_AI** | AI 분석 | GPT-5.2, 사주 분석 로직 |
| **Jina** | AI 대화 | Gemini 3.0, 대화 생성 |
| **SH** | UI/UX | 화면, 위젯, 애니메이션 |

---

## 폴더 소유권

```
frontend/lib/
├── AI/
│   ├── common/         → JH_AI + Jina (공동)
│   ├── jh/             → JH_AI (전용)
│   └── jina/           → Jina (전용)
│
├── core/
│   ├── interfaces/     → DK (관리)
│   ├── services/supabase/ → JH_BE
│   └── theme/          → SH
│
├── features/
│   ├── ads/            → DK
│   ├── */data/         → JH_BE + AI팀
│   └── */presentation/ → SH
│
├── router/             → DK
├── shared/             → SH
│
└── sql/                → JH_BE
```

---

## Git 브랜치

```
master (배포)
  └── develop (통합)
        ├── DK
        ├── BE
        ├── AI
        └── UI
```

---

## PR 규칙

| 변경 영역 | 승인자 |
|----------|--------|
| 자기 전용 폴더 | 셀프 머지 가능 |
| AI/common/ | JH_AI + Jina 둘 다 |
| core/, shared/ | DK 승인 필수 |
| interfaces/ | 전체 팀 동의 |

---

## 커밋 컨벤션

```
[이니셜] type: 설명

예시:
[DK] feat: 광고 모듈 초기 구조
[JH_BE] migration: 채팅 테이블 추가
[JH_AI] fix: GPT 응답 파싱 오류
[Jina] refactor: 프롬프트 개선
[SH] style: 다크모드 적용
```

---

## 일일 워크플로우

```
09:00  git pull origin develop (동기화)
       ↓
작업   담당 폴더에서 개발
       ↓
18:00  PR → develop
       ↓
       DK 통합 빌드 확인
       ↓
       다음날 아침 동기화
```

---

## 인터페이스 계약

팀 간 연결은 `core/interfaces/`에 정의:

```dart
// AI ↔ Supabase
abstract class ChatRepositoryInterface {
  Future<void> saveMessage(ChatMessage msg);
  Stream<List<ChatMessage>> watchMessages(String roomId);
}

// AI ↔ UI
abstract class AIPipelineInterface {
  Stream<String> generateResponse(String input);
  Future<SajuAnalysis> analyze(SajuProfile profile);
}

// Supabase ↔ UI
abstract class AuthInterface {
  Future<User?> signIn();
  Stream<AuthState> get authStateChanges;
}
```

---

## 연락처

| 이니셜 | 연락 방법 |
|--------|----------|
| DK | (추가 필요) |
| JH_BE | (추가 필요) |
| JH_AI | (추가 필요) |
| Jina | (추가 필요) |
| SH | (추가 필요) |
