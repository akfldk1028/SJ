# Supabase 데이터베이스 마이그레이션 현황

> 최종 업데이트: 2025-12-09
>
> **상태: Supabase에 적용 완료**

---

## 1. 프로젝트 연결 정보

| 항목 | 값 |
|------|-----|
| **Supabase Project URL** | `https://kfciluyxkomskyxjaeat.supabase.co` |
| **환경변수 파일** | `frontend/.env` |
| **MCP 연결** | 확인됨 |

---

## 2. 적용된 마이그레이션

Supabase MCP를 통해 적용 완료:

| 버전 | 이름 | 내용 |
|------|------|------|
| 20251209111144 | `initial_schema_v2` | 4개 테이블 생성 |
| 20251209111155 | `rls_policies` | RLS 정책 적용 |
| 20251209111208 | `triggers` | 트리거 함수 생성 |

---

## 3. 생성된 테이블

| 테이블 | RLS | 설명 | Flutter 매핑 |
|--------|-----|------|-------------|
| `saju_profiles` | O | 사주 프로필 | `SajuProfile` |
| `saju_analyses` | O | 만세력 + 상세 분석 (JSONB) | `SajuChart` + `SajuAnalysis` |
| `chat_sessions` | O | 채팅 세션 | `ChatSession` |
| `chat_messages` | O | 채팅 메시지 | `ChatMessage` |

### 3.1 saju_profiles 주요 컬럼
- `user_id` → `auth.users(id)` FK
- `display_name`, `birth_date`, `gender`, `birth_city`
- `birth_time_minutes` (0~1439, NULL=시간모름)
- `is_lunar`, `is_leap_month`, `use_ya_jasi`
- `is_primary` (대표 프로필)

### 3.2 saju_analyses 주요 컬럼
- `profile_id` → `saju_profiles(id)` FK (1:1 UNIQUE)
- 4주: `year_gan/ji`, `month_gan/ji`, `day_gan/ji`, `hour_gan/ji`
- JSONB 필드:
  - `oheng_distribution` (오행 분포)
  - `yongsin` (용신/희신/기신)
  - `gyeokguk` (격국)
  - `sipsin_info` (십신)
  - `jijanggan_info` (지장간)
  - `sinsal_list` (신살)
  - `daeun` (대운)
  - `current_seun` (현재 세운)
  - `ai_summary` (Gemini 생성 요약)

### 3.3 chat_sessions 주요 컬럼
- `profile_id` → `saju_profiles(id)` FK
- `title`, `chat_type` (dailyFortune, sajuAnalysis, compatibility, general)
- `message_count`, `last_message_preview`
- `context_summary` (AI 대화 요약 - 토큰 절약용)

### 3.4 chat_messages 주요 컬럼
- `session_id` → `chat_sessions(id)` FK
- `role` (user, assistant, system)
- `content`, `status` (sending, sent, error)
- `suggested_questions[]`, `tokens_used`

---

## 4. RLS 정책

모든 테이블에 `auth.uid()` 기반 데이터 격리:

| 테이블 | 정책 이름 | 조건 |
|--------|----------|------|
| `saju_profiles` | `own_profiles` | `user_id = auth.uid()` |
| `saju_analyses` | `own_analyses` | 프로필 소유자 체크 (JOIN) |
| `chat_sessions` | `own_sessions` | 프로필 소유자 체크 (JOIN) |
| `chat_messages` | `own_messages` | 세션→프로필 소유자 체크 (JOIN) |

---

## 5. 트리거 함수

| 함수 | 적용 테이블 | 동작 |
|------|------------|------|
| `update_updated_at()` | profiles, analyses, sessions | UPDATE 시 자동 갱신 |
| `update_session_on_message()` | messages | 메시지 추가 시 세션 통계 업데이트 |
| `auto_session_title()` | messages | 첫 user 메시지로 세션 제목 생성 |
| `set_first_profile_primary()` | profiles | 첫 프로필 자동 대표 설정 |
| `ensure_single_primary()` | profiles | 대표 프로필 단일 유지 |

---

## 6. 파일 구조

```
frontend/lib/sql/
├── README.md                       # 이 파일 (진행 상황 요약)
├── 00_schema_design.md             # 스키마 설계 문서 (상세)
├── 00_full_migration_v2.sql        # 전체 마이그레이션 SQL (참고용)
├── 01_anonymous_auth_setup.md      # Anonymous Sign-In 설정 가이드 (Dashboard 상세)
└── 02_ai_context_best_practices.md # AI 컨텍스트 저장 베스트 프랙티스

frontend/lib/core/
├── services/
│   ├── supabase_service.dart    # Supabase 클라이언트 싱글톤
│   └── auth_service.dart        # 인증 서비스 (익명/영구 계정)
├── repositories/
│   ├── saju_profile_repository.dart   # 프로필 CRUD
│   ├── saju_analysis_repository.dart  # 만세력/분석 JSONB 매핑
│   └── chat_repository.dart           # 채팅 세션/메시지
└── providers/
    ├── auth_provider.dart             # Riverpod 인증 Provider
    └── repository_providers.dart      # Repository Providers
```

---

## 7. 다음 단계 (TODO)

### 7.1 Supabase Dashboard 설정 (필수) - 사용자 수동 작업
- [ ] **Anonymous Sign-In 활성화**
  - Dashboard → Authentication → Providers
  - "Enable Anonymous Sign-Ins" 토글 ON
  - URL: `https://supabase.com/dashboard/project/kfciluyxkomskyxjaeat/auth/providers`
- [ ] **Manual Linking 활성화** (익명→영구 전환용)
  - Dashboard → Project Settings → Authentication
  - "Enable Manual Linking" 토글 ON
  - URL: `https://supabase.com/dashboard/project/kfciluyxkomskyxjaeat/settings/auth`

### 7.2 Flutter 코드 구현
- [x] `signInAnonymously()` 구현 (앱 첫 실행 시) - **완료**
- [x] `linkIdentity()` 구현 (나중에 로그인 시) - **완료**
- [x] `SupabaseService` 구현 - **완료**
- [x] `AuthService` 구현 - **완료**
- [x] `AuthProvider` (Riverpod) 구현 - **완료**
- [x] Supabase Repository 구현 - **완료**
  - [x] `SajuProfileRepository` (CRUD)
  - [x] `SajuAnalysisRepository` (CRUD + JSONB 매핑)
  - [x] `ChatRepository` (세션 + 메시지)
- [x] Flutter Entity ↔ Supabase 테이블 매핑 - **완료**
  - [x] `SajuProfile` ↔ `saju_profiles`
  - [x] `SajuChart` + `SajuAnalysis` ↔ `saju_analyses`
  - [x] `ChatSession` ↔ `chat_sessions`
  - [x] `ChatMessage` ↔ `chat_messages`

### 7.3 AI 컨텍스트 연동
- [ ] 채팅 시작 시 `saju_analyses`에서 사주 정보 로드
- [ ] Gemini 프롬프트에 사주 컨텍스트 자동 주입
- [ ] 긴 대화 요약 저장 (`context_summary`)
- [ ] `ai_summary` JSON 생성 로직 구현

> **참고**: AI 컨텍스트 저장 베스트 프랙티스는 `02_ai_context_best_practices.md` 참조

---

## 8. 참고 명령어

### Supabase MCP로 테이블 확인
```
mcp__supabase__list_tables
mcp__supabase__list_migrations
```

### 직접 SQL 실행
```
mcp__supabase__execute_sql
```

### 새 마이그레이션 적용
```
mcp__supabase__apply_migration
- name: "migration_name"
- query: "SQL 쿼리"
```

---

## 9. 설계 핵심 포인트

### 9.1 Anonymous → Permanent User 패턴
```
signInAnonymously() → 익명 사용자 생성 (is_anonymous=true)
                    ↓
                 앱 사용 (데이터 저장)
                    ↓
linkIdentity() → 영구 계정 전환 (is_anonymous=false)
                 기존 데이터 유지됨!
```

### 9.2 AI 컨텍스트 저장 이유
- **토큰 절약**: 매번 만세력 재계산 X, DB에서 로드
- **세션 연속성**: "지난번에 말씀드린 것처럼 을목 일간이시니..."
- **대화 요약**: 긴 대화는 `context_summary`로 압축

### 9.3 JSONB 활용
- `oheng_distribution`, `yongsin`, `daeun` 등 복잡한 사주 분석 데이터
- 스키마 유연성 확보 (필드 추가 용이)
- PostgreSQL JSONB 인덱싱 지원

---

## 10. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-12-09 | v2 스키마 설계 및 Supabase 적용 완료 |
| 2025-12-09 | Anonymous Sign-In 가이드 작성 |
| 2025-12-09 | Flutter 인증 코드 구현 (SupabaseService, AuthService, AuthProvider) |
| 2025-12-09 | Supabase Repository 구현 (Profile, Analysis, Chat) |
| 2025-12-09 | Anonymous Sign-In 가이드 상세화 (Dashboard 위치 시각화) |
| 2025-12-09 | AI 컨텍스트 저장 베스트 프랙티스 문서 추가 |
