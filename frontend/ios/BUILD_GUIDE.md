# iOS 빌드 가이드 (사담 앱)

> Mac 사용자가 클론 후 **한 번에 빌드**할 수 있도록 순차적으로 정리한 가이드

---

## 현재 프로젝트 설정

| 항목 | iOS | Android (참고) |
|------|-----|----------------|
| **Bundle ID / Package** | `com.clickaround.sadam` | `com.clickaround.sadam` |
| **앱 이름** | 사담 | 사담 |
| **최소 버전** | iOS 13.0 | API 21 (Android 5.0) |
| **버전** | 0.1.0+13 | 0.1.0+13 |
| **AdMob App ID** | `ca-app-pub-7140787344231420~3931921704` | 동일 |
| **코드 서명** | Automatic Signing | key.properties + keystore |

---

## STEP 0. 사전 준비 (한 번만)

### 필수 설치

```bash
# 1. Xcode (App Store에서 설치 후)
xcode-select --install          # Command Line Tools
sudo xcodebuild -license accept # 라이선스 동의

# 2. CocoaPods
sudo gem install cocoapods
# 또는 Homebrew 사용:
# brew install cocoapods

# 3. Flutter SDK (없으면)
# https://docs.flutter.dev/get-started/install/macos
flutter doctor   # 환경 확인
```

### Apple Developer 계정 준비

- Apple Developer Program 가입 필요 ($99/년): https://developer.apple.com/programs/
- Team ID 확인: https://developer.apple.com → Account → Membership Details
- Team ID는 10자리 영문+숫자 (예: `ABC123XYZ0`)

---

## STEP 1. 프로젝트 클론 & 의존성 설치

```bash
git clone <repository-url>
cd SJ/frontend

# Flutter 의존성
flutter pub get

# 코드 생성 (Riverpod, Freezed 등)
dart run build_runner build --delete-conflicting-outputs

# iOS CocoaPods 설치
cd ios
pod install --repo-update
cd ..
```

---

## STEP 2. 환경 설정 파일 준비

### 2-1. .env 파일

프로젝트 루트(`frontend/`)에 `.env` 파일이 필요합니다. `.env.example`을 복사해서 사용:

```bash
cp .env.example .env
# 실제 키 값을 팀원에게 받아서 입력
```

### 2-2. ExportOptions.plist Team ID 변경

`ios/ExportOptions.plist`과 `ios/ExportOptions-AppStore.plist`의 `teamID`를 본인 Team ID로 변경:

```bash
# 두 파일 모두 수정
sed -i '' 's/UCXS46KDFJ/YOUR_TEAM_ID/g' ios/ExportOptions.plist
sed -i '' 's/UCXS46KDFJ/YOUR_TEAM_ID/g' ios/ExportOptions-AppStore.plist
```

---

## STEP 3. Xcode 서명 설정

### 3-1. Xcode에 Apple 계정 등록

1. Xcode 실행
2. **Xcode → Settings** (`Cmd + ,`)
3. **Accounts** 탭 → 좌측 하단 `+` → **Apple ID** 로그인
4. 로그인 후 Team 목록에 본인 이름/팀이 보이면 성공

### 3-2. 프로젝트에서 서명 설정

```bash
open ios/Runner.xcworkspace
```

> **주의:** `Runner.xcodeproj`가 아닌 **`Runner.xcworkspace`**를 열어야 함 (CocoaPods 때문)

1. 좌측 Navigator → **Runner** (파란 아이콘) 클릭
2. 중앙 **TARGETS** → **Runner** 선택
3. **Signing & Capabilities** 탭:
   - ✅ **Automatically manage signing** 체크 확인
   - **Team** 드롭다운 → 본인 계정/팀 선택

Xcode가 자동으로 인증서와 프로비저닝 프로파일을 생성합니다.

---

## STEP 4. 빌드

### 방법 A: 터미널 (권장)

```bash
cd frontend

# 클린 빌드 (최초 또는 문제 발생 시)
flutter clean && flutter pub get && cd ios && pod install && cd ..

# Ad Hoc IPA 빌드 (기기 직접 설치용)
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# App Store IPA 빌드 (TestFlight/스토어 배포용)
flutter build ipa --release --export-options-plist=ios/ExportOptions-AppStore.plist
```

빌드 결과물:
- Archive: `build/ios/archive/Runner.xcarchive`
- IPA: `build/ios/ipa/사담.ipa`

### 방법 B: Xcode에서 직접

1. `open ios/Runner.xcworkspace`
2. 상단 Device 선택 (시뮬레이터 또는 실제 기기)
3. **Product → Archive** (릴리즈 빌드)
4. Organizer 창 → **Distribute App**

### 디버그 실행

```bash
# 시뮬레이터
flutter run -d ios

# 실제 기기 (USB 연결)
flutter devices                    # 기기 목록 확인
flutter run -d <DEVICE_ID>
```

---

## STEP 5. 배포

### TestFlight 배포 (권장)

1. [App Store Connect](https://appstoreconnect.apple.com)에서 앱 생성
   - Bundle ID: `com.clickaround.sadam`
2. IPA 빌드:
   ```bash
   flutter build ipa --release --export-options-plist=ios/ExportOptions-AppStore.plist
   ```
3. **Transporter** 앱 (Mac App Store에서 설치)으로 IPA 업로드
4. App Store Connect → TestFlight → 테스터 이메일 초대

### Ad Hoc 배포 (제한적)

1. 테스터 iPhone UDID 수집 (설정 → 일반 → 정보 또는 https://udid.io)
2. [Apple Developer](https://developer.apple.com) → Devices에 UDID 등록
3. IPA 재빌드
4. Apple Configurator 2 또는 AltStore로 설치

### USB 직접 설치

```bash
flutter install -d <DEVICE_ID>
```

---

## 한 번에 설정하는 스크립트

Mac 터미널에서 실행:

```bash
#!/bin/bash

# ============================================
# === 아래 값을 본인 정보로 수정하세요 ===
NEW_TEAM_ID="YOUR_TEAM_ID"
# ============================================

cd "$(dirname "$0")/.."  # frontend/ 디렉토리로 이동

echo "📱 사담 iOS 빌드 설정 시작..."

# 1. ExportOptions Team ID 설정
sed -i '' "s/UCXS46KDFJ/$NEW_TEAM_ID/g" ios/ExportOptions.plist
sed -i '' "s/UCXS46KDFJ/$NEW_TEAM_ID/g" ios/ExportOptions-AppStore.plist
echo "✅ ExportOptions Team ID 설정 완료"

# 2. Flutter 의존성
flutter pub get
echo "✅ Flutter 패키지 설치 완료"

# 3. 코드 생성
dart run build_runner build --delete-conflicting-outputs
echo "✅ 코드 생성 완료"

# 4. CocoaPods
cd ios
pod install --repo-update
cd ..
echo "✅ CocoaPods 설치 완료"

echo ""
echo "🎉 설정 완료!"
echo "Team ID: $NEW_TEAM_ID"
echo "Bundle ID: com.clickaround.sadam"
echo ""
echo "다음 단계:"
echo "  1. open ios/Runner.xcworkspace"
echo "  2. Signing & Capabilities에서 Team 선택"
echo "  3. flutter build ipa --release"
```

---

## 다른 Apple 계정으로 빌드할 때

Bundle ID를 변경해야 합니다 (Apple에서 Bundle ID는 전 세계 유일해야 함):

```bash
NEW_BUNDLE_ID="com.yourcompany.sadam"
NEW_TEAM_ID="YOUR_TEAM_ID"

cd frontend

# Bundle ID 변경
sed -i '' "s/com.clickaround.sadam/$NEW_BUNDLE_ID/g" ios/Runner.xcodeproj/project.pbxproj

# Team ID 변경
sed -i '' "s/UCXS46KDFJ/$NEW_TEAM_ID/g" ios/ExportOptions.plist
sed -i '' "s/UCXS46KDFJ/$NEW_TEAM_ID/g" ios/ExportOptions-AppStore.plist
```

---

## 문제 해결

| 문제 | 해결 방법 |
|------|----------|
| **"앱을 확인할 수 없음"** | iPhone 설정 → 일반 → VPN 및 기기 관리 → 개발자 앱 신뢰 |
| **"No signing certificate"** | Xcode → Settings → Accounts → Manage Certificates → `+` → Apple Development |
| **"Failed to register bundle identifier"** | Bundle ID가 이미 사용 중. 다른 고유 이름으로 변경 |
| **"Provisioning profile doesn't include signing certificate"** | Automatically manage signing 체크 해제 후 다시 체크 |
| **CocoaPods 오류** | `cd ios && pod deintegrate && pod cache clean --all && pod install --repo-update` |
| **앱이 바로 종료** | Release 모드로 빌드: `flutter build ipa --release` |
| **인증서 만료** | Apple Developer → Certificates에서 새 인증서 생성 |
| **iOS 26 디버그 모드 깨짐** | iOS 26 베타 기기 대신 시뮬레이터 사용 (Flutter 3.38.6 기준 알려진 이슈) |
| **Module 'xxx' not found** | `flutter clean && flutter pub get && cd ios && pod install && cd ..` |

---

## 파일 구조

```
frontend/
├── .env                            # API 키 (git 미포함, .env.example 참고)
├── pubspec.yaml                    # 앱 버전 0.1.0+13, 의존성
├── ios/
│   ├── Runner.xcworkspace          # ← Xcode에서 이 파일을 열기
│   ├── Runner.xcodeproj/
│   │   └── project.pbxproj         # Bundle ID, 서명 설정
│   ├── Runner/
│   │   ├── Info.plist              # 앱 메타데이터, AdMob ID, SKAdNetwork
│   │   ├── AppDelegate.swift       # 앱 진입점
│   │   └── Assets.xcassets/        # 앱 아이콘
│   ├── Podfile                     # CocoaPods 의존성 (Google-Mobile-Ads-SDK)
│   ├── ExportOptions.plist         # Ad Hoc 배포용
│   ├── ExportOptions-AppStore.plist # App Store/TestFlight 배포용
│   └── BUILD_GUIDE.md             # 이 문서
├── android/
│   ├── app/build.gradle.kts        # Android 빌드 설정 (참고용)
│   ├── key.properties              # Android 서명 키 (git 미포함)
│   └── upload-keystore.jks         # Android 키스토어 (git 미포함)
└── build/
    └── ios/
        ├── archive/Runner.xcarchive
        └── ipa/사담.ipa
```

---

## iOS vs Android 비교

| 항목 | iOS | Android |
|------|-----|---------|
| 서명 방식 | Xcode Automatic Signing | key.properties + keystore |
| 서명 파일 | 인증서 + Provisioning Profile (자동) | upload-keystore.jks |
| 빌드 명령 | `flutter build ipa --release` | `flutter build apk --release` |
| 결과물 | `.ipa` | `.apk` |
| 배포 | TestFlight / Ad Hoc | Google Play / APK 직접 배포 |
| 난독화 | `--obfuscate --split-debug-info=...` | ProGuard (build.gradle에 설정됨) |
| 광고 | Info.plist + SKAdNetwork | AndroidManifest.xml |

---

## 빠른 참조 명령어

```bash
# 전체 클린 빌드 (한 줄)
flutter clean && flutter pub get && cd ios && pod install --repo-update && cd .. && flutter build ipa --release

# Xcode 프로젝트 열기
open ios/Runner.xcworkspace

# 시뮬레이터 실행
flutter run -d ios

# 기기 목록
flutter devices

# 기기 설치
flutter install -d <DEVICE_ID>
```

---

*최종 업데이트: 2026-02-01*
