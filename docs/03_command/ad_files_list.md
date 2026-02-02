# 광고 시스템 관련 파일 전체 리스트

> 날짜: 2026-02-02
> 목적: 다른 AI에게 컨텍스트 제공

---

## 📋 핵심 문서 (docs/03_command/)

### 1. 최종 설정 문서
- **`ad_token_final_settings.md`** ⭐ 최신
  - 클릭 광고만 사용 (영상 제거)
  - 토큰 15,000
  - 손익 계산 완료

### 2. 광고 시스템 문서
- **`ad_system.md`**
  - 광고 타입별 구조
  - 트리거 매핑
  - 페이지 전환 전면광고
  - 변경 이력 (v27, v28)

### 3. 비즈니스 로직
- **`v27_ad_business_logic.md`**
  - v27 광고 비즈니스 로직
  - 3가지 광고 경로
  - 토큰 보상 설정 (구버전)

### 4. 유저 플로우
- **`ad_token_user_flow.md`**
  - 토큰 시스템 개요
  - 유저 플로우
  - 손익 시나리오

### 5. 비용 계산 가이드
- **`ad_cost_calculation.md`**
  - Gemini 실제 가격
  - 손익분기 토큰 계산
  - 과거 계산 오류 분석

### 6. IAP 설정
- **`iap_setup_checklist.md`**
  - 인앱 결제 체크리스트
  - 광고 제거 상품 ($2,900)
  - RevenueCat 설정

### 7. 수익화 계획
- **`monetization_plan.md`**
  - 전체 수익화 전략
  - 광고 + IAP 통합

---

## 💻 코드 파일 (frontend/lib/)

### A. 광고 설정 및 전략

#### 1. `ad/ad_strategy.dart` ⭐ 핵심
```
광고 표시 전략 및 토큰 보상 설정
- depletedRewardTokensVideo = 0 (영상 제거)
- depletedRewardTokensNative = 15000 (클릭)
- inlineAdMessageInterval = 4
- intervalClickRewardTokens = 7000
```

#### 2. `ad/ad_config.dart`
```
AdMob 설정
- Ad Unit ID (Android/iOS)
- 테스트 광고 ID
- 광고 간격 설정
```

---

### B. 광고 서비스

#### 3. `ad/ad_service.dart` ⭐ 핵심
```
AdMob 광고 로딩 및 표시
- RewardedAd (영상, 미사용)
- InterstitialAd (전면)
- BannerAd (배너)
- NativeAd (네이티브)
```

#### 4. `ad/ad_tracking_service.dart`
```
광고 이벤트 추적
- Supabase ad_events 테이블 기록
- 노출, 클릭, 완료 추적
```

#### 5. `ad/token_reward_service.dart`
```
광고 보상 토큰 지급
- grantNativeAdTokens() - 네이티브 클릭 시
- grantRewardedAdTokens() - 영상 시청 시 (미사용)
- Supabase rewarded_tokens_earned 업데이트
```

#### 6. `ad/feature_unlock_service.dart`
```
광고 시청으로 기능 해금
- 운세 카테고리 해금
- Supabase feature_unlocks 테이블
```

---

### C. 광고 위젯

#### 7. `ad/widgets/native_ad_widget.dart` ⭐ 인라인 광고
```
채팅 버블 스타일 Native 광고
- NativeAdWidget (Medium 템플릿)
- CompactNativeAdWidget (Small 템플릿)
- onAdClicked: 7,000 토큰 지급
```

#### 8. `ad/widgets/inline_ad_widget.dart`
```
인라인 광고 (ChatAdWidget)
- 4메시지마다 표시
- 정적 Native 광고
```

#### 9. `ad/widgets/card_native_ad_widget.dart`
```
카드 스타일 Native 광고
- 메인 화면 등에 사용
```

#### 10. `ad/widgets/banner_ad_widget.dart`
```
하단 배너 광고 (Adaptive)
- BottomNavigationBar 위
```

---

### D. 채팅 내 광고 (features/saju_chat/)

#### 11. `features/saju_chat/presentation/widgets/token_depleted_banner.dart` ⭐ 핵심
```
토큰 소진 시 2버튼 배너
- 영상 버튼 (제거 예정)
- 클릭 버튼 (유지)
→ 1버튼으로 변경 필요
```

#### 12. `features/saju_chat/presentation/widgets/ad_native_bubble.dart`
```
대화형 네이티브 광고 버블
- 채팅 메시지처럼 보이는 광고
- AdNativeBubble 위젯
```

#### 13. `features/saju_chat/presentation/widgets/conversational_ad_widget.dart`
```
대화형 광고 위젯 (v27, 구버전)
- 청운도사 페르소나
- 현재 비활성화
```

#### 14. `features/saju_chat/presentation/providers/conversational_ad_provider.dart`
```
대화형 광고 상태 관리
- ConversationalAdNotifier
- AdMessageType (tokenDepleted, intervalAd 등)
- showRewardedAd(), switchToNativeAd()
```

#### 15. `features/saju_chat/data/services/ad_trigger_service.dart`
```
광고 트리거 체크
- checkTrigger() - 언제 광고 표시할지 판단
- tokenDepleted, tokenNearLimit 체크
```

---

### E. 기타 광고 관련

#### 16. `ad/providers/ad_provider.dart`
```
광고 상태 Provider
- 광고 로드 상태 관리
```

#### 17. `features/saju_chat/presentation/screens/saju_chat_shell.dart`
```
채팅 화면 Shell
- TokenDepletedBanner 포함
- 광고 표시 위치
```

---

## 🗄️ Supabase 테이블

### 1. `user_daily_token_usage`
```sql
토큰 사용량 추적
- daily_quota (20,000)
- chatting_tokens (사용량)
- rewarded_tokens_earned (보상형 광고 토큰)
- native_tokens_earned (네이티브 클릭 토큰)
- bonus_tokens (보너스)
```

### 2. `ad_events`
```sql
광고 이벤트 로그
- ad_type (rewarded, native, interstitial, banner)
- event_type (impression, click, complete)
- reward_tokens (지급된 토큰)
```

### 3. `feature_unlocks`
```sql
광고 시청으로 해금한 기능
- feature_type (yearly, monthly, daily)
- feature_key (career, love 등)
```

### 4. `subscriptions`
```sql
구독 정보 (IAP)
- product_id (sadam_ad_removal, sadam_ai_premium, sadam_combo)
- status (active, cancelled)
```

---

## 🔧 설정 파일

### 1. `frontend/pubspec.yaml`
```yaml
광고 관련 패키지
- google_mobile_ads: ^5.2.0
```

### 2. `frontend/android/app/src/main/AndroidManifest.xml`
```xml
AdMob App ID
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxx~xxxxx"/>
```

---

## 📊 IAP 관련 (구독 & 광고 제거)

### 1. `frontend/lib/purchase/purchase_config.dart`
```
RevenueCat 설정
- API Key
- 상품 ID (sadam_ad_removal, sadam_ai_premium, sadam_combo)
```

### 2. `frontend/lib/purchase/purchase_service.dart`
```
구매 서비스
- 광고 제거 여부 체크
- 프리미엄 구독 체크
```

---

## 🎯 광고 흐름 요약

### 1. 인라인 광고 (대화 중)
```
ChatAdWidget (4메시지마다)
→ NativeAdWidget
→ onAdClicked: 7,000 토큰 (선택)
```

### 2. 토큰 소진 광고
```
TokenDepletedBanner (토큰 0일 때)
→ 버튼 클릭: _handleNativeAd()
→ AdNativeBubble 표시
→ 클릭 시: 15,000 토큰
```

### 3. 전면 광고
```
페이지 전환 시
→ AdService.showInterstitialAd()
→ InterstitialAd 표시
```

---

## ⚠️ 주의사항

### AdMob 정책
- "광고 클릭하세요" 금지 → "광고 보고" 사용
- 클릭 유도 금지
- 인센티브는 "토큰" "대화" 등으로 표현

### 토큰 지급 타이밍
- Native Ad 클릭: 즉시 지급 (onAdClicked)
- Rewarded Video: 시청 완료 후 지급
- 웹페이지 방문 시간 추적 불가

### 현재 변경 필요
- [ ] `ad_strategy.dart`: depletedRewardTokensNative = 15000
- [ ] `token_depleted_banner.dart`: 버튼 1개로 변경
- [ ] 영상 광고 관련 코드 제거 또는 비활성화

---

## 📝 추가 참고

### AdMob 광고 타입
1. **Rewarded Video** (보상형 영상)
   - 끝까지 봐야 보상
   - eCPM $15~30
   - 현재 미사용

2. **Native Ad** (네이티브)
   - 콘텐츠에 자연스럽게 통합
   - 클릭 시 CPC $0.10~0.50
   - **현재 주 수익원**

3. **Interstitial** (전면)
   - 페이지 전환 시
   - eCPM $2~10

4. **Banner** (배너)
   - 하단 고정
   - eCPM $0.5~2

---

**이 파일 리스트를 다른 AI에게 제공하면 광고 시스템 전체를 이해할 수 있습니다.**
