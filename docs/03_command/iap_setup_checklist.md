# IAP 설정 체크리스트

## 상품별 혜택 매트릭스

| 혜택 | 무료 | 광고제거(₩2,900) | AI프리미엄(₩9,900/월) | 콤보(₩11,000/월) |
|------|------|----------------|---------------------|----------------|
| 강제 광고 (인터벌/네이티브) | O | **X** | O | **X** |
| 토큰 경고(80%) 광고 | O | **X** | O | **X** |
| 토큰 소진(100%) 보상형 광고 | O | **O** (충전 수단) | 해당 없음 | 해당 없음 |
| daily_quota | 20,000 | 20,000 | **무제한** | **무제한** |
| 토큰 충전 방법 | 보상형 광고 | **보상형 광고** | 불필요 | 불필요 |

> 광고 제거 = 강제 광고만 제거. 토큰 소진 시 보상형 광고는 유저가 직접 선택 가능.

---

## 순서 요약

| 순서 | 어디서 | 뭘 | 완료 |
|------|--------|-----|------|
| 1 | Google Play Console | 상품 3개 등록 + 테스터 Gmail 추가 | [ ] |
| 2 | RevenueCat | 프로젝트 생성 → API Key 발급 | [ ] |
| 3 | RevenueCat | Products + Entitlements + Offerings 설정 | [ ] |
| 4 | 코드 | `purchase_config.dart`에 API Key 입력 | [ ] |
| 5 | Supabase | SQL 실행 (subscriptions 테이블) | [ ] |
| 6 | Supabase | Edge Function 배포 | [ ] |
| 7 | RevenueCat | Webhook URL 등록 | [ ] |
| 8 | 테스트 | 라이선스 테스터로 3개 상품 테스트 구매 | [ ] |

---

## Step 1: Google Play Console

### 1-A. 인앱 상품 등록 (비소모성)

**경로**: `Play Console → 앱 선택 → 수익 창출 → 제품 → 인앱 상품 → "상품 만들기"`

| 항목 | 값 |
|------|-----|
| Product ID | `sadam_ad_removal` |
| 이름 | 광고 제거 |
| 설명 | 모든 광고를 영구적으로 제거합니다 |
| 가격 | ₩2,900 (VAT 제외 금액 입력) |
| 상태 | **활성** (반드시 활성으로 변경) |

### 1-B. 구독 등록

**경로**: `Play Console → 앱 선택 → 수익 창출 → 제품 → 구독 → "구독 만들기"`

1. 구독 그룹 생성: **"사담 프리미엄"**

2. 구독 상품 추가:

| Product ID | 이름 | 가격 | 기간 |
|-----------|------|------|------|
| `sadam_ai_premium` | AI 프리미엄 | ₩9,900/월 | 1개월 |
| `sadam_combo` | 올인원 | ₩11,000/월 | 1개월 |

- 각 구독에 기본 요금제(base plan) 추가
- 기간: 1개월, 자동 갱신
- 가격 설정 후 **활성** 상태로 변경

### 1-C. 라이선스 테스터 등록

**경로**: `Play Console → 설정(Settings) → 라이선스 테스트(License testing)`

- 앱별이 아님 → **개발자 계정 전역 설정**
- 테스트할 Gmail 주소 추가
- 이 계정으로 구매 시 실제 결제 안 됨
- 라이선스 응답: "RESPOND_NORMALLY" 선택

> **주의**: 앱이 최소 **내부 테스트 트랙**에 게시되어 있어야 인앱 결제 테스트 가능
> APK/AAB를 내부 테스트 트랙에 업로드 필요

### 1-D. 앱 서명 키 확인

**경로**: `Play Console → 앱 선택 → 설정 → 앱 무결성 → 앱 서명`

- SHA-1 인증서 지문 복사
- RevenueCat Android 앱 등록 시 필요

---

## Step 2: RevenueCat Dashboard — 프로젝트 생성

**URL**: https://app.revenuecat.com

1. **Projects → "+ New"** 클릭
2. 프로젝트 이름: "사담 (Sadam)"
3. **Android 앱 추가**:
   - 패키지명: `com.example.sadam` (실제 패키지명)
   - Google Play Credentials (JSON key) 업로드
     - Google Cloud Console → 서비스 계정 → JSON 키 생성
     - Play Console → 설정 → API 액세스에서 서비스 계정 연결
4. **API Key 복사**: `goog_xxxxxx` 형태
   - → `purchase_config.dart`의 `revenueCatApiKeyAndroid`에 입력

---

## Step 3: RevenueCat — Products + Entitlements + Offerings

### 3-A. Products 등록

**경로**: `RevenueCat → Project → Products → "+ New"`

| App Store Product ID | 플랫폼 |
|---------------------|--------|
| `sadam_ad_removal` | Google Play |
| `sadam_ai_premium` | Google Play |
| `sadam_combo` | Google Play |

### 3-B. Entitlements 생성

**경로**: `RevenueCat → Project → Entitlements → "+ New"`

| Entitlement ID | 연결 Products |
|---------------|--------------|
| `ad_free` | `sadam_ad_removal`, `sadam_combo` |
| `ai_premium` | `sadam_ai_premium`, `sadam_combo` |

### 3-C. Offerings 설정

**경로**: `RevenueCat → Project → Offerings`

- `default` Offering 생성 (또는 기본 사용)
- 3개 Package 추가:
  - `sadam_ad_removal` → Lifetime 타입
  - `sadam_ai_premium` → Monthly 타입
  - `sadam_combo` → Monthly 타입

---

## Step 4: 코드 — API Key 입력

`frontend/lib/purchase/purchase_config.dart`:
```dart
static const String revenueCatApiKeyAndroid = 'goog_실제키';
static const String revenueCatApiKeyIos = 'appl_나중에';
```

---

## Step 5: Supabase — subscriptions 테이블

SQL Editor에서 실행:
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  product_id TEXT NOT NULL,
  platform TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  original_transaction_id TEXT,
  starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  is_lifetime BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own subscriptions" ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role full access" ON subscriptions
  FOR ALL USING (auth.role() = 'service_role');

CREATE INDEX idx_subscriptions_user_status
  ON subscriptions(user_id, status);
```

---

## Step 6: Supabase — Edge Function 배포

```bash
supabase functions deploy purchase-webhook
supabase secrets set REVENUECAT_WEBHOOK_SECRET=your_secret_here
```

---

## Step 7: RevenueCat — Webhook 등록

**경로**: `RevenueCat → Project → Webhooks → "+ New"`

| 항목 | 값 |
|------|-----|
| URL | `https://<project-ref>.supabase.co/functions/v1/purchase-webhook` |
| Authorization | `Bearer <REVENUECAT_WEBHOOK_SECRET>` |

---

## Step 8: 테스트

### 테스트 시나리오

| # | 시나리오 | 확인 |
|---|---------|------|
| 1 | `sadam_ad_removal` 구매 → 광고 사라짐 | [ ] |
| 2 | `sadam_ai_premium` 구독 → 20,000 토큰 넘어도 채팅 가능 | [ ] |
| 3 | `sadam_combo` 구독 → 광고 없음 + 무제한 | [ ] |
| 4 | 구독 만료 → quota 20,000 복귀, 광고 다시 표시 | [ ] |
| 5 | 앱 재설치 → "구매 복원" → ad_removal 영구 복원 | [ ] |

### Google Play 테스트 구독 주기
- 1주일 → 5분
- 1개월 → 5분
- 3개월 → 10분
- 6개월 → 15분
- 1년 → 30분

---

## iOS (나중에)

App Store Connect에서 동일한 상품 등록 + Xcode에서 In-App Purchase capability 추가.
RevenueCat에 iOS 앱 추가 + `appl_xxx` API Key 발급.

---

## 참고 링크

- [인앱 상품 만들기 - Play Console](https://support.google.com/googleplay/android-developer/answer/1153481?hl=ko)
- [라이선스 테스트 - Play Console](https://support.google.com/googleplay/android-developer/answer/6062777?hl=ko)
- [Google Play Billing 테스트](https://developer.android.com/google/play/billing/test)
- [RevenueCat 문서](https://www.revenuecat.com/docs)
