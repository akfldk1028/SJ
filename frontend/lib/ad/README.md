# AdMob 광고 모듈

> **담당자**: DK
> **패키지**: google_mobile_ads ^5.3.0

---

## 폴더 구조

```
frontend/lib/ad/
├── ad.dart                    # 모듈 exports
├── ad_config.dart             # 광고 상수/설정
├── ad_service.dart            # 광고 로딩/표시 서비스
├── ad_strategy.dart           # 비즈니스 수익화 전략
├── providers/
│   └── ad_provider.dart       # Riverpod 광고 상태 관리
├── widgets/
│   └── banner_ad_widget.dart  # 배너 광고 위젯
├── DK/                        # DK 전용 (수정 X)
└── README.md                  # 이 파일
```

---

## 빠른 시작

### 1. SDK 초기화 (main.dart)

```dart
import 'package:frontend/ad/ad.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob SDK 초기화
  await AdService.instance.initialize();

  runApp(MyApp());
}
```

### 2. 배너 광고 표시

```dart
import 'package:frontend/ad/ad.dart';

// 위젯 트리에 배너 추가
Scaffold(
  body: YourContent(),
  bottomNavigationBar: const BannerAdWidget(),
)
```

### 3. 전면 광고 (Interstitial)

```dart
// 로드 (미리 로드해두기)
await AdService.instance.loadInterstitialAd();

// 표시 (예: 화면 전환 시)
await AdService.instance.showInterstitialAd();
```

### 4. 보상형 광고 (Rewarded)

```dart
// 로드
await AdService.instance.loadRewardedAd();

// 표시 + 보상 지급
await AdService.instance.showRewardedAd(
  onRewarded: (amount, type) {
    print('보상: $amount $type');
    // 예: 크레딧 지급, 프리미엄 기능 해제 등
  },
);
```

---

## 광고 유형

| 유형 | 설명 | 사용 시점 |
|------|------|----------|
| Banner | 화면 하단 고정 | 메인 화면 |
| Interstitial | 전체 화면 | 화면 전환 시 |
| Rewarded | 보상형 | 프리미엄 기능 해제 |

---

## 테스트 vs 프로덕션

### 현재 모드 확인

`ad_config.dart`:
```dart
const AdMode currentAdMode = AdMode.test;  // 테스트 모드
```

### 프로덕션 배포 전

1. `ad_config.dart`에서 `AdMode.production`으로 변경
2. `ProductionAdUnitIds`에 실제 광고 ID 입력
3. `AndroidManifest.xml` App ID 교체
4. `Info.plist` App ID 교체

---

## 플랫폼 설정

### Android

`android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxx~xxxxx"/>
```

### iOS

`ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxx~xxxxx</string>
```

---

## 광고 정책

| 설정 | 값 | 설명 |
|------|---|------|
| 전면 광고 간격 | 60초 | 연속 노출 방지 |
| 보상형 재로드 | 3초 | 광고 종료 후 대기 |

---

## 테스트 Ad Unit ID

| 유형 | Android | iOS |
|------|---------|-----|
| Banner | ca-app-pub-3940256099942544/6300978111 | ca-app-pub-3940256099942544/2934735716 |
| Interstitial | ca-app-pub-3940256099942544/1033173712 | ca-app-pub-3940256099942544/4411468910 |
| Rewarded | ca-app-pub-3940256099942544/5224354917 | ca-app-pub-3940256099942544/1712485313 |

---

## 주의사항

- **개발 중에는 반드시 테스트 ID 사용** (계정 정지 방지)
- 광고 클릭 유도 금지 (Google 정책 위반)
- 광고 숨김/가림 금지
- 보상형 광고는 사용자 동의 후 표시

---

## 비즈니스 수익화 전략

### 광고 배치

| 위치 | 광고 유형 | 타이밍 |
|------|----------|--------|
| 메인 화면 하단 | 배너 | 상시 노출 |
| AI 채팅 | 전면 | 5개 메시지마다 |
| 새 채팅 시작 | 전면 | 하루 3회 제한 |
| 프리미엄 기능 | 보상형 | 사용자 선택 |

### eCPM 예상

| 광고 유형 | eCPM 범위 | 특징 |
|----------|----------|------|
| 배너 | $0.5~2 | 낮지만 impression 많음 |
| **Native (채팅 내)** | **$3~15** | **채팅 버블처럼 자연스러움** |
| 전면 | $2~10 | 중간 수익 |
| 보상형 | $10~50 | 가장 높은 eCPM |

### 채팅 내 광고 유형 (모듈형)

`ad_strategy.dart`에서 설정:

```dart
// 채팅 내 광고 유형 선택
static const ChatAdType chatAdType = ChatAdType.nativeMedium;
```

| 유형 | 설명 | eCPM |
|------|------|------|
| `inlineBanner` | 간단한 배너 | $1~3 |
| `nativeMedium` | 채팅 버블 스타일 ★ | $3~15 |
| `nativeCompact` | 컴팩트 네이티브 | $2~8 |

### Native Ad 예시

```dart
// ChatMessageList에서 자동 삽입됨
// 7개 메시지마다 광고 표시 (최대 3개)

// Factory 패턴으로 유형 변경 가능
ChatAdFactory.create(
  index: 0,
  type: ChatAdType.nativeMedium,  // 또는 inlineBanner, nativeCompact
);
```

### AdController Provider 사용

```dart
// 채팅 메시지 전송 후 광고 체크
ref.read(adControllerProvider.notifier).onChatMessage();

// 새 세션 시작 시 광고
await ref.read(adControllerProvider.notifier).onNewSession();

// 보상형 광고 표시
await ref.read(adControllerProvider.notifier).showRewarded(
  onRewarded: (amount, type) {
    // 보상 지급 로직
  },
);
```

### 설정 조정

`ad_strategy.dart`에서 수익화 파라미터 조정:

```dart
// 전면 광고 메시지 간격
static const int interstitialMessageInterval = 5;

// 일일 전면 광고 한도
static const int interstitialDailyLimit = 5;

// 전면 광고 쿨다운 (초)
static const int interstitialCooldownSeconds = 60;
```
