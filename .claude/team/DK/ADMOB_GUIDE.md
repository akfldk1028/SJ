# AdMob 완전 초보 가이드 (2025)

> 하나도 모르는 상태에서 시작하는 AdMob 보상형 광고 연동

---

## PART 1: AdMob 계정 만들기

### Step 1.1: AdMob 사이트 접속
```
1. 크롬 브라우저 열기
2. 주소창에 입력: admob.google.com
3. Enter 누르기
```

### Step 1.2: Google 계정 로그인
```
1. "시작하기" 또는 "Sign up" 버튼 클릭
2. Google 계정 이메일 입력
3. "다음" 클릭
4. 비밀번호 입력
5. "다음" 클릭

※ Google 계정이 없으면:
   → "계정 만들기" 클릭
   → 이름, 이메일, 비밀번호 입력
   → 휴대폰 인증
```

### Step 1.3: AdMob 계정 정보 입력
```
1. 국가 선택: "대한민국" 선택
   ⚠️ 주의: 나중에 변경 불가!

2. 시간대 선택: "(GMT+09:00) 서울" 선택

3. 통화 선택: "KRW - 대한민국 원" 선택
   ⚠️ 주의: 나중에 변경 불가!
   (달러로 받고 싶으면 USD 선택)

4. "계속" 버튼 클릭
```

### Step 1.4: 약관 동의
```
1. AdMob 이용약관 읽기 (스크롤)
2. "예, 위 내용에 동의합니다" 체크박스 클릭
3. "AdMob 계정 만들기" 버튼 클릭
```

### Step 1.5: 이메일 알림 설정
```
1. 수익 관련 알림 받기: "예" 선택 (권장)
2. 프로모션 이메일: 원하는 대로 선택
3. "계속" 버튼 클릭
```

### Step 1.6: 계정 생성 완료!
```
✅ "AdMob에 오신 것을 환영합니다" 화면이 보이면 성공!

📝 기억해둘 것:
   - 로그인 이메일: _______________
   - 계정 생성 날짜: _______________
```

---

## PART 2: 앱 등록하기

### Step 2.1: 앱 메뉴로 이동
```
1. 왼쪽 사이드바에서 "앱" 클릭
2. "앱 추가" 버튼 클릭 (파란색)
```

### Step 2.2: 플랫폼 선택
```
< Android 앱 등록 >

1. "Android" 선택
2. "앱이 지원되는 앱 스토어에 등록되어 있나요?" 질문:

   ▶ 아직 Play Store에 없으면:
     → "아니요" 선택
     → 앱 이름 입력: "만톡" (또는 원하는 이름)

   ▶ 이미 Play Store에 있으면:
     → "예" 선택
     → 앱 검색해서 선택

3. "앱 추가" 버튼 클릭
```

### Step 2.3: 앱 ID 복사 (중요!)
```
앱 등록 완료 화면에서:

┌─────────────────────────────────────────────┐
│  앱 ID: ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYY  │
│                              [복사] 버튼     │
└─────────────────────────────────────────────┘

1. [복사] 버튼 클릭
2. 메모장에 붙여넣기 (Ctrl+V)
3. 저장해두기!

📝 내 Android 앱 ID: _________________________________
```

### Step 2.4: iOS 앱도 등록 (같은 방법)
```
1. 다시 "앱" → "앱 추가" 클릭
2. "iOS" 선택
3. 앱 이름: "만톡" (같은 이름)
4. "앱 추가" 클릭
5. 앱 ID 복사해두기

📝 내 iOS 앱 ID: _________________________________
```

---

## PART 3: 광고 단위 만들기

### Step 3.1: 앱 선택
```
1. 왼쪽 사이드바 "앱" 클릭
2. 등록한 앱 이름 클릭 (예: "만톡")
```

### Step 3.2: 광고 단위 메뉴
```
1. 앱 상세 페이지에서 왼쪽 메뉴 "광고 단위" 클릭
2. "광고 단위 추가" 버튼 클릭 (또는 "시작하기")
```

### Step 3.3: 광고 유형 선택
```
광고 형식 선택 화면:

┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│  배너    │ │  전면    │ │ ★보상형★ │ │ 네이티브 │
│  Banner  │ │Intersti- │ │ Rewarded │ │  Native  │
│          │ │  tial    │ │ ← 이거!  │ │          │
└──────────┘ └──────────┘ └──────────┘ └──────────┘

1. "보상형" (Rewarded) 클릭!
```

### Step 3.4: 광고 단위 설정
```
광고 단위 이름 입력:

┌────────────────────────────────────┐
│ 광고 단위 이름                      │
│ ┌────────────────────────────────┐ │
│ │ SajuChat_Reward               │ │  ← 원하는 이름 입력
│ └────────────────────────────────┘ │
└────────────────────────────────────┘

보상 설정 (선택사항):
┌────────────────────────────────────┐
│ 보상 수량: [ 1 ]                   │  ← 코인 1개
│ 보상 항목: [ coin ]                │  ← 항목 이름
└────────────────────────────────────┘

"광고 단위 만들기" 버튼 클릭!
```

### Step 3.5: 광고 단위 ID 복사 (매우 중요!)
```
광고 단위 생성 완료 화면:

┌─────────────────────────────────────────────────┐
│  광고 단위 ID                                    │
│  ca-app-pub-XXXXXXXXXXXXXXXX/AAAAAAAAAA         │
│                                    [복사] 버튼   │
└─────────────────────────────────────────────────┘

1. [복사] 버튼 클릭
2. 메모장에 붙여넣기
3. 저장!

📝 내 Android 보상형 광고 단위 ID: _________________________________
```

### Step 3.6: iOS도 같은 방법으로
```
1. iOS 앱 선택
2. 광고 단위 → 광고 단위 추가
3. 보상형 선택
4. 이름: "SajuChat_Reward_iOS"
5. 생성 후 ID 복사

📝 내 iOS 보상형 광고 단위 ID: _________________________________
```

---

## PART 4: Flutter 프로젝트 설정

### Step 4.1: 패키지 설치
```
터미널(CMD)에서:

1. 프로젝트 폴더로 이동:
   cd D:\Data\20_Flutter\01_SJ\frontend

2. 패키지 추가:
   flutter pub add google_mobile_ads

3. 설치 확인:
   flutter pub get
```

### Step 4.2: Android 설정 (AndroidManifest.xml)

**파일 위치:** `frontend/android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="mantok"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- ⬇️ 이 부분 추가! ⬇️ -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
        <!-- ⬆️ 여기에 PART 2에서 복사한 Android 앱 ID 붙여넣기 ⬆️ -->

        <activity
            android:name=".MainActivity"
            ... 기존 내용 ...
        </activity>
    </application>
</manifest>
```

**실제 예시:**
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-1234567890123456~1234567890"/>
```

### Step 4.3: iOS 설정 (Info.plist)

**파일 위치:** `frontend/ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <!-- 기존 내용들... -->

    <!-- ⬇️ 이 부분 추가! (</dict> 바로 위에) ⬇️ -->
    <key>GADApplicationIdentifier</key>
    <string>ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ</string>
    <!-- ⬆️ 여기에 PART 2에서 복사한 iOS 앱 ID 붙여넣기 ⬆️ -->

    <!-- iOS 14+ 필수: SKAdNetwork -->
    <key>SKAdNetworkItems</key>
    <array>
        <dict>
            <key>SKAdNetworkIdentifier</key>
            <string>cstr6suwn9.skadnetwork</string>
        </dict>
    </array>

</dict>
</plist>
```

### Step 4.4: build.gradle 확인

**파일 위치:** `frontend/android/app/build.gradle`

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // ← 최소 21 이상이어야 함!
        // ... 나머지 ...
    }
}
```

---

## PART 5: 코드 작성하기

### Step 5.1: AdHelper 클래스 만들기

**새 파일 생성:** `frontend/lib/core/ads/ad_helper.dart`

```dart
import 'dart:io';

/// 광고 ID를 관리하는 헬퍼 클래스
class AdHelper {

  // ═══════════════════════════════════════════════════════
  // 테스트용 광고 ID (개발 중에만 사용!)
  // ═══════════════════════════════════════════════════════

  /// 테스트용 보상형 광고 ID
  static String get testRewardedAdUnitId {
    if (Platform.isAndroid) {
      // Android 테스트 ID (Google 공식)
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      // iOS 테스트 ID (Google 공식)
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('지원하지 않는 플랫폼');
  }

  // ═══════════════════════════════════════════════════════
  // 실제 광고 ID (출시할 때 사용!)
  // ═══════════════════════════════════════════════════════

  /// 실제 보상형 광고 ID
  /// ⚠️ 출시 전에 PART 3에서 복사한 ID로 교체하세요!
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      // TODO: 실제 Android 광고 단위 ID로 교체
      return 'ca-app-pub-여기에입력/AAAAAAAAAA';
    } else if (Platform.isIOS) {
      // TODO: 실제 iOS 광고 단위 ID로 교체
      return 'ca-app-pub-여기에입력/BBBBBBBBBB';
    }
    throw UnsupportedError('지원하지 않는 플랫폼');
  }

  // ═══════════════════════════════════════════════════════
  // 개발/출시 모드 전환
  // ═══════════════════════════════════════════════════════

  /// true = 테스트 모드 (개발 중)
  /// false = 실제 모드 (출시)
  static const bool isTestMode = true;  // ← 출시할 때 false로!

  /// 현재 사용할 광고 ID
  static String get currentRewardedAdUnitId {
    return isTestMode ? testRewardedAdUnitId : rewardedAdUnitId;
  }
}
```

### Step 5.2: RewardedAdManager 클래스 만들기

**새 파일 생성:** `frontend/lib/core/ads/rewarded_ad_manager.dart`

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

/// 보상형 광고를 관리하는 클래스
class RewardedAdManager {
  // 광고 객체
  RewardedAd? _rewardedAd;

  // 로딩 중인지 확인
  bool _isLoading = false;

  // ═══════════════════════════════════════════════════════
  // 1. 광고 미리 로드하기
  // ═══════════════════════════════════════════════════════

  /// 광고를 미리 불러옵니다
  /// 앱 시작할 때 또는 광고 보여준 후 호출
  Future<void> loadAd() async {
    // 이미 로딩 중이거나 광고가 있으면 스킵
    if (_isLoading || _rewardedAd != null) {
      print('[AdMob] 이미 광고가 있거나 로딩 중');
      return;
    }

    _isLoading = true;
    print('[AdMob] 광고 로딩 시작...');

    await RewardedAd.load(
      adUnitId: AdHelper.currentRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(

        // ✅ 광고 로드 성공!
        onAdLoaded: (RewardedAd ad) {
          print('[AdMob] ✅ 광고 로드 성공!');
          _rewardedAd = ad;
          _isLoading = false;
        },

        // ❌ 광고 로드 실패
        onAdFailedToLoad: (LoadAdError error) {
          print('[AdMob] ❌ 광고 로드 실패: ${error.message}');
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 2. 광고 보여주기
  // ═══════════════════════════════════════════════════════

  /// 광고를 보여주고 보상을 받습니다
  ///
  /// [onRewarded] 사용자가 광고를 끝까지 보면 호출됨
  /// 반환값: 광고를 성공적으로 보여줬으면 true
  Future<bool> showAd({
    required void Function(int amount) onRewarded,
  }) async {
    // 광고가 없으면
    if (_rewardedAd == null) {
      print('[AdMob] 광고가 아직 준비 안됨, 로드 시도...');
      await loadAd();
      return false;
    }

    // 콜백 설정
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(

      // 광고가 화면에 표시됨
      onAdShowedFullScreenContent: (RewardedAd ad) {
        print('[AdMob] 광고 표시됨');
      },

      // 사용자가 광고를 닫음
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('[AdMob] 광고 닫힘');
        ad.dispose();
        _rewardedAd = null;

        // 다음 광고 미리 로드
        loadAd();
      },

      // 광고 표시 실패
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('[AdMob] 광고 표시 실패: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
      },
    );

    // 광고 보여주기!
    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // 🎉 사용자가 보상을 받음!
        print('[AdMob] 🎉 보상 획득! ${reward.amount} ${reward.type}');
        onRewarded(reward.amount.toInt());
      },
    );

    return true;
  }

  // ═══════════════════════════════════════════════════════
  // 3. 상태 확인
  // ═══════════════════════════════════════════════════════

  /// 광고가 준비되었는지 확인
  bool get isReady => _rewardedAd != null;

  /// 로딩 중인지 확인
  bool get isLoading => _isLoading;

  // ═══════════════════════════════════════════════════════
  // 4. 정리
  // ═══════════════════════════════════════════════════════

  /// 리소스 해제 (화면 dispose에서 호출)
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
```

### Step 5.3: main.dart 수정하기

**파일 위치:** `frontend/lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';  // ← 추가!

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // ⬇️ AdMob 초기화 추가! ⬇️
  await MobileAds.instance.initialize();
  print('[AdMob] SDK 초기화 완료');

  // 기존 앱 실행 코드
  runApp(const MyApp());
}
```

### Step 5.4: 화면에서 사용하기 예시

```dart
import 'package:flutter/material.dart';
import '../core/ads/rewarded_ad_manager.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 광고 매니저 생성
  final _adManager = RewardedAdManager();

  // 코인 수
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    // 화면 열릴 때 광고 미리 로드
    _adManager.loadAd();
  }

  @override
  void dispose() {
    // 화면 닫힐 때 정리
    _adManager.dispose();
    super.dispose();
  }

  // 광고 보기 버튼 클릭
  void _onWatchAdPressed() async {
    // 광고 보여주기
    final success = await _adManager.showAd(
      onRewarded: (amount) {
        // 보상 받음!
        setState(() {
          _coins += amount;
        });

        // 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 $amount 코인 획득!')),
        );
      },
    );

    // 광고가 아직 준비 안됐으면
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('광고 준비 중... 잠시 후 다시 시도해주세요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('코인: $_coins'),
        actions: [
          // 광고 보기 버튼
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: _adManager.isReady ? _onWatchAdPressed : null,
            tooltip: '광고 보고 코인 받기',
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _adManager.isReady ? _onWatchAdPressed : null,
          icon: const Icon(Icons.play_circle),
          label: Text(
            _adManager.isReady
              ? '광고 보고 코인 받기'
              : '광고 로딩 중...',
          ),
        ),
      ),
    );
  }
}
```

---

## PART 6: 테스트하기

### Step 6.1: 앱 실행
```bash
cd frontend
flutter run
```

### Step 6.2: 테스트 확인 사항
```
✅ 앱이 크래시 없이 실행되는가?
✅ 콘솔에 "[AdMob] SDK 초기화 완료" 메시지가 보이는가?
✅ 콘솔에 "[AdMob] ✅ 광고 로드 성공!" 메시지가 보이는가?
✅ 광고 버튼을 누르면 테스트 광고가 표시되는가?
✅ 광고를 끝까지 보면 코인이 증가하는가?
```

### Step 6.3: 테스트 광고 화면
```
테스트 광고는 이렇게 보입니다:

┌─────────────────────────────────┐
│                                 │
│    Rewarded interstitial       │
│    advancement video ad         │
│                                 │
│          advancement            │
│    ☁️ 비행기 그림 ☁️            │
│                                 │
│    advancement slot             │
│                                 │
│    advancement                  │
│                                 │
│  [X]                            │
└─────────────────────────────────┘

→ 광고 영상이 끝나면 X 버튼 또는 닫기 버튼 활성화
→ 닫으면 보상 콜백 실행됨
```

### Step 6.4: 테스트 기기 등록하기 (선택사항)

> 실제 광고 ID를 사용하면서 테스트 광고를 받고 싶을 때!
> 테스트 기기로 등록하면 실제 광고가 "Test Ad" 라벨 붙어서 나옴

#### 자동으로 테스트 기기인 경우 (등록 불필요!)
```
✅ Android 에뮬레이터 → 자동으로 테스트 기기
✅ iOS 시뮬레이터 → 자동으로 테스트 기기

→ 에뮬레이터/시뮬레이터에서 개발 중이면 별도 등록 필요 없음!
→ 실제 폰에서 테스트할 때만 아래 방법 사용
```

#### 방법 A: 코드로 등록 (개발자용)

**Step 1: 기기 ID 찾기**
```
1. 앱 실행 (flutter run)
2. 콘솔(logcat/터미널) 확인
3. 이런 메시지 찾기:

   Android:
   I/Ads: Use RequestConfiguration.Builder.setTestDeviceIds(["33BE2250B43518CCDA7DE426D04EE231"])

   iOS:
   <Google> To get test ads on this device, set: GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers = @[ @"2077ef9a63d2b398840261c8221a0c9b" ]

4. 따옴표 안의 ID 복사!

📝 내 기기 ID: _________________________________
```

**Step 2: main.dart에 추가**
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob 초기화
  await MobileAds.instance.initialize();

  // ⬇️ 테스트 기기 등록 추가! ⬇️
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: [
        '33BE2250B43518CCDA7DE426D04EE231',  // ← 위에서 복사한 ID
        // 여러 기기 등록 가능
        // 'ABCDEF123456...',
      ],
    ),
  );

  runApp(const MyApp());
}
```

**Step 3: 확인**
```
이제 실제 광고 ID를 사용해도
등록된 기기에서는 테스트 광고가 표시됨!

광고 상단에 "Test Ad" 또는 "테스트 광고" 라벨이 보이면 성공!
```

#### 방법 B: AdMob 콘솔에서 등록 (비개발자도 쉬움)

**Step 1: AdMob 설정 이동**
```
1. admob.google.com 접속
2. 왼쪽 사이드바 맨 아래 "설정" 클릭 (톱니바퀴 아이콘)
```

**Step 2: 테스트 기기 메뉴**
```
1. 설정 화면에서 "테스트 기기" 클릭
2. "테스트 기기 추가" 버튼 클릭 (파란색)
```

**Step 3: 기기 정보 입력**
```
┌─────────────────────────────────────────────────┐
│  테스트 기기 추가                                │
├─────────────────────────────────────────────────┤
│                                                 │
│  기기 이름                                       │
│  ┌─────────────────────────────────────────┐   │
│  │ 내 갤럭시폰                              │   │  ← 알아볼 수 있는 이름
│  └─────────────────────────────────────────┘   │
│                                                 │
│  플랫폼                                         │
│  ○ Android  ○ iOS                              │  ← 기기에 맞게 선택
│                                                 │
│  광고 ID / IDFA                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 33BE2250B43518CCDA7DE426D04EE231        │   │  ← 콘솔에서 찾은 ID
│  └─────────────────────────────────────────┘   │
│                                                 │
│                          [취소]  [저장]         │
└─────────────────────────────────────────────────┘

1. 기기 이름: 알아볼 수 있는 이름 입력
2. 플랫폼: Android 또는 iOS 선택
3. 광고 ID: 콘솔에서 찾은 ID 붙여넣기
4. "저장" 클릭
```

**Step 4: 적용 대기**
```
⏰ 적용 시간:
   - 빠르면: 15분
   - 늦으면: 최대 24시간

💡 팁: 앱을 완전히 종료했다가 다시 실행하면 더 빨리 적용될 수 있음
```

#### 테스트 기기 등록의 장점

| 항목 | 테스트 광고 ID | 테스트 기기 등록 |
|------|---------------|-----------------|
| 설정 난이도 | 쉬움 | 약간 복잡 |
| 실제 광고 모양 | X (샘플 광고) | O (실제 광고 + Test 라벨) |
| 수익 발생 | X | X |
| 계정 정지 위험 | 없음 | 없음 |
| 추천 상황 | 개발 초기 | 출시 직전 최종 테스트 |

#### 주의사항
```
⚠️ 테스트 기기를 등록하지 않고 실제 광고를 클릭하면:
   → 무효 클릭으로 간주
   → AdMob 계정 정지될 수 있음!

⚠️ 출시 전 반드시:
   1. 테스트 기기 등록 하거나
   2. 테스트 광고 ID 사용

⚠️ 앱 출시할 때:
   → 코드에서 testDeviceIds 설정 제거하거나
   → AdHelper.isTestMode = false 로 변경
   (Google 공식 권장: 프로덕션 빌드에서는 테스트 기기 코드 제거)
```

---

## PART 7: 실제 출시하기

### Step 7.1: AdHelper 수정
```dart
// ad_helper.dart에서:

static const bool isTestMode = true;   // ← 이 줄을
static const bool isTestMode = false;  // ← 이렇게 변경!
```

### Step 7.2: 실제 광고 ID 입력
```dart
// ad_helper.dart에서:

static String get rewardedAdUnitId {
  if (Platform.isAndroid) {
    // PART 3에서 복사한 실제 ID
    return 'ca-app-pub-1234567890123456/9876543210';
  } else if (Platform.isIOS) {
    return 'ca-app-pub-1234567890123456/1234567890';
  }
  throw UnsupportedError('지원하지 않는 플랫폼');
}
```

### Step 7.3: 빌드 및 배포
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release
```

---

## 트러블슈팅

### 문제 1: 앱이 크래시됨
```
원인: AndroidManifest.xml에 앱 ID가 없음
해결: PART 4.2 다시 확인
```

### 문제 2: 광고가 안 나옴
```
원인 1: 인터넷 연결 안됨
해결: WiFi/데이터 확인

원인 2: 광고 ID가 잘못됨
해결: 복사한 ID 다시 확인

원인 3: AdMob 계정 승인 대기 중
해결: 1~2일 기다리기
```

### 문제 3: "Ad failed to load" 에러
```
원인: 테스트 기기에서 실제 광고 ID 사용
해결:
1. 테스트 ID 사용하거나
2. AdMob에서 테스트 기기 등록
```

---

## 체크리스트

### AdMob 콘솔
- [ ] AdMob 계정 생성 완료
- [ ] Android 앱 등록 완료
- [ ] iOS 앱 등록 완료
- [ ] Android 보상형 광고 단위 생성 완료
- [ ] iOS 보상형 광고 단위 생성 완료

### Flutter 프로젝트
- [ ] google_mobile_ads 패키지 설치
- [ ] AndroidManifest.xml에 앱 ID 추가
- [ ] Info.plist에 앱 ID 추가
- [ ] main.dart에서 SDK 초기화
- [ ] AdHelper 클래스 생성
- [ ] RewardedAdManager 클래스 생성
- [ ] 화면에서 광고 연동

### 테스트
- [ ] 테스트 광고로 동작 확인
- [ ] 보상 콜백 동작 확인
- [ ] 에러 없이 완료

### 출시
- [ ] isTestMode = false 로 변경
- [ ] 실제 광고 ID로 교체
- [ ] 앱 빌드 및 배포

---

## 참고 링크

- [AdMob 공식 사이트](https://admob.google.com)
- [Flutter AdMob 문서](https://developers.google.com/admob/flutter/quick-start)
- [Flutter 보상형 광고 가이드](https://developers.google.com/admob/flutter/rewarded)
- [Google Codelabs - Flutter AdMob](https://codelabs.developers.google.com/codelabs/admob-ads-in-flutter)
