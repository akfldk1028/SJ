# iOS 빌드 가이드 (사담 앱)

## 사전 요구사항

1. **macOS** (Xcode는 macOS에서만 실행 가능)
2. **Xcode 15.0+** (App Store에서 설치)
3. **Flutter SDK** (3.0 이상)
4. **CocoaPods** 설치:
   ```bash
   sudo gem install cocoapods
   ```

## 빌드 단계

### 1. 프로젝트 설정

```bash
# 프로젝트 디렉토리로 이동
cd frontend

# Flutter 패키지 설치
flutter pub get

# iOS 폴더로 이동하여 CocoaPods 설치
cd ios
pod install
cd ..
```

### 2. 개발 빌드 (디버그)

```bash
# iOS 시뮬레이터에서 실행
flutter run -d ios

# 또는 특정 시뮬레이터 선택
flutter devices  # 사용 가능한 디바이스 목록 확인
flutter run -d "iPhone 15"
```

### 3. 릴리즈 빌드 (배포용)

```bash
# IPA 파일 생성 (App Store 배포용)
flutter build ipa --release

# 또는 Xcode에서 직접 빌드
open ios/Runner.xcworkspace
```

### 4. Xcode에서 직접 빌드

1. `ios/Runner.xcworkspace` 파일을 Xcode에서 열기
2. 상단 메뉴에서 기기 선택 (시뮬레이터 또는 실제 기기)
3. `Product > Build` (Cmd + B) 또는 `Product > Run` (Cmd + R)

## 설정 정보

- **최소 iOS 버전**: 13.0
- **지원 기기**: iPhone only (iPad 미지원)
- **화면 방향**: 세로 모드만 지원
- **Bundle ID**: `com.example.frontend` (배포 시 변경 필요)

## 앱 스토어 배포 전 체크리스트

1. **Bundle ID 변경**
   - `ios/Runner.xcodeproj/project.pbxproj`에서 `PRODUCT_BUNDLE_IDENTIFIER` 수정

2. **AdMob App ID 변경**
   - `ios/Runner/Info.plist`에서 `GADApplicationIdentifier` 값을 실제 앱 ID로 변경

3. **앱 아이콘 설정**
   - `ios/Runner/Assets.xcassets/AppIcon.appiconset/` 경로에 앱 아이콘 추가

4. **서명 및 프로비저닝**
   - Xcode에서 Team 선택 및 Signing 설정

## 문제 해결

### pod install 에러 시
```bash
cd ios
pod deintegrate
pod cache clean --all
pod install
```

### Flutter 빌드 에러 시
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios
```
