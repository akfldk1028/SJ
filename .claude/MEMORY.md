# 만톡(Mantok) 프로젝트 메모리

## 프로젝트 개요
- **이름**: 만톡 (Mantok) - AI 사주 챗봇
- **목표**: 생년월일 입력 → 만세력 계산 → AI 대화형 사주 상담
- **차별점**: 기존 "긴 리포트" 방식 → 채팅 중심 UX

## 핵심 플로우
```
1. 프로필 생성 (생년월일, 시간, 성별)
   ↓
2. 만세력 계산 (사주팔자, 오행, 십신, 격국 등)
   ↓
3. saju_analyses 테이블 저장
   ↓
4. AI Edge Function 비동기 호출
   - ai-openai (GPT-5.2) - 심층 분석
   - ai-gemini (Gemini 3.0) - 대화형 응답
   ↓
5. ai_summaries 테이블 저장
   ↓
6. 채팅 화면에서 AI 상담 시작
```

## 기술 스택
| 구분 | 기술 |
|------|------|
| Frontend | Flutter 3.x, Dart |
| State | Riverpod 3.0 |
| UI | shadcn_ui |
| Backend | Supabase (PostgreSQL, Edge Functions, Auth) |
| AI | GPT-5.2 (분석), Gemini 3.0 (대화) |
| Local | Hive (캐시), flutter_secure_storage |

## Supabase 정보
- **Project Ref**: `kfciluyxkomskyxjaeat`
- **주요 테이블**:
  - `saju_profiles`: 사용자 프로필 (생년월일, 성별 등)
  - `saju_analyses`: 만세력 계산 결과
  - `ai_summaries`: AI 분석 결과
  - `chat_sessions`, `chat_messages`: 채팅 기록

## Edge Functions
- `ai-openai`: GPT-5.2 호출 (분석용)
- `ai-gemini`: Gemini 3.0 호출 (대화용)

## 현재 상태 (2025-12-27)

### 완료된 것
- [x] 프로필 생성/저장 플로우
- [x] 만세력 계산 로직
- [x] saju_analyses RLS 정책 수정 (authenticated 전체 허용)
- [x] Edge Function 배포 (ai-openai, ai-gemini)
- [x] ai_summaries 저장 플로우

### 확인 필요
- [ ] 새 프로필 생성 시 AI 분석 자동 발동 확인
- [ ] 채팅 화면에서 AI 응답 표시
- [ ] 오류 처리 및 재시도 로직

## 실행 방법
```powershell
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat run -d chrome --web-port=9999"
```

## 디버깅 팁
1. **RLS 에러**: Supabase Dashboard → SQL Editor에서 정책 확인
2. **AI 호출 실패**: Edge Function 로그 확인
3. **앱 상태 초기화**: 브라우저 IndexedDB 삭제 후 재시작

---
**최종 업데이트**: 2025-12-27
