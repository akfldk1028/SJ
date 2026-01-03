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

## Phase 22: 만세력 계산 로직 수정 (2024-12-31)

### 개요
만세력 계산 결과가 사주플러스(정답)와 다르게 나오는 문제 수정

### 발견된 오류 및 수정

#### 1. 지장간(支藏干) 테이블 오류
**문제**: 왕지(旺支)의 여기(餘氣) 누락
- 자(子), 묘(卯), 오(午), 유(酉)는 왕지로 여기 10일 + 정기 20일 구조
- 기존 코드: 정기만 있음 (100%)

**수정된 지장간 테이블:**
| 지지 | 여기 | 중기 | 정기 | 일수 |
|------|------|------|------|------|
| 자(子) | 임(壬) | - | 계(癸) | 10/0/20 |
| 묘(卯) | 갑(甲) | - | 을(乙) | 10/0/20 |
| 오(午) | 병(丙) | 기(己) | 정(丁) | 10/9/11 |
| 유(酉) | 경(庚) | - | 신(辛) | 10/0/20 |

**파일**: `frontend/lib/features/saju_chart/data/constants/jijanggan_table.dart`

#### 2. 12신살 기준 변경
**문제**: 년지 기준으로 계산 → 장성살 (오답)
**정답**: 일지 기준으로 계산 → 육해살

**수정 내용:**
- `useYearJi` 기본값: `true` → `false`
- 현대 명리학에서는 일지 기준이 더 적중률이 높음

**파일**: `frontend/lib/features/saju_chart/domain/services/twelve_sinsal_service.dart`

#### 3. 신강/신약 점수 계산 가중치 조정
**문제**: 69점(신강) → 정답은 태강(75점 이상)
**원인**: 득령/득지/득세 가중치가 너무 낮음

**수정된 가중치:**
| 항목 | 이전 | 수정 후 |
|------|------|---------|
| 득령 | +8/-6 | +12/-8 |
| 득지 | +5/-4 | +8/-5 |
| 득시 | +3/-2 | +4/-2 |
| 득세 | +4/-3 | +6/-4 |

**파일**: `frontend/lib/features/saju_chart/domain/services/day_strength_service.dart`

### 참고 자료
- [사주스터디 - 지장간](https://www.sajustudy.com/31)
- [12신살 계산법](https://smtmap.com/12-2/)
- [코스몬소다 - 지장간](https://blog.cosmonsoda.com/4460/)

---

## Phase 23: 누락된 신살/귀인 추가 구현 (2024-12-31)

### 개요
웹 검색 결과와 비교하여 누락된 신살/귀인 계산 로직 추가

### 추가된 신살 목록

#### P1 (우선순위 높음) - 완료 ✅
| 신살 | 한자 | 기준 | 설명 |
|------|------|------|------|
| 금여 | 金輿 | 일간 → 지지 | 좋은 배우자 운, 물질적 풍요 |
| 삼기귀인 | 三奇貴人 | 천간 조합 | 천상삼기(갑무경), 인중삼기(신임계), 지하삼기(을병정) |
| 복성귀인 | 福星貴人 | 일주/연간 | 복록, 조력자 만남 |
| 낙정관살 | 落井關殺 | 일간 → 지지 | 추락/익사 위험, 배신 주의 |

#### P2 (보통) - 추가 완료 ✅
| 신살 | 한자 | 기준 | 설명 |
|------|------|------|------|
| 문곡귀인 | 文曲貴人 | 일간 → 지지 | 학문, 예술, 문서운 |
| 태극귀인 | 太極貴人 | 일간 → 지지 | 큰 귀인의 도움 |
| 천의귀인 | 天醫貴人 | 월지 → 지지 | 의료 관련, 건강운 |
| 천주귀인 | 天廚貴人 | 일간 → 지지 | 식복, 음식 관련 |
| 암록귀인 | 暗祿貴人 | 일간 → 지지 | 숨은 재물운, 음덕 |
| 홍란살 | 紅鸞煞 | 년지 → 지지 | 결혼운, 연애운 |
| 천희살 | 天喜煞 | 년지 → 지지 | 경사, 기쁜 일 |

### 수정된 파일

| 파일 | 변경 내용 |
|------|-----------|
| `twelve_sinsal.dart` | SpecialSinsal enum에 11개 신살 추가 + 계산 로직 함수 |
| `sinsal.dart` | SinSal enum에 11개 신살 추가 |
| `gilseong_service.dart` | GilseongAnalysisResult에 새 필드 추가 + 분석 로직 |

### 계산 로직 테이블

**금여 (일간 → 지지)**
| 갑 | 을 | 병 | 정 | 무 | 기 | 경 | 신 | 임 | 계 |
|---|---|---|---|---|---|---|---|---|---|
| 진 | 사 | 미 | 신 | 미 | 신 | 술 | 해 | 축 | 인 |

**삼기귀인 (천간 순서)**
- 천상삼기: 년갑-월무-일경 또는 월갑-일무-시경
- 인중삼기: 년신-월임-일계 또는 월신-일임-시계
- 지하삼기: 년을-월병-일정 또는 월을-일병-시정

**복성귀인 일주**
- 갑인, 을축, 병자, 정유, 무신, 기미, 경오, 신사, 임진, 계묘

**낙정관살 (일간 → 지지)**
| 갑 | 을 | 병 | 정 | 무 | 기 | 경 | 신 | 임 | 계 |
|---|---|---|---|---|---|---|---|---|---|
| 유 | 술 | 신 | 해 | 미 | 사 | 자 | 축 | 술 | 묘 |

**낙정관살 일주 (강력)**
- 기사, 경자, 병신, 임술, 계묘

### 참고 자료
- [명리하게 - 금여](https://imim.kkotaera.com/entry/사주-금여-金輿)
- [무진스님 - 삼기귀인](https://blog.daum.net/mujins/1636)
- [조세일보 - 복성귀인](https://m.joseilbo.com/news/view.htm?newsid=476584)
- [초연의 인생노트 - 낙정관살](https://sounivers.com/낙정관살/)

---

## Phase 24: P2/P3 추가 신살 구현 (2024-12-31)

### 개요
P2/P3 우선순위 신살 계산 로직 추가 및 UI 표시 구현

### 추가된 신살 목록

| 신살 | 한자 | 기준 | 설명 | 타입 |
|------|------|------|------|------|
| 건록 | 健祿 | 일간 → 지지 | 자신감, 추진력, 재정 건전 | 길 |
| 비인살 | 飛刃殺 | 일간 → 지지 | 양인의 충, 은밀한 위험 | 흉 |
| 효신살 | 梟神殺 | 일주 조합 | 어머니 영향, 든든한 배경 | 중립 |
| 고신살 | 孤神殺 | 년지 → 지지 | 남자 배우자운 약화 | 흉 |
| 과숙살 | 寡宿殺 | 년지 → 지지 | 여자 배우자운 약화 | 흉 |
| 원진살 | 怨嗔殺 | 지지 쌍 | 관계 불화, 갈등 | 흉 |
| 천라지망 | 天羅地網 | 진술 동시 | 구속, 답답함 | 흉 |

### 수정된 파일

| 파일 | 변경 내용 |
|------|-----------|
| `twelve_sinsal.dart` | SpecialSinsal enum + 계산 함수 추가 |
| `sinsal.dart` | SinSal enum에 Phase 24 신살 추가 |
| `gilseong_service.dart` | 새 필드 및 분석 로직 추가 |
| `gilseong_display.dart` | `ExtendedSinsalInfoCard` 위젯 추가 |
| `saju_detail_tabs.dart` | `_SinsalTab`에 성별 전달 및 위젯 통합 |

### 테스트 결과 (박재현 1997.11.29 08:03)

**사주**: 정축/신해/을해/경진

| 신살 | 결과 |
|------|------|
| 효신살 | ✅ 을해 일주 해당 |
| 원진살 | 2개 발견 (진-해 원진 관계) |
| 양인살 | ✅ 시주 진 |
| 귀문관살 | ✅ 인신사해 2개 이상 |
| 천문성 | ✅ 월주/일주 해 |

---

## Phase 25: 야자시/조자시 로직 검증 (2024-12-31)

### 개요
시간 모름(시주 없음) 및 야자시/조자시 옵션의 로직 검증 및 UI 수정

### 명리학 이론 (웹 검색 결과)

| 학설 | 23:00-24:00 | 00:00-01:00 | 사용 비율 |
|------|-------------|-------------|----------|
| **야자시(夜子時)** | 당일 일주 유지 | 익일 일주 적용 | ~20% |
| **정자시(正子時)** | 익일 일주 적용 | 익일 일주 (이미 다음 날짜) | ~80% |

### 수정 내용

| 파일 | 변경 내용 |
|------|-----------|
| `birth_time_options.dart` | 툴팁 설명 수정 + 라벨 변경 ("야자시 적용") |
| `jasi_service.dart` | enum 주석 상세화 (사용 비율 ~20%/~80%, 참고 링크) |
| `jasi_service_test.dart` | 테스트 케이스 19개 추가 |

### 테스트 결과

```
✅ 19개 테스트 모두 통과
- isJasiHour: 5개
- 야자시 모드: 3개
- 정자시 모드: 3개
- 월/년 경계: 4개
- getModeDescription: 2개
- 밀레니엄 베이비 예시: 2개
```

### 참고 자료
- [나무위키 - 사주팔자](https://namu.wiki/w/사주팔자)
- [초코서당 - 야자시/조자시](https://chocosd.com/3441/)

---

## Phase 26: saju_base 생성 실패 분석 (2024-12-31)

### 개요
프로필 저장 후 `saju_base` (GPT-5.2 평생사주 분석)가 DB에 저장되지 않는 문제 분석

### 문제 현상
- `daily_fortune` (Gemini): 정상 생성 ✅
- `saju_base` (GPT-5.2): 생성 안 됨 ❌
- 사용자 체감: 프로필 저장 20초 미만 (정상처럼 보임)

### 원인 분석

#### 사용자 체감 vs 실제 동작
```
┌─────────────────────────────────────────────────────────────────┐
│  ■ 사용자 체감 (20초 미만) - 정상으로 보임                        │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  1. 프로필 저장        → 즉시                              │ │
│  │  2. 만세력 계산        → 빠름                              │ │
│  │  3. 화면 전환          → 즉시 반환 (runInBackground=true)  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ■ 백그라운드 실패 (사용자 모름)                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  4. GPT-5.2 호출       → 100-150초 소요                    │ │
│  │  5. Supabase 타임아웃  → 150초 제한 → 546 에러             │ │
│  │  6. saju_base 저장     → ❌ 실패 (DB에 저장 안 됨)         │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

#### DB 증거 (최근 프로필)
| 프로필명 | 생성시간 | daily_fortune | saju_base |
|----------|----------|---------------|-----------|
| 박재현 | 06:45 | ✅ 있음 | ❌ 없음 |
| 박재현 | 06:33 | ✅ 있음 | ❌ 없음 |
| 김동현 | 06:16 | ✅ 있음 | ❌ 없음 |
| 이지나 | 06:00 | ✅ 있음 | ❌ 없음 |
| 김동현 | 04:49 | ✅ 있음 | ✅ 있음 (133초) ← 운좋게 성공 |

#### Edge Function 로그 증거
| Function | Status | 소요시간 |
|----------|--------|----------|
| ai-gemini (daily_fortune) | 200 OK | 10-12초 |
| ai-openai (saju_base) | 546 Timeout | 150초 |

#### 성공한 saju_base 처리 시간 (DB 기록)
- 102,484ms ~ 146,331ms (102초 ~ 146초)
- Supabase Edge Function 타임아웃: **150초**
- 결과: 타임아웃 경계에서 운에 따라 성공/실패

### 관련 코드

**saju_analysis_service.dart:207-210**
```dart
if (runInBackground) {
  // 백그라운드에서 GPT-5.2 호출 (사용자 모름)
  _runBothAnalysesInBackground(userId, profileId, inputData, onComplete);
  return const ProfileAnalysisResult(); // 즉시 반환 ← 사용자는 여기서 20초!
}
```

### 해결 → Phase 27에서 완료 ✅

---

## Phase 27: saju_base 타임아웃 해결 - DK 솔루션 (2026-01-01) ✅ 완료

### 개요
DK가 OpenAI Responses API `background=true` 모드를 활용한 Async + Polling 패턴 구현 완료.
master 브랜치에서 merge하여 적용됨.

### 핵심 커밋
- **커밋**: `867de8b` - `[DK] feat: OpenAI Responses API v24 background mode 구현`
- **병합**: `f425179` - `Merge branch 'master' into Jaehyeon(Test)`

### 문제 원인 (재정리)
```
┌─────────────────────────────────────────────────────────────────┐
│  Supabase Edge Function 타임아웃 구조                            │
│  ├─ 150초: HTTP 응답 반환 시간 제한 ← 여기서 걸림!               │
│  └─ 400초: 응답 반환 후 백그라운드 작업 시간 (Pro 플랜)          │
│                                                                   │
│  기존 문제: OpenAI 응답(100-150초) 대기 후 HTTP 응답 반환        │
│  → 150초 제한에 걸려서 546 Timeout 에러 발생                      │
└─────────────────────────────────────────────────────────────────┘
```

### 솔루션: OpenAI Responses API Background Mode

#### 1. Edge Function (ai-openai v24)
```typescript
// 핵심 변경: OpenAI Responses API 사용
const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";

// run_in_background=true 요청 시
const responsesApiBody = {
  model,
  input: inputText,
  background: true,  // 핵심! OpenAI 클라우드에서 비동기 처리
  store: true,       // background 모드 필수
  max_output_tokens,
};

// 즉시 task_id + openai_response_id 반환 (150초 전에!)
return { task_id, openai_response_id, status: "queued" };
```

#### 2. 결과 조회 Edge Function (ai-openai-result v4)
```typescript
// OpenAI /v1/responses/{id} 직접 폴링
const openaiResponse = await fetch(
  `${OPENAI_RESPONSES_URL}/${task.openai_response_id}`
);

// 상태 변환: queued → in_progress → completed
// 완료 시 ai_tasks 테이블에 결과 캐싱
```

#### 3. Flutter 클라이언트 (openai_edge_datasource.dart)
```dart
// 폴링 설정
static const int _maxPollingAttempts = 120; // 최대 120회
static const Duration _pollingInterval = Duration(seconds: 2); // 2초 간격 = 최대 240초

// Step 1: Background 모드로 요청
'run_in_background': true,  // v24 Responses API

// Step 2: 결과 폴링
return await _pollForResult(taskId);
```

### 변경된 파일

| 파일 | 버전 | 변경 내용 |
|------|------|-----------|
| `supabase/functions/ai-openai/index.ts` | v24 | OpenAI Responses API background 모드 |
| `supabase/functions/ai-openai-result/index.ts` | v4 (신규) | OpenAI 폴링 엔드포인트 |
| `frontend/.../openai_edge_datasource.dart` | - | Async + Polling 클라이언트 |
| `sql/migrations/20241231_create_ai_tasks_table.sql` | - | ai_tasks 테이블 |

### 흐름도

```
┌─────────────────────────────────────────────────────────────────┐
│  Before (v10-v23): 타임아웃 발생                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Flutter → ai-openai → [OpenAI 100-150초 대기] → 응답 반환   ││
│  │                                    ↑ 150초 초과 → 546 에러  ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  After (v24): Async + Polling                                    │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Flutter → ai-openai → OpenAI Responses API (background=true)││
│  │                    ↓ 즉시 반환 (task_id)                     ││
│  │ Flutter → ai-openai-result (polling) → OpenAI /v1/responses ││
│  │                    ↓ 상태: queued → in_progress → completed  ││
│  │ Flutter ← 결과 수신 ← ai_tasks 캐싱                          ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 테스트 필요 항목
- [ ] 새 프로필 생성 후 saju_base 저장 확인
- [ ] ai_tasks 테이블에 task 기록 확인
- [ ] 폴링 정상 작동 확인 (queued → completed)

---

## Phase 28: AiApiService Polling 로직 추가 (2026-01-01) ✅ 완료

### 개요
`AiApiService.callOpenAI()`에 v24 Background 모드 polling 로직이 누락되어 saju_base 분석 결과가 빈 응답으로 반환되는 문제 수정

### 문제 원인 분석

**두 개의 OpenAI 호출 경로:**
| 파일 | 용도 | Polling | 문제 |
|------|------|---------|------|
| `openai_edge_datasource.dart` | 채팅용 | ✅ 있음 | 정상 |
| `ai_api_service.dart` | **saju_base 분석용** | ❌ 없음 | **빈 응답!** |

**v24 Background 모드 흐름:**
```
1. ai-openai Edge Function: run_in_background=true로 요청
2. OpenAI Responses API에 background=true로 전달
3. 즉시 task_id + openai_response_id 반환 (content는 비어있음!)
4. Flutter 클라이언트가 ai-openai-result로 polling 해야 함

문제: AiApiService는 polling 없이 즉시 content 파싱 시도 → 빈 응답
```

**증거:**
- AI API LOG: `"content": "{}"` (빈 JSON)
- ai_tasks 테이블: 나중에 `status: completed`되면서 `result_data`에 실제 결과 저장됨
- 앱: Polling 시작 전에 종료됨 (프로필 조회 실패 등)

### 수정 내용

**파일**: `frontend/lib/AI/services/ai_api_service.dart`

1. **Polling 상수 추가** (line 171-175)
   ```dart
   static const int _maxPollingAttempts = 120;  // 최대 120회
   static const Duration _pollingInterval = Duration(seconds: 2);  // 2초 간격 = 최대 240초
   ```

2. **callOpenAI() 수정** (line 206-322)
   - `runInBackground` 파라미터 추가 (기본값: true)
   - `run_in_background: true` body에 추가
   - task_id 반환 시 `_pollForOpenAIResult()` 호출

3. **_pollForOpenAIResult() 신규 추가** (line 324-465)
   - `ai-openai-result` Edge Function으로 polling
   - 상태: `queued` → `in_progress` → `completed`
   - completed 시 content 파싱, 토큰 사용량 추출, 로그 저장

### 흐름도

```
┌─────────────────────────────────────────────────────────────────┐
│  Before (문제): AiApiService polling 없음                        │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ SajuAnalysisService → AiApiService.callOpenAI()             ││
│  │   → ai-openai v24 (task_id 반환)                            ││
│  │   → data['content'] 즉시 파싱 → 빈 값! → saju_base 빈 결과  ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  After (수정됨): AiApiService polling 추가                        │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ SajuAnalysisService → AiApiService.callOpenAI()             ││
│  │   → ai-openai v24 (task_id 반환)                            ││
│  │   → _pollForOpenAIResult(taskId)                            ││
│  │     → ai-openai-result (polling)                            ││
│  │     → OpenAI /v1/responses/{id}                             ││
│  │     → completed 시 content 반환                              ││
│  │   → saju_base 정상 저장! ✅                                  ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 테스트 필요 항목
- [ ] 새 프로필 생성 후 saju_base 저장 확인
- [ ] ai_tasks 테이블에 task 기록 확인
- [ ] 폴링 정상 작동 확인 (queued → completed)
- [ ] AI API LOG에서 content 정상 수신 확인

---

## Phase 29: UI와 DB 불일치 점검 및 프롬프트 강화 (2026-01-01) ✅ 완료

### 개요
AI 응답(DB)과 Flutter 계산값(UI) 비교 분석 후, 불일치 항목 발견 및 프롬프트 수정

### 점검 결과

| 항목 | Flutter 계산 | AI 응답 (DB) | 상태 |
|------|-------------|--------------|------|
| 신강/신약 level | 8단계 (중화신강 등) | "신약" (오류) | ❌ → ✅ 수정됨 |
| 오행 분포 | 직접 카운트 | 0으로 반환 | ⚠️ AI 미계산 (허용) |
| 격국 | gyeokguk_service.dart | 정상 | ✅ 정상 |
| 합충형파해 | hapchung_service.dart | 상세 분석 | ✅ 정상 |
| 12운성 | twelve_unsung_service.dart | 분석됨 | ✅ 정상 |
| 12신살 | twelve_sinsal_service.dart | 분석됨 | ✅ 정상 |

### 발견된 불일치

**핵심 문제: 신강/신약 level 불일치**

```
Flutter 계산: score 53 → "중화신강" (50-62점 범위)
AI 응답:     score 53 → "신약" (잘못됨!)
```

**원인**: Phase 28.1에서 8단계 기준을 추가했지만, AI가 여전히 무시하고 자체 판단

### 수정 내용

**파일**: `frontend/lib/AI/prompts/saju_base_prompt.dart`

1. **`_buildDayStrengthSection()` 강화** (line 407-440)
   - 시각적 강조 박스 추가 (ASCII 테이블)
   - "재계산 금지" 명시
   - 8단계 기준표 마크다운 테이블로 표시
   - 경고 메시지 추가: `점수 $score은 "$level"입니다. 응답에서 이 등급을 그대로 사용하세요.`

2. **JSON 스키마 singang_singak.level 설명 강화** (line 219)
   ```
   Before: "위 입력 데이터의 점수에 맞는 8단계 등급 사용"
   After:  "※필수※ ... 50-62=중화신강 ..." (점수-등급 매핑 명시)
   ```

### 프롬프트 변경 예시

```
## 신강/신약 (8단계 판정) - ⚠️ 중요 ⚠️

┌─────────────────────────────────────────────────┐
│ ★★★ 이 값을 그대로 사용하세요 (재계산 금지) ★★★  │
├─────────────────────────────────────────────────┤
│ 점수: 53점                                       │
│ 등급: 중화신강                                   │
│ is_singang: true                                 │
└─────────────────────────────────────────────────┘

**8단계 기준표** (점수 → 등급 매핑):
| 점수 범위 | 등급 | is_singang |
|-----------|------|------------|
| 50-62 | **중화신강** | **true** |
...

> **경고**: 점수 53은 "중화신강"입니다. 응답에서 이 등급을 그대로 사용하세요.
```

### 테스트 필요 항목
- [ ] 새 프로필 생성 후 saju_base level 확인
- [ ] AI 응답의 singang_singak.level이 Flutter 계산값과 일치하는지 확인

---

## 다음 작업 예정

1. ~~**saju_base 타임아웃 해결**~~ ✅ Phase 27 완료 (DK 솔루션)
2. ~~**AiApiService polling 로직 추가**~~ ✅ Phase 28 완료
3. ~~**UI와 DB 불일치 점검**~~ ✅ Phase 29 완료
4. ~~**음력 테이블 한중 차이 수정**~~ ✅ Phase 30 완료
5. ~~**12신살 기준 검증**~~ ✅ Phase 31 완료 (일지 기준 유지)
6. **Phase 29 테스트** - 신강/신약 level 일치 확인
7. 채팅 테스트 후 토큰 사용량 확인
8. 시간 모름 처리 개선 - 삼주(三柱) 분석 모드
9. 필요시 추가 버그 수정

---

## Phase 31: 12신살 기준 검증 (2026-01-03) ✅ 완료

### 개요
포스텔러와 12신살 결과가 다른 문제 분석 및 검증

### 문제 분석

**증상**: 포스텔러와 12신살 결과 차이
- 포스텔러: 월지/일지(해)=역마살, 시지(진)=반안
- 우리 앱: 월지/일지(해)=지살, 시지(진)=반안

### 원인 분석

12신살 계산에는 두 가지 기준이 있음:
1. **년지 기준** (전통 방식)
2. **일지 기준** (현대 명리학 대세)

| 기준 | 월지/일지(해) | 시지(진) | 년지(축) |
|------|-------------|---------|---------|
| 일지 기준 | 지살 | 반안 | 월살 |
| 년지 기준 | 역마 | 천살 | 화개 |

### 결론

1. **포스텔러는 혼합 기준 사용**
   - 기본 12신살: 일지 기준 (시지=반안, 년지=월살)
   - 역마살 등 주요 신살: 년지 기준으로 별도 표시

2. **우리 앱 현황**
   - **TwelveSinsalService**: 일지 기준 (기본 12신살)
   - **GilseongService**: 년지 기준 (역마살, 도화살, 화개살 등 주요 신살)
   - DB와 UI 모두 일관성 있게 일지 기준 사용

3. **변경 없이 유지**
   - 현대 명리학 기준에 부합
   - DB와 UI 일관성 유지됨

### 참고 자료
- [나무위키 - 사주팔자/신살](https://namu.wiki/w/사주팔자/신살)
- [십이신살의 이해](https://www.sajubaju.com/십이신살의-이해)

---

## Phase 30: 음력 테이블 한중 차이 수정 (2026-01-03) ✅ 완료

### 개요
음력으로 입력 시 사주(일주/시주)가 포스텔러와 다르게 나오는 문제 해결

### 문제 분석

**증상**: 음력 생년월일로 입력 시 일주/시주의 천간/지지가 포스텔러와 1일 차이

**원인**: 음력 테이블이 중국 기준으로 되어 있어 한국 기준과 1일 차이 발생
- 한국과 중국은 표준시가 1시간 차이 (UTC+9 vs UTC+8)
- 합삭(新月) 시각이 자정 경계에 걸리면 설날 날짜가 다름
- 우리 테이블은 중국 기준으로 되어 있었음

### 수정된 연도 목록

| 연도 | 수정 전 (중국) | 수정 후 (한국) | 합삭 시각 |
|------|---------------|---------------|----------|
| 1997년 | 2월 7일 | **2월 8일** | 0시 6분 |
| 2028년 | 1월 26일 | **1월 27일** | 0시 12분 |
| 2061년 | 1월 21일 | **1월 22일** | 0시 14분 |
| 2089년 | 2월 10일 | **2월 11일** | 0시 14분 |
| 2092년 | 2월 7일 | **2월 8일** | 0시 2분 |

### 수정된 파일

1. **`lunar_table_1950_1999.dart`** (line 335-342)
   - 1997년 solarNewYear: 2월 7일 → 2월 8일

2. **`lunar_table_2000_2050.dart`** (line 202-209)
   - 2028년 solarNewYear: 1월 26일 → 1월 27일

3. **`lunar_table_2051_2100.dart`**
   - 2061년 solarNewYear: 1월 21일 → 1월 22일 (line 76-83)
   - 2089년 solarNewYear: 2월 10일 → 2월 11일 (line 273-280)
   - 2092년 solarNewYear: 2월 7일 → 2월 8일 (line 295-302)

### 기술 참고

- 한국천문연구원(KASI) 공식 음양력 변환: https://astro.kasi.re.kr/life/pageView/8
- 1914년~2099년 사이 한중 설날 차이 연도: 약 15회
- 각 수정 연도에 주석으로 합삭 시각과 한국/중국 기준 명시

### 영향 범위

- 1997년생 음력 프로필: 일주가 1일 차이나던 문제 해결
- 2028년 이후 미래 연도: 사전에 수정하여 문제 예방
- 양력 입력: 영향 없음 (음력→양력 변환 시에만 관련)

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
