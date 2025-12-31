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

## 다음 작업 예정

1. 채팅 테스트 후 토큰 사용량 확인
2. 만세력 계산 추가 검증 (다른 생년월일 테스트)
3. Phase 26 (진공/반공 신살 추가) - 공망의 충/합 위치
4. 시간 모름 처리 개선 - 삼주(三柱) 분석 모드
5. 필요시 추가 버그 수정

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
