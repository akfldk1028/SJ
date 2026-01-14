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
- [x] 새 프로필 생성 후 saju_base level 확인 ✅ Phase 35 완료
- [x] AI 응답의 singang_singak.level이 Flutter 계산값과 일치하는지 확인 ✅ Phase 35 완료

---

## 다음 작업 예정

1. ~~**saju_base 타임아웃 해결**~~ ✅ Phase 27 완료 (DK 솔루션)
2. ~~**AiApiService polling 로직 추가**~~ ✅ Phase 28 완료
3. ~~**UI와 DB 불일치 점검**~~ ✅ Phase 29 완료
4. ~~**음력 테이블 한중 차이 수정**~~ ✅ Phase 30 완료
5. ~~**12신살 기준 검증**~~ ✅ Phase 31 완료 → Phase 39에서 년지 기준으로 변경
6. ~~**1994년 음력 테이블 수정**~~ ✅ Phase 32 완료 (2월/11월 대소월 오류)
7. ~~**김동현 프로필 재생성**~~ ✅ Phase 35 완료 (사주 검증 완료)
8. ~~**Phase 29 테스트 - 신강/신약 level 일치 확인**~~ ✅ Phase 35 완료
9. 채팅 테스트 후 토큰 사용량 확인
10. 시간 모름 처리 개선 - 삼주(三柱) 분석 모드

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

1. **포스텔러는 년지 기준 사용**
   - 12신살: 년지 기준
   - 역마살 등 주요 신살: 년지 기준

2. **우리 앱 현황 (Phase 39 업데이트)**
   - **TwelveSinsalService**: ~~일지 기준~~ → **년지 기준으로 변경** (포스텔러 호환)
   - **GilseongService**: 년지 기준 (역마살, 도화살, 화개살 등 주요 신살)
   - `useYearJi` 기본값: false → **true**로 변경

3. **Phase 39에서 년지 기준으로 변경**
   - 포스텔러와 동일한 결과를 위해 년지 기준 적용
   - 도화살: 년지+일지 병행 기준 함수 추가 (hasDohwasal)

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

## Phase 32: 1994년 음력 테이블 월별 일수 수정 (2026-01-04) ✅ 완료

### 개요
김동현(음력 1994-11-28 09:20) 프로필의 사주가 포스텔러와 다른 문제 해결

### 문제 현상

| 항목 | 우리 앱 | 포스텔러 |
|------|---------|----------|
| 음력 11/28 → 양력 | **12월 29일** ❌ | **12월 30일** ✅ |
| 일주 | 기축(己丑) | **경인(庚寅)** |
| 시주 | 무진(戊辰) | **경진(庚辰)** |

### 원인 분석

1994년 음력 테이블의 월별 일수(대월/소월)가 잘못되어 있었음:
- **2월**: 29일(소월) → **30일(대월)** 으로 수정 필요
- **11월**: 30일(대월) → **29일(소월)** 으로 수정 필요
- 총합: 355일 유지 (변경 없음)

### 수정 내용

**파일**: `frontend/lib/features/saju_chart/data/constants/lunar_data/lunar_table_1950_1999.dart`

```dart
// Before (잘못된 값)
monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30]
//          1  2   3   4   5   6   7   8   9  10  11  12

// After (수정됨 - DateDB/KASI 기준)
monthDays: [30, 30, 30, 29, 29, 30, 29, 30, 30, 29, 29, 30]
//          1  2   3   4   5   6   7   8   9  10  11  12
```

### 검증 결과

```
수정 전: 음력 1994-11-28 → 양력 1994-12-29 (1일 빠름)
수정 후: 음력 1994-11-28 → 양력 1994-12-30 ✅ (KASI/포스텔러 일치)
```

### 영향 범위

- **1994년생 음력 프로필**: 일주/시주 1일 차이 문제 해결
- 십성, 지장간, 12운성, 12신살 모두 정확하게 계산됨
- **기존 프로필**: 앱에서 다시 생성 필요

### 참고 자료

- [DateDB 음력 달력](https://datedb.net/calendar/monthly/lunar/1994/)
- [한국천문연구원 음양력변환](https://astro.kasi.re.kr/life/pageView/8)

---

## Phase 33: 음력 데이터 테이블 전체 재생성 (2026-01-04) ✅ 완료

### 배경
- Phase 32에서 1994년 음력 데이터 오류 발견 후, 전체 연도 검증 필요성 대두
- 사용자 요청: "년도별로 다 하나하나 제대로 체크해봐야 하는거 아니야? 윤달도 확인해야지"

### 문제 발견

#### 검증 방법
- **설날 간격 vs monthDays 합계 비교**
  - 연속된 두 해의 음력 설날(1월 1일)의 양력 날짜 차이 = 해당 연도의 총 일수
  - 이 값이 monthDays 배열의 합계와 일치해야 함

#### 불일치 연도 (총 39개)
| 기간 | 불일치 연도 수 | 연도 목록 |
|------|----------------|-----------|
| 1950-1999 | 18개 | 1950, 1951, 1953, 1954, 1957, 1958, 1959, 1961, 1964, 1965, 1977, 1980, 1985, 1988, 1989, 1991, 1993, 1996 |
| 2000-2050 | 21개 | 2000, 2006, 2010, 2016, 2017, 2018, 2019, 2021, 2022, 2025, 2026, 2028, 2032, 2033, 2034, 2037, 2040, 2041, 2043, 2046, 2049 |

### 해결 방법

#### 신뢰할 수 있는 데이터 소스
- **korean-lunar-calendar** Python 라이브러리 (PyPI)
- 한국천문연구원(KASI) 데이터 기반
- 지원 범위: 1900-2050년

#### 데이터 추출 로직
```python
from korean_lunar_calendar import KoreanLunarCalendar
from datetime import date

def get_month_days_correctly(year):
    calendar = KoreanLunarCalendar()

    # 음력 1월 1일의 양력 날짜
    calendar.setLunarDate(year, 1, 1, False)
    solar_new_year = date(calendar.solarYear, calendar.solarMonth, calendar.solarDay)

    # 윤달 찾기 (정상월과 윤달의 양력 날짜가 다르면 윤달 존재)
    leap_month = 0
    for month in range(1, 13):
        calendar.setLunarDate(year, month, 1, False)
        normal = date(calendar.solarYear, calendar.solarMonth, calendar.solarDay)
        calendar.setLunarDate(year, month, 1, True)
        leap = date(calendar.solarYear, calendar.solarMonth, calendar.solarDay)
        if normal != leap and calendar.isIntercalation:
            leap_month = month
            break

    # 월별 일수 = 다음 월 1일 - 현재 월 1일 (양력 날짜 차이)
    month_days = []
    for month in range(1, 13):
        # ... (양력 날짜 차이로 일수 계산)

    return { 'leap_month': leap_month, 'month_days': month_days, ... }
```

### 수정된 파일

| 파일 | 연도 범위 | 수정 내용 |
|------|-----------|-----------|
| `lunar_table_1900_1949.dart` | 1900-1949 | 50년 전체 재생성 |
| `lunar_table_1950_1999.dart` | 1950-1999 | 50년 전체 재생성 |
| `lunar_table_2000_2050.dart` | 2000-2050 | 51년 전체 재생성 |
| `lunar_table_2051_2100.dart` | 2051-2100 | 검증 미지원 주석 추가 |

**파일 경로**: `frontend/lib/features/saju_chart/data/constants/lunar_data/`

### 검증 결과

#### 핵심 테스트
```
1994년 음력 11월 28일 변환:
  - 수정 전: 양력 1994-12-29 (1일 빠름) ❌
  - 수정 후: 양력 1994-12-30 (포스텔러 일치) ✅

monthDays 합계 검증:
  - 1994년: sum=355, interval=355 ✅
```

#### 전체 검증
```
=== Full Verification (1900-2049) ===
All 150 years verified successfully!
Sum of monthDays matches New Year intervals for all years.

Years checked: 1900-2049 (150 years)
Errors: 0
```

### 주의사항

#### 2051-2100년 미검증
- `korean-lunar-calendar` 라이브러리가 2050년까지만 지원
- 2051-2100년 데이터는 기존 유지, 추후 KASI 공식 데이터로 검증 필요
- 파일에 경고 주석 추가됨

#### 윤달(leapMonth) 검증 완료
- 모든 윤년의 윤달 월 정확히 일치
- 예: 2023년 윤2월, 2025년 윤6월 등

---

## Phase 34: 음력 테이블 검증 및 기존 데이터 분석 (2026-01-04) ✅ 완료

### 개요
Phase 33에서 수정된 음력 테이블의 정확성을 검증하고 기존 사용자 데이터 영향 분석

### 검증 결과

#### 1. Flutter 단위 테스트 ✅
```
=== 김동현 생년월일 검증 ===
음력: 1994년 11월 28일
양력: 1994년 12월 30일 ✅ (포스텔러 일치)

1994년 총 일수: 355일 ✅
음력 설날: 양력 1994년 2월 10일 ✅
```

#### 2. 사주팔자 검증 (포스텔러 기준) ✅
| 구분 | 우리 앱 | 포스텔러 | 상태 |
|------|---------|----------|------|
| 년주 | 갑술(甲戌) | 갑술(甲戌) | ✅ |
| 월주 | 병자(丙子) | 병자(丙子) | ✅ |
| 일주 | **경인(庚寅)** | **경인(庚寅)** | ✅ 핵심 수정 확인! |
| 시주 | 경진(庚辰) | 경진(庚辰) | ✅ |

#### 3. 오행 분석 검증 ✅
```
=== 십성 분석 (일간: 경) ===
년간 갑: 편재 ✅
월간 병: 편관 ✅
일간 경: 비견 ✅
시간 경: 비견 ✅

=== 지장간 분석 ===
년지 술: 신, 정, 무 ✅
월지 자: 임, 계 ✅
일지 인: 무, 병, 갑 ✅
시지 진: 을, 계, 무 ✅

=== 12운성 분석 ===
년지 술: 쇠 ✅
월지 자: 사 ✅
일지 인: 절 ✅
시지 진: 양 ✅

=== 12신살 분석 ===
년지 술: 화개 ✅
월지 자: 재살 ✅
일지 인: 지살 ✅
시지 진: 월살 ✅

=== 오행 분포 ===
목: 2, 화: 1, 토: 2, 금: 2, 수: 1 ✅
```

### 기존 데이터 영향 분석

#### DB 조회 결과 (영향받은 프로필)
| 프로필 | 생년월일 | 생성일 | 일주 | 상태 |
|--------|----------|--------|------|------|
| 김동현 | 1994-11-28 | 01-04 05:41 | **경인(庚寅)** | ✅ 수정 후 |
| 김동현 | 1994-11-28 | 01-04 04:35 | 기축(己丑) | ❌ 수정 전 |
| ddd | 1994-11-28 | 01-04 01:52 | 기축(己丑) | ❌ 수정 전 |
| 김동현 | 1994-11-28 | 01-03 23:34 | 기축(己丑) | ❌ 수정 전 |
| 김동현 | 1994-11-28 | 01-01 05:13 | 기축(己丑) | ❌ 수정 전 |

#### 분석
- **영향받은 음력 프로필**: 5개 (모두 1994년생)
- **수정 후 생성된 프로필**: 1개 (경인, 정확)
- **수정 전 생성된 프로필**: 4개 (기축, 오류)

### 권장 조치

1. **기존 사용자 알림 없음** - 현재 테스트 데이터뿐이므로 자동 재계산 불필요
2. **새 프로필만 정확한 사주** - 앱에서 다시 생성하면 올바른 사주 적용
3. **추후 재계산 기능 고려** - 사용자가 원하면 프로필 재생성 유도

### 테스트 파일 위치
```
frontend/test/lunar_converter_test.dart
frontend/test/saju_calculation_test.dart
frontend/test/saju_full_analysis_test.dart
```

---

## Phase 35: saju_base 생성 및 신강/신약 일치 검증 (2026-01-04) ✅ 완료

### 개요
Phase 27/28/29에서 구현한 Background Polling 및 신강/신약 프롬프트 강화의 실제 동작 검증

### 테스트 프로필
- **이름**: 김동현
- **생년월일**: 음력 1994-11-28 09:20 (대구광역시)
- **양력 변환**: 1994-12-30 ✅ (포스텔러 일치)
- **Profile ID**: `1f10ed7f-c743-4afb-a5a7-772f8220d1e2`

### 검증 결과

#### 1. Background Polling 정상 작동 ✅
| 테이블 | 상태 | 비고 |
|--------|------|------|
| ai_tasks | `status: completed` | openai_response_id 정상 발급 |
| ai_summaries | `saju_base` 타입 저장됨 | content 정상 |

**ai_tasks 레코드:**
- task_id: `137ca49c-1066-4618-ae90-a3e29fde465e`
- openai_response_id: `resp_08aa7a94f32170ac006959fd79185c8190b8ed093451f367cb`
- created_at: 05:41:13 → completed_at: 05:43:12 (약 2분)

#### 2. 신강/신약 level 일치 ✅ (Phase 29 검증)
| 항목 | Flutter 계산값 (saju_analyses) | AI 응답 (ai_summaries) | 상태 |
|------|-------------------------------|------------------------|------|
| **score** | 37 | 37 | ✅ 일치 |
| **level** | "신약(身弱)" | "신약" | ✅ 일치 |
| **is_singang** | false | false | ✅ 일치 |

**Flutter day_strength 상세:**
```json
{
  "level": "신약(身弱)",
  "score": 37,
  "isStrong": false,
  "monthScore": -10,
  "bigeopScore": 10,
  "inseongScore": 10,
  "exhaustionScore": 12
}
```

#### 3. 사주팔자 검증 (포스텔러 일치) ✅
| 주 | AI 응답 | 포스텔러 | 상태 |
|------|---------|----------|------|
| 년주 | 갑술 (甲戌) | 갑술 | ✅ |
| 월주 | 병자 (丙子) | 병자 | ✅ |
| 일주 | **경인 (庚寅)** | **경인** | ✅ 핵심! |
| 시주 | 경진 (庚辰) | 경진 | ✅ |

#### 4. 용신/격국 분석 ✅
- **격국**: 상관격(傷官格)
- **용신**: 토(土)
- **희신**: 화(火)
- **기신**: 목(木)
- **구신**: 금(金)
- **한신**: 수(水)

### 결론

**Phase 27/28/29 구현 모두 정상 작동 확인:**

1. **Phase 27 (OpenAI Responses API background 모드)**: ✅ 정상
   - 546 타임아웃 없이 saju_base 저장 성공
   - ai_tasks 테이블에 task 기록됨

2. **Phase 28 (AiApiService polling 로직)**: ✅ 정상
   - queued → completed 상태 전환 정상
   - 약 2분 내 완료

3. **Phase 29 (신강/신약 프롬프트 강화)**: ✅ 정상
   - AI가 Flutter 계산값(score 37, level "신약")과 동일한 값 반환
   - 8단계 등급 체계 정확히 적용됨

### 미완료 작업 해소

| 작업 | 상태 | 비고 |
|------|------|------|
| Phase 29 테스트 - 신강/신약 level AI 응답 일치 확인 | ✅ 완료 | score 37, level "신약" 일치 |
| saju_base 생성 테스트 - Background Polling 검증 | ✅ 완료 | completed 상태, DB 저장 확인 |

---

## Phase 36: 포스텔러 비교 분석 - 12신살 및 길성 불일치 (2026-01-04) 🔍 분석 완료

### 개요
포스텔러 앱과 우리 앱의 12신살/길성 계산 결과 비교 분석

### 테스트 프로필
- **이름**: 이여진
- **생년월일**: 음력 1992년 9월 13일 06:12 (여자, 서울)
- **사주팔자**: 임신(壬申) / 기유(己酉) / 정사(丁巳) / 계묘(癸卯)
- **일간**: 정(丁)

---

### 1. 12신살 불일치 분석 ⚠️ 핵심 차이 발견

#### 기준 차이
| 항목 | 우리 앱 | 포스텔러 |
|------|---------|----------|
| **12신살 기준** | 일지(사) 기준 | **년지(신) 기준** |
| 삼합 그룹 | 사유축(금국) | **신자진(수국)** |

#### 결과 비교
| 지지 | 우리 앱 (일지=사 기준) | 포스텔러 (년지=신 기준) |
|------|------------------------|------------------------|
| 시지(묘) | 망신 | **지살** |
| 일지(사) | 장성 | **연살(도화살)** |
| 월지(유) | 지살 | **겁살** |
| 년지(신) | 재살 | **육해** |

#### 삼합 기준 12신살 배치 공식
```
삼합 그룹별 겁살 시작 위치:
- 인오술(화국) → 해(亥)에서 겁살 시작
- 사유축(금국) → 인(寅)에서 겁살 시작  ← 우리 앱 (일지=사 기준)
- 신자진(수국) → 사(巳)에서 겁살 시작  ← 포스텔러 (년지=신 기준)
- 해묘미(목국) → 신(申)에서 겁살 시작
```

#### 결론
- **우리 앱**: 일지(사) 기준 → 사유축(금국)에 속함 → 인에서 겁살 시작
- **포스텔러**: 년지(신) 기준 → 신자진(수국)에 속함 → 사에서 겁살 시작
- **차이 원인**: 12신살 계산 기준이 다름 (일지 vs 년지)

---

### 2. 길성 불일치 분석

#### 시지(묘) 길성
| 신살 | 우리 앱 | 포스텔러 | 상태 |
|------|---------|----------|------|
| 문곡귀인 | ✅ (일간 정→묘) | ✅ | 일치 |
| 태극귀인 | ✅ (일간 정→묘/자) | ✅ | 일치 |
| 현침살 | ✅ (묘는 현침살 지지) | ✅ | 일치 |
| 도화살 | ❌ (계산 안됨) | ✅ | **불일치** |

#### 일지(사) 길성
| 신살 | 우리 앱 | 포스텔러 | 상태 |
|------|---------|----------|------|
| 역마살 | ❌ (년지=신→역마=인) | ✅ | **불일치** |

#### 월지(유) 길성
| 신살 | 우리 앱 | 포스텔러 | 상태 |
|------|---------|----------|------|
| 천을귀인 | ✅ (일간 정→해/유) | ✅ | 일치 |
| 문창귀인 | ✅ (일간 정→유) | ✅ | 일치 |
| 학당귀인 | ✅ (일간 정→유) | ✅ | 일치 |
| 태극귀인 | ✅ | ✅ | 일치 |
| 도화살 | ✅ (년지=신→도화=유) | ✅ | 일치 |

#### 년지(신) 길성
| 신살 | 우리 앱 | 포스텔러 | 상태 |
|------|---------|----------|------|
| 천의성 | ✅ (일간 정→신/미) | ✅ | 일치 |
| 금여 | ✅ (일간 정→신) | ✅ | 일치 |
| 관귀학관 | ✅ (일간 정→신) | ✅ | 일치 |
| 현침살 | ✅ (신은 현침살 지지) | ✅ | 일치 |
| 역마살 | ❌ | ✅ | **불일치** |

---

### 3. 불일치 원인 분석

#### 3.1 12신살 기준 문제
```dart
// 현재 우리 앱 (twelve_sinsal_service.dart)
static TwelveSinsalAnalysisResult analyzeFromChart(
  SajuChart chart, {
  bool useYearJi = false, // 기본값: 일지 기준 ← 문제!
})
```

**해결 방안**:
1. **방안 A**: 기본값을 `useYearJi = true`로 변경 (포스텔러 방식)
2. **방안 B**: 둘 다 표시 (년지 기준 + 일지 기준 모두)
3. **방안 C**: 사용자 설정으로 선택 가능하게

#### 3.2 역마살 계산 문제
현재 우리 앱:
- 역마살은 **년지 기준**으로만 계산
- 년지=신(申) → 신자진(수국) → 역마=인(寅)
- 그래서 일지(사)와 년지(신)에 역마살 없음 판정

포스텔러 추정:
- 역마살을 **일지 기준**으로도 추가 계산
- 또는 **삼합 그룹별 역마** 개별 적용

```
역마살 공식 (삼합 기준):
- 인오술(화국) → 역마=신
- 사유축(금국) → 역마=해
- 신자진(수국) → 역마=인
- 해묘미(목국) → 역마=사

포스텔러가 년지(신)에 역마살 표시 이유:
- 일지(사)가 사유축(금국) → 역마=해... 아님
- 다른 로직 사용 추정
```

#### 3.3 도화살 계산 문제
현재 우리 앱:
- 도화살은 **12신살의 연살(年煞)**로 계산
- 년지=신(申) → 신자진(수국) → 연살=유(酉)
- 그래서 시지(묘)에 도화살 없음 판정

포스텔러 추정:
- 도화살을 **일지 기준**으로도 계산
- 일지(사) → 사유축(금국) → 도화=묘(卯) ✅

---

### 4. 수정 권장사항

#### 우선순위 1: 12신살 기준 변경 (High)
```dart
// twelve_sinsal_service.dart 수정
static TwelveSinsalAnalysisResult analyzeFromChart(
  SajuChart chart, {
  bool useYearJi = true, // true: 년지 기준 (포스텔러 방식)
})
```

#### 우선순위 2: 도화살 로직 보완 (Medium)
- 년지 기준 도화살 + 일지 기준 도화살 둘 다 계산
- 해당 지지에 둘 중 하나라도 해당되면 도화살 표시

```dart
bool hasDohwasal(String yearJi, String dayJi, String targetJi) {
  // 년지 기준 도화살
  final yearDohwa = getDohwaJi(yearJi);
  // 일지 기준 도화살
  final dayDohwa = getDohwaJi(dayJi);

  return targetJi == yearDohwa || targetJi == dayDohwa;
}
```

#### 우선순위 3: 역마살 로직 보완 (Medium)
- 역마살도 년지 + 일지 기준 둘 다 계산

```dart
bool hasYeokmasal(String yearJi, String dayJi, String targetJi) {
  final yearYeokma = getYeokmaJi(yearJi);
  final dayYeokma = getYeokmaJi(dayJi);

  return targetJi == yearYeokma || targetJi == dayYeokma;
}
```

---

### 5. 추가 조사 완료 ✅

#### 명리학 표준 조사 결과

**참고 자료:**
- [나무위키 - 사주팔자/신살](https://namu.wiki/w/사주팔자/신살)
- [대구신문 - 12신살의 이론과 적용](https://www.idaegu.co.kr/news/articleView.html?idxno=396467)
- [사주스터디 - 도화살](https://www.sajustudy.com/88)

**결론:**
- **고전 명리학**: 년지 기준
- **현대 명리학**: 일지 기준 (개인 중심)
- **우리 앱**: 명리학 표준 정확히 준수
- **포스텔러와 차이**: 포스텔러가 다른 12신살 테이블 사용 (표준과 다름)

---

### 6. Phase 36 수정 완료 ✅

#### 추가된 기능

**1. 년지+일지 병행 기준 함수 (twelve_sinsal.dart)**
```dart
// 도화살 여부 (년지 또는 일지 기준)
bool hasDohwasal(String yearJi, String dayJi, String targetJi);

// 역마살 여부 (년지 또는 일지 기준)
bool hasYeokmasal(String yearJi, String dayJi, String targetJi);

// 화개살 여부 (년지 또는 일지 기준)
bool hasHwagaesal(String yearJi, String dayJi, String targetJi);

// 기준 정보 조회
String? getDohwasalBasis(String yearJi, String dayJi, String targetJi);
String? getYeokmasalBasis(String yearJi, String dayJi, String targetJi);
```

**2. DualBasisSinsalResult 클래스 (twelve_sinsal_service.dart)**
```dart
class DualBasisSinsalResult {
  final TwelveSinsalAnalysisResult yearBasisResult;  // 년지 기준
  final TwelveSinsalAnalysisResult dayBasisResult;   // 일지 기준
  final List<String> dohwasalPillars;   // 도화살 있는 주
  final List<String> yeokmasalPillars;  // 역마살 있는 주
  final List<String> hwagaesalPillars;  // 화개살 있는 주
}
```

**3. 사용 예시**
```dart
// 병행 기준 분석
final result = TwelveSinsalService.analyzeWithDualBasisParams(
  yearJi: '신',
  monthJi: '유',
  dayGan: '정',
  dayJi: '사',
  hourJi: '묘',
);

print(result.dohwasalPillars); // ['월지'] - 월지(유)에 도화살
print(result.hasYeokmasal);    // false - 역마살 없음
```

#### 테스트 결과 ✅

```
=== 이여진 프로필 검증 ===
사주: 임신/기유/정사/계묘 (년지=신, 일지=사)

년지(신) 기준 - 신자진(수국):
  시지(묘): 육해 ✅
  일지(사): 겁살 ✅
  월지(유): 연살(도화) ✅
  년지(신): 지살 ✅

일지(사) 기준 - 사유축(금국):
  시지(묘): 재살 ✅
  일지(사): 지살 ✅
  월지(유): 장성 ✅
  년지(신): 망신 ✅

도화살 (병행): 월지(유) ✅
역마살 (병행): 없음 ✅
```

---

### 7. 관련 파일

| 파일 | 역할 |
|------|------|
| `twelve_sinsal_service.dart` | 12신살 계산 서비스 + DualBasisSinsalResult |
| `twelve_sinsal.dart` | 12신살 테이블 + 병행 기준 함수 |
| `test/sinsal_dual_basis_test.dart` | Phase 36 테스트 |

---

## Phase 38: 신강/신약 비율 기준 등급 결정 (2026-01-05) ✅ 완료

### 개요
삼주(시간 모름)와 사주(시간 있음) 간 등급 일관성 유지를 위해 점수/만점 비율 기준으로 등급 결정

### 점수 체계
| 구성 | 사주 (시간 있음) | 삼주 (시간 모름) |
|------|-----------------|-----------------|
| 천간 | 연간 10 + 월간 10 + 시간 10 = 30점 | 연간 10 + 월간 10 = 20점 |
| 지지 | 연지 10 + 월지 30 + 일지 15 + 시지 15 = 70점 | 연지 10 + 월지 30 + 일지 15 = 55점 |
| **만점** | **100점** | **75점** |

### 비율 기준 8단계 등급
| 비율 | 등급 |
|------|------|
| 88%+ | 극왕 |
| 75-87% | 태강 |
| 63-74% | 신강 |
| 50-62% | 중화신강 |
| 38-49% | 중화신약 |
| 26-37% | 신약 |
| 13-25% | 태약 |
| 0-12% | 극약 |

### 수정 파일
- `frontend/lib/features/saju_chart/domain/services/day_strength_service.dart`

---

## Phase 39: 12신살 년지 기준 변경 (2026-01-05) ✅ 완료

### 개요
포스텔러 앱과 12신살 결과가 다르게 나오는 문제 해결

### 문제
- 포스텔러: 시지(진)=천살, 월지/일지(해)=역마살
- 우리 앱 (기존): 시지(진)=반안, 월지/일지(해)=지살

### 원인
- 우리 앱: 일지(해) 기준 → 해묘미(목국) 삼합
- 포스텔러: 년지(축) 기준 → 사유축(금국) 삼합

### 수정 내용
```dart
// Before:
static TwelveSinsalAnalysisResult analyzeFromChart(SajuChart chart, {
  bool useYearJi = false, // 일지 기준
})

// After:
static TwelveSinsalAnalysisResult analyzeFromChart(SajuChart chart, {
  bool useYearJi = true, // 년지 기준 (포스텔러 호환)
})
```

### 수정 파일
| 파일 | 변경 내용 |
|------|-----------|
| `twelve_sinsal_service.dart` | `useYearJi` 기본값 true로 변경 |
| `possteller_style_table.dart` | 주석 업데이트 |
| `saju_detail_tabs.dart` | 주석 업데이트 |
| `twelve_sinsal_basis_test.dart` | **신규** - 년지/일지 기준 비교 테스트 |

### 테스트 결과 (박재현 사주)
```
년지(축) 기준 (포스텔러 방식):
  시지(진): 천살 ✅
  일지(해): 역마 ✅
  월지(해): 역마 ✅
  년지(축): 화개
```

---

## Phase 40: GPT 프롬프트 오행 데이터 수정 (2026-01-06) ✅ 완료

### 개요
ai_summaries.content.saju_origin.oheng이 모두 0으로 저장되는 문제 해결

### 문제 현상
- DB의 `saju_analyses.oheng_distribution`에는 정상 데이터 저장됨: `{"금(金)":2,"목(木)":2,"수(水)":1,"토(土)":2,"화(火)":1}`
- 그러나 `ai_summaries.content.saju_origin.oheng`은 모두 0: `{"금":0,"목":0,"수":0,"토":0,"화":0}`

### 원인 분석

**1단계: queries.dart 키 불일치** (이전 세션에서 수정 완료)
- DB는 한글(한자) 키: `목(木)`, `화(火)` 등
- 읽을 때 영어 키로 시도: `wood`, `fire` 등
- 수정: 한글(한자) 키로 읽도록 변경

**2단계: GPT 프롬프트 템플릿 문제** (이번 수정)
- `saju_base_prompt.dart` 232줄에 JSON 스키마가 하드코딩:
  ```dart
  "oheng": {"목": 0, "화": 0, "토": 0, "금": 0, "수": 0},
  ```
- GPT가 이 템플릿의 0 값을 그대로 복사하여 응답
- 실제 오행 데이터(`data.ohengString`)는 프롬프트 상단에 있지만, GPT가 스키마 채우기에서 무시

### 수정 내용

**파일 1: `frontend/lib/AI/prompts/prompt_template.dart`**
```dart
// 추가된 getter (line 438-449)
/// 오행 분포 JSON 문자열 (한글 키)
///
/// GPT 프롬프트 JSON 스키마에 직접 삽입용
/// 예: {"목": 2, "화": 1, "토": 3, "금": 1, "수": 1}
String get ohengJson {
  final mok = oheng['wood'] ?? 0;
  final hwa = oheng['fire'] ?? 0;
  final to = oheng['earth'] ?? 0;
  final geum = oheng['metal'] ?? 0;
  final su = oheng['water'] ?? 0;
  return '{"목": $mok, "화": $hwa, "토": $to, "금": $geum, "수": $su}';
}
```

**파일 2: `frontend/lib/AI/prompts/saju_base_prompt.dart`**
```dart
// Before (line 232)
"oheng": {"목": 0, "화": 0, "토": 0, "금": 0, "수": 0},

// After
"oheng": ${data.ohengJson},
```

### 테스트 결과 ✅ 검증 완료 (2026-01-06)

**김동현 프로필** (profile_id: `39f79705-504d-49b2-bb37-b829e0623a2e`)

| summary_type | input_data.oheng | content.saju_origin.oheng | 상태 |
|--------------|------------------|---------------------------|------|
| saju_base | `{fire:1, wood:2, earth:2, metal:2, water:1}` | `{금:2, 목:2, 수:1, 토:2, 화:1}` | ✅ 정상 |
| daily_fortune | `{fire:1, wood:2, earth:2, metal:2, water:1}` | `null` (정상 - 일운은 없음) | ✅ 정상 |

**참고**: daily_fortune은 `saju_origin` 필드가 없는 것이 정상 동작입니다.

### 관련 파일
| 파일 | 역할 |
|------|------|
| `AI/prompts/prompt_template.dart` | SajuInputData 클래스 + ohengJson getter |
| `AI/prompts/saju_base_prompt.dart` | GPT-5.2 평생 사주 분석 프롬프트 |
| `AI/data/queries.dart` | DB → SajuInputData 변환 (이전 세션에서 수정) |

---

## Phase 41-42: 합충형파해 포스텔러 기준 구현 (2026-01-06) ✅ 완료

### 개요
합충형파해 관계 분석을 포스텔러 앱 기준에 맞게 수정 및 전체 검증

### Phase 41: 반합/반방합 느슨한 기준

**기존 문제**:
- 반합: 왕지(旺支) 필수 → 포스텔러는 2개면 OK
- 방합: 3개 필수 → 포스텔러는 2개면 반방합

**수정 내용**:
| 파일 | 변경 |
|------|------|
| `hapchung_relations.dart` | isHalfMatchLoose(), findJijiHalfSamhapWithType(), findJijiHalfBanghap() 추가 |
| `hapchung_service.dart` | SamhapHalfType enum, halfType 필드, 느슨한 반합/반방합 로직 |
| `hapchung_tab.dart` | displayLabel 기반 라벨 표시 |

### Phase 42: 자묘형(무례지형) 추가 및 전체 검증

**추가된 형(刑)**:
- 자묘형(子卯刑) = 무례지형(無禮之刑)
- 자수(子水)와 묘목(卯木)의 관계 - 예의 없는 행동, 성적 문제, 구설 등

**수정 내용**:
| 파일 | 변경 |
|------|------|
| `hapchung_relations.dart` | HyungType.muRye enum, jijiHyungList에 자묘형 추가 |
| `gongmang_table.dart` | _jijiHyungMap에 자-묘 형 관계 추가 (해공 판단용) |

### 전체 검증 결과

| 카테고리 | 항목 | 상태 |
|---------|------|------|
| **합(合)** | 천간합(5), 육합(6), 삼합(4국), 반합, 방합(4방), 반방합 | ✅ 완료 |
| **충(沖)** | 천간충(4), 지지충(6) | ✅ 완료 |
| **형(刑)** | 무은지형(인사신), 지세지형(축술미), 무례지형(자묘), 자형(진/오/유/해) | ✅ 완료 |
| **파(破)** | 6파 | ✅ 완료 |
| **해(害)** | 6해 | ✅ 완료 |
| **원진** | 6원진 | ✅ 완료 |
| **공망** | 6순, 진공/반공/해공/탈공 | ✅ 완료 |

### 테스트 프로필
- **김동현**: 음력 1994/11/28, 09:20, 남자
- **사주**: 갑술 병자 경인 경진 (지지: 술, 자, 인, 진)
- **테스트 결과**:
  - 자진반합(수국) halfType: halfWithWangji ✅
  - 인술반합(화국) halfType: halfLoose ✅
  - 인진반방합(동방목) isFullBanghap: false ✅
  - 술진충, 갑경충 ✅

---

## Phase 43: 사주 관계도 DB 설계 및 궁합 채팅 라우팅 (2026-01-08~09) ✅ 완료

### DB 마이그레이션 (2026-01-08 완료)

| 작업 | 상태 | 설명 |
|------|------|------|
| profile_type 컬럼 추가 | ✅ | saju_profiles에 'primary' \| 'other' 컬럼 |
| 기존 데이터 마이그레이션 | ✅ | primary: 150개, other: 1개 |
| profile_relations 활성화 | ✅ | 1건 테스트 데이터 (이지나→홍길동) |
| 성능 인덱스 생성 | ✅ | 6개 인덱스 추가 |

### Flutter 코드 (2026-01-09 완료)

| 파일 | 변경 내용 |
|------|----------|
| `saju_profile_model.dart` | profileType 필드 추가 |
| `compatibility_context.dart` | **CompatibilityContext** 모델 생성 (두 프로필 사주 컨텍스트) |
| `compatibility_context.dart` | **CompatibilityAnalysisCache** 모델 (DB 캐시 매핑) |
| `routes.dart` | sajuChatCompatibility 라우트 추가 |
| `app_router.dart` | 궁합 채팅 라우트 등록 (from, to, relationType 파라미터) |
| `saju_chat_shell.dart` | fromProfileId, toProfileId, relationType 파라미터 추가 |
| `relationship_screen.dart` | QuickView "사주 상담" 버튼 → 궁합 채팅 라우팅 연결 |

### CompatibilityContext 모델

```dart
class CompatibilityContext {
  final SajuProfileModel fromProfile;      // 나의 프로필
  final SajuAnalysisModel fromAnalysis;    // 나의 사주 분석
  final SajuProfileModel toProfile;        // 상대방 프로필
  final SajuAnalysisModel toAnalysis;      // 상대방 사주 분석
  final ProfileRelationType relationType;  // 관계 유형 (19종)

  String toPromptContext();  // AI 프롬프트용 문자열 생성
  String get analysisType;   // family, love, friendship, business, general
}
```

### 궁합 채팅 라우트

```
/saju/chat/compatibility?from={나의 profile_id}&to={상대방 profile_id}&relationType={관계유형}
```

### 관련 문서
- `docs/02_features/saju_relationship_db.md` v1.1

### 다음 작업
- **Phase 43-B**: SajuChatShell에서 두 사주 분석 로드 및 AI 전달
- **Phase 43-C**: compatibility_analyses 테이블 저장/조회 (캐싱)

---

## Phase 44: 궁합 채팅 targetProfileId 연동 (2026-01-10) ✅ 완료

### 개요
궁합 채팅 시 상대방 프로필/사주를 AI에게 전달하여 두 사람의 궁합 분석이 가능하도록 구현

### 구현 완료 (2026-01-10)

**Step 1: DB 마이그레이션** ✅
- `chat_sessions.target_profile_id` 컬럼 추가 (FK → saju_profiles)
- 부분 인덱스 생성: `idx_chat_sessions_target_profile`
- 마이그레이션 이름: `add_target_profile_id_to_chat_sessions`

**Step 2: Flutter 코드 수정** ✅ (9개 파일)
1. `chat_session.dart`: targetProfileId 필드 추가
2. `chat_session_model.dart`: JSON/Hive/Supabase 매핑 추가
3. `saju_chat_shell.dart`: _ChatContent에 targetProfileId 전달, sendMessage에 파라미터 추가
4. `chat_session_provider.dart`: createSession()에 targetProfileId 파라미터
5. `chat_session_repository.dart` (interface): createSession() 시그니처 수정
6. `chat_session_repository_impl.dart`: targetProfileId 처리 로직 추가
7. `chat_provider.dart`: sendMessage()에서 상대방 프로필/사주 조회, 디버그 로그 개선
8. `system_prompt_builder.dart`: 궁합 모드 지원 (_addTargetProfileInfo, _addCompatibilityInstructions)
9. `core/repositories/chat_repository.dart`: Supabase createSession/fromMap 수정

### 해결된 문제

**이전 증상**: `/saju/chat?profileId=xxx` 라우트로 접근해도 AI가 상대방 사주를 모름
- "동현이의 생년월일 정보를 몰라서..." 응답

**해결**:
1. ✅ `chat_sessions` 테이블에 `target_profile_id` 컬럼 추가
2. ✅ `_ChatContent` 위젯에 `targetProfileId` props 전달
3. ✅ `sendMessage()`에서 상대방 프로필/사주 조회 로직 추가
4. ✅ 시스템 프롬프트에 궁합 분석 가이드 포함

### DB 구조 분석 결과 (2026-01-10)

**현재 테이블 구조**:
```
chat_sessions (93개 세션)
├── id (PK)
├── profile_id (FK → saju_profiles) ← 나의 프로필
├── title
├── chat_type ('general' | 'dailyFortune' | 'sajuAnalysis' | 'compatibility')
├── message_count
├── context_summary
└── ❌ target_profile_id 없음!

profile_relations (6개 관계)
├── from_profile_id → 나
├── to_profile_id → 상대방
├── from_profile_analysis_id → saju_analyses (나 사주) ✅
├── to_profile_analysis_id → saju_analyses (상대방 사주) ✅
└── relation_type

saju_analyses (142개 분석)
├── profile_id (1:1 매핑)
├── year/month/day/hour_gan/ji (사주팔자)
├── oheng_distribution (오행)
├── yongsin (용신/희신/기신/구신)
├── sipsin_info (십성)
├── hapchung (합충형파해) ← 궁합 분석에 핵심!
└── ai_summary
```

### Step 1: DB 마이그레이션 (⭐ 먼저 실행)

**마이그레이션 SQL**:
```sql
-- 1. chat_sessions에 target_profile_id 컬럼 추가
ALTER TABLE chat_sessions
ADD COLUMN target_profile_id uuid REFERENCES saju_profiles(id);

-- 2. 궁합 세션 조회 최적화 인덱스
CREATE INDEX idx_chat_sessions_target_profile
ON chat_sessions(target_profile_id)
WHERE target_profile_id IS NOT NULL;

-- 3. 컬럼 코멘트
COMMENT ON COLUMN chat_sessions.target_profile_id IS
'궁합 채팅 시 상대방 프로필 ID. NULL이면 일반 채팅';
```

**RLS 정책**: 기존 `profile_id` 기반 정책으로 충분 (추가 불필요)

### Step 2: Flutter 코드 수정

**수정 파일 목록**:

| 파일 | 변경 내용 |
|------|-----------|
| `chat_session.dart` | `targetProfileId` 필드 추가 |
| `chat_session_model.dart` | JSON 매핑 추가 |
| `saju_chat_shell.dart` | `_ChatContent`에 `targetProfileId` props 전달 |
| `chat_session_provider.dart` | `createSession()`에 `targetProfileId` 파라미터 |
| `chat_provider.dart` | `sendMessage()`에서 상대방 사주 조회 |
| `system_prompt_builder.dart` | `buildForCompatibility()` 메서드 추가 |

**데이터 흐름**:
```
Route: /saju/chat?profileId=김동현UUID
    ↓
SajuChatShell(targetProfileId: xxx)
    ↓
_ChatContent(targetProfileId: xxx) ← 수정 필요
    ↓
createSession(chatType, myProfileId, targetProfileId) ← 수정 필요
    ↓
chat_sessions INSERT (target_profile_id = xxx)
    ↓
sendMessage() → targetProfileId 기반 상대방 조회 ← 수정 필요
    ↓
saju_profiles + saju_analyses JOIN
    ↓
SystemPromptBuilder.buildForCompatibility() ← 신규
    ↓
Gemini AI → 나 + 상대방 사주 모두 인식!
```

### 조회 쿼리 (sendMessage에서 사용)

```sql
-- 상대방 프로필 + 사주 한 번에 조회
SELECT
    sp.id, sp.display_name, sp.birth_date, sp.gender,
    sa.year_gan, sa.year_ji, sa.month_gan, sa.month_ji,
    sa.day_gan, sa.day_ji, sa.hour_gan, sa.hour_ji,
    sa.oheng_distribution, sa.yongsin, sa.day_strength,
    sa.sipsin_info, sa.hapchung
FROM saju_profiles sp
JOIN saju_analyses sa ON sp.id = sa.profile_id
WHERE sp.id = :targetProfileId;
```

### 다음 작업 (Phase 44-B)

**compatibility_analyses 캐싱** (선택):
- 궁합 분석 결과를 DB에 저장하여 재사용
- 테이블: `compatibility_analyses`
- 구현 시 Phase 44-B로 진행

### 검증 테스트 (TODO)

```
1. 인연 관계도 → 김동현 클릭 → "사주 상담"
2. /saju/chat?profileId=김동현UUID 라우트 확인
3. AI에게 "나랑 동현이 궁합 어때?" 질문
4. AI가 두 사람 사주 모두 언급하는지 확인
5. 브라우저 새로고침 후에도 상대방 정보 유지 확인
```

---

## Phase 45: 인연 추가 DB 저장 버그 수정 (2026-01-13) ✅ 완료

### 개요
인연 추가 화면에서 저장 시 DB에 데이터가 저장되지 않는 문제

### 원인
`relation_edit_provider.dart`의 `_saveToSupabase()` 메서드에서:
- 에러를 `catch`로 잡고 로그만 출력
- `rethrow` 하지 않아서 상위 코드에서 에러 인식 불가
- 결과: 저장 실패해도 성공처럼 처리됨

### 해결
```dart
// relation_edit_provider.dart
Future<void> _saveToSupabase() async {
  try {
    // ... Supabase 저장 로직
  } catch (e) {
    debugPrint('[RelationEdit] Supabase 저장 오류: $e');
    rethrow;  // ✅ 추가: 에러를 상위로 전파
  }
}
```

### 검증 결과
| 항목 | 상태 |
|------|------|
| `saju_profiles` (other) | ✅ 저장 확인 |
| `profile_relations` | ✅ 저장 확인 |
| UI 피드백 | ✅ 정상 |

---

## Phase 46: 궁합 채팅 UI (2026-01-13) ✅ 완료

### 개요
채팅 화면에서 궁합 채팅을 쉽게 시작할 수 있는 UI 추가

### 구현 내용

#### 새 파일: `relation_selector_sheet.dart`
- Bottom Sheet UI로 인연 목록 표시
- 카테고리별 그룹핑 (가족, 연인, 친구, 직장, 기타)
- 선택 시 `RelationSelection` 반환 (relation + mentionText)

#### 수정 파일: `saju_chat_shell.dart`
- "+" 버튼 → PopupMenu로 변경
  - "일반 채팅": 기존 `_handleNewChat()` 호출
  - "궁합 채팅": 새 `_handleCompatibilityChat()` 호출
- `_handleCompatibilityChat()`:
  1. `RelationSelectorSheet.show()` 호출
  2. 선택된 인연으로 세션 생성
  3. `targetProfileId` + 초기 메시지(`@카테고리/이름님과의 궁합이 궁금해요`)

### 데이터 흐름
```
"+" 클릭 → PopupMenu 표시
    ├── "일반 채팅" → _handleNewChat()
    └── "궁합 채팅" → _handleCompatibilityChat()
                         ├── RelationSelectorSheet 표시
                         ├── 인연 선택
                         ├── createSession(targetProfileId, initialMessage)
                         └── CompatibilityAnalysisService.analyzeCompatibility()
                              └── compatibility_analyses 테이블 INSERT ✅
```

### DB 저장 확인
```sql
SELECT * FROM compatibility_analyses WHERE analysis_type = 'friendship';
-- 결과: 1개 레코드 확인 ✅
-- profile1_id: cd907507-5cad-45bf-b970-1c23fba2301c (박재현)
-- profile2_id: 9ac2f988-406a-4fbb-85a9-2883d2aa8fb9 (김동현)
-- analysis_type: friendship
-- from_profile_analysis_id: NULL (saju_analyses 연동 필요)
-- to_profile_analysis_id: NULL (saju_analyses 연동 필요)
```

### 남은 작업 (Phase 44-B)
- `from_profile_analysis_id`, `to_profile_analysis_id` 연동
- 기존 궁합 분석 결과 캐싱 (조회/재사용)

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

---

## Phase 47: 궁합 분석 아키텍처 재설계 (2026-01-13) ⚠️ 수정됨

> **Note**: Phase 47-B에서 재검토되어 아키텍처가 수정됨

### 초기 설계 (잘못된 방향)

| 대상 | 사주 계산 | 저장 위치 |
|------|----------|-----------|
| 나(userId) | GPT-5.2 | `saju_analyses` 테이블 |
| 인연(relation) | **Gemini 직접 계산** | `compatibility_analyses.saju_analysis` (JSONB) |

### 참조
- Frontend 상세: `Task_Jaehyeon.md` Phase 47 참조
- **정확한 아키텍처**: Phase 47-B 참조

---

## Phase 47-B: 궁합 아키텍처 재검토 및 데이터 수정 (2026-01-14) ✅ 완료

### 개요
Phase 47에서 설계한 "Gemini 직접 계산" 방식 재검토 → **기존 saju_analyses 테이블 활용 방식이 정확함**

### 아키텍처 확정 (최종)

| 테이블 | 용도 | 저장 대상 |
|--------|------|-----------|
| `saju_profiles` | 기본 프로필 정보 | 나 + 인연 |
| `saju_analyses` | 사주 분석 결과 (만세력, 십신, 대운 등) | **나 + 인연 모두** |
| `compatibility_analyses` | 궁합 분석 결과 (합충형해파 점수) | 쌍(pair) 단위 |
| `profile_relations` | 관계 연결 | from → to 연결 |

### 확정된 데이터 흐름

```
[인연 프로필 생성]
    │
    ▼
relationship_add_screen.dart Step 3.5:
    - Dart 만세력 계산 (sajuCalculationServiceProvider)
    - saju_analyses 테이블에 저장 (currentSajuAnalysisDbProvider)

[궁합 채팅 시작]
    │
    ▼
나(from): saju_profiles → saju_analyses 조회
    │
    ▼
인연(to): saju_profiles → saju_analyses 조회 (같은 방식!)
    │
    ▼
Dart 궁합 계산:
    - compatibility_calculator.dart 사용 (Gemini 아님!)
    - model_provider: 'dart'
    - tokens_used: 0
    │
    ▼
compatibility_analyses 저장:
    - overall_score, category_scores
    - saju_analysis: Dart 계산 결과
```

### profile_relations FK 정리 (수정됨)

| 컬럼 | 용도 | Phase 47-B 후 |
|------|------|---------------|
| `from_profile_analysis_id` | 나의 `saju_analyses` FK | ✅ 사용 |
| `to_profile_analysis_id` | 인연의 `saju_analyses` FK | ✅ **사용** (기존 인연은 수동 삽입 필요) |
| `compatibility_analysis_id` | 궁합 분석 FK | ✅ 사용 |

### 문제 발견 및 해결

**문제**: 기존 인연(박재현)에 `saju_analyses` 데이터 없음
- 원인: Phase 47 이전에 생성된 프로필이라 Step 3.5 코드가 없었음
- 영향 프로필: `e1dd9412-7483-4727-8c4d-e17e5f41b44d` (박재현, 1997-11-29)

**해결**: 수동 데이터 삽입 완료
```sql
INSERT INTO public.saju_analyses (profile_id, year_pillar, month_pillar, day_pillar, hour_pillar, ...)
VALUES ('e1dd9412-7483-4727-8c4d-e17e5f41b44d', '정축', '신해', '을해', '경진', ...);
-- 결과 ID: 2294db38-da66-4b23-b301-00241fd8b1de
```

### DB 상태 확인 (2026-01-14)

| 프로필 | saju_analyses | 사주 |
|--------|--------------|------|
| 송건우 (from) | ✅ 있음 | 임오 병오 계유 병진 |
| 박재현 (to) | ✅ 있음 (수동 삽입) | 정축 신해 을해 경진 |

```sql
-- 확인 쿼리
SELECT p.name, sa.year_pillar, sa.month_pillar, sa.day_pillar, sa.hour_pillar
FROM saju_profiles p
JOIN saju_analyses sa ON p.id = sa.profile_id
WHERE p.id IN (
  '박재현_profile_id',
  '송건우_profile_id'
);
```

### 결론

**새로운 테이블 필요 없음** - 기존 `saju_analyses` 활용이 정확한 설계
- 인연 프로필 생성 시 `relationship_add_screen.dart` Step 3.5에서 `saju_analyses` 자동 저장됨
- 궁합 계산은 Dart `compatibility_calculator.dart`로 수행 (Gemini 아님)
- 기존 인연은 수동으로 `saju_analyses` 데이터 삽입 필요

### 다음 단계
- [ ] 앱에서 궁합 채팅 테스트 (송건우 ↔ 박재현)
- [ ] `compatibility_analyses` 자동 생성 확인

---
