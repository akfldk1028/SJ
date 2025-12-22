# DK TODO - 빌드, 광고, DB 연결

## 담당 영역
- 앱 빌드 & 스토어 출시 (Android/iOS)
- AdMob 보상형 광고 연동
- Supabase 데이터베이스 연결
- 전체 프로젝트 총괄

---

## Phase 1: Supabase 데이터베이스 연결

### 1.1 Supabase 프로젝트 생성
```
1. https://supabase.com 접속 → 로그인
2. "New Project" 클릭
3. 프로젝트명: mantok (또는 원하는 이름)
4. Database Password: 안전한 비밀번호 설정 (저장해둘 것!)
5. Region: Northeast Asia (ap-northeast-1) 또는 가까운 곳
6. 생성 완료까지 약 2분 대기
```

### 1.2 API 키 확인
```
Project Settings > API 에서 확인:
- Project URL: https://xxxxx.supabase.co
- anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 1.3 Flutter 패키지 설치
```bash
cd frontend
flutter pub add supabase_flutter
flutter pub add flutter_dotenv  # 환경변수용
```

**pubspec.yaml** 확인:
```yaml
dependencies:
  supabase_flutter: ^2.8.0
  flutter_dotenv: ^5.1.0
```

### 1.4 환경변수 설정

**.env 파일 생성** (frontend/.env):
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**.gitignore에 추가**:
```
.env
*.env
```

**pubspec.yaml에 assets 추가**:
```yaml
flutter:
  assets:
    - .env
```

### 1.5 Supabase 초기화 (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 로드
  await dotenv.load(fileName: ".env");

  // Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

// 전역 클라이언트 접근
final supabase = Supabase.instance.client;
```

### 1.6 데이터베이스 테이블 생성

**Supabase Dashboard > SQL Editor에서 실행**:

```sql
-- 사용자 프로필 테이블
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  birth_date DATE NOT NULL,
  birth_time TIME,
  birth_type TEXT DEFAULT 'solar', -- 'solar' or 'lunar'
  gender TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 채팅 히스토리 테이블
CREATE TABLE chat_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  session_id UUID NOT NULL,
  role TEXT NOT NULL, -- 'user' or 'assistant'
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS (Row Level Security) 활성화
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_history ENABLE ROW LEVEL SECURITY;

-- ✅ RLS 정책 (Supabase 공식 권장 패턴)
-- TO authenticated: 인증된 사용자만
-- (select auth.uid()): 함수 결과 캐싱으로 100배+ 성능 향상

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = id);

CREATE POLICY "Users can view own chat"
  ON chat_history FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own chat"
  ON chat_history FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
```

### 1.7 CRUD 예제 코드

```dart
// ═══ SELECT ═══
final data = await supabase
    .from('profiles')
    .select()
    .eq('id', supabase.auth.currentUser!.id)
    .single();

// ═══ INSERT ═══
await supabase.from('profiles').insert({
  'id': supabase.auth.currentUser!.id,
  'name': '홍길동',
  'birth_date': '1990-01-15',
  'birth_time': '14:30:00',
  'gender': 'male',
});

// ═══ UPDATE ═══
await supabase
    .from('profiles')
    .update({'name': '새이름'})
    .eq('id', supabase.auth.currentUser!.id);

// ═══ DELETE ═══
await supabase
    .from('chat_history')
    .delete()
    .eq('session_id', sessionId);
```

### 1.8 인증 구현

```dart
// ═══ 회원가입 ═══
final response = await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'securepassword123',
);

// ═══ 로그인 ═══
final response = await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'securepassword123',
);

// ═══ 소셜 로그인 (Google) ═══
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'io.supabase.mantok://login-callback/',
);

// ═══ 로그아웃 ═══
await supabase.auth.signOut();

// ═══ 현재 사용자 확인 ═══
final user = supabase.auth.currentUser;

// ═══ 인증 상태 리스닝 ═══
supabase.auth.onAuthStateChange.listen((data) {
  final session = data.session;
  if (session != null) {
    // 로그인됨
  } else {
    // 로그아웃됨
  }
});
```

### Phase 1 체크리스트
- [ ] Supabase 프로젝트 생성
- [ ] API 키 확인 및 .env 파일 생성
- [ ] supabase_flutter 패키지 설치
- [ ] main.dart에서 초기화 코드 추가
- [ ] 테이블 생성 (profiles, chat_history)
- [ ] RLS 정책 설정
- [ ] 인증 플로우 테스트

---

## Phase 2: AdMob 보상형 광고 연동

### 2.1 AdMob 계정 설정
```
1. https://admob.google.com 접속 → 로그인
2. "시작하기" 클릭하여 계정 생성
3. 결제 정보 입력 (수익 수령용)
```

### 2.2 앱 등록
```
1. 앱 > "앱 추가" 클릭
2. Android 앱 등록:
   - 패키지명: com.yourcompany.mantok
   - 앱 이름: 만톡
3. iOS 앱 등록:
   - 번들 ID: com.yourcompany.mantok
   - 앱 이름: 만톡
4. 각 앱의 "앱 ID" 복사해두기:
   - Android: ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
   - iOS: ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ
```

### 2.3 광고 단위 생성
```
1. 앱 > 광고 단위 > "광고 단위 추가"
2. "보상형" 선택
3. 광고 단위 이름: "Saju Chat Reward"
4. 보상 설정:
   - 보상 수량: 1
   - 보상 항목: coin (또는 원하는 이름)
5. 생성 완료 후 "광고 단위 ID" 복사:
   - Android: ca-app-pub-XXXXXXXXXXXXXXXX/AAAAAAAAAA
   - iOS: ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB
```

### 2.4 Flutter 패키지 설치

```bash
cd frontend
flutter pub add google_mobile_ads
```

### 2.5 Android 설정

**android/app/src/main/AndroidManifest.xml**:
```xml
<manifest>
    <application>
        <!-- 기존 내용... -->

        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
    </application>
</manifest>
```

**android/app/build.gradle** (minSdkVersion 확인):
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // 최소 21 이상
    }
}
```

### 2.6 iOS 설정

**ios/Runner/Info.plist**:
```xml
<dict>
    <!-- 기존 내용... -->

    <!-- AdMob App ID -->
    <key>GADApplicationIdentifier</key>
    <string>ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ</string>

    <!-- SKAdNetwork (iOS 14+) -->
    <key>SKAdNetworkItems</key>
    <array>
        <dict>
            <key>SKAdNetworkIdentifier</key>
            <string>cstr6suwn9.skadnetwork</string>
        </dict>
        <!-- 추가 네트워크 ID들... -->
    </array>
</dict>
```

### 2.7 보상형 광고 구현

**lib/core/ads/rewarded_ad_manager.dart**:
```dart
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // 테스트 광고 ID (개발 중 사용)
  static String get testAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android 테스트
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS 테스트
    }
    throw UnsupportedError('Unsupported platform');
  }

  // 실제 광고 ID (출시 시 교체)
  static String get prodAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/AAAAAAAAAA'; // 실제 Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB'; // 실제 iOS
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 광고 미리 로드
  Future<void> loadAd() async {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: testAdUnitId, // 출시 시 prodAdUnitId로 변경
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('보상형 광고 로드 완료');
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('보상형 광고 로드 실패: $error');
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// 광고 표시 및 보상 콜백
  Future<bool> showAd({
    required void Function(int amount) onRewarded,
  }) async {
    if (_rewardedAd == null) {
      print('광고가 아직 로드되지 않았습니다');
      await loadAd();
      return false;
    }

    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        print('광고 표시됨');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('광고 닫힘');
        ad.dispose();
        _rewardedAd = null;
        loadAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('광고 표시 실패: $error');
        ad.dispose();
        _rewardedAd = null;
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('보상 획득: ${reward.amount} ${reward.type}');
        onRewarded(reward.amount.toInt());
        rewarded = true;
      },
    );

    return rewarded;
  }

  /// 광고 준비 여부
  bool get isReady => _rewardedAd != null;

  /// 리소스 해제
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
```

### 2.8 main.dart에서 초기화

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob 초기화
  await MobileAds.instance.initialize();

  // 기존 초기화 코드...
  runApp(const MyApp());
}
```

### 2.9 사용 예시 (채팅 화면)

```dart
class ChatScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _adManager = RewardedAdManager();
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _adManager.loadAd(); // 미리 로드
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  void _watchAdForCoins() async {
    final success = await _adManager.showAd(
      onRewarded: (amount) {
        setState(() {
          _coins += amount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$amount 코인 획득!')),
        );
      },
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('광고를 준비 중입니다...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('코인: $_coins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: _adManager.isReady ? _watchAdForCoins : null,
            tooltip: '광고 보고 코인 받기',
          ),
        ],
      ),
      // ... 채팅 UI
    );
  }
}
```

### Phase 2 체크리스트
- [ ] AdMob 계정 생성
- [ ] Android/iOS 앱 등록
- [ ] 보상형 광고 단위 생성
- [ ] google_mobile_ads 패키지 설치
- [ ] AndroidManifest.xml 설정
- [ ] Info.plist 설정
- [ ] RewardedAdManager 클래스 생성
- [ ] 테스트 광고로 동작 확인

---

## Phase 3: Android 빌드 & Play Store 출시

### 3.1 서명 키 생성

```bash
# Windows
keytool -genkey -v -keystore D:\keystore\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Mac/Linux
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

입력 정보:
- 키스토어 비밀번호: (안전하게 저장!)
- 이름, 조직 등 입력

### 3.2 key.properties 생성

**android/key.properties** (절대 Git에 커밋하지 않기!):
```properties
storePassword=키스토어비밀번호
keyPassword=키비밀번호
keyAlias=upload
storeFile=D:\\keystore\\upload-keystore.jks
```

**.gitignore에 추가**:
```
android/key.properties
*.jks
```

### 3.3 build.gradle 설정

**android/app/build.gradle**:
```gradle
// 파일 상단에 추가
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // 기존 내용...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 3.4 앱 아이콘 설정

```bash
flutter pub add flutter_launcher_icons --dev
```

**pubspec.yaml**:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"  # 1024x1024 권장
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

```bash
dart run flutter_launcher_icons
```

### 3.5 앱 빌드

```bash
cd frontend

# APK (테스트용)
flutter build apk --release

# App Bundle (Play Store 업로드용)
flutter build appbundle --release
```

빌드 결과물:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 3.6 Play Console 설정

```
1. https://play.google.com/console 접속
2. 개발자 계정 등록 ($25 일회성)
3. "앱 만들기" 클릭
4. 앱 정보 입력:
   - 앱 이름: 만톡
   - 기본 언어: 한국어
   - 앱/게임: 앱
   - 무료/유료: 무료
5. 앱 콘텐츠 설정:
   - 개인정보처리방침 URL 입력
   - 앱 액세스 권한 선언
   - 광고 포함 여부: 예
   - 콘텐츠 등급 설문
   - 타겟 연령층 설정
```

### 3.7 스토어 등록정보

```
1. 스토어 설정 > 기본 스토어 등록정보
2. 필수 항목:
   - 앱 이름 (30자 이내)
   - 간단한 설명 (80자 이내)
   - 자세한 설명 (4000자 이내)
   - 앱 아이콘 (512x512 PNG)
   - 그래픽 이미지 (1024x500 PNG)
   - 스크린샷:
     - 휴대전화: 최소 2개 (16:9 또는 9:16)
     - 태블릿: 권장
```

### 3.8 출시

```
1. 프로덕션 > 새 버전 만들기
2. App Bundle (.aab) 업로드
3. 출시 노트 작성
4. 검토 시작
5. 검토 완료까지 1~7일 소요
```

### Phase 3 체크리스트
- [ ] 서명 키 생성 (upload-keystore.jks)
- [ ] key.properties 생성
- [ ] build.gradle signingConfigs 설정
- [ ] 앱 아이콘 생성 및 적용
- [ ] flutter build appbundle 성공
- [ ] Play Console 계정 등록 ($25)
- [ ] 앱 정보 입력
- [ ] 스토어 등록정보 완성
- [ ] App Bundle 업로드
- [ ] 검토 통과

---

## Phase 4: iOS 빌드 & App Store 출시

### 4.1 Apple Developer Program 가입

```
1. https://developer.apple.com 접속
2. "Account" → Apple ID로 로그인
3. "Apple Developer Program" 가입 ($99/년)
4. 신원 확인 후 승인 (1~2일)
```

### 4.2 Xcode 설정

```bash
cd frontend
flutter build ios --release  # 먼저 빌드
open ios/Runner.xcworkspace  # Xcode 열기
```

Xcode에서:
```
1. Runner 프로젝트 선택
2. Signing & Capabilities 탭
3. Team: 본인 개발자 계정 선택
4. Bundle Identifier: com.yourcompany.mantok
5. Automatically manage signing: 체크
```

### 4.3 App Store Connect 설정

```
1. https://appstoreconnect.apple.com 접속
2. "앱" > "+" > "신규 앱"
3. 앱 정보:
   - 플랫폼: iOS
   - 이름: 만톡
   - 기본 언어: 한국어
   - 번들 ID: com.yourcompany.mantok
   - SKU: mantok-001
```

### 4.4 앱 스크린샷 및 정보

```
필수 스크린샷 (각 기기별):
- iPhone 6.7" (1290 x 2796)
- iPhone 6.5" (1284 x 2778)
- iPhone 5.5" (1242 x 2208)
- iPad Pro 12.9" (2048 x 2732)

앱 정보:
- 프로모션 텍스트 (170자)
- 설명 (4000자)
- 키워드 (100자, 쉼표 구분)
- 지원 URL
- 개인정보 처리방침 URL
- 연령 등급 설문
```

### 4.5 Archive 및 업로드

Xcode에서:
```
1. Product > Archive
2. 완료 후 "Distribute App" 클릭
3. "App Store Connect" 선택
4. "Upload" 선택
5. 업로드 완료 대기
```

또는 터미널에서:
```bash
flutter build ipa --release

# Transporter 앱 또는 xcrun으로 업로드
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u APPLE_ID -p APP_SPECIFIC_PASSWORD
```

### 4.6 심사 제출

```
1. App Store Connect > 앱 선택
2. 빌드 추가 (업로드한 빌드 선택)
3. 앱 심사 정보:
   - 연락처 정보
   - 데모 계정 (필요시)
   - 메모 (심사원 참고사항)
4. "심사를 위해 제출" 클릭
5. 심사 기간: 보통 24~48시간 (최대 1주)
```

### 4.7 심사 거절 대응

흔한 거절 사유:
```
- Guideline 2.1: 앱 크래시/버그 → 테스트 후 재제출
- Guideline 4.2: 앱 기능 부족 → 최소 기능 보완
- Guideline 5.1.1: 개인정보 처리방침 미비 → URL 확인
- Guideline 3.1.1: 인앱결제 필요 → 코인 구매 시 IAP 사용
```

### Phase 4 체크리스트
- [ ] Apple Developer Program 가입 ($99/년)
- [ ] Xcode에서 Signing 설정
- [ ] App Store Connect에 앱 생성
- [ ] 스크린샷 준비 (각 기기별)
- [ ] 앱 정보 입력
- [ ] Archive 및 업로드
- [ ] 심사 제출
- [ ] 심사 통과

---

## 우선순위 및 일정

### Week 1-2: Supabase 연결
1. 프로젝트 생성 및 Flutter 연동
2. 테이블 생성 및 RLS 설정
3. 인증 플로우 구현
4. 기존 Hive 데이터 마이그레이션 로직

### Week 3: AdMob 연동
1. 계정 및 앱 등록
2. 보상형 광고 구현
3. 테스트 광고로 검증

### Week 4: Android 출시
1. 서명 키 및 빌드 설정
2. Play Console 등록
3. 스토어 등록정보 작성
4. 심사 제출

### Week 5: iOS 출시
1. Apple Developer 등록
2. Xcode 설정 및 Archive
3. App Store Connect 등록
4. 심사 제출

---

## 참고 링크

- [Supabase Flutter 문서](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Google AdMob Flutter 가이드](https://developers.google.com/admob/flutter/quick-start)
- [Flutter Android 출시 가이드](https://docs.flutter.dev/deployment/android)
- [Flutter iOS 출시 가이드](https://docs.flutter.dev/deployment/ios)
- [Play Console 도움말](https://support.google.com/googleplay/android-developer)
- [App Store Connect 도움말](https://developer.apple.com/app-store-connect/)
