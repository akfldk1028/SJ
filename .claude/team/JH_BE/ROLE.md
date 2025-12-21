# JH_BE - Supabase 백엔드

## 역할
- **Supabase 설정**: 테이블 스키마, RLS 정책, Edge Functions
- **인증/인가**: 사용자 인증 로직
- **DB 마이그레이션**: 스키마 변경 관리

---

## 담당 폴더

### 전용 영역 (자유 수정)
```
sql/
├── migrations/             # DB 마이그레이션
├── functions/              # Edge Functions
├── triggers/               # DB 트리거
└── views/                  # DB 뷰

frontend/lib/
├── core/services/supabase/ # Supabase 서비스 (신규 생성)
└── features/*/data/datasources/*_supabase_datasource.dart
```

### 협업 영역
```
frontend/lib/core/interfaces/  # DK 승인 후 구현
```

---

## 수정 금지

```
frontend/lib/AI/              # AI 팀 전용
frontend/lib/features/*/presentation/  # UI 팀 전용
frontend/lib/shared/          # UI 팀 전용
```

---

## 사용 Agent

| Agent | 용도 |
|-------|------|
| 20_supabase_schema | DB 스키마 설계 |
| 21_edge_functions | Edge Function 개발 |
| 22_rls_policy | Row Level Security 정책 |

---

## 커밋 컨벤션

```
[JH_BE] feat: 사용자 테이블 스키마 추가
[JH_BE] fix: RLS 정책 버그 수정
[JH_BE] migration: 채팅 테이블 컬럼 추가
```

---

## 주요 책임

1. **스키마 변경**: 마이그레이션 파일로 관리, 직접 DB 수정 금지
2. **Edge Functions**: TypeScript로 작성, 테스트 필수
3. **RLS 정책**: 보안 검토 후 적용
4. **인터페이스**: `AuthInterface`, `DataInterface` 구현

---

## AI 팀과 협업

```dart
// AI 팀이 호출할 인터페이스 구현
class SupabaseChatRepository implements ChatRepositoryInterface {
  Future<void> saveMessage(ChatMessage msg);
  Future<List<ChatMessage>> getHistory(String roomId);
}
```

---

## 충돌 방지 (Lock 시스템)

### 작업 시작 전
```bash
git pull origin develop
ls .claude/locks/   # lock 파일 확인
```

### sql/ 폴더는 내 전용 → Lock 불필요

### core/services/supabase/ 수정 시
```bash
# 1. Lock 생성
echo "owner: JH_BE
task: 작업 내용
started: $(date -Iseconds)" > .claude/locks/core.lock

# 2. 작업 진행...

# 3. 완료 후
rm .claude/locks/core.lock
git add . && git commit && git push
```
