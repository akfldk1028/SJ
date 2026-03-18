# Ad Kill Switch

## 현재 상태: OFF (광고 비활성화)

AdMob "invalid traffic" 제한으로 전체 광고 비활성화됨 (2026-02-10)

## 광고 켜기 (1줄 변경)

파일: `frontend/lib/ad/ad_config.dart` 20번째 줄

```dart
// 현재 (OFF)
const bool adEnabled = false;

// 변경 (ON)
const bool adEnabled = true;
```

## 킬스위치 적용 범위

### 광고 SDK 레이어
| 파일 | 체크 위치 |
|------|----------|
| `ad_config.dart` | `adEnabled` 플래그 정의 |
| `ad_service.dart` | `initialize()`, `loadBannerAd()`, `loadInterstitialAd()`, `loadRewardedAd()`, `showInterstitialAd()`, `showRewardedAdWithUnlock()` |
| `ad_provider.dart` | `preloadAds()`, `canShowInterstitial()`, `onChatMessage()`, `onNewSession()`, `onNewSessionRewarded()`, `canShowRewarded()` |

### 광고 위젯 레이어
| 파일 | 체크 위치 |
|------|----------|
| `banner_ad_widget.dart` | `_loadAd()`, `build()` |
| `inline_ad_widget.dart` | `_loadAd()`, `build()` |
| `native_ad_widget.dart` | `initState()`, `_loadAd()`, `build()` (NativeAdWidget + CompactNativeAdWidget) |
| `card_native_ad_widget.dart` | `_loadAd()`, `build()` |
| `chat_ad_factory.dart` | `ChatAdWidget.build()` — 안내텍스트 포함 (adEnabled=true일 때만 표시) |

### 대화형 광고 (채팅 내)
| 파일 | 체크 위치 |
|------|----------|
| `conversational_ad_provider.dart` | `_loadNativeAd()`, `_loadRewardedAd()` — SDK 호출 차단 |
| `token_depleted_banner.dart` | `build()` — adEnabled=false: "점검 중" 안내 + 프리미엄만 표시 |

### 쿼타/다이얼로그
| 파일 | 체크 위치 |
|------|----------|
| `quota_exceeded_dialog.dart` | 안내 메시지 + "광고 보고 토큰 받기" 버튼 숨김 |

### 운세 잠금해제 (보상형 광고)
| 파일 | 체크 위치 |
|------|----------|
| `fortune_category_chip_section.dart` | `_showAdNotReadyDialog()` — "점검 중" 메시지 |
| `fortune_monthly_chip_section.dart` | `_showAdNotReadyDialog()` — "점검 중" 메시지 |
| `fortune_weekly_chip_section.dart` | `_showAdNotReadyDialog()` — "점검 중" 메시지 |
| `fortune_monthly_step_section.dart` | `_showAdNotReadyDialog()` — "점검 중" 메시지 |

## adEnabled=false 일 때 유저 경험

| 상황 | 동작 |
|------|------|
| 채팅 인라인 광고 | 안 보임 (SizedBox.shrink) |
| 하단 배너 광고 | 안 보임 |
| 메뉴 카드 네이티브 광고 | 안 보임 |
| 토큰 소진 | "점검 중" + 프리미엄 구매 버튼만 |
| 쿼타 초과 다이얼로그 | "점검 중" 안내 + 광고 버튼 숨김 |
| 운세 잠금해제 | "점검 중" 다이얼로그 + 프리미엄 안내 |
| 전면/보상형 광고 | 자동 스킵 |

## 대체 네트워크 상태

| 네트워크 | 상태 | 예상 시점 |
|----------|------|----------|
| AdMob | 제한 (invalid traffic) | 해제 미정 |
| Kakao AdFit | 등록 대기 (비공개테스트 12일 필요) | ~2026-02-14 이후 |
| AppLovin MAX | 승인 대기 (메일 발송) | 1~2주 |
