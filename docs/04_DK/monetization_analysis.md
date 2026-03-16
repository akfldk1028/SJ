# 사담 수익화 분석 및 전략

> 작성: 2026-03-08 | 상태: AdMob 밴 (2/10 invalid traffic), 킬스위치 OFF

---

## 1. 현재 상태 요약

### AdMob 밴 원인 (Invalid Traffic)
- **직접 원인**: 네이티브 광고 클릭 → 토큰 보상 = **인센티브화 클릭 (정책 위반)**
- `onAdClicked` → `TokenRewardService.grantNativeAdTokens()` 직접 호출
- 소진 시 15,000 토큰, 인터벌 시 10,000 토큰 즉시 지급
- 클릭 횟수 제한 없음 → CTR 비정상 급등 → SDK가 Google에 리포트
- **AdMob 정책**: 보상형(Rewarded) 포맷만 보상 허용. Native/Banner/Interstitial 클릭 보상 = 금지

### 추가 위반 사항
| 항목 | 현재 | 정책 |
|------|------|------|
| 광고 라벨 | "후원자 소개" 10px | "광고"/"Ad" 15px+ |
| 시각적 구분 | 채팅 버블과 동일 디자인 | 명확히 구분 필요 |
| 클릭 제한 | 없음 (무제한) | 비정상 클릭 패턴 감지 시 밴 |

### 대체 네트워크 탐색 결과
| 네트워크 | 결과 |
|----------|------|
| AppLovin | 거절 (다운로드 부족) |
| Kakao AdFit | 앱 미인덱싱 (출시 후 2주, Play Store API 지연) |
| Pangle (TikTok) | 한국 개인사업자 불가 (중국 법인 또는 한국 법인 필요) |
| Yandex Ads | Flutter 미지원 (Android native만) |
| Unity Ads | 게임 전용, 비게임 앱 수익 저조 |
| InMobi/Smaato | 최소 트래픽 요구사항 (월 100만 노출+) |

**결론: 단기적으로 AdMob 밴 해제가 유일한 현실적 옵션**

---

## 2. 수익 구조 분석

### 토큰 이코노미 (현재)
```
일일 무료 쿼타: 20,000 토큰
메시지당 평균: ~6,485 토큰 (totalTokenCount 기준)
기본 대화 횟수: 20,000 / 6,485 = ~3회

광고 클릭 보상 (위반): 10,000~15,000 토큰/클릭
광고 시청 유저: 평균 6번 클릭 → 19회/일 대화
```

### 수익성 계산
```
네이티브 CPC (한국): ~$0.25/클릭
API 비용 (10K 토큰): ~$0.006 (Gemini Flash)
순이익/클릭: $0.244 (마진 97.6%)

BUT: 인센티브화 클릭 = 밴 → 수익 $0
```

### 유료 상품 (RevenueCat)
| 상품 | 가격 | 혜택 |
|------|------|------|
| sadam_day_pass | 24h | 토큰 무제한 + 광고 제거 |
| sadam_week_pass | 7일 | 토큰 무제한 + 광고 제거 |
| sadam_monthly | 월 구독 | 토큰 무제한 + 광고 제거 |

---

## 3. 수익화 전략 (AdMob 밴 해제 후)

### 핵심 원칙
> 네이티브/배너/전면 광고 = 노출 수익만 (CPM/CPC, 보상 금지)
> 보상형(Rewarded) 광고 = 유일한 토큰 보상 수단
> 운세 기능 해금 = Rewarded Ad 시청 (현재 구현 OK, 정책 준수)

### A. 광고 수익 (AdMob 정책 준수)

#### 네이티브 광고 (채팅 내)
- **역할**: 순수 노출/클릭 수익 (CPM/CPC)
- **보상 제거**: `_onAdClicked()`에서 토큰 지급 코드 삭제
- **라벨 수정**: "광고" 15px+, 배경색 구분
- **빈도**: 4~5메시지 간격 유지 (현재 설정 OK)
- **예상 수익**: eCPM $3~$15 (네이티브 미디엄)

#### 전면 광고 (세션 전환)
- **타이밍**: 새 세션 시작, 채팅 종료 시
- **빈도**: 1일 3~5회 제한 (현재 9999 → 수정 필요)
- **예상 수익**: eCPM $5~$11

#### 보상형 광고 (토큰 보상)
- **유일한** 토큰 보상 수단
- **트리거**: 토큰 소진 시 (100% 사용)
- **보상**: 영상 시청 완료 → 10,000~15,000 토큰
- **사용자 선택**: 시청 안 하면 대화 중단 or 유료 전환
- **현실**: 많은 유저가 안 볼 수 있음 → 구독 전환 유도

### B. 운세 기능 해금 (Rewarded Ad - 정책 준수)
```
feature_unlock_service.dart (현재 구현 OK)
- 연간 운세 카테고리 → 광고 시청으로 해금
- 월간 운세 카테고리 → 광고 시청으로 해금
- 평생운 → 광고 시청으로 해금
```
- 이 방식은 AdMob 정책 100% 준수 (Rewarded Ad 포맷 사용)
- 수정 불필요

### C. 구독/패스 전환 (핵심 수익)
- **토큰 소진 시**: 구독 CTA 강화 (광고 시청 vs 구독 선택)
- **프리미엄 혜택 강조**: 무제한 대화, 광고 제거, 전용 기능
- ChatGPT/Character.AI 모델: 무료 제한 → 유료 전환이 주 수익

---

## 4. 필수 수정 사항 (AdMob 밴 해제 전)

### P0: 정책 위반 수정
1. **`conversational_ad_provider.dart`**: `_onAdClicked()` 에서 토큰 지급 삭제
2. **`ad_native_bubble.dart`**: "후원자 소개" → "광고" (15px+)
3. **`native_ad_widget.dart`**: 광고 라벨 10px → 15px+
4. **`card_native_ad_widget.dart`**: 광고 라벨 가시성 개선
5. **`ad_strategy.dart`**: `intervalClickRewardTokens = 0`, `depletedRewardTokensNative = 0`

### P1: 빈도 조정
1. `interstitialDailyLimit`: 9999 → 5
2. `newSessionInterstitialDailyLimit`: 9999 → 3
3. `interstitialCooldownSeconds`: 0 → 120

### P2: UX 개선
1. 토큰 소진 시: 구독 CTA + 보상형 광고 선택지 (네이티브 클릭 보상 제거)
2. 네이티브 광고 시각적 구분 (배경색, 테두리 등)

---

## 5. 수익 시뮬레이션

### 시나리오: DAU 100명, AdMob 정상 가동
```
네이티브 CPM 수익:
  100명 × 5노출/일 × $7 eCPM / 1000 = $3.5/일

전면 광고 수익:
  100명 × 2회/일 × $8 eCPM / 1000 = $1.6/일

보상형 광고 수익:
  100명 × 30% 시청 × 2회 × $20 eCPM / 1000 = $1.2/일

운세 해금 광고:
  100명 × 20% × 1회 × $20 eCPM / 1000 = $0.4/일

광고 합계: ~$6.7/일 = ~$200/월

구독 전환:
  100명 × 5% 전환 × ₩9,900/월 = ₩49,500/월 (~$37)

API 비용:
  100명 × $0.03/일 = $90/월

월 순수익: ~$147/월 (DAU 100 기준)
```

### DAU 1,000명 시
```
광고: ~$2,000/월
구독: ~$370/월
API: ~$900/월
순수익: ~$1,470/월
```

---

## 6. 액션 아이템

| 순서 | 작업 | 파일 | 상태 |
|------|------|------|------|
| 1 | 네이티브 클릭 → 토큰 보상 제거 | conversational_ad_provider.dart | TODO |
| 2 | ad_strategy 보상 값 0으로 | ad_strategy.dart | TODO |
| 3 | 광고 라벨 "광고" 15px+ | native_ad_widget, ad_native_bubble, card_native_ad_widget | TODO |
| 4 | 광고 시각적 구분 | native_ad_widget, ad_native_bubble | TODO |
| 5 | 전면 광고 빈도 제한 | ad_strategy.dart | TODO |
| 6 | AdMob 정책 센터 확인 | 수동 | TODO |
| 7 | 밴 해제 후 `adEnabled = true` | ad_config.dart | TODO |
| 8 | 카카오 AdFit 재시도 (인덱싱 후) | 수동 | 대기 |
| 9 | AppLovin 재신청 (DAU 증가 후) | 수동 | 대기 |

---

## 7. 킬스위치 상태

```dart
// ad_config.dart
const bool adEnabled = false;  // 현재 OFF
// 밴 해제 + 위반사항 수정 완료 후 true로 변경
```

운세 기능 해금(feature_unlock_service)은 별도 플로우이므로 킬스위치와 무관하게 동작 가능.
단, adEnabled=false면 Rewarded Ad 로드 자체가 안 되므로 해금도 사실상 비활성.
