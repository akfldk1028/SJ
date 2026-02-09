# iOS IAP (앱 내 구입) 남은 작업

> 작성일: 2026-02-06
> 현재 상태: 앱 v0.1.0 심사 대기 중 (IAP 미포함)

---

## 현재 상황

### App Store Connect 상품 현황

| 상품 ID | 유형 | 현지화 | 가격 | 심사 메모 | 심사 스크린샷 | 상태 |
|---------|------|--------|------|-----------|-------------|------|
| `sadam_day_pass` | 비갱신 구독 | 한국어 OK | 175개국 (KRW 1,100) | OK | **미등록** | 메타데이터 누락 |
| `sadam_week_pass` | 비갱신 구독 | 한국어 OK | 174개국 (KRW 4,900) | OK | **미등록** | 메타데이터 누락 |
| `sadam_monthly` | 자동갱신 구독 (프리미엄 그룹) | 한국어 OK | 설정됨 (KRW 12,900) | OK | **미등록** | 메타데이터 누락 |

### RevenueCat 연동 상태 (Google Play)
- `sadam_day_pass`: Consumable, 정상 동작
- `sadam_week_pass`: Consumable, 정상 동작
- `sadam_monthly`: Subscription, 정상 동작

---

## TODO (순서대로)

### 1. 심사 스크린샷 업로드 (3개 상품 모두)
- [ ] 앱에서 페이월(구매) 화면 캡처 (iPhone 시뮬레이터)
- [ ] App Store Connect > 비갱신 구독 > `sadam_day_pass` > 심사 정보 > 스크린샷 업로드
- [ ] App Store Connect > 비갱신 구독 > `sadam_week_pass` > 심사 정보 > 스크린샷 업로드
- [ ] App Store Connect > 구독 > 프리미엄 > `sadam_monthly` > 심사 정보 > 스크린샷 업로드
- 스크린샷 업로드 후 상태가 "메타데이터 누락됨" → "제출 준비 중"으로 변경되는지 확인

### 2. 앱 버전에 상품 연결
- [ ] App Store Connect > iOS 앱 > 버전 페이지 > "앱 내 구입" 섹션에서 3개 상품 선택
- 현재 v0.1.0이 심사 대기 중이므로:
  - 방법 A: 심사 통과 후, 다음 버전(v0.1.1)에서 IAP 포함하여 제출
  - 방법 B: 현재 심사 취소 → IAP 연결 → 재제출 (심사 대기열 뒤로 밀림)

### 3. 심사 제출
- [ ] 상품 연결 후 앱 심사 제출
- Apple 안내: "첫 번째 비갱신 구독은 새로운 앱 버전과 함께 제출해야 합니다"

### 4. RevenueCat iOS 연동 확인
- [ ] RevenueCat 대시보드에서 iOS 앱 등록 확인
- [ ] RevenueCat에 App Store Connect Shared Secret 입력 확인
- [ ] iOS 샌드박스에서 구매 테스트

---

## 참고

### 비갱신 구독 vs 소모품 (iOS)
- iOS에서 day_pass/week_pass는 "비갱신 구독"으로 생성됨
- Google Play에서는 "일회성 제품" + RevenueCat Consumable
- 둘 다 재구매 가능하므로 동작상 문제 없음

### RevenueCat SDK `Missing productDetails` 경고
- `productType='subs'`로 먼저 조회 후 `inapp`으로 재조회하는 SDK 내부 동작
- 정상 동작이며 버그 아님 (RevenueCat 공식 확인)

### 관련 파일
- `frontend/lib/purchase/providers/purchase_provider.dart` - 구매 로직
- `frontend/lib/purchase/widgets/paywall_screen.dart` - 페이월 화면
- `frontend/lib/purchase/config/purchase_config.dart` - 상품 ID 설정
