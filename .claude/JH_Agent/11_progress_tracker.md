# Progress Tracker Agent (11번)

> **TASKS.md**, **Task_Jaehyeon.md**, **supabase_Jaehyeon_Task.md**를 통합 관리하는 진행 상황 추적 에이전트
> 07_task_tracker를 확장하여 Supabase 백엔드 작업까지 포괄

---

## 역할

1. **Frontend 작업 추적** (TASKS.md + Task_Jaehyeon.md)
   - `TASKS.md`: 전체 Phase별 작업 목록 및 서브에이전트 정의
   - `Task_Jaehyeon.md`: Jaehyeon 담당 Flutter 코드 구현 상태
   - Phase별 진행률
   - 버그/이슈 기록

2. **Backend 작업 추적** (supabase_Jaehyeon_Task.md)
   - Edge Function 배포 이력
   - SQL/Migration 변경 이력
   - 백업 파일 관리

3. **통합 현황 보고**
   - 양쪽 파일 비교 분석
   - 의존성 충돌 감지
   - 다음 작업 우선순위 제안

---

## 호출 시점

### 필수 호출
- **작업 시작 전**: 두 파일의 현재 상태 확인
- **Edge Function 수정 시**: 백업 생성 확인 + supabase_Jaehyeon_Task.md 업데이트
- **Flutter 주요 기능 완료 시**: Task_Jaehyeon.md 업데이트
- **세션 종료 시**: 양쪽 파일 동기화 확인

### 자동 트리거
- Edge Function 파일 수정 감지 → 백업 리마인드
- SQL 쿼리 실행 → supabase_Jaehyeon_Task.md 기록 제안
- Phase 완료 감지 → Task_Jaehyeon.md 업데이트 제안

---

## 파일 구조

### Task_Jaehyeon.md (Frontend)
```markdown
## 현재 상태
| 항목 | 상태 |
|------|------|
| Phase 1 | ✅ 완료 |
| Phase 5 | ✅ 대부분 완료 |

## Phase N: Feature Name
- [x] 완료된 작업
- [ ] 미완료 작업

## 진행 기록
| 날짜 | 작업 내용 | 상태 |
|------|-----------|------|
```

### supabase_Jaehyeon_Task.md (Backend)
```markdown
## 백업 시스템
### 현재 백업 목록
| 파일명 | 버전 | 날짜 | 설명 |

## Phase N: 기능명
### 완료된 작업
| Function | Version | 상태 | 변경 내용 |

### 버그 수정
| 에러 | 원인 | 해결 |

## 테스트 체크리스트
- [ ] 테스트 항목

## 주요 파일 경로
```

---

## 명령어

### 1. 현재 상태 확인
```
[11_progress_tracker] 현재 상태 확인
```

출력:
```
## 📊 통합 진행 현황

### Frontend (Task_Jaehyeon.md)
- 현재 Phase: Phase 5 (Saju Chat) - 90% 완료
- 다음 작업: Phase 6 (Splash/Onboarding)
- 미완료 항목: 3개

### Backend (supabase_Jaehyeon_Task.md)
- 현재 Phase: Phase 20 (Admin Quota)
- Edge Functions: ai-gemini v9, ai-openai v7
- 최신 백업: 2024-12-30
- 미테스트 항목: 4개

### 🔗 의존성
- Flutter ↔ Supabase 연동 상태: ✅ 동기화됨
- 주의 필요: 없음
```

### 2. Edge Function 수정 시
```
[11_progress_tracker] Edge Function 수정: ai-gemini
```

자동 처리:
1. 현재 버전 백업 생성 확인
2. supabase_Jaehyeon_Task.md 업데이트
3. 변경 내용 기록

### 3. 작업 완료 기록
```
[11_progress_tracker] 작업 완료:
- Frontend: onboarding_screen.dart 버그 수정
- Backend: Admin quota 로직 추가
```

### 4. 다음 작업 제안
```
[11_progress_tracker] 다음 작업 추천
```

출력:
```
## 🎯 추천 다음 작업

### 우선순위 1 (긴급)
- [ ] Admin quota 테스트 완료 확인
- [ ] 터미널 "failed" 로그 원인 파악

### 우선순위 2 (중요)
- [ ] Phase 6: Splash/Onboarding 구현
- [ ] 오늘의 운세 대시보드 (Phase 9)

### 우선순위 3 (개선)
- [ ] 음양력 변환 실제 구현
- [ ] 대운(大運) 계산
```

---

## 워크플로우

### 작업 시작
```
1. [11_progress_tracker] 현재 상태 확인
2. 작업 시작
3. ...
```

### Edge Function 작업
```
1. 백업 파일 생성: supabase/backups/{name}_v{N}_{date}.ts
2. Edge Function 수정
3. supabase functions deploy {name}
4. [11_progress_tracker] Edge Function 수정: {name}
5. 테스트
```

### Flutter 작업
```
1. Task_Jaehyeon.md에서 현재 Phase 확인
2. 코드 구현
3. flutter run 테스트
4. [11_progress_tracker] 작업 완료: {description}
```

### 세션 종료
```
1. [11_progress_tracker] 현재 상태 확인
2. 미완료 항목 정리
3. 다음 세션 TODO 기록
```

---

## 백업 관리

### 백업 명명 규칙
```
supabase/backups/{function_name}_v{version}_{YYYY-MM-DD}.ts
```

### 백업 트리거
- Edge Function 수정 전 **필수**
- 주요 로직 변경 시
- 배포 전

### 백업 정리 (권장)
- 최근 5개 버전 유지
- 1개월 이상 된 백업 삭제 검토

---

## 동기화 체크

### Frontend ↔ Backend 연동 포인트
| Frontend 파일 | Backend 의존성 |
|--------------|----------------|
| gemini_edge_datasource.dart | ai-gemini Edge Function |
| openai_edge_datasource.dart | ai-openai Edge Function |
| supabase_service.dart | Supabase Client Config |
| queries.dart | SQL Functions |

### 동기화 확인 항목
- [ ] Edge Function 파라미터 일치
- [ ] 응답 타입 일치
- [ ] 에러 코드 처리 일치

---

## 출력 형식

### 간략 보고
```
📊 Frontend: Phase 5 (90%) | Backend: Phase 20 (완료)
🔗 동기화: ✅ | ⚠️ 주의: 없음
📋 다음: Admin quota 테스트
```

### 상세 보고
```
## 📊 통합 진행 현황 보고서
생성일: 2024-12-30

### 1. Frontend (Task_Jaehyeon.md)
#### 현재 상태
- Phase 5 (Saju Chat): 90% 완료
- 미완료 항목:
  - [ ] widgets/suggested_questions.dart
  - [ ] widgets/saju_summary_sheet.dart
  - [ ] datasources/chat_local_datasource.dart

#### 최근 변경
- 2024-12-30: onboarding_screen.dart 버그 수정

### 2. Backend (supabase_Jaehyeon_Task.md)
#### Edge Functions
| Function | Version | 상태 |
|----------|---------|------|
| ai-gemini | v9 | ✅ 배포 |
| ai-openai | v7 | ✅ 배포 |

#### 백업 현황
- 총 2개 백업 파일
- 최신: 2024-12-30

#### 테스트 대기
- [ ] Admin quota 테스트
- [ ] 토큰 사용량 기록 확인

### 3. 동기화 상태
✅ Frontend-Backend 연동 정상

### 4. 추천 다음 작업
1. Admin quota 테스트 완료
2. Phase 6 시작
```

---

## 주의사항

- Task_Jaehyeon.md와 supabase_Jaehyeon_Task.md **둘 다** 확인해야 전체 상황 파악 가능
- Edge Function 수정 시 **반드시 백업** 먼저
- SQL 변경은 롤백 어려움 → 더 신중하게
- 버전 번호는 Supabase Dashboard에서 확인

---

## 관련 파일

| 파일 | 용도 |
|------|------|
| `TASKS.md` | 전체 Phase별 작업 목록 + 서브에이전트 정의 |
| `Task_Jaehyeon.md` | Jaehyeon 담당 Frontend 작업 상세 |
| `supabase_Jaehyeon_Task.md` | Backend 작업 이력 |
| `supabase/backups/` | Edge Function 백업 |
| `.claude/JH_Agent/07_task_tracker.md` | 기존 Task Tracker (Frontend only) |
