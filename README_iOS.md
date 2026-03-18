# iOS 앱 빌드 & App Store 배포 가이드

> Mac 사용자 또는 AI 에이전트가 클론 → 설정 → 빌드 → 배포까지 **순서대로** 따라갈 수 있는 완전 가이드
>
> **AI 에이전트 참고**: 이 문서는 순차적으로 Part 1 → Part 7까지 따라가면 됩니다.
> Part 4, 5는 이미 완료되어 있으므로 건너뛰고 Part 1~3 (빌드) 후 Part 5-6~7 (업로드/배포)만 진행하면 됩니다.
> 관련 파일: `ios/CREDENTIALS.md` (계정 정보, gitignore됨), `ios/ExportOptions-AppStore.plist` (Team ID 세팅 완료)

---

## 현재 프로젝트 정보

| 항목 | iOS | Android (참고) |
|------|-----|----------------|
| **Bundle ID / Package** | `com.clickaround.sadam` | `com.clickaround.sadam` |
| **앱 이름** | 사담 | 사담 |
| **최소 버전** | iOS 13.0 | API 21 |
| **앱 버전** | 0.1.0+13 | 0.1.0+13 |
| **AdMob App ID** | `ca-app-pub-7140787344231420~3931921704` | 동일 |
| **Team ID** | `UCXS46KDFJ` (ClickAround) | - |
| **코드 서명** | Xcode Automatic Signing | key.properties + keystore |

### App Store Connect 정보 (등록 완료)

| 항목 | 값 |
|------|-----|
| **App Store Connect URL** | https://appstoreconnect.apple.com/apps/6758574982 |
| **Apple ID (앱)** | `6758574982` |
| **SKU** | `sadam-001` |
| **기본 언어** | 한국어 |
| **상태** | 제출 준비 중 (버전 1.0) |

### 입력 완료 항목

| 항목 | 값 | 상태 |
|------|-----|------|
| 앱 이름 | 사담 | ✅ |
| 번들 ID | com.clickaround.sadam | ✅ (Apple Developer 식별자 등록 완료) |
| 기본 언어 | 한국어 | ✅ |
| 키워드 | 사주,운세,AI,챗봇,만세력,사담,오늘운세,신년운세,궁합,토정비결 | ✅ |
| 버전 | 0.1.0 | ✅ |
| 저작권 | 2026 ClickAround | ✅ |
| 프로모션 텍스트 | AI가 풀어주는 나만의 사주 이야기... | ✅ |
| 설명 | AI 기반 사주 상담 챗봇 소개 + 기능 목록 | ✅ |
| 심사 연락처 | Donghyeon Kim / clickaround8@gmail.com | ✅ |
| 로그인 필요 | 아니요 (체크 해제) | ✅ |
| 앱 출시 방식 | 자동으로 버전 출시 | ✅ |

### 아직 필요한 항목 (빌드 전에 준비)

| 항목 | 설명 | 긴급도 |
|------|------|--------|
| **스크린샷** | 6.5" iPhone (1284x2778px) 최소 3장 필요 | **필수** |
| **개인정보 처리방침 URL** | 웹페이지 만들어서 URL 등록 (앱 정보 메뉴) | **필수** |
| **지원 URL** | 고객 지원/문의 페이지 URL | **필수** |
| **카테고리** | 앱 정보 → 카테고리: 라이프스타일 설정 | **필수** |
| **연령 등급** | 앱 정보 → 연령 등급 질문 답변 | **필수** |
| **가격** | 가격 및 사용 가능 여부 → 무료, 대한민국 | **필수** |
| **IPA 빌드 업로드** | Mac에서 빌드 후 Transporter로 업로드 | **필수** |
| **앱 아이콘** | 1024x1024px (빌드에 포함되어 있으면 자동) | 확인 필요 |
| 마케팅 URL | 앱 홍보 페이지 (선택) | 선택 |
| 앱 미리보기 동영상 | 15~30초 (선택) | 선택 |

---

## Part 1: Mac 환경 세팅 (최초 1회)

### 1-1. 필수 소프트웨어 설치

```bash
# Xcode (Mac App Store에서 설치 후)
xcode-select --install
sudo xcodebuild -license accept

# CocoaPods
sudo gem install cocoapods

# Flutter SDK
# https://docs.flutter.dev/get-started/install/macos
flutter doctor   # 환경 점검
```

### 1-2. Xcode에 Apple 계정 등록

> 계정 정보는 `ios/CREDENTIALS.md` 파일 참고 (DK에게 파일 요청)

1. Xcode 실행 → **Xcode → Settings** (`Cmd + ,`)
2. **Accounts** 탭 → `+` → **Apple ID**
3. `CREDENTIALS.md`에 적힌 Apple ID / 비밀번호 입력
4. **2FA 인증 코드**는 DK에게 요청
5. Team 목록에 **ClickAround**가 보이면 OK

---

## Part 2: 프로젝트 설정

### 2-1. 클론 & 의존성

```bash
git clone <repository-url>
cd SJ/frontend

flutter pub get
dart run build_runner build --delete-conflicting-outputs

cd ios
pod install --repo-update
cd ..
```

### 2-2. 환경 변수 (.env)

```bash
cp .env.example .env
# 팀원에게 실제 API 키 받아서 입력
```

### 2-3. Xcode 서명 설정

```bash
open ios/Runner.xcworkspace    # xcodeproj가 아님!
```

1. 좌측 **Runner** (파란 아이콘) → **TARGETS → Runner**
2. **Signing & Capabilities** 탭
3. **Automatically manage signing** 체크
4. **Team** 드롭다운 → **ClickAround** 선택

> ExportOptions에 Team ID `UCXS46KDFJ`가 이미 세팅되어 있어 별도 수정 불필요

---

## Part 3: 빌드

```bash
cd frontend

# 클린 빌드 (문제 있을 때)
flutter clean && flutter pub get && cd ios && pod install && cd ..

# Ad Hoc IPA (기기 직접 설치용)
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# App Store IPA (TestFlight / 스토어 배포용)
flutter build ipa --release --export-options-plist=ios/ExportOptions-AppStore.plist
```

결과물: `build/ios/ipa/사담.ipa`

---

## Part 4: Apple Developer 사이트에서 Bundle ID 등록 ✅ 완료

> **이미 완료됨** — `com.clickaround.sadam`이 등록되어 있음. 새로 할 필요 없음.
> 아래는 참고용 절차입니다.
>
> https://developer.apple.com 로그인

### 4-1. 인증서, ID 및 프로파일 → 식별자

사이트 메뉴 구조:
```
프로그램 리소스
├── App Store Connect          ← Part 5에서 사용
├── 인증서, ID 및 프로파일     ← 지금 여기
│   ├── 인증서
│   ├── 식별자                 ← 여기서 Bundle ID 등록
│   ├── 기기
│   ├── 프로파일
│   └── 키
└── 서비스
```

### 4-2. Bundle ID 등록 절차

1. **인증서, ID 및 프로파일** 클릭
2. 좌측 메뉴 **식별자** 클릭
3. 상단 `+` 버튼 클릭
4. **App IDs** 선택 → **계속**
5. **앱** 선택 → **계속**
6. 입력:

| 항목 | 값 |
|------|-----|
| **설명** | 사담 |
| **Bundle ID** | **명시적** 선택 → `com.clickaround.sadam` 입력 |

7. 하단 **기능** 섹션에서 필요한 것 체크:
   - ✅ 앱 내 구입 (In-App Purchase) — RevenueCat 사용 중이므로
   - ✅ 푸시 알림 — 나중에 필요하면
   - 나머지는 기본값 OK

8. **계속** → **등록** 클릭

---

## Part 5: App Store Connect에서 앱 등록

> https://appstoreconnect.apple.com 로그인

### 5-1. 신규 앱 생성

사이트 메뉴:
```
App Store Connect
├── 앱                ← 여기
├── 앱 분석
├── 판매 및 추세
├── 지불 및 재무 보고서
├── 비즈니스
└── 사용자 및 액세스
```

1. **앱** 클릭
2. 좌측 상단 `+` → **신규 앱**
3. 입력:

| 항목 | 값 |
|------|-----|
| **플랫폼** | ✅ iOS |
| **이름** | 사담 |
| **기본 언어** | 한국어 |
| **번들 ID** | `com.clickaround.sadam` (Part 4에서 등록한 것 선택) |
| **SKU** | `sadam-001` (내부 식별자, 아무거나 OK) |
| **전체 접근** | ✅ 체크 |

4. **생성** 클릭

### 5-2. 앱 정보 입력

앱 선택 → 좌측 메뉴 **앱 정보**:

| 항목 | 필수 | 값 |
|------|------|-----|
| **개인정보 처리방침 URL** | 필수 | 개인정보처리방침 페이지 URL |
| **카테고리** | 필수 | 주 카테고리: **라이프스타일** |
| **보조 카테고리** | 선택 | 엔터테인먼트 |
| **콘텐츠 권한** | 필수 | "제3자 콘텐츠를 포함하지 않음" 선택 |

### 5-3. 가격 및 사용 가능 여부

좌측 메뉴 **가격 및 사용 가능 여부**:

| 항목 | 값 |
|------|-----|
| **가격** | 무료 (₩0) |
| **사용 가능 여부** | 대한민국 ✅ (다른 국가도 필요시 체크) |

### 5-4. 연령 등급

좌측 메뉴 **연령 등급**:

- 질문에 답변 (폭력, 도박 등 해당 없음 선택)
- 결과: **4+** (대부분의 경우)

### 5-5. 버전 정보 (앱 스토어 탭)

앱 선택 → 좌측 **iOS 앱** → 버전 페이지 → **App Store** 탭:

| 항목 | 필수 | 값 / 설명 |
|------|------|-----------|
| **스크린샷 6.7"** | 필수 | iPhone 15 Pro Max: **1290 x 2796 px**, 최소 3장 |
| **스크린샷 6.5"** | 필수 | iPhone 14 Plus: **1284 x 2778 px**, 최소 3장 |
| **앱 미리보기** | 선택 | 15~30초 동영상 |
| **프로모션 텍스트** | 선택 | 170자 이내 (심사 없이 수시 변경 가능) |
| **설명** | 필수 | 앱 설명, 4000자 이내 |
| **키워드** | 필수 | `사주,운세,AI,챗봇,만세력,사담,오늘운세,신년운세,궁합` (100자, 쉼표 구분) |
| **지원 URL** | 필수 | 고객 지원 페이지 URL |
| **마케팅 URL** | 선택 | 앱 홍보 페이지 URL |
| **버전** | 필수 | `0.1.0` |
| **저작권** | 필수 | `2026 ClickAround` |

### 5-6. 빌드 업로드

#### 방법 A: Transporter 앱 (권장)

1. Mac App Store에서 **Transporter** 설치
2. Transporter 실행 → Apple ID 로그인
3. IPA 파일 드래그 앤 드롭: `build/ios/ipa/사담.ipa`
4. **전송** 클릭
5. 업로드 완료까지 대기

#### 방법 B: Xcode에서 직접

1. `open ios/Runner.xcworkspace`
2. **Product → Archive**
3. Organizer 창 → **Distribute App** → **App Store Connect** → **업로드**

> 업로드 후 App Store Connect에서 처리되기까지 10~30분 소요

### 5-7. 빌드 선택

업로드 처리 완료 후:

1. App Store Connect → 앱 → 버전 페이지
2. **빌드** 섹션 → `+` 클릭
3. 업로드한 빌드 선택

---

## Part 6: TestFlight 테스트 배포

### 6-1. 내부 테스트 (팀원용, 심사 없음)

App Store Connect → 앱 → **TestFlight** 탭:

1. **내부 테스트** → `+` 그룹 생성 (예: "개발팀")
2. **테스터 추가**: 팀원 Apple ID 이메일 입력
3. 빌드 선택 → **테스트 시작**
4. 팀원은 iPhone에서 **TestFlight 앱** 설치 → 초대 수락 → 앱 설치

> 내부 테스트: 최대 100명, 즉시 테스트 가능

### 6-2. 외부 테스트 (일반 유저용, 간단 심사)

1. **외부 테스트** → `+` 그룹 생성 (예: "베타 테스터")
2. 테스터 이메일 추가 또는 **공개 링크** 생성
3. 빌드 선택 → **심사 제출**
4. Apple 간단 심사 (1~2일) 후 테스터에게 배포

> 외부 테스트: 최대 10,000명

---

## Part 7: App Store 정식 출시

### 7-1. 심사 제출

1. App Store Connect → 앱 → 버전 페이지
2. 모든 메타데이터 입력 확인 (스크린샷, 설명, URL 등)
3. 빌드가 선택되어 있는지 확인
4. **심사를 위해 추가** 클릭
5. **수출 규정 준수 정보** 답변:
   - "앱이 암호화를 사용합니까?" → **아니요** (표준 HTTPS만 사용하는 경우)
   - 또는 **예** → "면제에 해당합니까?" → **예**
6. **App Review에 제출** 클릭

### 7-2. 심사 결과

- **승인**: 자동 출시 또는 수동 출시 선택에 따라 App Store에 게시
- **거부**: 거부 사유 확인 → 수정 후 재제출

> 심사는 보통 1~3일 소요

---

## Part 8: 다른 Apple 계정으로 빌드할 때

Bundle ID는 Apple에서 전 세계 유일해야 하므로, 다른 계정이면 변경 필요:

```bash
NEW_BUNDLE_ID="com.yourcompany.sadam"
NEW_TEAM_ID="YOUR_TEAM_ID"

cd frontend
sed -i '' "s/com.clickaround.sadam/$NEW_BUNDLE_ID/g" ios/Runner.xcodeproj/project.pbxproj
sed -i '' "s/UCXS46KDFJ/$NEW_TEAM_ID/g" ios/ExportOptions.plist
sed -i '' "s/UCXS46KDFJ/$NEW_TEAM_ID/g" ios/ExportOptions-AppStore.plist
```

---

## 문제 해결

| 문제 | 해결 |
|------|------|
| "앱을 확인할 수 없음" | iPhone 설정 → 일반 → VPN 및 기기 관리 → 개발자 앱 신뢰 |
| "No signing certificate" | Xcode → Settings → Accounts → Manage Certificates → `+` → Apple Development |
| "Failed to register bundle identifier" | Bundle ID 중복. 다른 이름으로 변경 |
| "Provisioning profile doesn't include..." | Automatically manage signing 해제 후 다시 체크 |
| CocoaPods 오류 | `cd ios && pod deintegrate && pod cache clean --all && pod install --repo-update` |
| 앱이 바로 종료 | `flutter build ipa --release` (Release 모드 확인) |
| iOS 26 디버그 깨짐 | 시뮬레이터 사용 (Flutter 3.38.6 알려진 이슈) |
| Module not found | `flutter clean && flutter pub get && cd ios && pod install && cd ..` |
| Transporter 업로드 실패 | Bundle ID가 App Store Connect의 번들 ID와 일치하는지 확인 |
| "수출 규정 준수 누락" | App Store Connect → TestFlight → 빌드 → 수출 규정 준수 → "아니요" 선택 |
| "심사 거부: 개인정보처리방침 누락" | 앱 정보 → 개인정보 처리방침 URL 입력 필수 |

---

## Google Play Console vs App Store Connect 비교

| | Google Play Console | App Store Connect |
|---|---|---|
| **URL** | play.google.com/console | appstoreconnect.apple.com |
| **등록비** | $25 (1회) | ₩129,000/년 |
| **앱 등록 전 준비** | 없음 | **인증서, ID 및 프로파일 → 식별자**에서 Bundle ID 먼저 등록 |
| **빌드 업로드** | APK/AAB 직접 드래그 | Transporter 앱 또는 Xcode |
| **테스트 배포** | 내부/비공개/공개 테스트 트랙 | TestFlight (내부/외부) |
| **심사** | 몇 시간~1일 | 1~3일 |
| **개인정보처리방침** | 필수 | 필수 |
| **스크린샷** | 자유 해상도 | **기기별 정확한 해상도 필수** |
| **앱 정보 메뉴** | 스토어 등록정보 | 앱 정보 + 버전 페이지 (App Store 탭) |
| **카테고리** | 카테고리 | 카테고리 |
| **콘텐츠 등급** | 콘텐츠 등급 질문지 | 연령 등급 질문지 |
| **가격** | 가격 설정 | 가격 및 사용 가능 여부 |

---

## 빠른 참조 명령어

```bash
# 전체 클린 빌드 (한 줄)
flutter clean && flutter pub get && cd ios && pod install --repo-update && cd .. && flutter build ipa --release

# Xcode 프로젝트 열기
open ios/Runner.xcworkspace

# 시뮬레이터 실행
flutter run -d ios

# App Store용 빌드
flutter build ipa --release --export-options-plist=ios/ExportOptions-AppStore.plist

# 기기 직접 설치
flutter devices && flutter install -d <DEVICE_ID>
```

---

## 체크리스트: App Store 출시 전

### Apple Developer 사이트
- [x] 인증서, ID 및 프로파일 → 식별자 → `com.clickaround.sadam` 등록

### App Store Connect — 완료
- [x] 앱 → 신규 앱 생성 (앱 ID: `6758574982`)
- [x] 버전 페이지 → 설명 입력
- [x] 버전 페이지 → 키워드 입력
- [x] 버전 페이지 → 프로모션 텍스트 입력
- [x] 버전 페이지 → 저작권: `2026 ClickAround`
- [x] 버전 페이지 → 버전: `0.1.0`
- [x] 심사 연락처 정보 입력

### App Store Connect — 아직 필요
- [ ] **개인정보 처리방침 URL** (앱 정보 메뉴) — 웹페이지 필요
- [ ] **지원 URL** (버전 페이지) — 고객 문의 페이지 필요
- [ ] **카테고리** 설정 (앱 정보 → 라이프스타일)
- [ ] **연령 등급** 질문 답변 (앱 정보 → 연령 등급)
- [ ] **가격 및 사용 가능 여부** → 무료, 대한민국
- [ ] **스크린샷** 업로드 — 6.5" iPhone (1284x2778px) 최소 3장

### 빌드 & 업로드
- [ ] `.env` 파일에 프로덕션 API 키 설정
- [ ] `flutter build ipa --release --export-options-plist=ios/ExportOptions-AppStore.plist`
- [ ] Transporter로 IPA 업로드
- [ ] App Store Connect → 빌드 선택
- [ ] 수출 규정 준수 답변 완료

### 테스트 & 출시
- [ ] TestFlight 내부 테스트 완료
- [ ] 심사를 위해 추가 → App Review에 제출

---

*최종 업데이트: 2026-02-01*
