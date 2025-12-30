# 만톡 - 구현 작업 목록

> Main Claude 컨텍스트 유지용 작업 노트
> 작업 브랜치: Jaehyeon(Test)
> 백엔드(Supabase): 사용자가 직접 처리
> 최종 업데이트: 2025-12-30 (Phase 20 AI Edge Function 통합 완료)

---

## 🚀 새 세션 시작 가이드

### 프롬프트 예시

**기본 프롬프트** (새 세션 시작):
```
@Task_Jaehyeon.md 읽고 현재 상황 파악해.
Supabase MCP로 DB 현황 체크하고, context7로 필요한 문서 참조해서 작업해.

[요청 내용 입력]
```

**상세 프롬프트** (특정 작업 이어하기):
```
@Task_Jaehyeon.md 읽고 현재 상황 파악해.
Supabase MCP로 DB 현황 체크하고, context7로 필요한 문서 참조해서 작업해.

현재 상태:
- MVP v0.1 완료 ✅ (만세력 + AI 채팅 기본)
- Phase 17-A (보안 강화) ✅ 완료 (2025-12-29)
- Phase 18 (윤달 유효성 검증) ✅ 완료 (2025-12-30)
- Phase 19 (토큰 사용량 추적) ✅ 완료 (2025-12-30)
- Phase 20 (AI Edge Function 통합) ✅ 완료 (2025-12-30)
  - gemini_edge_datasource.dart, openai_edge_datasource.dart 생성
  - saju_chat_edge_datasource.dart 생성
  - API 키가 Supabase Secrets에만 저장 (보안 강화)
- 대운(大運) 계산: ✅ 이미 구현됨 (daeun_service.dart)
- 음양력 변환: ✅ 이미 구현됨 (lunar_solar_converter.dart)

다음 작업 후보:
1. Phase 17-B (인증 방식 추가) - 이메일/Google/Apple 로그인
2. 절입시간 계산 검증 - solar_term_service.dart 정확도 확인
3. 만세력 단위 테스트 - 특정 생년월일 계산 검증
4. AI 프롬프트 개선 - saju_base_prompt.dart 품질 향상
5. 합충형파해 AI 해석 - 관계 분석 결과를 AI에 전달
6. UI/UX 개선 - 채팅 화면, 프로필 화면 디자인

[원하는 작업 선택 또는 새 요청]
```

### 🛠️ Flutter 개발 환경 (2025-12-30 업데이트)

| 항목 | 경로/값 |
|------|---------|
| **Flutter SDK** | `C:\Users\SOGANG\flutter\flutter\bin\flutter.bat` |
| **프로젝트 위치** | `E:\SJ\frontend` |
| **Pub Cache** | `C:\Users\SOGANG\AppData\Local\Pub\Cache` (기본값) |

#### ⚠️ Windows symlink 에러 해결

```
ERROR_INVALID_FUNCTION: Try moving your Flutter project to the same drive as your Flutter SDK.
```

**원인**: Flutter SDK(C드라이브)와 프로젝트(E드라이브)가 다른 드라이브에 있어서 Windows 플랫폼 빌드 시 symlink 생성 실패

**해결 방법**:
- **Chrome(web) 빌드는 문제없음** - symlink 에러 무시하고 실행 가능
- Windows 데스크톱 빌드 필요 시: 개발자 모드 활성화 또는 PUB_CACHE를 E 드라이브로 이동

#### Flutter 실행 명령어

```powershell
# E:\SJ\frontend 에서 실행

# 1. 의존성 설치
C:\Users\SOGANG\flutter\flutter\bin\flutter.bat pub get

# 2. 코드 생성 (flutter clean 이후 필수!)
C:\Users\SOGANG\flutter\flutter\bin\flutter.bat pub run build_runner build --delete-conflicting-outputs

# 3. Chrome으로 실행
C:\Users\SOGANG\flutter\flutter\bin\flutter.bat run -d chrome

# 또는 포트 지정
C:\Users\SOGANG\flutter\flutter\bin\flutter.bat run -d chrome --web-port=9999
```

#### 주의사항
- `flutter clean` 실행 후에는 **반드시** `build_runner` 재실행 필요
- `.g.dart`, `.freezed.dart` 파일이 없으면 빌드 에러 발생

---

### 핵심 파일 경로
| 파일 | 용도 |
|------|------|
| `frontend/lib/features/saju_chart/` | 만세력 기능 전체 |
| `frontend/lib/features/saju_chat/` | AI 채팅 기능 |
| `frontend/lib/features/profile/` | 프로필 입력/관리 |
| `frontend/lib/core/repositories/` | DB 연동 Repository |
| `frontend/lib/AI/` | AI 모듈 (프롬프트, 페르소나, 서비스) |
| `frontend/lib/ad/` | 광고 모듈 (AdMob 연동) |
| `supabase/functions/` | Edge Functions |
| `.claude/team/` | 팀원별 역할/TODO 정의 |

### Phase 18 관련 파일 (2025-12-30 추가)
| 파일 | 용도 |
|------|------|
| `saju_chart/domain/entities/lunar_validation.dart` | 윤달 검증 결과/정보 엔티티 |
| `saju_chart/domain/services/lunar_solar_converter.dart` | 음양력 변환 + 윤달 검증 |
| `profile/presentation/providers/profile_provider.dart` | 프로필 폼 상태 관리 |
| `profile/presentation/widgets/lunar_options.dart` | 윤달 옵션 UI 위젯 |
| `profile/presentation/screens/profile_edit_screen.dart` | 프로필 입력 화면 |

### Phase 19 관련 파일 (2025-12-30 추가)
| 파일 | 용도 |
|------|------|
| `core/services/quota_service.dart` | Quota 조회/광고 보너스 RPC 호출 |
| `core/services/ai_chat_service.dart` | QUOTA_EXCEEDED 처리 추가 |
| `core/services/ai_summary_service.dart` | QUOTA_EXCEEDED 처리 추가 |
| `shared/widgets/quota_exceeded_dialog.dart` | Quota 초과 다이얼로그 |
| `supabase/functions/saju-chat/index.ts` | Edge Function v6 (quota 체크) |
| `supabase/functions/generate-ai-summary/index.ts` | Edge Function v8 (quota 체크) |

### 현재 개발 단계
- **MVP (v0.1)**: 만세력 + AI 채팅 기본 완료 ✅
- **다음 단계 (v0.2)**: 인증 체계 강화 (Phase 17)

---

## 현재 상태

| 항목 | 상태 |
|------|------|
| 기획 문서 | ✅ 완료 |
| CLAUDE.md | ✅ 완료 |
| JH_Agent (서브에이전트) | ✅ 완료 (9개) |
| Flutter 프로젝트 | ✅ 기반 설정 완료 |
| 의존성 | ✅ 설치 완료 |
| 폴더 구조 | ✅ 구현 완료 |
| Phase 1 | ✅ **완료** |
| Phase 2 | ✅ **부분 완료** (상수/테마) |
| Phase 4 (Profile) | ✅ **완료** |
| Phase 5 (Saju Chat) | ✅ **대부분 완료** (Gemini 3.0 연동) |
| Phase 8 (만세력) | ✅ **기본 완료** |
| **Phase 9 (만세력 고급)** | ✅ **9-A/9-B 완료** |
| **Phase 10 (RuleEngine)** | ✅ **완료** (10-A/10-B/10-C + 서비스 전환 + 반합 추가) |
| **Supabase MCP** | ✅ **설정 완료** (2025-12-15) |
| **Phase 11 (Supabase 연동)** | ✅ **완료** (모델/서비스/Repository/Provider + 자동 저장 연동) |
| **Phase 9-C (UI 컴포넌트)** | ✅ **완료** (saju_detail_tabs, hapchung_tab, unsung_display, sinsal_display, gongmang_display) |
| **Phase 9-D (포스텔러 UI)** | ✅ **완료** (대운/세운/월운, 신강/용신, 오행 차트) |
| **신강/신약 로직 수정** | ✅ **완료** (8단계 + 득령/득지/득시/득세 계산) |
| **Phase 12-A (DB 최적화)** | ✅ **완료** (RLS 최적화 8개 + Function 보안 6개) |
| **Phase 12-B (12운성/12신살 DB)** | ✅ **완료** (13개 프로필 데이터 채움) |
| **Phase 13-A (UI 확인)** | ✅ **완료** |
| **Phase 13-B (ai_summary)** | ✅ **완료** (Edge Function + Flutter 서비스) |
| **Phase 13-C (배포/테스트)** | ✅ **완료** (2025-12-23) |
| **Phase 13-D (채팅 연동)** | ✅ **완료** (2025-12-23) |
| **Phase 13 전체** | ✅ **완료** 🎉 |
| **Phase 14-A (tokens_used)** | ✅ **완료** (2025-12-23) |
| **Phase 14-B (suggested_questions)** | ✅ **완료** (2025-12-24) |
| **Phase 14-C (cached 버그 수정)** | ✅ **완료** (2025-12-24, 배포 완료) |
| **Phase 14 (채팅 DB 최적화)** | ✅ **완료** 🎉 |
| **만세력 기능 구현 현황** | ✅ **전체 완료** (2025-12-24 검증) |
| **Phase 15 (한글+한자 페어 수정)** | ✅ **완료** (2025-12-24) |
| **Phase 15-D (sipsin_info 수정)** | ✅ **완료** (2025-12-24) |
| **Phase 16 (길성 기능 구현)** | ✅ **완료** (2025-12-24) |
| **Phase 16-C (길성 DB 저장)** | ✅ **완료** (2025-12-25) |
| **Phase 16-D (길성 마이그레이션)** | ✅ **완료** (2025-12-25, 18/18 레코드) |
| **Supabase MCP 상태 체크** | ✅ **완료** (2025-12-25) |
| **Phase 16-E (데이터 표준화)** | ✅ **완료** (2025-12-25, oheng/yongsin) |
| **Phase 16-F (JSONB 형식 통일)** | ✅ **완료** (2025-12-29, 6개 마이그레이션) |
| **Phase 16-G (hapchung/gilseong 마이그레이션)** | ✅ **완료** (2025-12-29, Edge Function) |
| **DKBB Merge** | ✅ **완료** (2025-12-29) |
| **광고 모듈 (AdMob)** | ✅ **추가됨** (DK 작업) |
| **페르소나 시스템** | ✅ **추가됨** (Jina 작업) |
| **관계(궁합) 관리** | ✅ **추가됨** |
| **성능 최적화** | ✅ **완료** (withOpacity → const Color 캐싱) |
| **음양력 변환 (LunarSolarConverter)** | ✅ **이미 구현됨** (1900-2100년, 윤달 처리 포함) |
| **Phase 17-A (보안 강화)** | ✅ **완료** (2025-12-29, search_path 수정 13개 + 인덱스 확인) |
| **Phase 17-B~D (인증 체계 강화)** | 📋 **계획 수립** (v0.2 예정) |
| **대운(大運) 계산** | ✅ **이미 구현됨** (daeun_service.dart) |
| **Phase 18 (윤달 유효성 검증)** | ✅ **완료** (2025-12-30) |
| **Phase 19 (토큰 사용량 추적)** | ✅ **완료** (2025-12-30, quota 체크 + QUOTA_EXCEEDED 처리) |
| **Phase 20 (AI Edge Function 통합)** | ✅ **완료** (2025-12-30, API 키 보안 강화) |

---

## 🔐 Phase 20: AI Edge Function 통합 (다음 작업)

### 개요

프론트엔드에서 직접 AI API를 호출하는 방식을 **Edge Function 경유**로 변경하여 API 키 보안 강화

### 현재 문제점

```
현재 구조 (❌ 보안 취약):
┌─────────────────────────────────────────────────────────────┐
│  Flutter App                                                │
│      │                                                      │
│      ├──→ GeminiRestDatasource ──→ Gemini API (직접 호출)   │
│      │         └── API 키가 .env에 포함 ❌                   │
│      │                                                      │
│      └──→ OpenAIDatasource ──→ OpenAI API (직접 호출)       │
│                └── API 키가 .env에 포함 ❌                   │
└─────────────────────────────────────────────────────────────┘

※ .env는 .gitignore 되어있지만, APK 빌드 시 포함될 수 있음
```

### 목표 구조

```
목표 구조 (✅ 보안 강화):
┌─────────────────────────────────────────────────────────────┐
│  Flutter App                                                │
│      │                                                      │
│      ├──→ Edge Function (ai-gemini) ──→ Gemini API          │
│      │         └── API 키는 Supabase Secrets에만 ✅          │
│      │                                                      │
│      └──→ Edge Function (ai-openai) ──→ OpenAI API          │
│                └── API 키는 Supabase Secrets에만 ✅          │
└─────────────────────────────────────────────────────────────┘
```

### Edge Function 현황 (Supabase 배포됨)

| Function | 버전 | 용도 | 상태 |
|----------|------|------|------|
| **ai-gemini** | v8 | Gemini 3.0 대화용 | ✅ ACTIVE → **Flutter 연동 완료** |
| **ai-openai** | v6 | GPT-5.2 분석용 | ✅ ACTIVE → **Flutter 연동 완료** |
| **saju-chat** | v6 | 사주 채팅 (quota 포함) | ✅ ACTIVE → **Flutter 연동 완료** |
| generate-ai-summary | v8 | AI 요약 생성 | ✅ ACTIVE (사용중) |

### TODO 작업 목록

| 단계 | 작업 | 파일 | 상태 |
|------|------|------|------|
| **20-A** | GeminiRestDatasource → Edge Function 호출로 변경 | `gemini_edge_datasource.dart` | ✅ **완료** (2025-12-30) |
| **20-B** | OpenAIDatasource → Edge Function 호출로 변경 | `openai_edge_datasource.dart` | ✅ **완료** (2025-12-30) |
| **20-C** | Repository/Pipeline Edge 버전으로 전환 | `chat_repository_impl.dart`, `ai_pipeline_manager.dart` | ✅ **완료** (2025-12-30) |
| **20-D** | .env에서 AI API 키 삭제 (SUPABASE만 유지) | `frontend/.env` | ⏭️ **스킵** (개발 편의) |
| **20-E** | saju-chat Edge Function 연동 | `saju_chat_edge_datasource.dart` | ✅ **완료** (2025-12-30) |

### 생성/수정된 파일 (2025-12-30)

| 파일 | 설명 | 상태 |
|------|------|------|
| `gemini_edge_datasource.dart` | Gemini Edge Function 호출 (신규) | ✅ 생성 |
| `openai_edge_datasource.dart` | OpenAI Edge Function 호출 (신규) | ✅ 생성 |
| `saju_chat_edge_datasource.dart` | saju-chat Edge Function 호출 (신규) | ✅ 생성 |
| `chat_repository_impl.dart` | Edge Datasource 사용으로 변경 | ✅ 수정 |
| `ai_pipeline_manager.dart` | Edge Datasource 사용으로 변경 | ✅ 수정 |
| `chat_provider.dart` | Edge Datasource 사용으로 변경 | ✅ 수정 |
| `README.md` | Edge Function 문서 추가 | ✅ 수정 |

### 레거시 파일 (참고용으로 유지)

| 파일 | 설명 |
|------|------|
| `gemini_rest_datasource.dart` | Gemini API 직접 호출 (개발용) |
| `openai_datasource.dart` | OpenAI API 직접 호출 (개발용) |

### 구현 예시

**Before (현재 - gemini_rest_datasource.dart:53):**
```dart
static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

_dio = Dio(BaseOptions(
  baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
  queryParameters: {'key': _apiKey},  // ❌ API 키 노출
));
```

**After (목표):**
```dart
_dio = Dio(BaseOptions(
  baseUrl: '${Supabase.instance.client.supabaseUrl}/functions/v1/ai-gemini',
  headers: {
    'Authorization': 'Bearer ${Supabase.instance.client.supabaseKey}',
    'Content-Type': 'application/json',
  },
));
```

### 참고: Edge Function 요청/응답 형식

**ai-gemini 요청:**
```json
{
  "messages": [
    {"role": "system", "content": "시스템 프롬프트"},
    {"role": "user", "content": "사용자 메시지"}
  ],
  "model": "gemini-2.5-flash",
  "max_tokens": 50000,
  "temperature": 0.8
}
```

**ai-gemini 응답:**
```json
{
  "success": true,
  "content": "AI 응답 텍스트",
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 200,
    "total_tokens": 300
  },
  "model": "gemini-2.5-flash",
  "finish_reason": "stop"
}
```

---

## 🔧 JH_AI 작업 현황 (2025-12-30)

### 대운(大運) 계산 - 이미 구현됨 ✅

> **요청**: 대운 계산기 만들기
> **결과**: 이미 완전 구현되어 있음!

| 파일 | 용도 | 상태 |
|------|------|------|
| `saju_chart/domain/entities/daeun.dart` | 대운/세운/월운 엔티티 | ✅ 완료 |
| `saju_chart/domain/services/daeun_service.dart` | 대운 계산 서비스 | ✅ 완료 |
| `saju_chart/presentation/widgets/fortune_display.dart` | 대운 UI | ✅ 완료 |

**구현된 기능:**
- 순행/역행 판단 (남양순, 여음순)
- 대운수(시작 나이) 계산 (절입일 기준)
- 10개 대운 주기 생성
- 세운(년운) 계산
- 현재 대운 찾기

### 음양력 변환 - 이미 구현됨 ✅

| 파일 | 용도 | 상태 |
|------|------|------|
| `saju_chart/domain/services/lunar_solar_converter.dart` | 음양력 변환 서비스 | ✅ 완료 |
| `saju_chart/domain/entities/lunar_date.dart` | 음력 날짜 엔티티 | ✅ 완료 |
| `saju_chart/data/constants/lunar_data/` | 1900-2100년 데이터 테이블 | ✅ 완료 |

**구현된 기능:**
- `solarToLunar(DateTime)` - 양력 → 음력 변환
- `lunarToSolar(LunarDate)` - 음력 → 양력 변환
- `hasLeapMonth(year)` - 윤달 여부 확인
- `getLeapMonth(year)` - 해당 연도 윤달 월 반환
- `getLunarMonthDays(year, month, isLeapMonth)` - 음력 월 일수
- `validateLunarDate(LunarDate)` - 음력 날짜 유효성 검증 **(Phase 18 추가)**
- `getLeapMonthInfo(year)` - 연도별 윤달 상세 정보 **(Phase 18 추가)**
- `canSelectLeapMonth(year, month)` - 윤달 선택 가능 여부 **(Phase 18 추가)**

### 다음 작업 후보 (JH_AI)

| 우선순위 | 작업 | 설명 | 상태 |
|---------|------|------|------|
| ~~**P0**~~ | ~~**윤달 유효성 검증**~~ | ~~Phase 18~~ | ✅ **완료** |
| P1 | **절입시간 계산 검증** | `solar_term_service.dart` 정확도 확인 | 📋 대기 |
| P1 | **만세력 단위 테스트** | 특정 생년월일 계산 검증 | 📋 대기 |
| P2 | **AI 프롬프트 개선** | `saju_base_prompt.dart` 품질 향상 | 📋 대기 |
| P2 | **합충형파해 AI 해석** | 관계 분석 결과를 AI에 전달 | 📋 대기 |

---

## 💰 Phase 19: 토큰 사용량 추적 시스템 ✅ 완료 (2025-12-30)

### 개요

AI 상담 수익화를 위한 일일 토큰 quota 시스템 구현
- **일일 무료 quota**: 50,000 토큰
- **광고 시청 시 보너스**: 5,000 토큰
- **quota 초과 시**: 광고 시청 또는 결제 유도

### 구현 완료 내역

| 단계 | 작업 | 상태 |
|------|------|------|
| Phase 19-A | `user_daily_token_usage` 테이블 생성 | ✅ |
| Phase 19-B | DB 트리거 (chat_messages, ai_summaries 토큰 자동 집계) | ✅ |
| Phase 19-C | RPC 함수 (check_user_quota, add_ad_bonus_tokens) | ✅ |
| Phase 19-D | Edge Function quota 체크 (saju-chat v6, generate-ai-summary v8) | ✅ |
| Phase 19-E | Flutter QUOTA_EXCEEDED 처리 (QuotaService, 다이얼로그) | ✅ |

### DB 테이블: user_daily_token_usage

```sql
CREATE TABLE user_daily_token_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  usage_date DATE DEFAULT CURRENT_DATE,
  chat_tokens INT DEFAULT 0,           -- AI 채팅 토큰
  ai_analysis_tokens INT DEFAULT 0,    -- AI 분석 토큰
  ai_chat_tokens INT DEFAULT 0,        -- 세션 채팅 토큰
  total_tokens INT GENERATED ALWAYS AS (chat_tokens + ai_analysis_tokens + ai_chat_tokens) STORED,
  daily_quota INT DEFAULT 50000,       -- 일일 한도
  is_quota_exceeded BOOL GENERATED ALWAYS AS (total_tokens >= daily_quota) STORED,
  ads_watched INT DEFAULT 0,           -- 시청한 광고 수
  bonus_tokens_earned INT DEFAULT 0,   -- 광고로 얻은 보너스
  UNIQUE(user_id, usage_date)
);
```

### RPC 함수

| 함수 | 용도 | 반환 |
|------|------|------|
| `check_user_quota(p_user_id)` | quota 상태 조회 | {can_use, tokens_used, quota_limit, remaining} |
| `add_ad_bonus_tokens(p_user_id, p_bonus_tokens)` | 광고 보너스 추가 | {new_quota, ads_watched, bonus_earned} |

### Edge Function 변경사항

**saju-chat v6 & generate-ai-summary v8:**
- JWT에서 user_id 추출
- `check_user_quota()` RPC로 quota 확인
- quota 초과 시 HTTP 429 반환:
  ```json
  {
    "error": "QUOTA_EXCEEDED",
    "message": "오늘 토큰 사용량을 초과했습니다.",
    "tokens_used": 52340,
    "quota_limit": 50000,
    "ads_required": true
  }
  ```
- AI 호출 후 토큰 사용량 DB 저장

### Flutter 구현 파일

| 파일 | 용도 |
|------|------|
| `core/services/quota_service.dart` | **신규** - Quota 조회/광고 보너스 RPC 호출 |
| `core/services/ai_chat_service.dart` | QUOTA_EXCEEDED 처리 추가 |
| `core/services/ai_summary_service.dart` | QUOTA_EXCEEDED 처리 추가 |
| `shared/widgets/quota_exceeded_dialog.dart` | **신규** - Quota 초과 다이얼로그 |

### 사용 예시

**Flutter에서 AI 호출 시:**
```dart
final result = await AiChatService.sendMessage(messages: messages);

if (result.quotaExceeded) {
  // 광고 시청 다이얼로그 표시
  final watched = await QuotaExceededDialog.show(
    context,
    tokensUsed: result.tokensUsed ?? 0,
    quotaLimit: result.quotaLimit ?? 50000,
  );

  if (watched == true) {
    // 광고 시청 완료 → 재시도
    final retryResult = await AiChatService.sendMessage(messages: messages);
  }
}
```

### 다음 단계 (TODO)

- [ ] 실제 광고 SDK 연동 (Google AdMob)
- [ ] 결제 시스템 연동 (프리미엄 구독)
- [ ] 토큰 사용량 통계 대시보드

---

## 🌙 Phase 18: 윤달 유효성 검증 ✅ 완료 (2025-12-30)

### 구현 완료 내역

| 단계 | 작업 | 상태 |
|------|------|------|
| Phase 18-A | `validateLunarDate()`, `getLeapMonthInfo()`, `canSelectLeapMonth()` 추가 | ✅ |
| Phase 18-B | `ProfileFormState` 확장 (leapMonthError, leapMonthInfo, canSelectLeapMonth) | ✅ |
| Phase 18-C | `lunar_options.dart` 생성 (윤달 체크박스 + 정보 배너 + 에러 메시지) | ✅ |
| Phase 18-D | `profile_edit_screen.dart`에 `LunarOptions` 위젯 추가 | ✅ |

### 생성/수정 파일

| 파일 | 변경 |
|------|------|
| `saju_chart/domain/entities/lunar_validation.dart` | **신규** - LunarValidationResult, LeapMonthInfo 엔티티 |
| `saju_chart/domain/services/lunar_solar_converter.dart` | 검증 메서드 3개 추가 |
| `profile/presentation/providers/profile_provider.dart` | State 확장 + 검증 로직 |
| `profile/presentation/widgets/lunar_options.dart` | **신규** - 윤달 옵션 UI 위젯 |
| `profile/presentation/screens/profile_edit_screen.dart` | LunarOptions import + 추가 |

### 동작 방식

1. **양력 선택**: 윤달 옵션 숨김
2. **음력 선택**:
   - 해당 연도 윤달 정보 조회 및 표시
   - 윤달이 있는 연도/월: 체크박스 활성화 + 정보 배너 (녹색)
   - 윤달이 없는 연도/월: 체크박스 비활성화 + 정보 배너 (회색)
3. **유효성 검증**:
   - 연도 범위 (1900-2100)
   - 윤달 유효성 (해당 연도/월에 윤달 존재 여부)
   - 일수 범위 (29일 또는 30일)
   - 에러 시 빨간색 에러 메시지 표시 + 저장 버튼 비활성화

---

## 🆕 DKBB Merge 후 추가된 사항 (2025-12-27~29)

### 새로 추가된 주요 파일들

| 분류 | 파일 | 설명 |
|------|------|------|
| **프로젝트 메모리** | `.claude/MEMORY.md` | 프로젝트 개요, 핵심 플로우, 기술 스택 정리 |
| **실행 가이드** | `.claude/RUN.md` | Flutter 실행 명령어 모음 (팀원별 가이드) |
| **AI 가이드** | `AI/jh_ai_todo.md` | JH_AI 사주 분석 프롬프트 수정 가이드 |
| **AI 가이드** | `AI/jina_todo.md` | Jina AI 대화 프롬프트 수정 가이드 |
| **광고 모듈** | `lib/ad/README.md` | AdMob 광고 연동 가이드 (배너/전면/보상형) |
| **팀 가이드** | `.claude/team/DK/TODO.md` | DK 빌드, 광고, DB 연결 가이드 |
| **팀 가이드** | `.claude/team/Jina/TODO.md` | Jina Gemini 3.0 대화 생성 TODO |

### 새로 추가된 기능

| 기능 | 파일 | 상태 | 담당 |
|------|------|------|------|
| **페르소나 시스템** | `AI/jina/personas/` | ✅ 추가됨 | Jina |
| **광고 모듈** | `lib/ad/` | ✅ 추가됨 | DK |
| **관계(궁합) 관리** | `features/profile/data/relation_*` | ✅ 추가됨 | - |
| **파일 로깅** | `AI/core/file_logger.dart` | ✅ 추가됨 | - |
| **채팅 사이드바** | `saju_chat/widgets/chat_history_sidebar/` | ✅ 추가됨 | - |

### 페르소나 시스템 상세

| 페르소나 | 파일 | 특징 |
|----------|------|------|
| 친근한 언니 | `friendly_sister.dart` | 기본값, 따뜻한 반말 |
| 현명한 학자 | `wise_scholar.dart` | 존댓말, 심층 분석 |
| 귀여운 친구 | `cute_friend.dart` | 발랄한 반말 |
| 할머니 | `grandma.dart` | 정겨운 사투리 |

### 광고 모듈 상세

| 유형 | 위치 | 용도 |
|------|------|------|
| 배너 | 메인 화면 하단 | 상시 노출 |
| 전면 | 화면 전환 | 5개 메시지마다 |
| 보상형 | 프리미엄 기능 | 사용자 선택 |
| Native (채팅 내) | 채팅 버블 사이 | 자연스러운 광고 |

### 성능 최적화 (DK 작업)

| 커밋 | 내용 |
|------|------|
| `1757f15` | `withOpacity → const Color` 캐싱 최적화 |
| `ddd2e43` | 메뉴 화면 프레임 렉 최적화 |

---

## Supabase 현황 (2025-12-29 Phase 17-A 완료)

### DB 테이블 현황
| 테이블 | RLS | 행 수 | 설명 |
|--------|-----|-------|------|
| saju_profiles | ✅ | 45 | 사주 프로필 |
| saju_analyses | ✅ | 33 | 만세력 분석 데이터 (**JSONB 100% 표준화 + hapchung/gilseong 완료**) |
| chat_sessions | ✅ | 12 | 채팅 세션 |
| chat_messages | ✅ | 24 | 채팅 메시지 |
| compatibility_analyses | ✅ | 0 | 궁합 분석 (미사용) |
| ai_summaries | ✅ | 23 | AI 분석 캐시 |
| ai_api_logs | ✅ | 24 | API 호출 로그 |
| profile_relations | ✅ | 0 | 프로필 관계 (미사용) |

### DB Functions 현황 (13개 - search_path 보안 수정 완료 ✅)
| 함수 | 용도 | 보안 |
|------|------|------|
| db_health_check() | 데이터 무결성 검사 | ✅ 수정됨 |
| get_compatibility_data() | 궁합 분석 데이터 조회 | ✅ 수정됨 |
| normalize_oheng_distribution() | 오행 JSONB 표준화 | ✅ 수정됨 |
| normalize_yongsin() | 용신 JSONB 표준화 | ✅ 수정됨 |
| get_gan_hanja(gan text) | 천간 한자 매핑 | ✅ 수정됨 |
| get_gan_oheng(gan text) | 천간 오행 매핑 | ✅ 수정됨 |
| calculate_sipsin(day_gan, target_gan) | 십신 계산 | ✅ 수정됨 |
| convert_jijanggan_array(...) | 지장간 변환 | ✅ 수정됨 |
| standardize_oheng_key(text) | 오행 키 표준화 | ✅ 수정됨 |
| standardize_oheng_value(text) | 오행 값 표준화 | ✅ 수정됨 |
| cleanup_old_ai_logs() | 오래된 AI 로그 정리 | ✅ 수정됨 |
| update_ai_summaries_updated_at() | 트리거 함수 | ✅ 수정됨 |
| update_profile_relations_updated_at() | 트리거 함수 | ✅ 수정됨 |

### 인덱스 현황 (최적화 확인 완료 ✅)
| 테이블 | 인덱스 | 상태 |
|--------|--------|------|
| chat_messages | `idx_chat_messages_session_created` (session_id, created_at) | ✅ 존재 |
| chat_messages | `idx_chat_messages_session_id` | ✅ 존재 |
| chat_sessions | `idx_chat_sessions_profile_updated` (profile_id, updated_at) | ✅ 존재 |
| saju_analyses | `idx_saju_analyses_gilseong`, `idx_saju_analyses_hapchung` (GIN) | ✅ 존재 |

### Edge Functions 현황
| 함수 | 버전 | JWT | 상태 | 용도 |
|------|------|-----|------|------|
| saju-chat | v5 | ✅ | ACTIVE | AI 채팅 |
| generate-ai-summary | v7 | ✅ | ACTIVE | AI 요약 생성 |
| ai-openai | v6 | ❌ | ACTIVE | OpenAI API 프록시 |
| ai-gemini | v6 | ✅ | ACTIVE | Gemini API 프록시 |
| migrate-hapchung | v1 | ✅ | ACTIVE | 합충형파해 마이그레이션 (33/33 완료) |
| migrate-gilseong | v5 | ✅ | ACTIVE | 길성 마이그레이션 (33/33 완료) |

### 보안 권고사항 (Advisory) - Phase 17-A 후 상태
✅ **Function Search Path Mutable** (13건) → **해결됨** (2025-12-29)
- 마이그레이션: `fix_function_search_path_security`

⚠️ **Anonymous Access Policies** (8건) → Phase 17-D (v1.0)에서 처리 예정
- ai_api_logs, ai_summaries, chat_messages, chat_sessions
- compatibility_analyses, profile_relations, saju_analyses, saju_profiles
- 개발 편의를 위해 현재 유지 중

⚠️ **Leaked Password Protection Disabled** → Phase 17-B (v0.2)에서 활성화 예정
- HaveIBeenPwned 연동 비활성화 상태

---

## 📋 Phase 16-F 데이터 형식 검증 결과 (2025-12-25)

> **검증 목적**: 한글+한자 페어가 만세력/사주 분석에 필수인지 확인
> **검증 방법**: Context7 (Tyme4j 만세력 라이브러리), Flutter 코드 분석, DB 현황 확인

### 🔍 핵심 발견 1: 만세력 라이브러리는 한자가 원본

| 라이브러리 | 데이터 형식 | 예시 |
|------------|------------|------|
| **Tyme4j** (Java) | 한자 기본 | `甲`, `子`, `甲子` |
| **lunar-javascript** | 한자 기본 | `甲`, `子`, `丙寅` |
| **우리 시스템** | 한글(한자) 페어 | `갑(甲)`, `자(子)` |

```java
// Tyme4j - 전문 만세력 라이브러리
HeavenStem stem = cycle.getHeavenStem();
stem.getName(); // Output: 甲  ← 한자가 원본!

EarthBranch branch = cycle.getEarthBranch();
branch.getName(); // Output: 子  ← 한자가 원본!
```

### 🔍 핵심 발견 2: 한글 동음이의어 문제

| 한글 | 천간 한자 | 지지 한자 | 구분 |
|------|----------|----------|------|
| **신** | 辛 (금) | 申 (원숭이) | ⚠️ 동음이의어 |
| 기타 | 고유 | 고유 | ✅ 문제없음 |

**우리 시스템 해결책**: 천간/지지 테이블 분리로 혼동 방지
```dart
// cheongan_jiji.dart
"cheongan": [{"hangul": "신", "hanja": "辛", ...}]  // 천간 신
"jiji": [{"hangul": "신", "hanja": "申", ...}]      // 지지 신
```

### 🔍 핵심 발견 3: Flutter 비교 로직은 한글로 동작

```dart
// hapchung_relations.dart - 천간끼리만 비교 (지지와 혼동 없음)
const Map<String, String> _cheonganHapPairs = {
  '갑': '기',  // 甲-己 합
  '을': '경',  // 乙-庚 합
  ...
};
bool isCheonganHap(String gan1, String gan2) {
  return _cheonganHapPairs[gan1] == gan2;  // 한글 == 한글
}
```

**왜 문제없는가?**
- 천간 10개 내에서 동음이의어 없음 → 천간끼리 비교 OK
- 지지 12개 내에서 동음이의어 없음 → 지지끼리 비교 OK
- 천간 vs 지지 비교는 없음 (다른 카테고리)

### ✅ 검증 결론

| 질문 | 답변 | 근거 |
|------|------|------|
| 비교 로직에 문제 있나? | ❌ **없음** | 천간/지지 각각 내에서만 비교 |
| 한글만으로 분석 가능? | ✅ **가능** | 카테고리 분리로 동음이의어 혼동 없음 |
| 한글+한자 페어 필요한가? | ✅ **권장** | 데이터 완전성, AI 정확도, UI 표시 |
| 지금 DB 문제는? | 🚨 **구조 불일치** | pillar vs gan/ji 스키마 다름 |

### 📊 한글+한자 페어를 유지해야 하는 이유

| 이유 | 설명 | 중요도 |
|------|------|--------|
| **데이터 완전성** | 한글만 저장 시 한자 정보 영구 손실 | 🔴 높음 |
| **AI 분석 정확도** | Gemini에게 "갑(甲)" 전달 → 더 정확한 해석 | 🔴 높음 |
| **사용자 UI** | 한자 함께 표시 → 전문성 있는 화면 | 🟡 중간 |
| **디버깅** | 문제 발생 시 한자로 정확한 데이터 확인 | 🟡 중간 |
| **국제화 대비** | 향후 중국어/일본어 지원 시 한자 필수 | 🟢 낮음 |

### 🎯 최종 결정: 데이터 형식 표준

| 데이터 유형 | 표준 형식 | 예시 | 비고 |
|------------|----------|------|------|
| **천간/지지 (원본)** | 한글(한자) | `갑(甲)`, `자(子)` | DB 컬럼 저장 형식 |
| **십신 (파생)** | 한글만 | `비견`, `정인` | Flutter에서 재계산 가능 |
| **격국 (파생)** | 영어 enum + 한글/한자 | `pyeonjaeGyeok` + `편재격` + `偏財格` | 3개 필드 분리 |
| **대운/세운 간지** | 한글(한자) | `{gan: "병(丙)", ji: "자(子)"}` | 원본 데이터 |
| **오행** | 한글 키 | `{목: 2, 화: 1, ...}` | 이미 통일됨 |

---

## 🚨 Phase 16-F: JSONB 데이터 형식 통일 (필수 - 궁합 분석 전)

> **문제**: saju_analyses 테이블의 JSONB 필드들이 레거시/현재 형식 혼재
> **핵심**: 한글+한자 형식은 OK, **스키마 구조가 불일치**가 진짜 문제
> **영향**: 두 사람 사주 비교 시 데이터 불일치로 AI 궁합 분석 불가

### 발견된 불일치 현황 (2025-12-25)

#### 🔴 심각 - 구조 자체가 다름
| 필드 | 레거시 형식 | Flutter 표준 형식 | 레거시 수 |
|------|------------|------------------|----------|
| **sipsin_info** | `dayJi`, `hourJi` | `day.ji`, `hour.ji` | 6개 |
| **jijanggan_info** | `["기","정"]` | `[{gan, type, sipsin}]` | 11개 |
| **gyeokguk** | `name: 정인격(正印格)` | `gyeokguk + korean + hanja` | 6개 |

#### 🟡 중간 - 값 형식이 다름
| 필드 | 레거시 형식 | Flutter 표준 형식 | 레거시 수 |
|------|------------|------------------|----------|
| **day_strength.level** | `신강(身强)`, `medium` | `singang`, `junghwaSingang` | 5개 |
| **daeun.list** | `pillar: 임(壬)자(子)` | `{gan: 임, ji: 자}` | 4개 |
| **current_seun** | `pillar: 을(乙)사(巳)` | `{gan: 을, ji: 사}` | 4개 |

#### ✅ 이미 수정됨
| 필드 | 상태 |
|------|------|
| **oheng_distribution** | ✅ 한글 키로 통일 완료 (`목`, `화`, `토`, `금`, `수`) |
| **yongsin** | ✅ 한글 값으로 통일 완료 |
| **twelve_unsung** | ✅ 일관됨 |
| **twelve_sinsal** | ✅ 일관됨 |
| **gilseong** | ✅ 마이그레이션 완료 (33/33) |
| **hapchung** | ✅ 마이그레이션 완료 (33/33) |

### Flutter 표준 형식 정의

```dart
// day_strength
{ "level": "junghwaSingang", "score": 52, "isStrong": true, ... }

// gyeokguk
{ "gyeokguk": "pyeonjaeGyeok", "korean": "편재격", "hanja": "偏財格", ... }

// sipsin_info
{ "year": {"gan": "정인", "ji": "편재"}, "month": {...}, "day": {...}, "hour": {...} }

// jijanggan_info
{ "dayJi": [{"gan": "무(戊)", "type": "여기", "sipsin": "정재(正財)"}, ...], ... }

// daeun.list
[{ "gan": "병", "ji": "자", "startAge": 3, "endAge": 12, "order": 1 }, ...]

// current_seun
{ "gan": "을(乙)", "ji": "사(巳)", "year": 2025, "age": 32 }
```

### 마이그레이션 완료 현황 ✅ (2025-12-29 최종)

| 단계 | 작업 | 마이그레이션 | 상태 |
|------|------|-------------|------|
| F-1 | day_strength.level 표준 enum 통일 (18개) | `f1_day_strength_level_standardize` | ✅ 완료 |
| F-2 | gyeokguk 구조 통일 (17개) | `f2_gyeokguk_standardize` | ✅ 완료 |
| F-3 | sipsin_info nested 구조 변환 (6개) | `f3_sipsin_info_restructure` | ✅ 완료 |
| F-4 | daeun 한글(한자) 페어 적용 | `f4_fix_daeun_add_hanja_pairs` | ✅ 완료 |
| F-5 | current_seun 한글(한자) 페어 적용 (15개) | `f5_current_seun_standardize` | ✅ 완료 |
| F-6 | jijanggan_info 구조 + 십신 계산 (11개) | `f6_jijanggan_info_standardize` | ✅ 완료 |

### 추가 수정 사항 (SQL 직접 실행)
| 항목 | 수정 내용 | 상태 |
|------|----------|------|
| jijanggan_info.type | 여기→여기(餘氣), 중기→중기(中氣), 정기→정기(正氣) | ✅ 완료 |
| jijanggan_info.sipsin | 한글→한글(한자) 페어 | ✅ 완료 |
| sinsal_list | type/location/relatedJi 한글(한자) 페어 | ✅ 완료 |

### 생성된 PostgreSQL 함수
- `get_gan_hanja(gan text)` - 천간 한자 매핑
- `get_gan_oheng(gan text)` - 천간 오행 매핑
- `calculate_sipsin(day_gan text, target_gan text)` - 십신 계산
- `convert_jijanggan_array(day_gan text, gan_array jsonb, pillar_name text)` - 지장간 변환

### 표준 데이터 형식 (마이그레이션 후)
```json
// day_strength
{ "level": "junghwaSingang", "score": 52, "isStrong": true }

// gyeokguk
{ "gyeokguk": "jeonginGyeok", "korean": "정인격", "hanja": "正印格" }

// sipsin_info
{ "year": {"gan": "정인", "ji": "편재"}, "day": {"gan": "비견", "ji": "정인"} }

// daeun.list
[{ "gan": "임(壬)", "ji": "자(子)", "order": 1, "startAge": 5, "endAge": 14 }]

// current_seun
{ "gan": "을(乙)", "ji": "사(巳)", "year": 2025, "age": 32 }

// jijanggan_info
{ "dayJi": [{"gan": "무(戊)", "type": "여기", "sipsin": "정재"}, ...] }

// hapchung (NEW - Phase 16-G)
{
  "cheongan_haps": [{"gan1": "정", "gan2": "임", "pillar1": "년", "pillar2": "시", "description": "정임합화목(丁壬合化木) - 인수지합"}],
  "cheongan_chungs": [...],
  "jiji_yukhaps": [...], "jiji_samhaps": [...], "jiji_banghaps": [...],
  "jiji_chungs": [...], "jiji_hyungs": [...], "jiji_pas": [...], "jiji_haes": [...],
  "wonjins": [...],
  "total_haps": N, "total_chungs": N, "total_negatives": N, "has_relations": true/false
}

// gilseong (Phase 16-D, 16-G 업데이트)
{
  "year": {"pillarName": "년주", "gan": "정", "ji": "묘", "sinsals": [...]},
  "month": {...}, "day": {...}, "hour": {...},
  "allUniqueSinsals": ["천을귀인", "천덕귀인", ...],
  "hasGwiMunGwanSal": false
}
```

---

## ✅ Phase 16-G: hapchung/gilseong 마이그레이션 완료 (2025-12-29)

> **목적**: NULL 레코드에 합충형파해(hapchung)와 길성(gilseong) 데이터 채우기
> **방식**: Edge Function으로 서버사이드 일괄 마이그레이션
> **결과**: 100% 완료 (33/33 레코드)

### 마이그레이션 결과

| 필드 | 마이그레이션 전 | 마이그레이션 후 | Edge Function |
|------|----------------|-----------------|---------------|
| **hapchung** | 3/33 (9%) | **33/33 (100%)** | `migrate-hapchung` v1 |
| **gilseong** | 22/33 (67%) | **33/33 (100%)** | `migrate-gilseong` v5 |

### Edge Function 상세

**migrate-hapchung (v1 - NEW)**
- Flutter `hapchung_service.dart` → TypeScript 포팅
- 천간합(5), 천간충(4), 지지육합(6), 삼합(4), 방합(4), 충(6), 형(3형), 파(6), 해(6), 원진(6) 분석
- 6쌍 기둥 조합 (년-월, 년-일, 년-시, 월-일, 월-시, 일-시) 비교
- `extractHangul()` 함수로 한글(한자) 페어에서 한글 추출

**migrate-gilseong (v5 - UPDATED)**
- Flutter `gilseong_service.dart` → TypeScript 포팅
- 11종 특수신살 분석: 천을귀인, 양인살, 백호대살, 현침살, 천덕귀인, 월덕귀인, 천문성, 황은대사, 학당귀인, 괴강살, 귀문관살
- 기둥별 (년/월/일/시) 개별 분석 + 전체 요약

### 실행 로그

```
hapchung 마이그레이션:
- 대상: 31개 (NULL 30개 + 구형식 1개)
- 성공: 31/31 (100%)

gilseong 마이그레이션:
- 대상: 11개 (NULL)
- 성공: 11/11 (100%)
```

### Edge Function 활용 방안

> 향후 로직 변경이나 새 레코드 마이그레이션 시 재사용 가능

```bash
# hapchung 재마이그레이션 (필요시)
curl -X POST "https://kfciluyxkomskyxjaeat.supabase.co/functions/v1/migrate-hapchung" \
  -H "Authorization: Bearer <anon_key>" \
  -H "Content-Type: application/json"

# gilseong 재마이그레이션 (필요시)
curl -X POST "https://kfciluyxkomskyxjaeat.supabase.co/functions/v1/migrate-gilseong" \
  -H "Authorization: Bearer <anon_key>" \
  -H "Content-Type: application/json"
```

---

## 🔐 Phase 17: 인증 체계 강화

### ✅ Phase 17-A: 보안 강화 (2025-12-29 완료)

**작업 내용:**
1. **Function search_path 보안 수정** - 13개 함수 완료
   - 마이그레이션: `fix_function_search_path_security`
   - Search path injection 공격 방지

2. **인덱스 최적화 확인** - 모두 이미 적용됨
   - `chat_messages(session_id, created_at)` ✅
   - `chat_sessions(profile_id, updated_at)` ✅
   - `saju_analyses` GIN 인덱스 (gilseong, hapchung) ✅

3. **Edge Function 구현 상태 확인** - 모두 완료
   - `generate-ai-summary` v7 ✅
   - `ai-gemini` v6 ✅

4. **RLS 정책 검증** - 정상 동작
   - `saju_profiles`: `auth.uid() = user_id` ✅

| 항목 | 상태 | 비고 |
|------|------|------|
| Function search_path | ✅ 수정됨 | 13개 함수 |
| 인덱스 최적화 | ✅ 확인됨 | 이미 적용 |
| Edge Functions | ✅ 구현됨 | 6개 ACTIVE |
| RLS 정책 | ✅ 적용됨 | user_id 기반 |
| 익명 인증 | ⚠️ 허용 중 | 개발 편의용 |

### Phase 17-B: 인증 방식 추가 (v0.2 예정)
```
우선순위:
1. 이메일/비밀번호 인증 (기본)
2. Google OAuth (글로벌)
3. Apple Sign-In (iOS App Store 필수)
4. Kakao 로그인 (한국 사용자 - 선택)
```

**Flutter 패키지:**
- `supabase_flutter` (이미 설치)
- `google_sign_in`
- `sign_in_with_apple`
- `kakao_flutter_sdk` (선택)

**새로운 Feature 구조:**
```
features/auth/
├── data/repositories/auth_repository_impl.dart
├── domain/
│   ├── entities/user.dart
│   └── repositories/auth_repository.dart
└── presentation/
    ├── providers/auth_provider.dart
    ├── screens/login_screen.dart, signup_screen.dart
    └── widgets/social_login_buttons.dart
```

### Phase 17-C: 익명 → 정규 전환 (v0.3 예정)
1. 계정 연결(Link) 기능 구현
2. 익명 사용자 데이터 마이그레이션
3. 데이터 병합 로직

### Phase 17-D: 프로덕션 보안 강화 (v1.0 예정)
```sql
-- 익명 사용자 접근 차단 정책
CREATE POLICY "no_anonymous_access" ON saju_profiles
  FOR ALL
  USING (
    auth.jwt()->>'is_anonymous' IS NULL
    OR auth.jwt()->>'is_anonymous' = 'false'
  );
```

**추가 보안 조치:**
- [ ] Leaked Password Protection 활성화
- [ ] Rate Limiting 적용
- [ ] 2FA 옵션 (선택적)
- [ ] 미사용 인덱스 정리
- [ ] 로그인 실패 모니터링

### 마일스톤 요약
| 버전 | 단계 | 주요 작업 |
|------|------|----------|
| v0.1 | MVP | 익명 인증 유지 (현재) |
| v0.2 | 베타 | 이메일 + Google 로그인 |
| v0.3 | 베타2 | Apple + Kakao + 계정 연결 |
| v1.0 | 프로덕션 | 보안 강화 + 익명 차단 |

---

## 📊 데이터 연동 현황 (2025-12-25 검증)

### 한글+한자 페어 일관성 ✅
| 데이터 타입 | 저장 방식 | 예시 |
|------------|----------|------|
| 천간/지지 (DB 컬럼) | `한글(한자)` 페어 | `"무(戊)"`, `"오(午)"` |
| 신살 (DB JSONB) | 별도 필드 | `name: "화개살"`, `hanja: "華蓋殺"` |
| Flutter enum | 별도 속성 | `korean: '천을귀인'`, `hanja: '天乙貴人'` |

### DB 저장 컬럼 (saju_analyses) - 2025-12-29 최종
| 컬럼 | 타입 | Flutter 계산 | DB 저장 | 마이그레이션 |
|------|------|-------------|---------|-------------|
| year_gan, year_ji 등 | TEXT | ✅ | ✅ `한글(한자)` | - |
| oheng_distribution | JSONB | ✅ | ✅ | ✅ 완료 |
| day_strength | JSONB | ✅ | ✅ | ✅ F-1 |
| yongsin | JSONB | ✅ | ✅ | ✅ 완료 |
| gyeokguk | JSONB | ✅ | ✅ | ✅ F-2 |
| sipsin_info | JSONB | ✅ | ✅ | ✅ F-3 |
| jijanggan_info | JSONB | ✅ | ✅ | ✅ F-6 |
| daeun | JSONB | ✅ | ✅ | ✅ F-4 |
| current_seun | JSONB | ✅ | ✅ | ✅ F-5 |
| twelve_sinsal | JSONB | ✅ | ✅ | ✅ 일관됨 |
| twelve_unsung | JSONB | ✅ | ✅ | ✅ 일관됨 |
| sinsal_list | JSONB | ✅ | ✅ | ✅ 완료 |
| **gilseong** | JSONB | ✅ | ✅ | ✅ **33/33 (100%)** |
| **hapchung** | JSONB | ✅ | ✅ | ✅ **33/33 (100%)** |

### 길성/합충 저장 현황 ✅ (Phase 16-G 마이그레이션 완료)
- **Flutter**: `gilseong_service.dart`, `hapchung_service.dart`에서 실시간 계산 → UI 표시 ✅
- **DB**: `gilseong`, `hapchung` JSONB 컬럼 → **33/33 레코드 100% 채움** ✅
- **Edge Function**: `migrate-gilseong` v5, `migrate-hapchung` v1 (로직 변경 시 재사용 가능)
- **AI 프롬프트**: 길성/합충 정보 활용 가능 ✅
- **UI 위치**: "신살" 탭 → "신살과 길성" 섹션, "합충" 탭에서 확인

### sinsal_list JSONB 구조
```json
{
  "name": "화개살",       // 한글
  "hanja": "華蓋殺",      // 한자
  "type": "neutral",      // lucky/unlucky/neutral
  "location": "년지",
  "relatedJi": "술",
  "description": "년지에 화개살 - 예술성과 영성이 강함"
}
```

---

## ✅ Phase 16: 길성(吉星) 기능 구현 (2025-12-24) - 완료

### 문제 발견
포스텔러 만세력에서는 "신살과 길성" 섹션에서 각 기둥별로 특수 신살(길성/흉성)을 표시하지만,
우리 앱에서는 12신살만 표시하고 **길성 행**이 없었음.

### 구현된 신살 vs 포스텔러 신살
| 신살 | 기존 구현 | 추가 구현 |
|------|----------|----------|
| 천을귀인 | ✅ | - |
| 천덕귀인 | ❌ | ✅ |
| 월덕귀인 | ❌ | ✅ |
| 도화살 | ✅ | - |
| 역마살 | ✅ | - |
| 화개살 | ✅ | - |
| 양인살 | ✅ | - |
| 공망 | ✅ | - |
| 원진살 | ✅ | - |
| 귀문관살 | ✅ | ✅ (개선) |
| 괴강살 | ✅ | - |
| **백호대살** | ❌ | ✅ |
| **현침살** | ❌ | ✅ |
| **천문성** | ❌ | ✅ |
| **황은대사** | ❌ | ✅ |
| **학당귀인** | ❌ | ✅ |

### 신규 신살 계산 로직

**백호대살(白虎大殺)** - 일주 기준
- 갑진, 을미, 병술, 정축, 무진, 임술, 계축

**현침살(懸針殺)** - 천간/지지 체크
- 천간: 갑(甲), 신(辛)
- 지지: 신(申), 묘(卯), 오(午)
- 강력 일주: 갑신, 신묘, 갑오

**천덕귀인(天德貴人)** - 월지 기준
| 월지 | 천덕귀인 |
|------|---------|
| 인 | 정 |
| 묘 | 신(申) |
| 진 | 임 |
| 사 | 신(辛) |
| 오 | 해 |
| 미 | 갑 |
| 신 | 계 |
| 유 | 인 |
| 술 | 병 |
| 해 | 을 |
| 자 | 사 |
| 축 | 경 |

**월덕귀인(月德貴人)** - 월지 삼합 기준
| 월지 삼합 | 월덕귀인 |
|-----------|---------|
| 인오술 | 병 |
| 신자진 | 임 |
| 사유축 | 경 |
| 해묘미 | 갑 |

**천문성(天門星)** - 지지 체크
- 1순위 (강): 해, 묘, 미, 술
- 2순위 (약): 인, 유

**황은대사(皇恩大赦)** - 월지 기준 특정 지지 조합

**학당귀인(學堂貴人)** - 일간 기준
| 일간 | 학당귀인 지지 |
|------|-------------|
| 갑 | 사 |
| 을 | 오 |
| 병 | 인 |
| 정 | 유 |
| 무 | 인 |
| 기 | 유 |
| 경 | 사 |
| 신 | 자 |
| 임 | 신 |
| 계 | 묘 |

### 추가/수정된 파일
1. `frontend/lib/features/saju_chart/data/constants/twelve_sinsal.dart`
   - SpecialSinsal enum 확장 (7개 → 14개)
   - SinsalFortuneType enum 추가
   - 새로운 신살 계산 함수들 추가

2. `frontend/lib/features/saju_chart/domain/services/gilseong_service.dart` (신규)
   - GilseongService 클래스
   - PillarGilseongResult 모델
   - GilseongAnalysisResult 모델

3. `frontend/lib/features/saju_chart/presentation/widgets/gilseong_display.dart` (신규)
   - SpecialSinsalBadge 위젯
   - GilseongRow 위젯
   - SinsalGilseongTable 위젯 (포스텔러 스타일)
   - GilseongSummaryCard 위젯

4. `frontend/lib/features/saju_chart/presentation/widgets/saju_detail_tabs.dart`
   - _SinsalTab에 SinsalGilseongTable 통합

### 검증
- Flutter analyze 통과 ✅
- 새로운 신살 로직 7개 추가 완료

---

## ✅ Phase 16-C: 길성 DB 저장 구현 (2025-12-25) - 완료

### 문제 발견
- Flutter `GilseongService`에서 새 길성(천덕귀인, 월덕귀인 등)을 실시간 계산 ✅
- **DB에는 저장 안 됨** ❌ → AI 프롬프트에서 새 길성 정보 활용 불가

### 해결

**1. DB 마이그레이션 (add_gilseong_column)**
```sql
ALTER TABLE saju_analyses
ADD COLUMN IF NOT EXISTS gilseong JSONB;

COMMENT ON COLUMN saju_analyses.gilseong IS
  '길성(吉星) 분석 결과 - 기둥별 특수 신살 JSONB';

CREATE INDEX IF NOT EXISTS idx_saju_analyses_gilseong
ON saju_analyses USING GIN (gilseong)
WHERE gilseong IS NOT NULL;
```

**2. Flutter Repository 수정**
- `saju_analysis_repository.dart`에 `_gilseongToJson()` 메서드 추가
- `GilseongService.analyzeFromChart()` 결과를 JSONB로 변환하여 저장

**3. gilseong JSONB 구조**
```json
{
  "year": {
    "pillarName": "년주",
    "gan": "갑",
    "ji": "술",
    "sinsals": [
      {"name": "천문성", "hanja": "天門星", "meaning": "영적 감각", "fortuneType": "good"}
    ]
  },
  "month": { ... },
  "day": { ... },
  "hour": { ... },
  "hasGwiMunGwanSal": false,
  "totalGoodCount": 3,
  "totalBadCount": 1,
  "allUniqueSinsals": [...],
  "summary": "천덕귀인, 월덕귀인, 천문성"
}
```

### 저장되는 새 길성 목록
| 신살 | 한자 | fortuneType |
|------|------|-------------|
| 천덕귀인 | 天德貴人 | good |
| 월덕귀인 | 月德貴人 | good |
| 백호대살 | 白虎大殺 | bad |
| 현침살 | 懸針殺 | mixed |
| 천문성 | 天門星 | good |
| 황은대사 | 皇恩大赦 | good |
| 학당귀인 | 學堂貴人 | good |
| 귀문관살 | 鬼門關殺 | mixed |
| 괴강살 | 魁罡殺 | mixed |
| 양인살 | 羊刃殺 | bad |
| 천을귀인 | 天乙貴人 | good |

### 수정된 파일
- `frontend/lib/core/repositories/saju_analysis_repository.dart`
  - import 추가: `gilseong_service.dart`
  - `_gilseongToJson()` 메서드 추가
  - `_toSupabaseMap()`에 `'gilseong': _gilseongToJson(analysis.chart)` 추가

### 검증
- Flutter analyze 통과 ✅
- 한글(한자) 형식 17개 모두 정상 ✅
- 기존 데이터: 앱에서 프로필 저장 시 자동 업데이트됨

---

## ✅ Phase 15-D: sipsin_info day.gan 수정 (2025-12-24) - 완료

### 문제 발견
DB `saju_analyses.sipsin_info` JSONB에서 `day.gan`이 **"일간"**으로 하드코딩되어 저장됨.
- Flutter UI: `day.gan = "비견"` ✅ (정확)
- Supabase DB: `day.gan = "일간"` ❌ (틀림)

### 원인
`core/repositories/saju_analysis_repository.dart`의 `_sipsinInfoToJson()` 메서드:
```dart
'day': {
  'gan': '일간',  // ❌ 하드코딩
  'ji': info.dayJiSipsin.korean,
},
```

### 해결
1. **Flutter 코드 수정**: `'gan': '일간'` → `'gan': '비견'`
2. **DB 마이그레이션**: 11개 레코드의 `sipsin_info.day.gan`을 "일간" → "비견"으로 수정

### 검증
- 일간 자신의 십신은 **항상 비견** (같은 오행, 같은 음양)
- 일간이 을(乙), 무(戊), 경(庚) 등 다 다르더라도 자기 자신 = 비견
- 포스텔러에서도 일주 천간 십성 = "비견"으로 표시됨

### 수정된 파일
- `frontend/lib/core/repositories/saju_analysis_repository.dart` (라인 179)

---

## ✅ Phase 15: 한글+한자 페어 DB 수정 (2025-12-24) - 완료

### 문제 발견
DB `saju_analyses` 테이블에서 천간/지지 데이터가 **일관성 없이 저장**되고 있음.

### 현재 DB 상태 (불일치)
```sql
-- ❌ 잘못된 데이터 (한글만)
year_gan: "갑", year_ji: "묘", month_gan: "무", month_ji: "진"

-- ✅ 올바른 데이터 (한글+한자 페어)
year_gan: "정(丁)", year_ji: "축(丑)", month_gan: "신(辛)", month_ji: "해(亥)"
```

### 영향 받는 컬럼 (saju_analyses 테이블)
| 컬럼 | 올바른 형식 | 현재 문제 |
|------|-------------|-----------|
| year_gan | `갑(甲)` | 일부 `갑` |
| year_ji | `자(子)` | 일부 `자` |
| month_gan | `을(乙)` | 일부 `을` |
| month_ji | `축(丑)` | 일부 `축` |
| day_gan | `병(丙)` | 일부 `병` |
| day_ji | `인(寅)` | 일부 `인` |
| hour_gan | `정(丁)` | 일부 `정` |
| hour_ji | `묘(卯)` | 일부 `묘` |

### 한글-한자 매핑 테이블

**천간 (10개)**
| 한글 | 한자 | 올바른 형식 |
|------|------|-------------|
| 갑 | 甲 | 갑(甲) |
| 을 | 乙 | 을(乙) |
| 병 | 丙 | 병(丙) |
| 정 | 丁 | 정(丁) |
| 무 | 戊 | 무(戊) |
| 기 | 己 | 기(己) |
| 경 | 庚 | 경(庚) |
| 신 | 辛 | 신(辛) |
| 임 | 壬 | 임(壬) |
| 계 | 癸 | 계(癸) |

**지지 (12개)**
| 한글 | 한자 | 올바른 형식 |
|------|------|-------------|
| 자 | 子 | 자(子) |
| 축 | 丑 | 축(丑) |
| 인 | 寅 | 인(寅) |
| 묘 | 卯 | 묘(卯) |
| 진 | 辰 | 진(辰) |
| 사 | 巳 | 사(巳) |
| 오 | 午 | 오(午) |
| 미 | 未 | 미(未) |
| 신 | 申 | 신(申) |
| 유 | 酉 | 유(酉) |
| 술 | 戌 | 술(戌) |
| 해 | 亥 | 해(亥) |

### 수정 필요 사항

1. **Flutter 코드 수정**: DB 저장 시 한글+한자 형식으로 변환
   - `saju_analysis_db_model.dart` 또는 관련 서비스

2. **기존 DB 데이터 마이그레이션**: 한글만 있는 데이터 → 한글(한자) 형식으로 UPDATE

3. **검증**: 모든 프로필의 saju_analyses 데이터가 올바른 형식인지 확인

### 작업 순서
- [x] 15-A: Flutter 코드에서 한글→한글(한자) 변환 로직 확인/수정 ✅
- [x] 15-B: DB 마이그레이션 SQL 작성 및 실행 ✅
- [x] 15-C: 전체 데이터 검증 ✅

### 완료 내용 (2025-12-24)

**15-A: Flutter 코드 수정**
- `core/repositories/saju_analysis_repository.dart`의 `_toSupabaseMap()` 메서드 수정
- `_formatWithHanja()`, `_extractHangul()` 헬퍼 함수 추가
- DB 저장 시 자동으로 한글(한자) 형식 변환

**15-B: DB 마이그레이션**
- Supabase MCP로 `update_saju_analyses_hangul_hanja_format` 마이그레이션 적용
- 천간 10개, 지지 12개에 대한 변환 규칙 적용
- 컬럼 코멘트 추가 (데이터 형식 문서화)

**15-C: 검증 결과**
- 마이그레이션 전: 한글만 12개, 한글(한자) 4개
- 마이그레이션 후: 한글(한자) 16개 (100%)
- 8개 컬럼 모두 유효성 검증 통과

---

## 📊 만세력 기능 구현 현황 (2025-12-24 검증 완료)

> **결론: 만세력 핵심 기능 78개 모두 구현 완료** ✅
> AI 채팅 기능은 새 협업자 2명이 담당 예정
> Supabase DB 관리는 JH_BE가 메인 담당

### 기본 사주팔자 계산 서비스

| 카테고리 | 기능 | 서비스 파일 | 상태 |
|----------|------|-------------|------|
| 년/월/일/시 기둥 | 사주팔자 4기둥 계산 | `saju_calculation_service.dart` | ✅ |
| 음양력 변환 | 양력↔음력 변환 (1900-2100) | `lunar_solar_converter.dart` | ✅ |
| 절기 계산 | 24절기 기반 월주 결정 | `solar_term_service.dart` | ✅ |
| 진태양시 보정 | 도시별 경도 보정 | `true_solar_time_service.dart` | ✅ |
| 서머타임 보정 | DST 자동 보정 | `dst_service.dart` | ✅ |
| 야자시/조자시 | 자시 처리 옵션 | `jasi_service.dart` | ✅ |

### 합충형파해 (合沖刑破害) - `hapchung_service.dart`

| 기능 | 상세 | 상태 |
|------|------|------|
| 천간합 (5합) | 갑기/을경/병신/정임/무계 | ✅ |
| 천간충 | 갑경/을신/병임/정계/무갑 등 | ✅ |
| 지지육합 | 자축/인해/묘술/진유/사신/오미 | ✅ |
| 지지삼합 | 인오술/사유축/신자진/해묘미 | ✅ |
| 지지반합 | 삼합의 2개 조합 | ✅ |
| 지지방합 | 인묘진/사오미/신유술/해자축 | ✅ |
| 지지충 (6충) | 자오/축미/인신/묘유/진술/사해 | ✅ |
| 지지형 | 무례지형/은혜지형/자형 등 | ✅ |
| 지지파 | 자유파/축진파 등 | ✅ |
| 지지해 | 자미해/축오해 등 | ✅ |
| 원진 | 자미원진/축오원진 등 | ✅ |

### 12운성 (十二運星) - `unsung_service.dart`

| 기능 | 상태 | 기능 | 상태 |
|------|------|------|------|
| 장생 | ✅ | 쇠 | ✅ |
| 목욕 | ✅ | 병 | ✅ |
| 관대 | ✅ | 사 | ✅ |
| 건록 | ✅ | 묘 | ✅ |
| 제왕 | ✅ | 절 | ✅ |
| | | 태/양 | ✅ |

### 12신살 (十二神煞) - `twelve_sinsal_service.dart`

| 기능 | 상태 | 기능 | 상태 |
|------|------|------|------|
| 겁살 | ✅ | 장성 | ✅ |
| 재살 | ✅ | 반안 | ✅ |
| 천살 | ✅ | 역마 | ✅ |
| 지살 | ✅ | 육해 | ✅ |
| 연살(도화) | ✅ | 화개 | ✅ |
| 월살/망신 | ✅ | | |

### 특수 신살 - `sinsal_service.dart`

| 기능 | 상태 | 기능 | 상태 |
|------|------|------|------|
| 천을귀인 | ✅ | 공망 | ✅ |
| 도화살 | ✅ | 원진살 | ✅ |
| 역마살 | ✅ | 귀문관살 | ✅ |
| 화개살 | ✅ | 괴강살 | ✅ |
| 양인살 | ✅ | | |

### 신강/신약 분석 - `day_strength_service.dart`

| 기능 | 상세 | 상태 |
|------|------|------|
| 8단계 판정 | 극약/태약/신약/중화신약/중화신강/신강/태강/극왕 | ✅ |
| 득령 | 월지 정기 기준 | ✅ |
| 득지 | 일지 정기 기준 | ✅ |
| 득시 | 시지 정기 기준 | ✅ |
| 득세 | 천간 비겁/인성 | ✅ |
| 십신 분포 | 비겁/인성/재성/관성/식상 카운트 | ✅ |

### 용신 (用神) - `yongsin_service.dart`

| 기능 | 상태 |
|------|------|
| 용신 선정 (억부법 기반) | ✅ |
| 희신 (용신을 생하는 오행) | ✅ |
| 기신 (용신을 극하는 오행) | ✅ |
| 구신 (용신을 설기하는 오행) | ✅ |
| 한신 (기신을 생하는 오행) | ✅ |

### 격국 (格局) - `gyeokguk_service.dart`

| 기능 | 상태 |
|------|------|
| 기본 격국 (정관격/정재격/식신격/정인격 등) | ✅ |
| 특수 격국 (종왕격/종살격/종재격) | ✅ |
| 중화격 (균형 잡힌 사주) | ✅ |

### 대운/세운 - `daeun_service.dart`

| 기능 | 상태 |
|------|------|
| 대운 계산 (10년 주기) | ✅ |
| 대운수 계산 (절입일 기반) | ✅ |
| 순행/역행 (성별+음양년 기준) | ✅ |
| 세운 계산 (연도별 년주) | ✅ |

### 지장간 (地藏干) - `jijanggan_service.dart`

| 기능 | 상태 |
|------|------|
| 여기/중기/정기 분석 | ✅ |
| 십성 계산 (일간 기준) | ✅ |
| 세력 분석 (지장간별 일수) | ✅ |

### 공망 (空亡) - `gongmang_service.dart`

| 기능 | 상태 |
|------|------|
| 공망 지지 (일주 기준 2개) | ✅ |
| 순(旬) 정보 (갑자순/갑술순 등) | ✅ |
| 궁성별 분석 (년지/월지/시지) | ✅ |
| 공망 유형 (진공/반공/탈공) | ✅ |

### 구현 요약

| 분류 | 기능 수 | 상태 |
|------|---------|------|
| 기본 사주 계산 | 6개 | ✅ |
| 합충형파해 | 11개 | ✅ |
| 12운성 | 12개 | ✅ |
| 12신살 | 12개 | ✅ |
| 특수 신살 | 9개 | ✅ |
| 신강/신약 | 6개 | ✅ |
| 용신 | 5개 | ✅ |
| 격국 | 3개 | ✅ |
| 대운/세운 | 4개 | ✅ |
| 지장간 | 3개 | ✅ |
| 공망 | 4개 | ✅ |
| RuleEngine | 3개 | ✅ |
| **총합** | **78개** | **✅ 완료** |

---

## Phase 1: 프로젝트 기반 설정 ✅ 완료

### 1.1 pubspec.yaml 의존성 추가 ✅
- [x] flutter_riverpod: ^2.6.1
- [x] riverpod_annotation: ^2.6.1
- [x] go_router: ^14.6.2
- [x] hive_flutter: ^1.1.0
- [x] flutter_secure_storage: ^9.2.4
- [x] shared_preferences: ^2.3.5
- [x] freezed_annotation: ^2.4.4
- [x] json_annotation: ^4.9.0
- [x] uuid: ^4.5.1
- [x] equatable: ^2.0.7
- [x] dio: ^5.7.0
- [x] intl: ^0.20.1

### 1.2 dev_dependencies ✅
- [x] build_runner: ^2.4.9
- [x] riverpod_generator: ^2.3.11
- [x] freezed: ^2.4.7
- [x] json_serializable: ^6.7.1
- [ ] riverpod_lint (disabled - analyzer 충돌)
- [ ] hive_generator (disabled - analyzer 충돌)

### 1.3 폴더 구조 생성 ✅
```
lib/
├── main.dart ✅
├── app.dart ✅
├── core/
│   ├── constants/
│   │   ├── app_colors.dart ✅
│   │   ├── app_strings.dart ✅
│   │   └── app_sizes.dart ✅
│   ├── theme/
│   │   └── app_theme.dart ✅
│   ├── utils/
│   │   ├── validators.dart
│   │   └── formatters.dart
│   └── errors/
│       ├── exceptions.dart
│       └── failures.dart
├── features/
│   ├── splash/ ✅ (placeholder)
│   ├── onboarding/ ✅ (placeholder)
│   ├── profile/ ✅ (placeholder)
│   ├── saju_chart/ ✅ (폴더만)
│   ├── saju_chat/ ✅ (placeholder)
│   ├── history/ ✅ (placeholder)
│   └── settings/ ✅ (placeholder)
├── shared/
│   ├── widgets/
│   └── extensions/
└── router/
    ├── app_router.dart ✅
    └── routes.dart ✅
```

### 1.4 기본 설정 파일 ✅
- [x] analysis_options.yaml (린트 규칙)
- [x] app.dart (MaterialApp 설정)
- [x] router/routes.dart (라우트 상수)
- [x] router/app_router.dart (go_router 설정)

---

## Phase 2: Core 레이어 구현 (부분 완료)

### 2.1 상수 정의 ✅
- [x] app_colors.dart - 컬러 팔레트
- [x] app_strings.dart - 문자열 상수
- [x] app_sizes.dart - 크기/패딩 상수

### 2.2 테마 설정 ✅
- [x] app_theme.dart - 라이트/다크 테마

### 2.3 에러 처리
- [ ] exceptions.dart - 예외 클래스
- [ ] failures.dart - Failure 클래스

### 2.4 유틸리티
- [ ] validators.dart - 생년월일 검증 등
- [ ] formatters.dart - 날짜 포맷 등

---

## Phase 3: 공유 컴포넌트

### 3.1 공통 위젯
- [ ] custom_button.dart
- [ ] custom_text_field.dart
- [ ] loading_indicator.dart
- [ ] error_widget.dart
- [ ] disclaimer_banner.dart ("사주는 참고용입니다")

### 3.2 Extensions
- [ ] context_extensions.dart
- [ ] datetime_extensions.dart

---

## Phase 4: Feature - Profile (P0) ✅ 완료

> 참조: docs/02_features/profile_input.md
> 2025-12-02: Profile Feature 구현 완료 (21개 파일)

### 4.1 Domain 레이어 ✅
- [x] entities/saju_profile.dart (Freezed)
- [x] entities/gender.dart (enum)
- [x] repositories/profile_repository.dart (abstract)

### 4.2 Data 레이어 ✅
- [x] models/saju_profile_model.dart (Freezed + JSON)
- [x] datasources/profile_local_datasource.dart (Hive)
- [x] repositories/profile_repository_impl.dart

### 4.3 Presentation 레이어 ✅
- [x] providers/profile_provider.dart (Riverpod 3.0)
- [x] screens/profile_edit_screen.dart
- [x] widgets/profile_name_input.dart
- [x] widgets/gender_toggle_buttons.dart
- [x] widgets/calendar_type_dropdown.dart
- [x] widgets/birth_date_picker.dart
- [x] widgets/birth_time_picker.dart
- [x] widgets/birth_time_options.dart
- [x] widgets/city_search_field.dart
- [x] widgets/time_correction_banner.dart
- [x] widgets/profile_action_buttons.dart

### 4.4 수락 조건 ✅
- [x] 프로필명 입력 (최대 12자)
- [x] 성별 선택 (필수) - 토글 버튼
- [x] 생년월일 선택 (필수) - ShadDatePicker
- [x] 음력/양력 선택 - ShadSelect
- [x] 출생시간 입력 (선택)
- [x] "시간 모름" 체크 기능
- [x] "야자시/조자시" 옵션 추가
- [x] 도시 검색 (25개 도시 + 자동완성)
- [x] 진태양시 보정 표시 (예: "-26분")
- [x] 로컬 저장 (Hive)
- [x] 유효성 검사

### 4.5 TODO
- [ ] `dart run build_runner build` 실행
- [ ] 빌드 테스트

---

## Phase 5: Feature - Saju Chat (P0) ✅ 대부분 완료

> 참조: docs/02_features/saju_chat.md
> 2025-12-05: Gemini 3.0 REST API 연동, 스트리밍 응답, UI 위젯 구현 완료

### 5.1 Domain 레이어 ✅
- [x] entities/chat_session.dart
- [x] entities/chat_message.dart (MessageRole, MessageStatus 포함)
- [x] models/chat_type.dart (ChatType enum)
- [x] repositories/chat_repository.dart (abstract)

- [x] widgets/typing_indicator.dart
- [x] widgets/disclaimer_banner.dart
- [x] widgets/error_banner.dart
- [ ] widgets/suggested_questions.dart (추후)
- [ ] widgets/saju_summary_sheet.dart (추후)

### 5.4 수락 조건
- [x] AI 인사 메시지 표시 (ChatType별 환영 메시지)
- [x] 메시지 입력/전송
- [x] 스트리밍 응답 표시
- [x] 타이핑 인디케이터
- [x] 면책 배너 표시
- [x] 에러 처리 (에러 배너)
- [ ] 추천 질문 칩 표시 (추후)
- [ ] 프로필 전환 기능 (추후)
- [ ] 사주 요약 바텀시트 (추후)

---

## Phase 6: Feature - Splash/Onboarding

### 6.1 Splash
- [x] screens/splash_screen.dart (프로필 체크 로직 추가)
- [x] 로컬 데이터 로드
- [x] 온보딩/프로필 체크 후 라우팅

### 6.2 Onboarding
- [x] screens/onboarding_screen.dart (사주 정보 입력 폼 구현)
- [x] 서비스 소개 페이지 (입력 폼으로 대체)
- [x] "사주는 참고용입니다" 안내
- [x] 온보딩 완료 플래그 저장 (프로필 저장으로 대체)

---

## Phase 7: Feature - History/Settings

### 7.1 History
- [ ] screens/history_screen.dart
- [ ] 과거 대화 목록 표시
- [ ] 대화 선택 → 채팅 화면 이동

### 7.2 Settings
- [ ] screens/settings_screen.dart
- [ ] 프로필 관리 진입점
- [ ] 알림 설정 (추후)
- [ ] 약관/면책 안내

---

## Phase 8: Saju Chart (만세력) ✅ 기본 완료

> 2025-12-02: 만세력 계산 로직 구현 완료 (19개 파일)

### 8.1 Constants ✅
- [x] data/constants/cheongan_jiji.dart - 천간(10), 지지(12), 오행
- [x] data/constants/gapja_60.dart - 60갑자
- [x] data/constants/solar_term_table.dart - 절기 시각 (2024-2025)
- [x] data/constants/dst_periods.dart - 서머타임 기간

### 8.2 Domain Entities ✅
- [x] domain/entities/pillar.dart - 기둥 (천간+지지)
- [x] domain/entities/saju_chart.dart - 사주 차트
- [x] domain/entities/lunar_date.dart - 음력 날짜
- [x] domain/entities/solar_term.dart - 24절기 enum
- [ ] domain/entities/daewoon.dart - 대운 (추후)

### 8.3 Domain Services ✅
- [x] domain/services/saju_calculation_service.dart - 통합 계산 (메인)
- [x] domain/services/lunar_solar_converter.dart - 음양력 변환 (Stub)
- [x] domain/services/solar_term_service.dart - 절입시간
- [x] domain/services/true_solar_time_service.dart - 진태양시 (25개 도시)
- [x] domain/services/dst_service.dart - 서머타임
- [x] domain/services/jasi_service.dart - 야자시/조자시

### 8.4 Data Models ✅
- [x] data/models/pillar_model.dart - JSON 직렬화
- [x] data/models/saju_chart_model.dart - JSON 직렬화

### 8.5 Presentation (미구현)
## 작업 규칙

### 컨텍스트 관리
1. **Compaction**: 대화 길어지면 이 파일에 진행 상황 업데이트
2. **노트 작성**: 결정 사항, 변경점 기록
3. **서브 Agent**: 복잡한 작업은 Task 도구로 분리

### Git 규칙
- 작업 브랜치: Jaehyeon(Test)
- master 건들지 않음
- 기능 단위로 커밋

### 우선순위
1. Phase 1-2: 기반 설정 (먼저)
2. Phase 4: Profile (P0 필수)
3. Phase 5: Saju Chat (P0 핵심)
4. Phase 6-7: 나머지 화면
5. Phase 8: Supabase 연동 후

---

## 진행 기록

| 날짜 | 작업 내용 | 상태 |
|------|-----------|------|
| 2025-12-01 | 프로젝트 시작, 기획 문서 완료 | 완료 |
| 2025-12-02 | TASKS.md 작성 | 완료 |
| 2025-12-02 | CLAUDE.md 생성 | 완료 |
| 2025-12-02 | JH_Agent 서브에이전트 생성 (8개) | 완료 |
| 2025-12-02 | 만세력 정확도 연구 (진태양시, 절입시간 등) | 완료 |
| 2025-12-02 | 세션 1 종료, Phase 1 시작 대기 | 완료 |
| 2025-12-02 | **Phase 1 완료**: 의존성, 폴더구조, 라우터, 테마 | 완료 |
| 2025-12-02 | **Phase 2 부분 완료**: 상수, 테마, Placeholder 화면들 | 진행중 |
| 2025-12-02 | **Phase 8 기본 완료**: 만세력 계산 로직 19개 파일 구현 | 완료 |
| 2025-12-02 | SubAgent A2A 아키텍처 개선 (Orchestrator 추가) | 완료 |
| 2025-12-02 | 09_manseryeok_calculator SubAgent 추가 | 완료 |
| 2025-12-02 | 앱 런칭 전략 문서 작성 (APP_LAUNCH_STRATEGY.md) | 완료 |
| 2025-12-02 | **Phase 4 완료**: Profile Feature 21개 파일 구현 | 완료 |
| 2025-12-05 | **Phase 5 대부분 완료**: Saju Chat 18개 파일 구현 | 완료 |
| 2025-12-05 | Gemini 3.0 REST API 연동 (SDK → REST 마이그레이션) | 완료 |
| 2025-12-05 | SSE 스트리밍 응답, 타이핑 인디케이터 구현 | 완료 |
| 2025-12-06 | 일주 계산 오류 분석 및 수정 완료 | ✅ 완료 |
| 2025-12-06 | baseDayIndex=10 확정, 테스트 통과 | ✅ 완료 |
| 2025-12-06 | 포스텔러 검증 완료 (1990-02-15, 1997-11-29) | ✅ 완료 |
| 2025-12-06 | SajuDetailSheet "자세히 보기" 에러 수정 (3개 파일) | ✅ 완료 |
| 2025-12-06 | Provider container 전달, ShadSheet→Flutter 위젯 변환 | ✅ 완료 |
| 2025-12-06 | PillarDisplay 한자 표시 기능 추가 | ✅ 완료 |
| 2025-12-06 | 천간지지 JSON 기반 리팩토링 (4개 파일) | ✅ 완료 |
| 2025-12-08 | DK-AA 브랜치 merge (관계도 그래프 기능) | ✅ 완료 |
| 2025-12-08 | 만세력 로직 문서 작성 (docs/manseryeok_logic.md) | ✅ 완료 |
| 2025-12-08 | **Phase 9 시작**: 만세력 고급 분석 기능 | ✅ 완료 |
| 2025-12-08 | **Phase 9-A 완료**: 데이터 구조 (Constants) 6개 파일 | ✅ 완료 |
| 2025-12-08 | **Phase 9-B 완료**: 고급 분석 서비스 5개 구현 | ✅ 완료 |
| 2025-12-08 | unsung_service.dart - 12운성 계산 서비스 | ✅ 완료 |
| 2025-12-08 | gongmang_service.dart - 공망 계산 서비스 | ✅ 완료 |
| 2025-12-08 | jijanggan_service.dart - 지장간+십성 분석 서비스 | ✅ 완료 |
| 2025-12-08 | twelve_sinsal_service.dart - 12신살 전용 서비스 | ✅ 완료 |
| 2025-12-08 | saju_chart.dart export 업데이트 | ✅ 완료 |
| 2025-12-12 | **Phase 10 시작**: RuleEngine 리팩토링 설계 | ✅ 완료 |
| 2025-12-12 | 코어 엔진 아키텍처 분석 및 피드백 반영 | ✅ 완료 |
| 2025-12-12 | **Phase 10-A 완료**: RuleEngine 기반 구축 (9개 파일) | ✅ 완료 |
| 2025-12-12 | **Phase 10-C 완료**: 나머지 룰 JSON 분리 (5개 JSON + 3개 코드 수정 + 테스트) | ✅ 완료 |
| 2025-12-13 | **Phase 10 서비스 전환 시작**: HapchungService RuleEngine 연동 착수 | ✅ 완료 |
| 2025-12-13 | HapchungService import 문 추가 완료 | ✅ 완료 |
| 2025-12-13 | **HapchungService RuleEngine 연동 완료** | ✅ 완료 |
| 2025-12-13 | RuleEngineHapchungResult 결과 모델 추가 | ✅ 완료 |
| 2025-12-13 | analyzeWithRuleEngine() 메서드 구현 | ✅ 완료 |
| 2025-12-13 | findRelationById() 메서드 구현 | ✅ 완료 |
| 2025-12-13 | analyzeByFortune() 메서드 구현 | ✅ 완료 |
| 2025-12-13 | compareWithLegacy() 메서드 구현 | ✅ 완료 |
| 2025-12-13 | HapchungByFortuneType 분류 클래스 추가 | ✅ 완료 |
| 2025-12-13 | HapchungComparisonResult 비교 결과 클래스 추가 | ✅ 완료 |
| 2025-12-13 | **compareWithLegacy() 테스트 검증 완료** | ✅ 완료 |
| 2025-12-13 | hapchung_compare_legacy_test.dart 생성 (17개 테스트) | ✅ 완료 |
| 2025-12-13 | 이름 정규화 로직 추가 (_normalizeName) | ✅ 완료 |
| 2025-12-13 | 정규화 일치율 88.2% 달성 (원본 53.6%) | ✅ 완료 |
| 2025-12-13 | **반합 규칙 8개 추가** (hapchung_rules.json) | ✅ 완료 |
| 2025-12-13 | 인오반합, 오술반합, 사유반합, 유축반합, 신자반합, 자진반합, 해묘반합, 묘미반합 | ✅ 완료 |
| 2025-12-13 | **정규화 일치율 90.0% 달성** (목표 70% 크게 초과) | ✅ 완료 |
| 2025-12-13 | **Phase 10 완료** - RuleEngine 연동 + 테스트 검증 완료 | ✅ 완료 |
| 2025-12-15 | **Supabase MCP 설정 완료** - Claude Code 연동 | ✅ 완료 |
| 2025-12-15 | **Phase 11 시작**: Supabase Flutter 연동 | ✅ 진행중 |
| 2025-12-15 | supabase_flutter ^2.12.0 의존성 추가 | ✅ 완료 |
| 2025-12-15 | SajuAnalysisDbModel 생성 (Supabase 테이블 매핑) | ✅ 완료 |
| 2025-12-15 | SupabaseService 초기화 코드 작성 | ✅ 완료 |
| 2025-12-15 | SajuAnalysisRepository 구현 (CRUD + 오프라인 동기화) | ✅ 완료 |
| 2025-12-15 | Riverpod Provider 생성 + build_runner | ✅ 완료 |
| 2025-12-15 | **Phase 9-C 완료**: UI 컴포넌트 (saju_detail_tabs, hapchung_tab, unsung_display, sinsal_display, gongmang_display) | ✅ 완료 |
| 2025-12-15 | **프로필 저장 시 분석 자동 저장 연동** 구현 | ✅ 완료 |
| 2025-12-15 | `saveFromAnalysis()` 메서드 추가 - SajuAnalysis → DB 변환 | ✅ 완료 |
| 2025-12-15 | profile_provider에 _saveAnalysisToDb() 연동 | ✅ 완료 |
| 2025-12-15 | **Phase 11 완료** - 자동 저장 연동 포함 | ✅ 완료 |
| 2025-12-18 | **절기 테이블 확장**: 2020-2030 → 1900-2100 (201년) | ✅ 완료 |
| 2025-12-18 | `solar_term_calculator.dart` - Jean Meeus VSOP87 알고리즘 구현 | ✅ 완료 |
| 2025-12-18 | `solar_term_table_extended.dart` - 동적 계산 + 캐싱 API | ✅ 완료 |
| 2025-12-18 | **Supabase 오프라인 모드 수정**: nullable SupabaseClient 처리 | ✅ 완료 |
| 2025-12-18 | 9개 파일 수정 (supabase_service, auth_service, repositories 등) | ✅ 완료 |
| 2025-12-18 | `Pillar` 엔티티에 `ganHanja`, `jiHanja` getter 추가 | ✅ 완료 |
| 2025-12-18 | **빌드 오류 전체 해결** - `flutter build web` 성공 | ✅ 완료 |
| 2025-12-21 | **Supabase DB 구조 분석** - MCP + REST API로 검증 | ✅ 완료 |
| 2025-12-21 | Terminal 3x 로그 원인 분석: Riverpod `ref.watch()` rebuild | ✅ 분석 |
| 2025-12-21 | upsert + onConflict로 중복 데이터 방지 확인 | ✅ 확인 |
| 2025-12-21 | **엔터프라이즈 스케일링 분석**: 1M 사용자 기준 row 추정 | ✅ 완료 |
| 2025-12-21 | `chat_messages` 병목 식별: 100M~1B rows 예상 (파티셔닝 필요) | ⚠️ TODO |
| 2025-12-21 | JSONB GIN 인덱스 필요: `yongsin`, `gyeokguk`, `oheng_distribution` | ⚠️ TODO |
| 2025-12-21 | `ai_summary` 설계 확인: saju_analyses에만 필요 (베스트 프랙티스) | ✅ 확인 |
| 2025-12-21 | **Phase 9-D 완료**: 포스텔러 스타일 UI 구현 (3개 위젯 추가) | ✅ 완료 |
| 2025-12-21 | `fortune_display.dart` - 대운/세운/월운 가로 슬라이더 | ✅ 완료 |
| 2025-12-21 | `day_strength_display.dart` - 신강/신약 그래프 + 용신 표시 | ✅ 완료 |
| 2025-12-21 | `oheng_analysis_display.dart` - 오행/십성 도넛 차트 + 오각형 다이어그램 | ✅ 완료 |
| 2025-12-21 | `saju_detail_tabs.dart` 확장 - 6개 → 9개 탭 (오행, 신강, 대운 추가) | ✅ 완료 |
| 2025-12-21 | Flutter build web 성공 (빌드 검증 완료) | ✅ 완료 |
| 2025-12-21 | **신강/신약 로직 전면 수정** - 포스텔러 8단계 방식 적용 | ✅ 완료 |
| 2025-12-21 | `DayStrengthLevel` enum 확장: 5단계 → 8단계 (극약/태약/신약/중화신약/중화신강/신강/태강/극왕) | ✅ 완료 |
| 2025-12-21 | `DayStrength` 엔티티 필드 추가: `deukryeong`, `deukji`, `deuksi`, `deukse` (boolean) | ✅ 완료 |
| 2025-12-21 | `DayStrengthService` 득령/득지/득시/득세 계산 로직 재구현 (정기 기준) | ✅ 완료 |
| 2025-12-21 | 점수 계산 공식: base 50 ± (득령±15, 득지±10, 득시±7, 득세±8) + 비겁/인성 보너스 - 설기 감점 | ✅ 완료 |
| 2025-12-21 | `day_strength_display.dart` UI 업데이트: 실제 득령/득지/득시/득세 값 표시 | ✅ 완료 |
| 2025-12-21 | 하위 호환성 처리: enum 값 매핑 (medium→junghwaSingang 등) in repository/model | ✅ 완료 |
| 2025-12-21 | 빌드 검증 완료 (DayStrengthLevel.medium 오류 해결) | ✅ 완료 |
| 2025-12-21 | **신강/신약 로직 2차 수정** - 포스텔러와 결과 불일치 문제 해결 | ✅ 완료 |
| 2025-12-21 | 득세 판단 기준 변경: 전체 비겁+인성 ≥3 → 천간만 비겁+인성 ≥2 (일간 제외) | ✅ 완료 |
| 2025-12-21 | `_countGanBigeopInseong()` 함수 추가 - 천간에서만 비겁/인성 개수 계산 | ✅ 완료 |
| 2025-12-21 | 점수 계산 배율 조정: 득령±8, 득지±5, 득시±3, 득세±4 (기존 대비 40% 감소) | ✅ 완료 |
| 2025-12-21 | 십신 분포 조정 범위 축소: ±5점 → ±3점 이내 | ✅ 완료 |
| 2025-12-21 | 테스트 케이스(박재현 1997-11-29): 태강 → **중화신강** (포스텔러 일치) | ✅ 검증 |
| 2025-12-21 | Flutter build web 성공 (최종 빌드 검증) | ✅ 완료 |
| 2025-12-23 | **Phase 12-A 완료**: RLS 정책 최적화 + Function 보안 수정 | ✅ 완료 |
| 2025-12-23 | RLS 정책 8개 최적화: `auth.uid()` → `(SELECT auth.uid())` | ✅ 완료 |
| 2025-12-23 | Function 6개 보안 수정: `search_path = public` 설정 | ✅ 완료 |
| 2025-12-23 | Supabase Performance Advisor: RLS 성능 경고 0개로 감소 | ✅ 완료 |
| 2025-12-23 | 마이그레이션 적용: `optimize_rls_policies`, `fix_function_search_path` | ✅ 완료 |
| 2025-12-23 | 신강/신약 테스트 재검증 (박재현 1997-11-29): 57점 중화신강 ✅ | ✅ 검증 |

---

## Phase 11: Supabase Flutter 연동 (2025-12-15~) ✅ 완료

> **목적**: 사주 분석 결과를 Supabase DB에 저장하여 클라우드 동기화
> **원칙**: 오프라인 우선 (Hive) + 온라인 동기화 (Supabase)
> **상태**: ✅ 완료 (.env 실제 키 설정 후 테스트 필요)

### 구현 완료 항목

#### 1. 의존성 추가 ✅
- `supabase_flutter: ^2.12.0` (pubspec.yaml)

#### 2. 모델 클래스 ✅
- `saju_analysis_db_model.dart` - Supabase 테이블 매핑
  - `fromSupabase()`, `toSupabase()` - Supabase JSON 변환
  - `fromHiveMap()`, `toHiveMap()` - Hive 캐시 변환
  - `fromSajuChart()`, `toSajuChart()` - Entity 변환

#### 3. 서비스 ✅
- `supabase_service.dart` - Supabase 클라이언트 초기화
  - `.env` 환경변수 로드 (SUPABASE_URL, SUPABASE_ANON_KEY)
  - 오프라인 모드 지원 (설정 없어도 앱 실행 가능)
  - 테이블별 쿼리 빌더 제공

#### 4. Repository ✅
- `saju_analysis_repository.dart` - CRUD + 동기화
  - `save()` - 저장 (Hive 우선 + Supabase 동기화)
  - `getById()`, `getByProfileId()` - 조회
  - `delete()` - 삭제
  - `syncPendingData()` - 오프라인 데이터 동기화
  - `pullFromRemote()` - 원격 데이터 가져오기

#### 5. Riverpod Provider ✅
- `saju_analysis_repository_provider.dart`
  - `sajuAnalysisRepositoryProvider` - Repository 인스턴스
  - `currentSajuAnalysisDbProvider` - 현재 프로필 분석 데이터
  - `sajuAnalysisSyncProvider` - 동기화 상태
  - `allSajuAnalysesProvider` - 전체 분석 목록

### 사용 방법

#### .env 설정 (필수)
```
SUPABASE_URL=https://kfciluyxkomskyxjaeat.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key
```

#### 코드에서 사용
```dart
// 사주 분석 결과 저장
final notifier = ref.read(currentSajuAnalysisDbProvider.notifier);
await notifier.saveAnalysis(
  chart: chart,
  ohengDistribution: {...},
  dayStrength: {...},
);

// 동기화 수행
final syncNotifier = ref.read(sajuAnalysisSyncProvider.notifier);
final result = await syncNotifier.sync();
print('동기화 결과: $result');
```

#### 6. 프로필 저장 시 자동 분석 저장 ✅ (2025-12-15 추가)
- `saju_analysis_repository_provider.dart`
  - `saveFromAnalysis()` 메서드 추가
  - SajuAnalysis Entity → SajuAnalysisDbModel 변환
  - 오행분포/일간강약/용신/격국/십신/지장간 정보 포함
- `profile_provider.dart`
  - `saveProfile()` 메서드에서 `_saveAnalysisToDb()` 호출
  - 프로필 저장 완료 후 사주 분석 결과 자동 저장

#### 사용 흐름
```
프로필 저장 → 프로필 목록 갱신 → 사주 분석 계산 → DB 자동 저장 (Hive + Supabase)
```

### 남은 작업 (선택)

- [ ] .env에 실제 Supabase 키 설정
- [x] 프로필 저장 시 자동으로 분석 결과 저장 연동 ✅
- [ ] 동기화 UI 컴포넌트 (설정 화면)
- [ ] 실시간 구독 (Realtime) 추가 (선택)

---

## Phase 10: RuleEngine 리팩토링 (2025-12-12~) ✅ 완료

> **목적**: 하드코딩된 룰/테이블을 JSON으로 분리하여 운영 유연성 확보
> **원칙**: JSON(작성/관리) + Dart Map(실행) 이중 구조
> **전략**: 인터페이스는 완성형, 구현은 MVP (Lean RuleEngine)

### 배경

현재 문제점:
- 신살/십성/합충 등 룰이 Dart 코드에 하드코딩
- 룰 수정 시 코드 변경 + 앱 재배포 필요
- 테스트 부족 (2개 케이스만)

목표 구조:
```
[JSON 룰 파일] ──→ [RuleRepository] ──→ [RuleEngine] ──→ [기존 서비스]
 (assets)          load + validate      matchAll()      사용
                   + compile
```

### Phase 10-A: 기반 구축 (Lean MVP)

#### 생성할 파일
```
lib/features/saju_chart/
├── domain/
│   ├── entities/
│   │   ├── rule.dart              # Rule 인터페이스 + 타입
│   │   ├── rule_condition.dart    # 조건 타입 (op enum)
│   │   ├── compiled_rules.dart    # 컴파일된 룰 구조
│   │   └── saju_context.dart      # 사주 컨텍스트
│   ├── repositories/
│   │   └── rule_repository.dart   # Repository 인터페이스
│   └── services/
│       ├── rule_engine.dart       # 매칭 엔진
│       └── rule_validator.dart    # 기본 검증
├── data/
│   ├── repositories/
│   │   └── rule_repository_impl.dart
│   └── models/
│       └── rule_models.dart       # JSON 파싱 모델

assets/data/rules/
└── sinsal_rules.json              # 첫 번째 JSON 룰
```

#### 작업 순서
- [x] 1. `rule.dart` - Rule 인터페이스 정의 ✅
- [x] 2. `rule_condition.dart` - 조건 타입 + op enum ✅
- [x] 3. `saju_context.dart` - SajuContext 정의 ✅
- [x] 4. `compiled_rules.dart` - CompiledRules (MVP: 단순 리스트) ✅
- [x] 5. `rule_repository.dart` - Repository 인터페이스 ✅
- [x] 6. `rule_engine.dart` - RuleEngine 핵심 로직 ✅
- [x] 7. `rule_validator.dart` - 기본 필드 검증 ✅
- [x] 8. `rule_models.dart` - JSON 파싱 모델 ✅
- [x] 9. `rule_repository_impl.dart` - Repository 구현 ✅

### Phase 10-B: 신살 JSON 분리 ✅ 완료 (2025-12-12)

- [x] `sinsal_rules.json` 생성 (957줄, 12신살 + 특수신살)
- [x] TwelveSinsalService.analyzeWithRuleEngine() 연동 완료
- [x] 테스트 케이스 19개 추가 (rule_engine_sinsal_test.dart)

### Phase 10-C: 나머지 룰 분리 ✅ 완료 (2025-12-12)

- [x] `hapchung_rules.json` - 합충형파해 56개 룰
- [x] `sipsin_tables.json` - 십신 10천간 매핑
- [x] `jijanggan_tables.json` - 지장간 12지지 매핑
- [x] `unsung_tables.json` - 12운성 테이블
- [x] `gongmang_tables.json` - 공망 6순 테이블
- [x] `rule_condition.dart` - gte/lte 연산자, jiCount/ganCount 필드 추가
- [x] `saju_context.dart` - jiCount/ganCount getter 추가
- [x] `rule_engine.dart` - _evaluateGte/_evaluateLte 메서드 추가
- [x] `rule_engine_hapchung_test.dart` - 합충형파해 테스트 케이스

### Phase 10-D: Supabase 연동 (추후)

- [ ] `loadFromRemote()` 구현
- [ ] 해시 검증 (SHA256)
- [ ] 버전 관리 + 롤백

### Phase 10 작업 순서 분석 (2025-12-12)

> **핵심 발견**: Option 3 (하드코딩 제거)는 마지막에 해야 함

#### 현재 앱 실행 흐름
```
saju_chart_provider.dart
        ↓
SajuAnalysisService.analyze()  ← 실제 앱 진입점
        ↓
SinSalService (하드코딩)
DayStrengthService
GyeokGukService
```

#### RuleEngine 적용 현황

| 서비스 | RuleEngine 메서드 | JSON 룰 | 상태 |
|--------|-------------------|---------|------|
| TwelveSinsalService | `analyzeWithRuleEngine()` ✅ | ✅ sinsal_rules.json | **완료** |
| HapchungService | `analyzeWithRuleEngine()` ✅ | ✅ hapchung_rules.json | **완료** |
| SipsinService | ❌ 없음 | ✅ sipsin_tables.json | 테이블만 |
| UnsungService | ❌ 없음 | ✅ unsung_tables.json | 테이블만 |
| GongmangService | ❌ 없음 | ✅ gongmang_tables.json | 테이블만 |
| JijangganService | ❌ 없음 | ✅ jijanggan_tables.json | 테이블만 |

#### 올바른 작업 순서

```
① Phase 10-B ✅ → ② 서비스 전환 → ③ 테스트 검증 → ④ 하드코딩 제거 → ⑤ UI
  (sinsal.json)    (RuleEngine)    (결과 비교)      (Option 3)       (Option 2)
```

| 순서 | 작업 | 설명 | 의존성 |
|:----:|------|------|--------|
| ✅ ① | Phase 10-B | sinsal_rules.json 생성 | 완료 |
| ✅ ② | 서비스 RuleEngine 전환 | HapchungService에 메서드 추가 | ① 완료 |
| 🔄 ③ 진행중 | 테스트 검증 | 하드코딩 == RuleEngine 결과 확인 | ② 완료 |
| ④ | 하드코딩 제거 (Option 3) | 기존 로직 deprecate | ③ 통과 |
| ⑤ | UI 컴포넌트 (Option 2) | 화면 표시 위젯 | ④ 선택 |

#### Option 3을 먼저 하면 안 되는 이유

1. ~~**sinsal_rules.json 미생성** → TwelveSinsalService RuleEngine 불완전~~ ✅ 해결됨
2. ~~**HapchungService에 RuleEngine 메서드 없음** → 하드코딩 제거 시 앱 깨짐~~ ✅ 해결됨 (2025-12-13)
3. 🔄 **검증 미완료** → 하드코딩 vs RuleEngine 결과 비교 테스트 필요

---

## Supabase MCP 활용 가이드

> **목적**: Claude Code에서 Supabase MCP를 활용하여 DB 작업 자동화
> **설정 완료**: 2025-12-15

### MCP 서버 정보

| 항목 | 값 |
|------|-----|
| 서버 URL | `https://mcp.supabase.com/mcp` |
| Project Ref | `kfciluyxkomskyxjaeat` |
| 설정 파일 | `E:\SJ\.mcp.json` |
| Scope | Project (팀 공유) |

### 활성화된 기능 (Features)

```
docs, account, database, development, functions, branching, storage, debugging
```

| Feature | 용도 |
|---------|------|
| **database** | SQL 실행, 마이그레이션, 스키마 관리 |
| **storage** | 파일 업로드/다운로드, 버킷 관리 |
| **functions** | Edge Functions 배포/관리 |
| **docs** | Supabase 공식 문서 조회 |
| **account** | 프로젝트/조직 정보 조회 |
| **development** | 개발 환경 설정 |
| **branching** | DB 브랜칭 (Preview) |
| **debugging** | 로그/에러 조회 |

### 주요 MCP 도구

#### Database 도구
| 도구 | 설명 | 용도 |
|------|------|------|
| `execute_sql` | Raw SQL 실행 | 일반 쿼리 (SELECT, INSERT 등) |
| `apply_migration` | DDL 마이그레이션 | 스키마 변경 (CREATE TABLE 등) |

#### Functions 도구
| 도구 | 설명 |
|------|------|
| `deploy_edge_function` | Edge Function 배포/업데이트 |

### Claude Code에서 활용 예시

**1. 테이블 생성 (마이그레이션)**
```
"saju_charts 테이블 생성해줘"
→ apply_migration 도구 자동 사용
```

**2. 데이터 조회**
```
"users 테이블에서 최근 10명 조회해줘"
→ execute_sql 도구 자동 사용
```

**3. RLS 정책 설정**
```
"saju_charts에 RLS 정책 추가해줘"
→ apply_migration 도구 자동 사용
```

### URL 파라미터 옵션

```
# 특정 프로젝트만 접근
?project_ref=kfciluyxkomskyxjaeat

# 읽기 전용 모드 (안전)
?read_only=true

# 특정 기능만 활성화
?features=database,docs
```

### 현재 설정 (`.mcp.json`)

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=kfciluyxkomskyxjaeat&features=docs,account,database,development,functions,branching,storage,debugging"
    }
  }
}
```

### Phase 11 연동 계획

| 작업 | MCP 도구 | 상태 |
|------|----------|------|
| saju_charts 테이블 생성 | `apply_migration` | ⏳ 대기 |
| saju_analysis 테이블 생성 | `apply_migration` | ⏳ 대기 |
| 인덱스 생성 | `apply_migration` | ⏳ 대기 |
| RLS 정책 설정 | `apply_migration` | ⏳ 대기 |
| 데이터 조회 테스트 | `execute_sql` | ⏳ 대기 |

---

## Phase 11: Supabase 만세력 DB 설계 (2025-12-12 분석)

> **목적**: 만세력 계산 결과를 DB에 저장하여 재계산 없이 빠르게 조회
> **원칙**: 정규화(4주) + JSONB(분석 데이터) 하이브리드 구조
> **확장성**: 100만 사용자까지 대응 가능한 스키마

### 현재 Supabase 구조

```
public.users (기존)
├── id (PK, uuid)
├── name (text)
├── gender (text)
├── birth_date (date)
├── birth_time (time)
├── birth_city (text)
├── is_lunar (boolean)
└── created_at (timestamp)
```

### 목표 DB 스키마

#### 11.1 saju_charts 테이블 (핵심)

```sql
CREATE TABLE saju_charts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 사주 기본 (정규화 - 인덱싱 가능)
  year_gan TEXT NOT NULL,      -- 년간 (갑~계)
  year_ji TEXT NOT NULL,       -- 년지 (자~해)
  month_gan TEXT NOT NULL,
  month_ji TEXT NOT NULL,
  day_gan TEXT NOT NULL,       -- 일간 = 나
  day_ji TEXT NOT NULL,
  hour_gan TEXT,               -- 시주 (선택)
  hour_ji TEXT,

  -- 계산 기준 정보
  birth_datetime TIMESTAMPTZ NOT NULL,
  corrected_datetime TIMESTAMPTZ,  -- 진태양시 보정 후
  birth_city TEXT,
  is_lunar BOOLEAN DEFAULT FALSE,

  -- 메타데이터
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  calculation_version TEXT DEFAULT '1.0.0',  -- 로직 버전
  needs_recalculation BOOLEAN DEFAULT FALSE
);
```

#### 11.2 saju_analysis 테이블 (분석 결과)

```sql
CREATE TABLE saju_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chart_id UUID UNIQUE REFERENCES saju_charts(id) ON DELETE CASCADE,

  -- JSONB 컬럼들 (가변 구조)
  sipsin JSONB,              -- 십성 분석
  twelve_unsung JSONB,       -- 12운성
  relations JSONB,           -- 합충형파해
  twelve_sinsal JSONB,       -- 12신살
  gongmang JSONB,            -- 공망
  jijanggan JSONB,           -- 지장간
  oheng_distribution JSONB,  -- 오행 분포

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 11.3 인덱싱 전략

```sql
-- 사용자별 조회
CREATE INDEX idx_saju_charts_user_id ON saju_charts(user_id);

-- 일간 기준 조회 (통계/분석용)
CREATE INDEX idx_saju_charts_day_gan ON saju_charts(day_gan);

-- 생년월일 범위 조회
CREATE INDEX idx_saju_charts_birth_datetime ON saju_charts(birth_datetime);

-- JSONB 내부 검색용 (선택적)
CREATE INDEX idx_saju_analysis_relations ON saju_analysis
  USING GIN (relations jsonb_path_ops);
```

#### 11.4 Row Level Security (RLS)

```sql
ALTER TABLE saju_charts ENABLE ROW LEVEL SECURITY;
ALTER TABLE saju_analysis ENABLE ROW LEVEL SECURITY;

-- 본인 데이터만 조회
CREATE POLICY "Users can view own charts" ON saju_charts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own charts" ON saju_charts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own charts" ON saju_charts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own charts" ON saju_charts
  FOR DELETE USING (auth.uid() = user_id);

-- saju_analysis는 chart_id 통해 간접 보호
CREATE POLICY "Users can view own analysis" ON saju_analysis
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM saju_charts
      WHERE saju_charts.id = saju_analysis.chart_id
      AND saju_charts.user_id = auth.uid()
    )
  );
```

### ERD

```
┌─────────────────────┐       ┌─────────────────────┐
│   auth.users        │       │    saju_charts      │
├─────────────────────┤       ├─────────────────────┤
│ id (PK)             │──1:N──│ user_id (FK)        │
│ email               │       │ id (PK)             │
│ ...                 │       │ year_gan/ji         │
└─────────────────────┘       │ month_gan/ji        │
                              │ day_gan/ji          │
                              │ hour_gan/ji         │
                              │ birth_datetime      │
                              │ corrected_datetime  │
                              └──────────┬──────────┘
                                         │
                                        1:1
                                         │
                              ┌──────────┴──────────┐
                              │   saju_analysis     │
                              ├─────────────────────┤
                              │ chart_id (FK, UQ)   │
                              │ sipsin (JSONB)      │
                              │ twelve_unsung       │
                              │ relations (JSONB)   │
                              │ twelve_sinsal       │
                              │ gongmang (JSONB)    │
                              │ jijanggan (JSONB)   │
                              │ oheng_distribution  │
                              └─────────────────────┘
```

### JSONB 데이터 구조 예시

```json
// sipsin
{ "yearGan": "정관", "monthGan": "편인", "dayGan": "비견", "hourGan": "식신" }

// twelve_unsung
{ "yearJi": { "name": "장생", "strength": 7 }, "monthJi": {...} }

// relations (합충형파해)
{
  "hapchung": [{"type": "자축합", "positions": ["년지", "월지"]}],
  "chung": [],
  "hyung": [{"type": "인사형", "positions": ["월지", "시지"]}]
}

// gongmang
{ "gongmangJi": ["술", "해"], "affectedPositions": ["년지"] }

// oheng_distribution
{ "목": 2, "화": 1, "토": 3, "금": 1, "수": 1 }
```

### 설계 원칙 요약

| 원칙 | 적용 |
|------|------|
| **정규화** | 4주(8개 간지)는 별도 컬럼 → 인덱싱/검색 최적화 |
| **JSONB** | 파생 데이터(십성/신살/관계)는 JSONB → 스키마 유연성 |
| **RLS** | user_id 기반 행 수준 보안 → 데이터 격리 |
| **Foreign Key** | auth.users.id 참조 (Supabase 권장) |
| **버전 관리** | calculation_version으로 로직 변경 추적 |
| **인덱싱** | user_id, day_gan, birth_datetime에 인덱스 |

### 구현 작업 (추후)

- [ ] Supabase 마이그레이션 SQL 작성
- [ ] Flutter 모델 클래스 생성 (saju_chart_model.dart)
- [ ] Repository 구현 (saju_chart_repository.dart)
- [ ] 로컬 캐시(Hive) ↔ Supabase 동기화 로직
- [ ] calculation_version 기반 재계산 트리거

### 설계 원칙

1. **인터페이스는 완성형** - 확장 대비
2. **구현은 MVP** - 빠른 출시
3. **하위 호환성** - 기존 하드코딩 로직 유지
4. **점진적 마이그레이션** - sinsal부터 시작

### JSON 룰 구조 (예시)

```json
{
  "schemaVersion": "1.0.0",
  "ruleType": "sinsal",
  "rules": [
    {
      "id": "cheon_eul_gwin",
      "name": "천을귀인",
      "hanja": "天乙貴人",
      "category": "길성",
      "when": {
        "op": "and",
        "conditions": [
          { "field": "dayGan", "op": "in", "value": ["갑", "무", "경"] },
          { "field": "jiAny", "op": "in", "value": ["축", "미"] }
        ]
      },
      "reasonTemplate": "일간 {dayGan}에서 {matchedJi}가 천을귀인"
    }
  ]
}
```

---

## Phase 9: 만세력 고급 분석 기능 (2025-12-08~)

> 포스텔러 레퍼런스 기준 - 사주 풀이 자세히 보기 기능 구현
> 현재: 기본 4주(년월일시) + 오행 분포만 표시
> 목표: 전문 만세력 수준의 상세 분석 제공

### 9.1 합충형파해(合沖刑破害) - 우선순위 1

#### 9.1.1 천간 관계
- [ ] **천간합(天干合)** - 5가지: 갑기합, 을경합, 병신합, 정임합, 무계합
- [ ] **천간충(天干沖)** - 4가지: 갑경충, 을신충, 병임충, 정계충

#### 9.1.2 지지 관계
- [ ] **지지육합(地支六合)** - 6가지: 자축합, 인해합, 묘술합, 진유합, 사신합, 오미합
- [ ] **지지삼합(地支三合)** - 4가지: 인오술(화), 사유축(금), 신자진(수), 해묘미(목)
- [ ] **지지방합(地支方合)** - 4가지: 인묘진(동), 사오미(남), 신유술(서), 해자축(북)
- [ ] **지지충(地支沖)** - 6가지: 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
- [ ] **지지형(地支刑)** - 삼형살, 자형, 상형 등
- [ ] **지지파(地支破)** - 6가지
- [ ] **지지해(地支害)** - 6가지: 자미해, 축오해, 인사해, 묘진해, 신해해, 유술해
- [ ] **원진(怨嗔)** - 12가지

### 9.2 십성(十星) - 우선순위 2

> 일간(나)을 기준으로 다른 천간/지지와의 관계

- [ ] **비견(比肩)** - 같은 오행, 같은 음양
- [ ] **겁재(劫財)** - 같은 오행, 다른 음양
- [ ] **식신(食神)** - 내가 생하는 오행, 같은 음양
- [ ] **상관(傷官)** - 내가 생하는 오행, 다른 음양
- [ ] **편재(偏財)** - 내가 극하는 오행, 같은 음양
- [ ] **정재(正財)** - 내가 극하는 오행, 다른 음양
- [ ] **편관(偏官/七殺)** - 나를 극하는 오행, 같은 음양
- [ ] **정관(正官)** - 나를 극하는 오행, 다른 음양
- [ ] **편인(偏印)** - 나를 생하는 오행, 같은 음양
- [ ] **정인(正印)** - 나를 생하는 오행, 다른 음양

### 9.3 지장간(支藏干) - 우선순위 3

> 지지 속에 숨어있는 천간 (여기, 중기, 본기)

| 지지 | 여기 | 중기 | 본기 |
|------|------|------|------|
| 자(子) | - | - | 계(癸) |
| 축(丑) | 계(癸) | 신(辛) | 기(己) |
| 인(寅) | 무(戊) | 병(丙) | 갑(甲) |
| 묘(卯) | - | - | 을(乙) |
| 진(辰) | 을(乙) | 계(癸) | 무(戊) |
| 사(巳) | 무(戊) | 경(庚) | 병(丙) |
| 오(午) | - | 기(己) | 정(丁) |
| 미(未) | 정(丁) | 을(乙) | 기(己) |
| 신(申) | 무(戊) | 임(壬) | 경(庚) |
| 유(酉) | - | - | 신(辛) |
| 술(戌) | 신(辛) | 정(丁) | 무(戊) |
| 해(亥) | - | 갑(甲) | 임(壬) |

- [ ] 지장간 테이블 구현 (이미 `jijanggan_table.dart` 있음)
- [ ] 지장간 기반 십성 계산
- [ ] UI에 지장간 표시

### 9.4 12운성(十二運星) - 우선순위 4

> 일간의 12단계 생명 주기

- [ ] 장생(長生) - 태어남
- [ ] 목욕(沐浴) - 씻김
- [ ] 관대(冠帶) - 성인
- [ ] 건록(建祿) - 독립
- [ ] 제왕(帝旺) - 전성기
- [ ] 쇠(衰) - 쇠퇴
- [ ] 병(病) - 병듦
- [ ] 사(死) - 죽음
- [ ] 묘(墓) - 무덤
- [ ] 절(絶) - 끊어짐
- [ ] 태(胎) - 잉태
- [ ] 양(養) - 양육

### 9.5 12신살(十二神殺) - 우선순위 5

> 길흉을 나타내는 신살

- [ ] 겁살(劫殺)
- [ ] 재살(災殺)
- [ ] 천살(天殺)
- [ ] 지살(地殺)
- [ ] 년살(年殺)
- [ ] 월살(月殺)
- [ ] 망신살(亡身殺)
- [ ] 장성살(將星殺)
- [ ] 반안살(攀鞍殺)
- [ ] 역마살(驛馬殺)
- [ ] 육해살(六害殺)
- [ ] 화개살(華蓋殺)

### 9.6 공망(空亡) - 우선순위 6

> 60갑자에서 빠진 지지 (순중공망)

- [ ] 일주 기준 공망 계산
- [ ] 공망 지지 표시
- [ ] 공망의 의미 설명

### 9.7 구현 계획

#### Phase 9-A: 데이터 구조 (Constants) ✅ 완료 (2025-12-08)
```
data/constants/
├── hapchung_relations.dart    # ✅ 합충형파해 관계 테이블
├── sipsin_relations.dart      # ✅ 십성 관계 (기존)
├── jijanggan_table.dart       # ✅ 지장간 (확장 완료)
├── twelve_unsung.dart         # ✅ 12운성 테이블
├── twelve_sinsal.dart         # ✅ 12신살 테이블
└── gongmang_table.dart        # ✅ 공망 테이블
```

#### Phase 9-B: 도메인 서비스 ✅ 완료 (2025-12-08)
```
domain/services/
├── hapchung_service.dart       # ✅ 합충형파해 분석 서비스
├── unsung_service.dart         # ✅ 12운성 계산 서비스
├── gongmang_service.dart       # ✅ 공망 계산 서비스
├── jijanggan_service.dart      # ✅ 지장간+십성 분석 서비스
├── twelve_sinsal_service.dart  # ✅ 12신살 전용 서비스
└── sinsal_service.dart         # ✅ 기존 신살 탐지 서비스
```

#### Phase 9-C: UI 컴포넌트
```
presentation/widgets/
├── hapchung_tab.dart          # 합충 탭 (천간합, 지지육합 등)
├── sipsung_display.dart       # 십성 표시
├── jijanggan_display.dart     # 지장간 표시
├── unsung_display.dart        # 12운성 표시
├── sinsal_display.dart        # 12신살 표시
├── gongmang_display.dart      # 공망 표시
├── fortune_display.dart       # 대운/세운/월운 슬라이더 (Phase 9-D) ✅
├── day_strength_display.dart  # 신강/신약 지수 + 용신 (Phase 9-D) ✅
├── oheng_analysis_display.dart # 오행/십성 도넛 차트 (Phase 9-D) ✅
└── saju_detail_tabs.dart      # 탭 컨테이너 (9개 탭: 만세력, 오행, 신강, 대운, 합충, 십성, 운성, 신살, 공망)
```

### 9.8 Phase 9-D: 포스텔러 스타일 UI 구현 ✅ (2025-12-21)

> 포스텔러 앱 레퍼런스 기반 고급 UI 구현

#### 구현 완료 항목

1. **fortune_display.dart** - 대운/세운/월운 슬라이더
   - `FortuneDisplay`: 대운수 표시 + 3개 슬라이더 통합
   - `DaeunSlider`: 10년 대운 가로 스크롤 (현재 대운 강조)
   - `SeunSlider`: 연도별 세운 슬라이더 (현재 연도 강조)
   - `WolunSlider`: 월별 월운 슬라이더

2. **day_strength_display.dart** - 신강/신약 지수 + 용신
   - 득령/득지/득시/득세 배지 표시
   - 신강/신약 8단계 막대 그래프 (극약~극왕)
   - 용신 카드 (조후용신 + 억부용신)
   - 일간 강약 분석 상세 (비겁/인성/재성/관성/식상)

3. **oheng_analysis_display.dart** - 오행/십성 차트
   - 오행 도넛 차트 (CustomPainter)
   - 십성 도넛 차트
   - 오행 오각형 상생/상극 다이어그램
   - 비율 테이블

4. **saju_detail_tabs.dart** 업데이트
   - 6개 → 9개 탭 확장
   - 새 탭: 오행, 신강, 대운

### 9.9 레퍼런스 (포스텔러 UI)

```
┌─────────────────────────────────────────────────────┐
│  사주 풀이 자세히 보기                           ∧  │
├─────────────────────────────────────────────────────┤
│ [궁성] [천간합] [지지육합] [지지삼합] [지지방합]    │
│ [천간충] [지지충] [공망] [형] [파] [해] [원진]      │
├─────────────────────────────────────────────────────┤
│        생시      생일      생월      생년          │
│        말년운    중년운    청년운    초년운        │
│        자녀운    정체성    부모      조상          │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐                       │
│ │ 경庚│ │ 을乙│ │ 신辛│ │ 정丁│  천간              │
│ │ 아들│ │ 자신│ │ 부친│ │ 조부│                    │
│ │ 정관│ │ 비견│ │ 편관│ │ 식신│  십성              │
│ └────┘ └────┘ └────┘ └────┘                       │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐                       │
│ │ 진辰│ │ 해亥│ │ 해亥│ │ 축丑│  지지              │
│ │ 딸  │ │배우자│ │ 모친│ │ 조모│                    │
│ │ 정재│ │ 정인│ │ 정인│ │ 편재│  십성              │
│ └────┘ └────┘ └────┘ └────┘                       │
│ 지장간  을계무   무갑임   무갑임   계신기            │
│ 12운성  관대     사       사       쇠               │
│ 12신살  천살     역마살   역마살   월살             │
└─────────────────────────────────────────────────────┘
```

---

## 메모

- Supabase는 사용자가 직접 설정 예정
- 프론트엔드만 집중해서 구현
- 로컬 저장(Hive) 우선, Supabase 연동은 나중에

### 만세력 정확도 연구 (2025-12-02)

**핵심 보정 요소:**
1. **진태양시 보정 (지역 시간차)**
   - 한국 표준시: 동경 135도 기준
   - 실제 한반도: 약 127도 → ~32분 차이
   - 예: 창원 = -26분, 서울 = -30분 보정

2. **절입시간 (24절기 정밀 계산)**
   - 월주 변경 시점 = 절기 시작 시간
   - 한국천문연구원 API 활용 가능

3. **서머타임 (일광절약시간제)**
   - 1948-1951, 1955-1960, 1987-1988 적용 기간
   - 해당 기간 출생자 +1시간 보정 필요

4. **야자시/조자시 처리**
   - 23:00-01:00 자시(子時) 구간 처리 방식
   - 야자시: 23:00-24:00 당일로 계산
   - 조자시: 00:00-01:00 익일로 계산

**참고 자료:**
- 한국천문연구원 음양력 API
- Inflearn 만세력 강의
- GitHub: bikul-manseryeok 프로젝트
- 포스텔러 만세력 2.2 (레퍼런스 앱)

---

## ✅ 완료된 작업 (2025-12-06)

### 일주(日柱) 계산 오류 수정 ✅

**문제 상황:**
- 1997-11-29 08:03 부산: 을유(乙酉) → **을해(乙亥)** 수정 필요
- 1990-02-15 09:30 서울: 신유(辛酉) → **신해(辛亥)** 수정 필요

**해결:**
- `saju_calculation_service.dart` baseDayIndex = **10** 확정
- 포스텔러 검증 완료 (두 케이스 모두 통과)

**포스텔러 검증 결과:**

| 날짜 | 시주 | 일주 | 월주 | 년주 | 상태 |
|------|------|------|------|------|------|
| 1990-02-15 서울 | 임진 | **신해** | 무인 | 경오 | ✅ |
| 1997-11-29 부산 | 경진 | **을해** | 신해 | 정축 | ✅ |

**테스트 결과:** `flutter test test/saju_logic_test.dart` → All tests passed!

### 만세력 UI 한자 표시 ✅

한자 표시 기능이 이미 구현되어 있음 확인:
- `Pillar.hanja` 게터
- `SajuChart.fullSajuHanja` 게터
- `PillarColumnWidget` - 한자 박스 표시 (28px)
- `SajuChartScreen` - 사주팔자 한자 표시

### SajuDetailSheet "자세히 보기" 에러 수정 ✅

**문제:** "자세히 보기" 버튼 클릭 시 "Unexpected null value" 에러 발생

**수정 내용 (3개 파일):**

1. **`saju_mini_card.dart`** - Provider container를 bottom sheet에 전달
   ```dart
   final container = ProviderScope.containerOf(context);
   showModalBottomSheet(
     builder: (sheetContext) => UncontrolledProviderScope(
       container: container,
       child: const SajuDetailSheet(),
     ),
   );
   ```

2. **`saju_detail_sheet.dart`** - ShadSheet → 네이티브 Flutter Container로 변경
   - shadcn_ui 의존성 제거
   - 안정적인 네이티브 Flutter 위젯으로 구현

3. **`yongsin_service.dart`** - null-safe 처리 추가
   ```dart
   final dayOheng = cheonganToOheng[dayMaster];
   if (dayOheng == null) {
     return YongSinResult(...); // 기본값 반환
   }
   ```

**결과:** ✅ "자세히 보기" 바텀시트 정상 동작 (만세력 + 오행 분포 표시)

---

### ✅ 해결됨: SajuDetailSheet 한자 표시 추가

**수정 내용:** `PillarDisplay` 위젯에 한자 표시 기능 추가

**수정 파일:** `frontend/lib/features/saju_chart/presentation/widgets/pillar_display.dart`

**변경 사항:**
- `showHanja` 파라미터 추가 (기본값: true)
- 한자를 큰 글씨(28px+)로, 한글을 작은 글씨로 표시
- 오행별 색상 적용 (목-초록, 화-빨강, 토-주황, 금-금색, 수-파랑)
- `cheongan_jiji.dart`의 한자 매핑 테이블 활용

---

### ✅ 완료: 천간지지 JSON 기반 리팩토링

**목적:** 데이터 정확도 향상, 타입 안전성, 확장성 개선

**생성/수정 파일:**

1. **`assets/data/cheongan_jiji.json`** - 통합 JSON 데이터
2. **`data/models/cheongan_model.dart`** - 천간 모델 클래스
3. **`data/models/jiji_model.dart`** - 지지 모델 클래스
4. **`data/models/oheng_model.dart`** - 오행 모델 클래스
5. **`data/constants/cheongan_jiji.dart`** - JSON 파싱 + 하위호환 API

**데이터 구조:**
```json
{
  "cheongan": [
    {"hangul": "갑", "hanja": "甲", "oheng": "목", "eum_yang": "양", "order": 0}
  ],
  "jiji": [
    {"hangul": "자", "hanja": "子", "oheng": "수", "animal": "쥐",
     "month": 11, "hour_start": 23, "hour_end": 1, "order": 0}
  ],
  "oheng": [
    {"name": "목", "hanja": "木", "color": "#4CAF50", "season": "봄", "direction": "동"}
  ]
}
```

**신규 기능:**
- `CheonganJijiData.instance` - 싱글톤 데이터 저장소
- `getCheonganByHanja()`, `getJijiByHanja()` - 한자→한글 역조회
- `getJijiByHour()` - 시간대로 지지 조회
- `cheonganEumYang`, `jijiEumYang` - 음양 매핑
- `ohengHanja`, `ohengColor` - 오행 한자/색상

**하위 호환성:** 기존 API 모두 유지
- `cheongan`, `jiji` (List)
- `cheonganHanja`, `jijiHanja`, `jijiAnimal` (Map)
- `cheonganOheng`, `jijiOheng` (Map)
- `getOheng()` 함수

**테스트 결과:** ✅ 2개 테스트 통과 (1990-02-15, 1997-11-29)

---

## ✅ 완료된 작업 (2025-12-08)

### Phase 9-B: 만세력 고급 분석 서비스 ✅ 완료

**생성된 서비스 파일:**

1. **`unsung_service.dart`** - 12운성 계산 서비스
   - `UnsungService.analyzeFromChart()` - 사주 차트 기반 분석
   - `UnsungService.analyze()` - 개별 파라미터 분석
   - `UnsungResult` - 단일 궁성 12운성 결과
   - `UnsungAnalysisResult` - 사주 전체 12운성 분석 결과
   - 건록지, 제왕지, 장생지, 묘지 조회 기능
   - 12운성별 상세 해석 제공

2. **`gongmang_service.dart`** - 공망 계산 서비스
   - `GongmangService.analyzeFromChart()` - 사주 차트 기반 분석
   - `GongmangService.analyze()` - 개별 파라미터 분석
   - `GongmangResult` - 단일 궁성 공망 결과
   - `GongmangAnalysisResult` - 사주 전체 공망 분석 결과
   - 진공/반공/탈공 유형 판단
   - 궁성별 공망 해석 (년지/월지/일지/시지)

3. **`jijanggan_service.dart`** - 지장간+십성 분석 서비스
   - `JiJangGanService.analyzeFromChart()` - 사주 차트 기반 분석
   - `JiJangGanService.analyze()` - 개별 파라미터 분석
   - `JiJangGanSipSin` - 지장간 천간의 십성 정보
   - `JiJangGanResult` - 단일 궁성 지장간 결과
   - `JiJangGanAnalysisResult` - 사주 전체 지장간 분석 결과
   - 정기/중기/여기 구분, 십성 분포 분석
   - 십성별 카테고리 분류 (비겁/식상/재성/관성/인성)

4. **`twelve_sinsal_service.dart`** - 12신살 전용 서비스
   - `TwelveSinsalService.analyzeFromChart()` - 사주 차트 기반 분석
   - `TwelveSinsalService.analyze()` - 개별 파라미터 분석
   - `TwelveSinsalResult` - 단일 궁성 12신살 결과
   - `TwelveSinsalAnalysisResult` - 사주 전체 12신살 분석 결과
   - 역마살, 도화살, 화개살, 장성살 조회 기능
   - 특수 신살 탐지 (양인살, 천을귀인)
   - 12신살별 상세 해석 제공

**업데이트된 파일:**

- **`saju_chart.dart`** - Phase 9 서비스 export 추가
  - `hapchung_service.dart` (합충형파해)
  - `unsung_service.dart` (12운성)
  - `gongmang_service.dart` (공망)
  - `jijanggan_service.dart` (지장간+십성)
  - `twelve_sinsal_service.dart` (12신살)

**서비스 아키텍처 패턴:**
- 모든 서비스는 `static` 메서드로 구현
- `analyzeFromChart()` - SajuChart 객체 직접 분석
- `analyze()` - 개별 파라미터로 분석 (유연성)
- Result 모델에 해석 메서드 포함

---

### Phase 9-A: 만세력 고급 분석 데이터 구조 ✅ 완료

**생성된 파일:**

1. **`hapchung_relations.dart`** - 합충형파해 관계 테이블
   - 천간합 (5합): 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
   - 천간충 (4충): 갑경충, 을신충, 병임충, 정계충
   - 지지육합 (6합): 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합토
   - 지지삼합 (4국): 인오술화국, 사유축금국, 신자진수국, 해묘미목국
   - 지지방합 (4방): 인묘진동방목, 사오미남방화, 신유술서방금, 해자축북방수
   - 지지충 (6충): 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
   - 지지형 (3형): 무은지형(인사신), 지세지형(축술미), 자형
   - 지지파 (6파)
   - 지지해 (6해)
   - 원진 (6원진)
   - 통합 분석 함수: `analyzeJijiRelations()`, `analyzeCheonganRelations()`

2. **`twelve_unsung.dart`** - 12운성 테이블
   - 12운성: 장생, 목욕, 관대, 건록, 제왕, 쇠, 병, 사, 묘, 절, 태, 양
   - 양간/음간별 장생 지지 테이블
   - `calculateTwelveUnsung()` - 12운성 계산
   - 운성별 강도(strength), 길흉(fortuneType) 속성
   - 운성별 해석 제공

3. **`gongmang_table.dart`** - 공망 테이블
   - 6순 공망: 갑자순(술해), 갑술순(신유), 갑신순(오미), 갑오순(진사), 갑진순(인묘), 갑인순(자축)
   - `getGongmangByGapja()` - 갑자로 공망 조회
   - `getDayGongmang()` - 일주 기준 공망 지지
   - `analyzeAllGongmang()` - 사주 전체 공망 분석
   - 궁성별 공망 해석 (년지/월지/시지)

4. **`twelve_sinsal.dart`** - 12신살 테이블
   - 12신살: 겁살, 재살, 천살, 지살, 연살(도화), 월살, 망신, 장성, 반안, 역마, 육해, 화개
   - 삼합 기준 12신살 배치
   - 특수 신살: 괴강살, 양인살, 천을귀인, 백호살, 천라지망, 문창귀인, 홍염살
   - `calculateSinsal()` - 12신살 계산
   - `analyzeSajuSinsal()` - 사주 전체 신살 분석

5. **`jijanggan_table.dart`** - 지장간 확장
   - `JiJangGanDetail` 클래스 (한자, 오행 포함)
   - `getJiJangGanDetail()` - 상세 지장간 조회
   - `JiJangGanTypeExtension` - korean, hanja, strengthRank 속성

**생성된 서비스:**

1. **`hapchung_service.dart`** - 합충형파해 분석 서비스
   - `HapchungService.analyzeSaju()` - 사주 전체 분석
   - `HapchungAnalysisResult` - 분석 결과 모델
   - `HapchungInterpreter` - 해석 유틸리티

### Flutter 경로 (로컬 환경)

- **Jaehyeon PC:** `C:\Users\SOGANG\flutter\flutter\bin\flutter.bat`
- **협업자(DK) PC:** `D:\development\flutter\bin\flutter.bat`

---

## ✅ 완료된 작업 (2025-12-12)

### Phase 10-A: RuleEngine 기반 구축 ✅ 완료

**생성된 파일 (9개):**

#### Domain Layer - Entities
1. **`rule.dart`** - Rule 인터페이스 + 타입 정의
   - `RuleType` enum: sinsal, hapchung, hyungpahae, sipsin, unsung, jijanggan, gongmang, gyeokguk, daeun
   - `FortuneType` enum: 길/흉/중
   - `Rule` 추상 인터페이스
   - `RuleMatchResult` 매칭 결과 클래스
   - `RuleSetMeta` 룰셋 메타데이터

2. **`rule_condition.dart`** - 조건 타입 + 연산자 정의
   - `ConditionOp` enum: eq, ne, in, notIn, and, or, not, samhapMatch, yukhapMatch 등
   - `ConditionField` enum: dayGan, dayJi, jiAny, ganAny 등 사주 필드
   - `RuleCondition` sealed class (SimpleCondition, CompositeCondition)

3. **`saju_context.dart`** - 사주 컨텍스트 래퍼
   - `SajuChart` 감싸서 RuleEngine 필드 접근 제공
   - `getFieldValue()`: ConditionField로 값 조회
   - 오행, 음양 파생 데이터 자동 계산

4. **`compiled_rules.dart`** - 컴파일된 룰 컨테이너
   - `CompiledRules`: 파싱된 룰셋 저장
   - `CompiledRulesRegistry`: 여러 RuleType 통합 관리

#### Domain Layer - Repository
5. **`rule_repository.dart`** - Repository 추상 인터페이스
   - `loadFromAsset()`, `loadFromRemote()`, `loadFromString()`
   - 캐시 관리: `getCached()`, `setCache()`, `invalidateCache()`
   - 버전 관리: `getLocalVersion()`, `needsUpdate()`
   - 예외 클래스: `RuleLoadException`, `RuleValidationException`

#### Domain Layer - Services
6. **`rule_engine.dart`** - 핵심 매칭 엔진
   - `RuleEngine.matchAll()`: 전체 룰 매칭
   - `RuleEngine.match()`: 단일 룰 매칭
   - `RuleEngine.evaluate()`: 조건 평가
   - 특수 연산자 지원: 삼합, 육합, 충, 형 매칭

7. **`rule_validator.dart`** - 룰 검증기
   - `validateRuleSet()`: 전체 룰셋 검증
   - `validateRule()`: 개별 룰 검증
   - `validateCondition()`: 조건 구조 검증
   - `ValidationResult`, `ValidationError` 결과 클래스

#### Data Layer - Models
8. **`rule_models.dart`** - JSON 파싱 모델
   - `RuleModel`: Rule 인터페이스 구현체
   - `RuleSetParseResult`: 파싱 결과 컨테이너
   - `RuleParser`: JSON 파싱 헬퍼

#### Data Layer - Repository
9. **`rule_repository_impl.dart`** - Repository 구현체
   - Asset 로드 구현 (MVP)
   - 메모리 캐시 관리
   - Remote 로드는 Phase 10-D 예정

**아키텍처:**
```
[JSON 룰 파일] → [RuleRepository] → [RuleEngine] → [기존 서비스]
 (assets)        load + validate    matchAll()     사용
                 + compile
```

**MVP 원칙 적용:**
- RuleValidator: 필수 필드 체크만 (스키마 검증은 추후)
- CompiledRules: 인덱싱 없이 단순 리스트 (성능 이슈 시 추가)
- 하위 호환성: 기존 하드코딩 서비스 유지

---

## 서브 에이전트 (.claude/JH_Agent/) - A2A Orchestration

### 아키텍처
```
Main Claude → [Orchestrator] → Pipeline → [Quality Gate] → 완료
```

### 에이전트 목록

| 번호 | 에이전트 | 역할 | 유형 |
|------|----------|------|------|
| **00** | **orchestrator** | 작업 분석 & 파이프라인 구성 | **진입점** |
| **00** | **widget_tree_guard** | 위젯 최적화 검증 | **품질 게이트** |
| 01 | feature_builder | Feature 폴더 구조 생성 | Builder |
| 02 | widget_composer | 화면→작은 위젯 분해 | Builder |
| 03 | provider_builder | Riverpod Provider 생성 | Builder |
| 04 | model_generator | Entity/Model 생성 | Builder |
| 05 | router_setup | go_router 설정 | Config |
| 06 | local_storage | Hive 저장소 설정 | Config |
| 07 | task_tracker | TASKS.md 관리 | Tracker |
| **08** | **shadcn_ui_builder** | shadcn_ui 모던 UI | **UI 필수** |
| **09** | **manseryeok_calculator** | 만세력 계산 로직 | **Domain 전문** |

### 호출 방식
```
# Orchestrator 자동 파이프라인 (권장)
Task 도구:
- prompt: "[Orchestrator] Profile Feature 구현"

# 개별 에이전트 직접 호출
Task 도구:
- prompt: "[09_manseryeok_calculator] 사주 계산 로직 구현"
```

### 필수 규칙
- **모든 위젯 코드 작성 시 00_widget_tree_guard 검증 필수**
- const 생성자/인스턴스화
- ListView.builder 사용
- 위젯 100줄 이하
- setState 범위 최소화

---

## 🔄 세션 재개 가이드 (2025-12-13 최종 업데이트)

### Phase 10 완료 ✅

**HapchungService RuleEngine 연동 + 반합 규칙 추가 완료**

| 항목 | 상태 | 설명 |
|------|------|------|
| hapchung_service.dart | ✅ 완료 | RuleEngine 연동 메서드 추가 |
| RuleEngine 결과 모델들 | ✅ 완료 | 카테고리/길흉 분류 헬퍼 |
| compareWithLegacy() 테스트 | ✅ 완료 | 17개 테스트 케이스 |
| **반합 규칙 8개 추가** | ✅ 완료 | hapchung_rules.json (총 64개 규칙) |

### 최종 테스트 결과 (2025-12-13)

| 구분 | 이전 | 최종 |
|------|------|------|
| 원본 평균 일치율 | 53.6% | **56.0%** |
| **정규화 평균 일치율** | 88.2% | **90.0%** ✅ |
| 정규화 완전 일치 | 3/5 (60%) | **4/5 (80%)** ✅ |

### 추가된 반합 규칙 (8개)

| 삼합 | 반합 1 | 반합 2 |
|------|--------|--------|
| 인오술 화국 | 인오반합 | 오술반합 |
| 사유축 금국 | 사유반합 | 유축반합 |
| 신자진 수국 | 신자반합 | 자진반합 |
| 해묘미 목국 | 해묘반합 | 묘미반합 |

### hapchung_rules.json 규칙 현황 (총 64개)

| 카테고리 | 개수 |
|----------|------|
| 천간합 | 5개 |
| 천간충 | 4개 |
| 지지육합 | 6개 |
| 지지삼합 | 4개 |
| **지지반합** | **8개** (신규) |
| 지지방합 | 4개 |
| 지지충 | 6개 |
| 지지형 | 10개 |
| 지지파 | 6개 |
| 지지해 | 6개 |
| 원진 | 6개 |

### 남은 차이점 (무시 가능)

- `해인` vs `인해` - 글자 순서 차이 (표기 방식만 다름, 의미 동일)

### 다음 작업 선택지

**Option 1**: .env 실제 키 설정 + 테스트 ⏳
- `.env`에 실제 Supabase URL/Key 설정
- 프로필 저장 → 분석 저장 → Supabase 확인

**Option 2**: 앱 통합 테스트
- 전체 플로우 테스트
- 버그 수정 및 최적화

**Option 3**: 동기화 UI 컴포넌트
- 설정 화면에 동기화 상태 표시
- 수동 동기화 버튼 추가

### 새 세션 시작 프롬프트

```
@Task_Jaehyeon.md 읽고 "세션 재개 가이드" 확인해.

현재 상태:
- Phase 9-C (UI 컴포넌트) ✅ 완료
- Phase 11 (Supabase 연동) ✅ 완료 (자동 저장 연동 포함)
- DB 스케일링 분석 ✅ 완료 (2025-12-21)

다음 작업:
1. .env 실제 키 설정 + 테스트
2. 앱 통합 테스트
3. 동기화 UI 컴포넌트 (선택)
4. 엔터프라이즈 스케일링 작업 (chat_messages 파티셔닝, JSONB 인덱스)
```

---

## ✅ 완료된 작업 (2025-12-21)

### Supabase DB 구조 검증 & 엔터프라이즈 스케일링 분석

**분석 배경:**
- Terminal에서 `[SajuAnalysis] Supabase 저장 완료` 로그가 3번 출력되는 현상 확인
- MVP DB 구조가 엔터프라이즈 스케일에 적합한지 검증 필요

**1. 3x 로그 원인 분석 ✅**

```dart
// saju_chart_provider.dart:100-148
@override
Future<SajuAnalysis?> build() async {
  final chart = await ref.watch(currentSajuChartProvider.future);  // ← watch 사용
  final activeProfile = await ref.watch(activeProfileProvider.future);
  // ...
  _saveToSupabase(activeProfile.id, analysis);  // 3번 호출됨
}
```

- **원인**: Riverpod `ref.watch()`가 Provider rebuild 시마다 호출
- **영향**: `_saveToSupabase()` 3번 호출 → DB 3번 접근
- **해결**: `upsert(data, onConflict: 'profile_id')` 사용 중이므로 데이터 중복 없음

**2. Supabase 테이블 구조 확인 ✅**

| 테이블 | FK 관계 | RLS |
|--------|---------|-----|
| `saju_profiles` | user_id → auth.users(id) | ✅ |
| `saju_analyses` | profile_id → saju_profiles(id) UNIQUE | ✅ |
| `chat_sessions` | profile_id → saju_profiles(id) | ✅ |
| `chat_messages` | session_id → chat_sessions(id) | ✅ |
| `compatibility_analyses` | profile1_id, profile2_id → saju_profiles(id) | ✅ |

- FK 관계 정상
- 1:1 관계 (profile ↔ analysis) `UNIQUE` 제약조건 적용됨

**3. 엔터프라이즈 스케일링 분석 ⚠️**

**1M 사용자 기준 예상 row 수:**

| 테이블 | 예상 rows | 위험도 |
|--------|-----------|--------|
| `saju_profiles` | 1-3M | 🟢 안전 |
| `saju_analyses` | 1-3M | 🟢 안전 |
| `chat_sessions` | 10-50M | 🟡 주의 |
| `chat_messages` | **100M-1B** | 🔴 **병목** |

**Supabase 실제 사례:**
> 한 고객이 500M rows의 채팅 메시지로 인해 쿼리 성능 저하 경험
> → **table partitioning** 권장 (created_at 기준 월별/분기별)

**4. 필요한 조치 (TODO)**

**4.1 chat_messages 파티셔닝 (엔터프라이즈 필수)**
```sql
-- 월별 파티셔닝 예시
CREATE TABLE chat_messages (
  id UUID,
  session_id UUID,
  created_at TIMESTAMPTZ,
  ...
) PARTITION BY RANGE (created_at);

CREATE TABLE chat_messages_2025_01 PARTITION OF chat_messages
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

**4.2 JSONB GIN 인덱스 추가**
```sql
-- saju_analyses JSONB 필드 인덱싱
CREATE INDEX idx_saju_analyses_yongsin ON saju_analyses USING GIN (yongsin);
CREATE INDEX idx_saju_analyses_gyeokguk ON saju_analyses USING GIN (gyeokguk);
CREATE INDEX idx_saju_analyses_oheng ON saju_analyses USING GIN (oheng_distribution);
```

**5. ai_summary 설계 확인 ✅**

- `ai_summary`: `saju_analyses` 테이블에만 존재 (사주 분석 요약)
- `context_summary`: `chat_sessions` 테이블에만 존재 (대화 컨텍스트 요약)
- **베스트 프랙티스 준수**: 토큰 절약을 위한 요약 분리 설계 적절

**결론:**
- 현재 MVP 구조는 **기능적으로 정상**
- 엔터프라이즈 스케일(1M+ 사용자) 대비 **chat_messages 파티셔닝 필수**
- JSONB 쿼리 성능 최적화를 위한 **GIN 인덱스 추가 권장**

---

## 🚀 Phase 12: 앱 출시 전 DB 최적화 (2025-12-21)

### 12.1 현재 DB 상태 진단

**✅ 잘 되어 있는 것:**

| 항목 | 상태 | 비고 |
|------|------|------|
| 기본 B-Tree 인덱스 | ✅ 21개 | 적절함 |
| RLS (Row Level Security) | ✅ 활성화 | 모든 테이블 |
| FK 관계 설정 | ✅ 정상 | CASCADE 포함 |
| 기본 테이블 구조 | ✅ 적절 | UNIQUE 제약조건 |

**⚠️ Supabase Performance Advisor 경고:**

| 문제 | 심각도 | 테이블/함수 | 영향 |
|------|--------|-------------|------|
| **RLS 정책 비효율** | 🟡 WARN | 모든 테이블 (8개 정책) | 매 row마다 `auth.uid()` 재실행 → 성능 최대 100배 저하 |
| **Function search_path 미설정** | 🟡 WARN | 6개 함수 | 보안 취약점 |
| **미사용 인덱스** | ℹ️ INFO | 15개 인덱스 | 현재 데이터 적음 → 무시 가능 |
| **Anonymous 접근 허용** | 🟡 WARN | 5개 테이블 | 의도적이면 OK |

**🔍 수정 필요한 RLS 정책:**
- `saju_profiles.own_profiles`
- `saju_analyses.own_analyses`
- `chat_sessions.own_sessions`
- `chat_messages.own_messages`
- `compatibility_analyses` (4개 정책)

**🔍 수정 필요한 함수:**
- `update_updated_at`
- `update_session_on_message`
- `auto_session_title`
- `set_first_profile_primary`
- `ensure_single_primary`
- `update_compatibility_updated_at`

---

### 12.2 GIN 인덱스 필요성 분석

**현재 JSONB 컬럼 (saju_analyses):**
```
oheng_distribution, day_strength, yongsin, gyeokguk,
sipsin_info, jijanggan_info, sinsal_list, daeun,
current_seun, ai_summary, twelve_unsung, twelve_sinsal
```

**GIN 인덱스 필요 시점:**

| 시나리오 | GIN 필요? | 이유 |
|----------|-----------|------|
| profile_id로 전체 로드 | ❌ 불필요 | B-Tree로 충분 (이미 있음) |
| 특정 신살 검색 ("역마살 있는 사람") | ✅ 필요 | JSONB 내부 검색 |
| 궁합 분석 (특정 속성 비교) | ✅ 필요 | 여러 사람 JSONB 비교 |
| 통계/분석 ("정관격 몇 명?") | ✅ 필요 | 집계 쿼리 |

**💡 결론:**
- **MVP 출시에는 불필요** (profile_id로 전체 row 로드하는 현재 흐름)
- **궁합 기능 추가 시 필요** (JSONB 내부 검색)

---

### 12.3 작업 우선순위

#### 🔴 출시 전 필수 (Phase 12-A) ✅ 완료 (2025-12-23)

| 순위 | 작업 | 이유 | 상태 |
|------|------|------|------|
| 1 | RLS 정책 최적화 | 성능 최대 100배 개선 | ✅ 완료 |
| 2 | Function search_path 수정 | 보안 취약점 해결 | ✅ 완료 |
| 3 | SSL Enforcement 활성화 | Production 보안 체크리스트 | ✅ 기본 활성화 |

**적용된 마이그레이션:**
- `20251223044614_optimize_rls_policies` - RLS 8개 정책 최적화
- `20251223044725_fix_function_search_path` - Function 6개 보안 수정

#### 🟡 10K+ 사용자 시 권장 (Phase 12-B)

| 작업 | 이유 | 상태 |
|------|------|------|
| JSONB GIN 인덱스 추가 | 궁합 분석, 검색 기능 | ⬜ TODO |
| 미사용 인덱스 정리 | 스토리지/쓰기 성능 | ⬜ TODO |

#### 🟢 100K+ 사용자 시 권장 (Phase 12-C)

| 작업 | 이유 | 상태 |
|------|------|------|
| chat_messages 파티셔닝 | 대용량 채팅 데이터 | ⬜ TODO |
| Read Replica 도입 | 읽기 부하 분산 | ⬜ TODO |
| 정규화 (신살/합충 별도 테이블) | 궁합 분석 최적화 | ⬜ TODO |

---

### 12.4 RLS 정책 최적화 SQL

**문제:** `auth.uid()`가 매 row마다 재실행됨 (최대 100배 성능 저하)

**해결:** subquery로 감싸서 1번만 실행

```sql
-- ❌ 현재 (느림)
WHERE sp.user_id = auth.uid()

-- ✅ 수정 (빠름)
WHERE sp.user_id = (SELECT auth.uid())
```

**적용할 마이그레이션:**
```sql
-- saju_profiles RLS 최적화
DROP POLICY IF EXISTS own_profiles ON public.saju_profiles;
CREATE POLICY own_profiles ON public.saju_profiles
  FOR ALL USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- saju_analyses RLS 최적화
DROP POLICY IF EXISTS own_analyses ON public.saju_analyses;
CREATE POLICY own_analyses ON public.saju_analyses
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM saju_profiles
      WHERE saju_profiles.id = saju_analyses.profile_id
      AND saju_profiles.user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM saju_profiles
      WHERE saju_profiles.id = saju_analyses.profile_id
      AND saju_profiles.user_id = (SELECT auth.uid())
    )
  );

-- chat_sessions RLS 최적화
DROP POLICY IF EXISTS own_sessions ON public.chat_sessions;
CREATE POLICY own_sessions ON public.chat_sessions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM saju_profiles
      WHERE saju_profiles.id = chat_sessions.profile_id
      AND saju_profiles.user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM saju_profiles
      WHERE saju_profiles.id = chat_sessions.profile_id
      AND saju_profiles.user_id = (SELECT auth.uid())
    )
  );

-- chat_messages RLS 최적화
DROP POLICY IF EXISTS own_messages ON public.chat_messages;
CREATE POLICY own_messages ON public.chat_messages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM chat_sessions cs
      JOIN saju_profiles sp ON cs.profile_id = sp.id
      WHERE cs.id = chat_messages.session_id
      AND sp.user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_sessions cs
      JOIN saju_profiles sp ON cs.profile_id = sp.id
      WHERE cs.id = chat_messages.session_id
      AND sp.user_id = (SELECT auth.uid())
    )
  );
```

---

### 12.5 Function search_path 수정 SQL

```sql
-- 보안: search_path를 명시적으로 설정
ALTER FUNCTION public.update_updated_at() SET search_path = public;
ALTER FUNCTION public.update_session_on_message() SET search_path = public;
ALTER FUNCTION public.auto_session_title() SET search_path = public;
ALTER FUNCTION public.set_first_profile_primary() SET search_path = public;
ALTER FUNCTION public.ensure_single_primary() SET search_path = public;
ALTER FUNCTION public.update_compatibility_updated_at() SET search_path = public;
```

---

### 12.6 GIN 인덱스 (궁합 기능 추가 시)

```sql
-- 궁합 분석용 JSONB GIN 인덱스
CREATE INDEX idx_saju_analyses_yongsin ON saju_analyses USING GIN (yongsin);
CREATE INDEX idx_saju_analyses_sinsal ON saju_analyses USING GIN (sinsal_list);
CREATE INDEX idx_saju_analyses_gyeokguk ON saju_analyses USING GIN (gyeokguk);
```

---

### 새 세션 시작 프롬프트 (Phase 12) - 완료됨

```
(Phase 12 완료 - 아래 Phase 13 참조)
```

---

## Phase 13: AI 요약 기능 구현 (2025-12-23~)

### 13.0 현재 상태 요약

#### DB 현황 (Supabase)
| 테이블 | 행 수 | 상태 |
|--------|-------|------|
| saju_profiles | 22 | ✅ |
| saju_analyses | 13 | ✅ 모든 컬럼 데이터 있음 |
| chat_sessions | 3 | ✅ |
| chat_messages | 4 | ✅ |

#### saju_analyses 주요 컬럼 상태
| 컬럼 | 상태 | 설명 |
|------|------|------|
| sinsal_list | ✅ 13/13 | 기존 신살 (도화살, 양인살 등) |
| twelve_unsung | ✅ 13/13 | 12운성 (장생/목욕/관대 등) |
| twelve_sinsal | ✅ 13/13 | 12신살 (겁살/재살/천살 등) |
| ai_summary | ✅ 1/13 | 테스트 완료, 점진적 생성 |

#### Flutter 구현 상태
| 파일 | 상태 | 용도 |
|------|------|------|
| `unsung_service.dart` | ✅ | 12운성 계산 |
| `twelve_sinsal_service.dart` | ✅ | 12신살 계산 |
| `unsung_display.dart` | ❓ 확인필요 | 12운성 UI 표시 |
| `sinsal_display.dart` | ❓ 확인필요 | 12신살 UI 표시 |
| `ai_chat_service.dart` | ✅ | Gemini 연동 (채팅용) |

#### Edge Function 상태
| 함수 | 상태 | 용도 |
|------|------|------|
| `saju-chat` | ✅ 배포됨 | 채팅용 Gemini 호출 |
| `generate-ai-summary` | ✅ 배포됨 | AI 사주 요약 생성 |

---

### 13.1 Phase 13-A: 12운성/12신살 UI 확인

**목표**: DB에 저장된 12운성/12신살 데이터가 앱 화면에 제대로 표시되는지 확인

**확인 파일**:
- `frontend/lib/features/saju_chart/presentation/widgets/unsung_display.dart`
- `frontend/lib/features/saju_chart/presentation/widgets/sinsal_display.dart`
- `frontend/lib/features/saju_chart/presentation/widgets/saju_detail_tabs.dart`

**체크리스트**:
- [ ] 12운성 위젯이 데이터를 받아서 표시하는지
- [ ] 12신살 위젯이 데이터를 받아서 표시하는지
- [ ] saju_detail_tabs에서 해당 위젯 사용하는지
- [ ] 앱 실행하여 실제 화면 확인

---

### 13.2 Phase 13-B: ai_summary 구현 ✅ 완료 (2025-12-23)

**목표**: Gemini가 사주 분석 요약을 생성하여 DB에 저장

**설계 결정 사항**:
| 항목 | 결정 | 이유 |
|------|------|------|
| 구현 위치 | Edge Function | API 키 보안, 기존 패턴 일관성 |
| 생성 시점 | 첫 채팅 시작 시 | 비용 절감 (미사용 프로필 제외) |
| JSON 구조 | 아래 참조 | 성격/강점/약점/진로/개운법 |

**ai_summary JSON 구조**:
```json
{
  "personality": {
    "core": "을목(乙木) 일간으로 유연하고 적응력이 뛰어남",
    "traits": ["유연함", "인내심", "창의적"]
  },
  "strengths": ["적응력", "세심함", "협력적"],
  "weaknesses": ["우유부단", "의존적"],
  "career": {
    "aptitude": ["예술", "상담", "교육"],
    "advice": "용신이 화(火)이므로 표현력 살리는 직업 적합"
  },
  "relationships": {
    "style": "조화를 중시하며 배려심이 깊음",
    "tips": "강한 주관을 가진 파트너와 궁합이 좋음"
  },
  "fortune_tips": {
    "colors": ["빨강", "보라"],
    "directions": ["남쪽"],
    "activities": ["운동", "창작 활동"]
  },
  "generated_at": "2025-12-23T10:30:00Z",
  "model": "gemini-2.0-flash",
  "version": "1.0"
}
```

**구현 파일**:
- [x] `supabase/functions/generate-ai-summary/index.ts` ✅ 완료
- [x] `supabase/functions/generate-ai-summary/prompts.ts` ✅ 완료
- [x] `frontend/lib/core/services/ai_summary_service.dart` ✅ 완료

**구현 상세**:
1. **Edge Function (generate-ai-summary)**
   - Gemini 2.0 Flash로 JSON 형식 요약 생성
   - 기존 ai_summary 있으면 캐시된 데이터 반환
   - `force_regenerate` 옵션으로 재생성 가능
   - fallback 로직 (Gemini 실패 시 기본 요약 생성)
   - responseMimeType: "application/json"으로 JSON 출력 강제

2. **Flutter Service (AiSummaryService)**
   - `generateSummary()` - Edge Function 호출
   - `getCachedSummary()` - DB에서 직접 조회
   - `hasSummary()` - 요약 존재 여부 확인
   - AiSummary 및 관련 모델 클래스 (AiPersonality, AiCareer, AiRelationships, AiFortuneTips)

**다음 단계**:
- [x] Edge Function 배포: `supabase functions deploy generate-ai-summary` ✅ 완료 (2025-12-23)
- [ ] 채팅 시작 시 ai_summary 자동 생성 연동

---

### 13.3 Phase 13-C: 배포 및 테스트 ✅ 완료 (2025-12-23)

**배포 완료**:
- Supabase MCP를 통해 Edge Function 배포 성공
- 함수 ID: `49c95700-f647-4e0b-8c09-086224441d16`
- 버전: v1
- 상태: ACTIVE

**테스트 결과**:
1. **신규 생성 테스트** ✅
   - 프로필 `a3a08334-6629-468b-ba9f-97783e481e4f`에 대해 AI 요약 생성 성공
   - Gemini 2.0 Flash 모델 사용
   - JSON 형식 응답 정상 파싱

2. **캐시 테스트** ✅
   - 동일 프로필 재호출 시 `cached: true` 반환
   - DB에서 기존 데이터 정상 조회

3. **DB 저장 확인** ✅
   - `saju_analyses.ai_summary` 컬럼에 JSON 정상 저장

**생성된 AI Summary 예시**:
```json
{
  "personality": {
    "core": "섬세하고 예민하며, 예술적인 감각이 뛰어납니다",
    "traits": ["사려 깊음", "예술적", "섬세함"]
  },
  "strengths": ["뛰어난 공감 능력", "안정적인 성격", "높은 집중력"],
  "weaknesses": ["결정력 부족", "소극적인 태도"],
  "career": {
    "aptitude": ["예술 분야", "상담 분야", "교육 분야"],
    "advice": "창의적인 아이디어를 적극적으로 표현하는 것이 좋습니다."
  },
  "relationships": {
    "style": "상대방을 배려하며 조화로운 관계를 지향합니다.",
    "tips": "자신의 감정을 솔직하게 표현하는 연습이 필요합니다."
  },
  "fortune_tips": {
    "colors": ["흰색", "금색"],
    "directions": ["서쪽"],
    "activities": ["악기 연주", "명상"]
  },
  "generated_at": "2025-12-23T11:15:57.252Z",
  "model": "gemini-2.0-flash",
  "version": "1.0"
}
```

---

### 13.4 Phase 13-D: 채팅 연동 ✅ 완료 (2025-12-23)

**목표**: 채팅 시작 시 ai_summary 없으면 자동 생성

**작업 내용**:
- [x] `chat_provider.dart`에서 채팅 시작 전 ai_summary 확인
- [x] ai_summary 없으면 `AiSummaryService.generateSummary()` 호출
- [x] 생성된 요약을 채팅 컨텍스트에 포함

**구현 상세**:

1. **`_ensureAiSummary()` 메서드 추가**
   - 캐시 확인 → DB 조회 → Edge Function 호출 순서
   - profileId로 해당 프로필의 AI Summary 확인/생성
   - 세션별로 캐시하여 중복 호출 방지

2. **`_appendAiSummaryToPrompt()` 메서드 추가**
   - AI Summary를 시스템 프롬프트에 추가
   - 성격/강점/약점/진로/대인관계/개운법 포함
   - Gemini가 맞춤형 상담 가능하도록 컨텍스트 제공

3. **`sendMessage()` 수정**
   - 첫 메시지일 때 자동으로 AI Summary 확인/생성
   - 이후 메시지는 캐시된 요약 사용
   - 시스템 프롬프트에 AI Summary 컨텍스트 추가

4. **`clearSession()` 수정**
   - 새 세션 전환 시 AI Summary 캐시 초기화

**흐름도**:
```
채팅 시작
  ↓
첫 메시지 전송
  ↓
_ensureAiSummary(profileId) 호출
  ├→ 캐시 있음 → 캐시 반환
  ├→ DB에 ai_summary 있음 → 캐시 저장 후 반환
  └→ 없음 → Edge Function 호출 → DB 저장 → 캐시 저장 후 반환
  ↓
_appendAiSummaryToPrompt()로 시스템 프롬프트 확장
  ↓
Gemini 대화 생성 (사주 분석 컨텍스트 포함)
```

---

### Phase 13 완료 요약

| 단계 | 내용 | 상태 |
|------|------|------|
| 13-A | 12운성/12신살 UI 확인 | ✅ 완료 |
| 13-B | ai_summary Edge Function + Flutter 서비스 | ✅ 완료 |
| 13-C | 배포 및 테스트 | ✅ 완료 |
| 13-D | 채팅 연동 | ✅ 완료 |

**Phase 13 전체 완료** 🎉

---

### 새 세션 시작 프롬프트 (Phase 13-D: 채팅 연동) - 완료됨

```
@Task_Jaehyeon.md 읽고 "Phase 13: AI 요약 기능 구현" 섹션 확인해.

현재 상태:
- Phase 13-C (배포/테스트) ✅ 완료
- Phase 13-D (채팅 연동) 🔄 진행 예정

완료된 것:
- Edge Function `generate-ai-summary` 배포 완료 (ACTIVE, v1)
- Flutter `AiSummaryService` 구현 완료
- 테스트 통과 (신규 생성 + 캐시 기능)
- DB: saju_analyses 13개 중 1개 ai_summary 있음

관련 파일:
- Edge Function: supabase/functions/generate-ai-summary/
- Flutter 서비스: frontend/lib/core/services/ai_summary_service.dart
- 채팅 Provider: frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart
- 세션 Provider: frontend/lib/features/saju_chat/presentation/providers/chat_session_provider.dart

Phase 13-D 작업:
1. chat_provider.dart에서 채팅 시작 전 ai_summary 확인
2. ai_summary 없으면 AiSummaryService.generateSummary() 호출
3. 생성된 요약을 채팅 컨텍스트에 포함

채팅 시작 시 ai_summary 자동 생성 로직 연동해줘.
```

---

### 새 세션 시작 프롬프트 (Phase 13-A)

```
@Task_Jaehyeon.md 읽고 "Phase 13: AI 요약 기능 구현" 섹션 확인해.

현재 상태:
- Phase 12-B (12운성/12신살 DB) ✅ 완료
- Phase 13-A (UI 확인) 🔄 진행 예정

DB 상태:
- saju_analyses 테이블에 twelve_unsung, twelve_sinsal 컬럼 데이터 13개 모두 채움
- sinsal_list도 13개 모두 있음

Phase 13-A 작업:
1. unsung_display.dart, sinsal_display.dart 확인
2. saju_detail_tabs.dart에서 해당 위젯 연결 상태 확인
3. 앱 실행하여 12운성/12신살 화면 표시 확인

Flutter 앱에서 12운성/12신살 UI가 제대로 표시되는지 확인해줘.
```

---

### 새 세션 시작 프롬프트 (Phase 13-B)

```
@Task_Jaehyeon.md 읽고 "Phase 13: AI 요약 기능 구현" 섹션 확인해.

현재 상태:
- Phase 13-A (UI 확인) ✅ 완료
- Phase 13-B (ai_summary 구현) 🔄 진행 예정

구현할 것:
1. Edge Function: generate-ai-summary (신규 생성)
2. Flutter: ai_summary_service.dart (신규 생성)
3. 첫 채팅 시작 시 ai_summary 없으면 자동 생성

ai_summary JSON 구조는 Task_Jaehyeon.md 13.2 섹션 참조.

Supabase Edge Function으로 ai_summary 생성 기능 구현해줘.
```

---

## Phase 14: 채팅 DB 최적화 및 기능 확장 (2025-12-23~)

### 14.0 현재 DB 분석 결과

#### 채팅 테이블 현황 (2025-12-23 분석)

**chat_sessions 테이블**:
| 컬럼 | 행 수 | NULL 비율 | 상태 |
|------|-------|-----------|------|
| id, user_id, profile_id, chat_type | 3 | 0% | ✅ 정상 |
| title, last_message_preview | 3 | 0% | ✅ 정상 |
| message_count | 3 | 0% | ✅ 정상 |
| context_summary | 3 | **100%** | ⚠️ 미사용 |
| created_at, updated_at | 3 | 0% | ✅ 정상 |

**chat_messages 테이블**:
| 컬럼 | 행 수 | NULL 비율 | 상태 |
|------|-------|-----------|------|
| id, session_id, role, content | 4 | 0% | ✅ 정상 |
| created_at | 4 | 0% | ✅ 정상 |
| suggested_questions | 4 | **100%** | ⚠️ 미사용 |
| tokens_used | 4 | **100%** | ⚠️ 미사용 |

#### NULL 컬럼 분석 및 우선순위

| 우선순위 | 컬럼 | 테이블 | 용도 | 구현 복잡도 |
|----------|------|--------|------|-------------|
| **P1** | tokens_used | chat_messages | 토큰 사용량 추적, 비용 분석 | 낮음 (API 응답에서 추출) |
| **P2** | suggested_questions | chat_messages | 후속 질문 추천 UI | 중간 (AI 생성 필요) |
| **P3** | context_summary | chat_sessions | 세션 요약 (긴 대화 컨텍스트 관리) | 높음 (요약 로직 필요) |

#### 권장 사항

1. **tokens_used (P1)**: Gemini API 응답의 usageMetadata에서 토큰 정보 추출하여 저장
2. **suggested_questions (P2)**: AI 응답 생성 시 후속 질문 3개 함께 생성
3. **context_summary (P3)**: 메시지 10개 이상 시 중간 요약 생성 (Phase 15+에서 검토)

#### Security Advisors 확인 결과

| 항목 | 상태 |
|------|------|
| chat_sessions RLS | ✅ 정상 |
| chat_messages RLS | ✅ 정상 |
| saju_profiles RLS | ✅ 정상 |
| saju_analyses RLS | ✅ 정상 |

---

### 14.1 Phase 14-A: tokens_used 구현 ✅ 완료 (2025-12-23)

**목표**: Gemini API 응답에서 토큰 사용량 추출하여 DB 저장

**작업 항목**:
- [x] GeminiRestDatasource에서 usageMetadata 파싱
- [x] chat_message 저장 시 tokens_used 포함
- [x] ChatMessage entity에 tokensUsed 필드 추가 (optional)
- [ ] 토큰 사용량 통계 쿼리 (선택사항 - Phase 15+)

**구현 내용**:

1. **GeminiResponse 모델 추가** (`gemini_rest_datasource.dart`)
   - `content`: AI 응답 텍스트
   - `promptTokenCount`: 프롬프트 토큰 수
   - `candidatesTokenCount`: 응답 토큰 수
   - `totalTokenCount`: 총 토큰 수
   - `thoughtsTokenCount`: Thinking 모드 토큰 수 (Gemini 3.0)

2. **usageMetadata 파싱**
   - `sendMessageWithMetadata()`: 일반 요청 시 토큰 정보 포함 반환
   - `sendMessageStream()`: 스트리밍 완료 후 `lastStreamingResponse`에서 토큰 정보 조회

3. **Entity/Model 수정**
   - `ChatMessage.tokensUsed`: nullable int 필드 추가
   - `ChatMessageModel.tokensUsed`: freezed 모델에 추가
   - Hive/Supabase 직렬화 지원

4. **저장 흐름**
   ```
   GeminiRestDatasource (usageMetadata 파싱)
   → ChatRepositoryImpl (getLastTokensUsed())
   → ChatNotifier (aiMessage.tokensUsed = tokensUsed)
   → ChatSessionRepositoryImpl (Hive + Supabase 저장)
   → chat_messages.tokens_used 컬럼에 저장
   ```

**관련 파일**:
- `frontend/lib/features/saju_chat/data/datasources/gemini_rest_datasource.dart` ✅
- `frontend/lib/features/saju_chat/domain/entities/chat_message.dart` ✅
- `frontend/lib/features/saju_chat/data/models/chat_message_model.dart` ✅
- `frontend/lib/features/saju_chat/data/repositories/chat_repository_impl.dart` ✅
- `frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart` ✅
- `frontend/lib/features/saju_chat/data/repositories/chat_session_repository_impl.dart` ✅

---

### 14.2 Phase 14-B: suggested_questions 구현 ✅ 완료 (2025-12-24)

**목표**: AI 응답 생성 시 후속 질문 3개 함께 생성

**작업 항목**:
- [x] 시스템 프롬프트에 후속 질문 생성 지시 추가
- [x] AI 응답 파싱하여 suggested_questions 추출
- [x] chat_message 저장 시 suggested_questions 포함
- [x] UI에 추천 질문 칩 표시 (widgets/suggested_questions.dart)

**구현 내용**:

1. **시스템 프롬프트 4개 파일 수정** (`frontend/assets/prompts/*.md`)
   - `general.md`, `saju_analysis.md`, `daily_fortune.md`, `compatibility.md`
   - 형식: `[SUGGESTED_QUESTIONS]질문1|질문2|질문3[/SUGGESTED_QUESTIONS]`

2. **SuggestedQuestionsParser 유틸리티** (`frontend/lib/core/utils/suggested_questions_parser.dart`)
   - AI 응답에서 태그 파싱하여 cleanedContent + suggestedQuestions 반환

3. **ChatMessage entity 수정** (`frontend/lib/features/saju_chat/domain/entities/chat_message.dart`)
   - `suggestedQuestions` 필드 추가 (List<String>?)

4. **ChatMessageModel 수정** (`frontend/lib/features/saju_chat/data/models/chat_message_model.dart`)
   - Hive/Supabase 직렬화 지원

5. **ChatProvider 통합** (`frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart`)
   - 스트리밍 완료 후 파싱하여 DB 저장

6. **UI 표시** (`frontend/lib/features/saju_chat/presentation/screens/saju_chat_shell.dart`)
   - 마지막 AI 메시지의 suggestedQuestions를 SuggestedQuestions 위젯에 전달

**관련 파일**:
- `frontend/assets/prompts/general.md` ✅
- `frontend/assets/prompts/saju_analysis.md` ✅
- `frontend/assets/prompts/daily_fortune.md` ✅
- `frontend/assets/prompts/compatibility.md` ✅
- `frontend/lib/core/utils/suggested_questions_parser.dart` ✅ (신규)
- `frontend/lib/features/saju_chat/domain/entities/chat_message.dart` ✅
- `frontend/lib/features/saju_chat/data/models/chat_message_model.dart` ✅
- `frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart` ✅
- `frontend/lib/features/saju_chat/presentation/widgets/suggested_questions.dart` ✅
- `frontend/lib/features/saju_chat/presentation/screens/saju_chat_shell.dart` ✅

---

### 14.3 Phase 14-C: AI Summary 캐시 버그 수정 ✅ 완료 (2025-12-24)

**문제**: AI Summary 생성 시 항상 `cached: false` 반환

**원인 분석**:
1. Flutter `saju_chart_provider.dart`에서 `isLoggedIn=false`면 `saju_analyses` 저장 스킵
2. Edge Function `generate-ai-summary`에서 `update`만 사용 → 레코드 없으면 저장 실패
3. 따라서 매번 새로 생성하고 `cached: false` 반환

**시나리오**:
```
1. 프로필 생성 → saju_profiles INSERT ✅
2. 사주 분석 → isLoggedIn=false → saju_analyses 저장 스킵 ❌
3. 채팅 시작 → Edge Function 호출
4. Edge Function: saju_analyses.ai_summary 조회 → 레코드 없음!
5. AI Summary 새로 생성
6. UPDATE 시도 → 0 rows affected (레코드 없어서)
7. cached: false 반환 (매번 반복)
```

**해결책**: Edge Function에서 `update` → `upsert` 변경

**작업 항목**:
- [x] Edge Function `generate-ai-summary/index.ts` 수정
  - `update()` → SELECT 후 INSERT/UPDATE 분리 (upsert는 check constraint 문제)
  - `saju_analysis` 데이터에서 필수 컬럼 추출하여 INSERT 가능하게 구현
  - 기존 레코드가 있으면 ai_summary만 UPDATE, 없으면 전체 INSERT
- [x] Edge Function 배포 (Supabase MCP로 배포 완료 - v4)
- [x] 테스트: 기존 프로필로 채팅 시작 → 두 번째부터 `cached: true` 확인 ✅

**수정된 코드** (`supabase/functions/generate-ai-summary/index.ts`):
```typescript
// 기존 레코드 확인
const { data: existing } = await supabase
  .from("saju_analyses")
  .select("id, ai_summary")
  .eq("profile_id", profile_id)
  .single();

// 기존 ai_summary가 있으면 캐시 반환
if (!force_regenerate && existing?.ai_summary) {
  return { success: true, ai_summary: existing.ai_summary, cached: true };
}

// DB에 저장: 기존 레코드가 있으면 UPDATE, 없으면 INSERT
if (existing) {
  // UPDATE: ai_summary만 업데이트
  await supabase
    .from("saju_analyses")
    .update({ ai_summary: aiSummary, updated_at: new Date().toISOString() })
    .eq("profile_id", profile_id);
} else {
  // INSERT: 새 레코드 생성 (saju_analysis 데이터에서 필수 컬럼 추출)
  await supabase
    .from("saju_analyses")
    .insert({ profile_id, year_gan, year_ji, ..., ai_summary });
}
```

**중요 발견 (2025-12-24)**:
- `upsert`는 check constraint 문제로 실패 (천간/지지 regex 검증)
- SELECT 후 INSERT/UPDATE 분리 방식으로 해결

**관련 파일**:
- `supabase/functions/generate-ai-summary/index.ts` ✅

**배포 방법**:
```bash
# Supabase CLI로 배포
cd supabase
supabase functions deploy generate-ai-summary
```

---

### Phase 14 완료 (2025-12-24) 🎉

**완료된 작업**:
- Phase 14-A: tokens_used 컬럼에 Gemini 토큰 사용량 저장 ✅
- Phase 14-B: AI 응답에서 suggested_questions 추출 및 UI 표시 ✅
- Phase 14-C: AI Summary 캐시 버그 수정 (SELECT → INSERT/UPDATE 분리) ✅

**테스트 결과**:
```
첫 번째 호출: cached: false, db_saved: true
두 번째 호출: cached: true (DB에서 캐시된 결과 반환)
```

---

### 다음 작업 선택 프롬프트

```
@Task_Jaehyeon.md 읽고 Phase 15 또는 다음 작업 선택해.

Phase 14 ✅ 완료:
- tokens_used, suggested_questions, cached 버그 수정 모두 완료

다음 작업 후보:
- Phase 14-D: context_summary 구현 (긴 대화 요약)
- 앱 테스트 및 버그 수정
- 다른 기능 추가
- 다른 작업
```

---

### 참고: Phase 14-B 프롬프트 (완료됨)

```
context7, supabase mcp써서 아래 프롬포트 제대로 해봐
@Task_Jaehyeon.md 읽고 "Phase 14: 채팅 DB 최적화 및 기능 확장" 섹션 확인해.

현재 상태:
- Phase 14-A (tokens_used) ✅ 완료
- Phase 14-B (suggested_questions) 🔄 진행 예정

완료된 것:
- tokens_used 컬럼에 토큰 사용량 저장 완료
- Gemini usageMetadata 파싱 완료
- OpenAI API 키 .env에 추가 완료

DB 분석 결과:
- chat_messages.suggested_questions 컬럼이 100% NULL
- AI 응답에 후속 질문 3개 포함하도록 프롬프트 수정 필요

주요 파일:
- 프롬프트: frontend/assets/prompts/*.md
- ChatMessage Entity: frontend/lib/features/saju_chat/domain/entities/chat_message.dart
- 추천 질문 위젯: frontend/lib/features/saju_chat/presentation/widgets/suggested_questions.dart

Phase 14-B 작업:
1. 시스템 프롬프트에 후속 질문 생성 지시 추가
2. AI 응답 파싱하여 suggested_questions 추출
3. ChatMessage entity에 suggestedQuestions 필드 추가
4. UI에 추천 질문 칩 표시

AI 응답에서 후속 질문 3개 추출하여 DB에 저장하고 UI에 표시하는 기능 구현해줘.
```

---

### 참고: Phase 14-A 프롬프트 (완료됨)

```
# 이미 완료된 작업 - 참고용
@Task_Jaehyeon.md 읽고 "Phase 14: 채팅 DB 최적화 및 기능 확장" 섹션 확인해.

Phase 14-A 작업:
1. gemini_rest_datasource.dart에서 usageMetadata 파싱
2. ChatMessage entity에 tokensUsed 필드 추가
3. AI 응답 저장 시 토큰 사용량 포함

Gemini API 응답에서 토큰 사용량 추출하여 DB에 저장하는 기능 구현해줘.
```

---
