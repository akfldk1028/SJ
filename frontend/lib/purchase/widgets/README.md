# Purchase Widgets

## 개요
IAP 관련 UI 위젯. shadcn_ui + Material 혼용.

## PaywallScreen (`/settings/premium`)
- 3개 상품 카드 레이아웃
- RevenueCat `offeringsProvider`에서 상품 정보 가져옴
- 1주일 이용권에 "인기" 뱃지, 월간 구독에 "BEST" 뱃지 표시
- 하단에 구매 복원 버튼 (Apple 필수)
- 진입점: 설정 화면, quota 소진 시, 광고 카드 내 "프리미엄" 버튼

### 상품 카드 구조
```
┌─────────────────────────────┐
│  1일 이용권                   │
│  ₩1,100 (일회성)             │
│  [구매하기]                   │
├─────────────────────────────┤  ← 인기 뱃지
│  1주일 이용권                 │
│  ₩4,900 (일회성)             │
│  [구매하기]                   │
├─────────────────────────────┤  ← BEST 뱃지
│  월간 구독                    │
│  ₩12,900/월                  │
│  [구독하기]                   │
└─────────────────────────────┘
         [구매 복원]
```

## PremiumBadgeWidget
- 사용자 구매 상태에 따라 뱃지 표시
- Premium → 금색 "PRO" 뱃지
- 무료 → 표시 안 함
- 사용 위치: 설정 화면, 프로필 영역 등

## RestoreButtonWidget
- Apple 가이드라인 필수 요소
- "구매 복원" 텍스트 버튼
- `Purchases.restorePurchases()` 호출
- 성공/실패 SnackBar 표시
