# iOS App Store 심사 대응 가이드

> **현재 상태**: v0.1.0 (빌드 0.0.9/9) → Guideline 2.1 리젝 (2026-02-05)
> **리젝 사유**: Information Needed - App Completeness
> **App ID**: 6758574982 | **Submission ID**: 785aa2fa-0107-4ec5-806b-e7a360e9184d

---

## 1. 리젝 사유 분석

Apple 심사팀이 **Guideline 2.1 - Information Needed**로 리젝.
이건 코드 버그나 크래시가 아니라 **심사에 필요한 정보가 부족**하다는 뜻.

> 전체 리젝의 40% 이상이 Guideline 2.1 관련.
> 신규 앱일수록 이 사유로 리젝될 확률이 높음.
> — [RevenueCat 가이드](https://www.revenuecat.com/blog/growth/the-ultimate-guide-to-app-store-rejections/)

### Apple이 요구한 6가지

| # | 요구 항목 | 상세 |
|---|----------|------|
| 1 | **실기기 화면 녹화** | 앱 실행~핵심 기능 전체 플로우. 회원가입/로그인/삭제, 결제, 권한 요청 포함 |
| 2 | **앱 목적 설명** | 어떤 문제를 해결하고 어떤 가치를 제공하는지 |
| 3 | **기능 접근 방법** | 주요 기능 사용법 + 테스트 계정/로그인 정보 |
| 4 | **외부 서비스 목록** | 데이터 제공자, 인증, 결제, AI 서비스 등 |
| 5 | **지역별 차이** | 지역에 따른 기능/콘텐츠 차이 또는 "전 지역 동일" 확인 |
| 6 | **규제 산업 문서** | 규제 대상 산업이면 관련 문서 (사주/운세는 해당 없음) |

---

## 2. 빌드 버전 올려야 하는가? — YES

### 핵심 규칙

> **App Store Connect에 업로드된 빌드는 동일한 빌드 번호로 재업로드할 수 없다.**
> — [Flutter 공식 문서](https://docs.flutter.dev/deployment/ios), [Apple Developer Forums](https://developer.apple.com/forums/thread/26985)

### 리젝 유형별 대응

| 리젝 유형 | 새 빌드 필요? | 버전 번호 변경? | 설명 |
|----------|:----------:|:----------:|------|
| **Metadata Rejection** (메타데이터만 수정) | X | X | 스크린샷, 설명 등만 수정 → 같은 빌드로 재제출 가능 |
| **Binary Rejection** (코드 수정 필요) | O | 빌드 번호만 올려도 됨 | 코드 수정 후 새 빌드 업로드 필수 |
| **Information Needed** (우리 케이스) | **상황에 따라** | - | 정보만 회신하면 같은 빌드로 가능하나, **코드 수정이 있으면 새 빌드** |

### 우리의 경우 — 새 빌드 권장

현재 빌드 `0.0.9 (9)`는 2026-02-05 제출본. 이후 코드가 많이 변경됨 (v0.1.6+53까지 진행).
**반드시 새 빌드를 올려야 함.**

```yaml
# pubspec.yaml 변경 예시
# 현재: version: 0.1.0+9
# 변경: version: 0.1.1+10  (또는 현재 Android 버전에 맞춤)
```

> **주의**: Android(Play Store)와 iOS(App Store)의 버전을 맞출지 별도 관리할지 결정 필요.
> Play Store는 이미 v0.1.6+53까지 나갔으므로, iOS도 동일 버전으로 맞추는 게 관리상 편함.

---

## 3. 재심사 전 필수 체크리스트

### 3-1. 화면 녹화 (가장 중요)

> 심사관은 **실제 기기에서** 앱을 테스트함. 시뮬레이터 녹화는 거절 사유가 될 수 있음.
> — [Apple Developer](https://developer.apple.com/distribute/app-review/)

**녹화 방법**: iPhone 실기기 → 설정 → 제어센터 → 화면 기록 추가 → 녹화

**필수 포함 장면**:
- [ ] 앱 아이콘 탭 → 스플래시 화면
- [ ] 온보딩 플로우 (있으면)
- [ ] 프로필 입력 (생년월일, 시간, 성별)
- [ ] **사주 채팅 핵심 플로우** — AI 질문 → 응답 수신까지
- [ ] 인앱결제 화면 진입 (프리미엄 구매 흐름)
- [ ] 설정 화면
- [ ] 계정 삭제 플로우 (Guideline 5.1.1 요구사항)
- [ ] 권한 요청 팝업 (알림, 추적 등)
- [ ] 광고 표시 장면

**녹화 팁**:
- 2~5분 이내로 (너무 길면 심사관이 안 봄)
- 말/설명 없이 조작만 (영문 자막 넣으면 가산점)
- 네트워크 연결 상태에서 촬영
- AI 응답이 실제로 오는 것을 보여줘야 함

### 3-2. App Review Notes 작성 (영문)

App Store Connect → 앱 → 버전 → **App Review Information** → Notes 필드에 작성.

**영문 템플릿**:

```
1. PURPOSE & VALUE
SaDam (사담) is an AI-powered fortune-telling chatbot based on traditional
East Asian astrology (Saju/사주). Users input their birth date, time, and
gender to receive personalized fortune readings through an interactive chat
interface. Unlike traditional fortune-telling apps that provide long static
reports, SaDam offers a conversational AI experience.

2. CORE FEATURES & HOW TO ACCESS
- Launch → Splash → Onboarding (first time only)
- Tap "Profile" → Enter birth date, time, gender → Save
- Main screen → Chat with AI fortune teller
- View daily/monthly/yearly fortunes
- Premium features available via in-app purchase

3. TEST ACCOUNT
No login required for basic features. The app generates a local profile
based on birth information. For premium features testing:
[테스트 계정 정보 또는 "No account required" 기재]

4. EXTERNAL SERVICES
- OpenAI GPT-5.2: AI fortune analysis engine
- Google Gemini 3.0: Conversational AI response generation
- DALL-E / Google Imagen: Fortune illustration image generation
- Supabase: Backend database and authentication
- RevenueCat: In-app purchase and subscription management
- Google AdMob: Advertising (with Liftoff/Mintegral mediation)
- Unity Ads: Secondary ad network
- PostHog: Privacy-friendly analytics

5. REGIONAL DIFFERENCES
The app functions consistently across all regions.
Currently supports 17 languages (Korean, English, Japanese, Chinese,
Vietnamese, Thai, Indonesian, Malay, Myanmar, French, German, Spanish,
Portuguese, Italian, Hindi, Arabic, Russian).
AI responses are generated in the user's device language.

6. REGULATED INDUSTRY
Fortune-telling/astrology is not a regulated industry.
No special licenses or certifications are required.
The app provides entertainment-purpose fortune readings only.
```

### 3-3. iOS 빌드 점검

| 항목 | 상태 | 작업 |
|------|------|------|
| AdMob iOS App ID | ❌ placeholder | `ad_config.dart`에서 `YOUR_IOS_APP_ID` → 실제 ID로 교체 |
| AdMob iOS 광고 단위 ID | ❌ placeholder | 전면/보상형/배너 각각 실제 ID 교체 |
| SKAdNetwork ID 76개 | ❌ 미추가 | `ios/Runner/Info.plist`에 추가 (→ `unity_skadnetwork_ios.md` 참조) |
| 개인정보 처리방침 URL | ✅ 확인 필요 | App Store Connect에 등록된 URL 유효한지 체크 |
| 계정 삭제 기능 | ❓ 확인 필요 | Apple Guideline 5.1.1 → 계정 삭제 필수 (2022.06~) |
| IPv6 호환성 | ❓ 확인 필요 | IPv4 직접 통신 시 리젝됨 (도메인 사용 필수) |
| App Transport Security | ❓ 확인 필요 | HTTP 통신 있으면 exception 설정 |
| 네트워크 단절 처리 | ❓ 확인 필요 | 오프라인 시 크래시 없이 에러 메시지 표시 |
| TestFlight 테스트 | ❌ 필수 | 실기기에서 최소 2~3기종 테스트 |
| 스크린샷 | ❓ 확인 필요 | 실제 앱 화면 (스플래시/로그인 화면만 X) |

### 3-4. 추가 주의사항 (커뮤니티 조사 기반)

> **자주 걸리는 포인트들** — [GeekDive](https://geekdive-corp.com/column/ios-appstore-guide), [OrangeBrother](https://orangebrother.dev/blog/app_why_reject), [0u0Blog](https://blog.0u0.kr/archives/1609)

1. **IDFA (광고 추적)**: ATT(App Tracking Transparency) 팝업 필수. AdMob/Unity 사용하면 무조건 구현해야 함
2. **개인정보 수집 라벨**: App Store Connect에서 "앱이 수집하는 개인정보" 정확히 기재. 생년월일, 기기 ID 등
3. **스크린샷 규정**: 실제 앱 화면이어야 함. 목업/타이틀 아트만 넣으면 리젝 (Guideline 2.3.3)
4. **purpose string**: 카메라/위치/알림 등 권한 요청 시 **왜 필요한지** 명확히 기술 (Info.plist)
5. **구독 정보**: 자동 갱신 구독이 있으면 가격, 기간, 이용약관, 개인정보 처리방침 링크 명시 (Guideline 3.1.2)
6. **로그인 없이 기본 기능**: 로그인 필수 앱이면 게스트 모드 or 데모 계정 제공 필요

---

## 4. 재제출 절차

### Step 1: 코드 수정 & 빌드

```bash
cd frontend

# pubspec.yaml 버전 업데이트
# version: 0.1.7+54  (예시, 현재 Android 버전에 맞춤)

# 의존성 & 코드 생성
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# iOS 빌드 (실기기 or Archive)
flutter build ios --release

# Xcode에서 Archive → App Store Connect 업로드
# Xcode → Product → Archive → Distribute App → App Store Connect
```

### Step 2: App Store Connect 설정

1. [App Store Connect](https://appstoreconnect.apple.com/apps/6758574982) 접속
2. 새 빌드 선택 (업로드 후 처리까지 ~30분 소요)
3. **App Review Information → Notes** 필드에 위 영문 템플릿 붙여넣기
4. **App Review Information → Attachment** 에 화면 녹화 영상 첨부
5. 스크린샷 업데이트 (필요시)
6. "앱이 수집하는 개인정보" 재확인

### Step 3: 회신 + 재제출

1. 앱 심사 페이지 → **"앱 심사에 회신"** 클릭
2. 요구된 6가지 항목 답변 작성 (영문)
3. **"앱 심사에 다시 제출"** 클릭

### Step 4: 대기

- 평균 심사 기간: 24~48시간 (신규 앱은 더 길 수 있음)
- 상태 확인: App Store Connect 또는 메일

---

## 5. 자주 하는 실수 (리젝 반복 방지)

| 실수 | 대응 |
|------|------|
| 데모 계정 안 줌 | Notes에 테스트 계정 명시 |
| 화면 녹화 시뮬레이터 | **반드시 실기기** |
| placeholder 텍스트 남김 | 앱 전체 "Lorem ipsum", "TODO" 검색 |
| 오프라인 크래시 | 네트워크 끊고 테스트 |
| 스크린샷이 앱과 다름 | 현재 버전 스크린샷으로 교체 |
| 구독 정보 누락 | 가격/기간/약관/개인정보 링크 |
| purpose string 부실 | "앱에서 알림을 보내기 위해 필요합니다" 식으로 구체적으로 |

---

## 참고 자료

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS 배포 공식 문서](https://docs.flutter.dev/deployment/ios)
- [App Store 리젝 완벽 가이드 (RevenueCat)](https://www.revenuecat.com/blog/growth/the-ultimate-guide-to-app-store-rejections/)
- [App Store Review 2026 체크리스트 (Adapty)](https://adapty.io/blog/how-to-pass-app-store-review/)
- [앱 스토어 배포 가이드 (GeekDive)](https://geekdive-corp.com/column/ios-appstore-guide)
- [앱 심사 리젝 사유 모음 (OrangeBrother)](https://orangebrother.dev/blog/app_why_reject)
- [Apple 심사 거부 사례 정리 (0u0Blog)](https://blog.0u0.kr/archives/1609)
- [Apple Developer Forums - Guideline 2.1](https://developer.apple.com/forums/thread/100426)
- [BuddyBoss - 2.1 대응 가이드](https://buddyboss.com/docs/app-store-guideline-2-1-performance-app-completeness-2/)
