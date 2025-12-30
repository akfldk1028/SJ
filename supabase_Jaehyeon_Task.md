# Supabase Jaehyeon Task - 작업 이력

## 작업자 정보
- **담당자**: JH_BE (Jaehyeon)
- **역할**: Supabase Backend
- **작업 범위**: Edge Functions, SQL, Database

---

## 백업 시스템

### 백업 위치
- **경로**: `supabase/backups/`
- **명명 규칙**: `{function_name}_v{version}_{YYYY-MM-DD}.ts`

### 현재 백업 목록
| 파일명 | 버전 | 날짜 | 설명 |
|--------|------|------|------|
| `ai-gemini_v9_2024-12-30.ts` | v9 | 2024-12-30 | Admin Quota 무제한 기능 추가 |
| `ai-gemini_v10_2024-12-30.ts` | v10 | 2024-12-30 | 모델명 수정 (임시: gemini-2.0-flash) |
| `ai-gemini_v11_2024-12-30.ts` | v11 | 2024-12-30 | 로컬 백업 (gemini-3-flash-preview) |
| `ai-gemini_v13_2024-12-30.ts` | v13 | 2024-12-30 | 모델명: gemini-3-flash-preview |
| `ai-gemini_v14_2024-12-30.ts` | v14 | 2024-12-30 | responseMimeType 제거 (JSON 응답 버그 수정) |
| `ai-gemini_v15_2024-12-30.ts` | v15 | 2024-12-30 | **max_tokens 4096 (짤림 방지) - 배포됨** |
| `ai-openai_v7_2024-12-30.ts` | v7 | 2024-12-30 | Admin Quota 무제한 기능 추가 |
| `ai-openai_v8_2024-12-30.ts` | v8 | 2024-12-30 | max_tokens → max_completion_tokens 수정 |
| `ai-openai_v9_2024-12-30.ts` | v9 | 2024-12-30 | gpt-4o-mini → gpt-5.2 모델 변경 |
| `ai-openai_v10_2024-12-31.ts` | v10 | 2024-12-31 | **gpt-5.2-thinking 모델, max_tokens 10000 - 배포됨** |

---

## Phase 20: Admin Quota 무제한 구현 (2024-12-30)

### 개요
Admin 사용자에게 일일 토큰 quota를 무제한(10억 토큰)으로 설정하는 기능 구현

### 완료된 작업

#### 1. Edge Function 수정 및 배포
| Function | Version | 상태 | 변경 내용 |
|----------|---------|------|-----------|
| ai-gemini | **v15** | ✅ 배포 완료 | Admin 체크 + Quota 무제한 + **gemini-3-flash-preview** + responseMimeType 제거 + max_tokens 4096 |
| ai-openai | **v10** | ✅ 배포 완료 | Admin 체크 + Quota 무제한 + **gpt-5.2-thinking 모델** + max_completion_tokens 10000 |

**로직 흐름**:
```
1. user_id 파라미터 수신
2. saju_profiles 테이블에서 relation_type = 'admin' 확인
3. Admin이면 daily_quota = 1,000,000,000 (10억)
4. 일반 사용자는 daily_quota = 50,000
5. user_daily_token_usage 테이블에 사용량 기록
```

#### 2. Flutter 코드 수정
| 파일 | 변경 내용 |
|------|-----------|
| `gemini_edge_datasource.dart` | Edge Function 호출 시 user_id 전달 |
| `openai_edge_datasource.dart` | Edge Function 호출 시 user_id 전달 |
| `onboarding_screen.dart` | Admin 프로필 중복 생성 방지 |

#### 3. Splash Queries 수정
- **목적**: Admin 프로필이 있어도 앱 시작 시 온보딩 화면 표시
- **변경**: 모든 프로필 조회에서 `relation_type = 'admin'` 제외

#### 4. Database 작업
- 중복 admin 프로필 삭제 (1개만 남김)
- `is_admin_user()` PostgreSQL 함수 생성

### 버그 수정 (2024-12-30)
| 에러 | 원인 | 해결 |
|------|------|------|
| `setActiveProfile` 메서드 없음 | `ActiveProfile` 클래스에 해당 메서드 없음 | `ProfileList.setActiveProfile(id)` 사용으로 변경 |
| `max_tokens not supported` (400 에러) | OpenAI 신규 모델(gpt-5.2)은 `max_tokens` 미지원 | Edge Function에서 `max_completion_tokens` 사용으로 변경 (v8) |
| **Admin 채팅 400 에러** | Admin 프로필에 `saju_analyses` 데이터 없음 | `ProfileForm.saveProfile()` 사용으로 변경 (일반 사용자와 동일 로직) |
| **채팅 400 에러 (일반/Admin 모두)** | Gemini 모델명 만료 (`gemini-2.5-flash-preview-05-20`) | 모델명 `gemini-3-flash-preview`로 변경 (ai-gemini v11) |
| **채팅 JSON 노출 버그** | `responseMimeType: "application/json"` 설정으로 Gemini가 JSON 형식 응답 | `responseMimeType` 제거하여 일반 텍스트 응답 (ai-gemini v14) |
| **채팅 짤림 버그** | `max_tokens = 1000` 너무 작음 | `max_tokens = 4096`으로 변경 (ai-gemini v15) |
| **gpt-4o-mini 사용 문제** | Edge Function 기본값이 `gpt-4o-mini`로 설정됨 | `gpt-5.2`로 모델 변경 (ai-openai v9) |

**수정 파일**: `onboarding_screen.dart:161-216`

**근본 원인 분석**:
- 일반 사용자: `ProfileForm.saveProfile()` → `_saveAnalysisToDb()` → saju_analyses 생성 ✅
- Admin (기존): `ActiveProfile.saveProfile()` → AI 트리거만 → saju_analyses 미생성 ❌

**해결**:
```dart
// Before (에러) - ActiveProfile 사용
final activeProfileNotifier = ref.read(activeProfileProvider.notifier);
await activeProfileNotifier.saveProfile(adminProfile);

// After (수정됨) - ProfileForm 사용 (일반 사용자와 동일)
final formNotifier = ref.read(profileFormProvider.notifier);
formNotifier.updateDisplayName(AdminConfig.displayName);
formNotifier.updateGender(Gender.female);
// ... 모든 필드 설정
await formNotifier.saveProfile();  // saju_analyses 자동 생성
```

**추가 작업**:
- 기존 Admin 프로필 삭제 (saju_analyses 없는 프로필)
- 앱에서 Admin 버튼 클릭 시 새로 생성됨

---

## 테스트 체크리스트

### Admin Quota 테스트 (2024-12-30 검증 완료)
- [x] Edge Function이 실제로 사용되고 있는지 확인 ✅
  - `gemini_edge_datasource.dart`: Supabase Edge Function 호출 확인
  - `openai_edge_datasource.dart`: Supabase Edge Function 호출 확인
- [x] Edge Function 버전 확인 ✅
  - ai-gemini: **v15** (Admin Quota + gemini-3-flash-preview + max_tokens 4096)
  - ai-openai: **v10** (Admin Quota + gpt-5.2-thinking 모델 + max_completion_tokens 10000)
- [x] Admin 사용자 daily_quota 확인 ✅
  - **user_id**: `63dc54f7-a14f-4675-9797-20a79060892e`
  - **relation_type**: `admin`
  - **daily_quota**: `1,000,000,000` (10억)
- [ ] 채팅 테스트 후 토큰 사용량 증가 확인

### 검증 결과 상세
```sql
-- Admin 사용자 확인 쿼리
SELECT u.*, s.relation_type
FROM user_daily_token_usage u
JOIN saju_profiles s ON u.user_id = s.user_id AND s.is_primary = true
WHERE u.usage_date = '2024-12-30'
ORDER BY u.created_at DESC;

-- 결과:
-- user_id: 63dc54f7-a14f-4675-9797-20a79060892e
-- daily_quota: 1000000000 ← Admin 무제한 ✅
-- relation_type: admin
```

**참고**: Supabase 대시보드에서 보이는 `daily_quota = 50000`은 **일반 사용자**의 값입니다. Admin 사용자는 `1,000,000,000`으로 정상 적용되어 있습니다.

---

## 주요 파일 경로

### Edge Functions
```
supabase/functions/ai-gemini/index.ts
supabase/functions/ai-openai/index.ts
```

### Flutter Datasources
```
frontend/lib/features/saju_chat/data/datasources/gemini_edge_datasource.dart
frontend/lib/features/saju_chat/data/datasources/openai_edge_datasource.dart
```

### Profile & Onboarding
```
frontend/lib/features/onboarding/presentation/screens/onboarding_screen.dart
frontend/lib/features/profile/presentation/providers/profile_provider.dart
frontend/lib/features/splash/data/queries.dart
```

---

## Phase 21: Edge Function 모델 최종 확정 (2024-12-31)

### 완료된 작업

| Edge Function | 버전 | 모델 | max_tokens | 상태 |
|---------------|------|------|------------|------|
| ai-gemini | **v15** | `gemini-3-flash-preview` | 4096 | ✅ 배포 완료 |
| ai-openai | **v10** | `gpt-5.2-thinking` | 10000 | ✅ 배포 완료 |

### 생성된 문서

- **EdgeFunction_task.md**: Edge Function 관리 문서 생성
  - 현재 배포된 모델/설정 명시
  - 모델 변경 금지 규칙
  - 배포 명령어 및 백업 절차

### 코드 변경

1. **ai-gemini/index.ts**: `// 변경 금지` 주석 추가
2. **ai-openai/index.ts**: `// 변경 금지` 주석 추가
3. **gemini_edge_datasource.dart**: 모델 고정
4. **openai_edge_datasource.dart**: `gpt-5.2-thinking`, max_tokens 10000

---

## 다음 작업 예정

1. 채팅 테스트 후 토큰 사용량 확인
2. 필요시 추가 버그 수정

---

## 참고사항

### Edge Function 배포 명령어
```bash
supabase functions deploy ai-gemini
supabase functions deploy ai-openai
```

### 로그 확인
```bash
supabase functions logs ai-gemini
supabase functions logs ai-openai
```

### 백업 복원
백업 파일에서 복원하려면:
1. `supabase/backups/` 에서 해당 버전 파일 복사
2. `supabase/functions/{function_name}/index.ts`에 덮어쓰기
3. 재배포

---

## 연관 문서

| 문서 | 용도 |
|------|------|
| `Task_Jaehyeon.md` | Frontend 작업 목록 (Phase별 진행 상황) |
| `supabase_Jaehyeon_Task.md` | 이 문서 (Backend 작업 이력) |
| `EdgeFunction_task.md` | **Edge Function 관리 문서 (모델 변경 금지 규칙)** |
| `.claude/JH_Agent/11_progress_tracker.md` | 통합 Tracker 에이전트 정의 |
| `.claude/JH_Agent/07_task_tracker.md` | 기존 Task Tracker (Frontend only) |

### 통합 상태 확인 방법
```
Task 도구:
- prompt: "[11_progress_tracker] 현재 상태 확인"
- subagent_type: general-purpose
```
