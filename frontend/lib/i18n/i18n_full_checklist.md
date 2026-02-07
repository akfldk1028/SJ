# 다국어(i18n) 완전 가이드 - 사담 앱

> 작성일: 2026-02-07
> 목적: "UI 글자만 바꾸는 게 아니라" 진짜 글로벌 출시를 위해 해야 할 모든 것

---

## 0. OS가 국가/언어를 판단하는 원리

### 어떻게 판단하는가?

```
사용자가 폰 설정 > 언어에서 "日本語" 선택
       ↓
OS가 시스템 Locale을 "ja" 로 설정
       ↓
앱 실행 시 Flutter가 OS에게 현재 Locale 질의
       ↓
easy_localization이 supportedLocales에서 매칭
       ↓
매칭 실패 시 fallbackLocale (ko) 사용
```

### 판단 기준 (중요!)

| 구분 | 설명 |
|------|------|
| **언어 (Language)** | 사용자가 설정 > 언어에서 선택한 것 (ko, en, ja) |
| **지역 (Region)** | 사용자가 설정 > 지역에서 선택한 것 (KR, US, JP) |
| **국가 ≠ 언어** | 일본에서 한국어 폰 = locale `ko`, region `JP` |

**Flutter에서 접근:**
```dart
import 'dart:ui';

// 언어 코드 (ko, en, ja)
final lang = PlatformDispatcher.instance.locale.languageCode;

// 국가 코드 (KR, US, JP) - 빈 문자열일 수 있음
final country = PlatformDispatcher.instance.locale.countryCode;

// easy_localization 사용 시
final lang = context.locale.languageCode;
```

**핵심**: 앱스토어에서 다운로드 받은 나라가 아니라, **폰에 설정된 언어**에 따라 결정됨.
- 한국인이 일본 여행 가서 써도 → 한국어 그대로
- 재일교포가 폰 언어를 일본어로 쓰면 → 일본어로 표시

---

## 1. 현재 완료된 것

| 항목 | 상태 | 비고 |
|------|:----:|------|
| easy_localization 설정 | ✅ | main.dart에 ko/en/ja 등록됨 |
| JSON 번역 파일 | ✅ | `lib/i18n/ko,en,ja/` 14개 파일씩 |
| MultiFileAssetLoader | ✅ | 커스텀 로더 구현됨 |
| app.dart locale 연결 | ✅ | `context.localizationDelegates` 연결됨 |
| i18n README (적용 매핑) | ✅ | 파일별 .tr() 변환 가이드 |

---

## 2. 아직 안 된 것 (UI 글자 외에 해야 할 것들)

### 2-A. 네이티브 앱 이름 다국어 (필수!)

홈 화면 아이콘 밑에 뜨는 이름. Flutter 코드가 아니라 **OS 네이티브 설정**.

#### Android

현재: `AndroidManifest.xml`에 `android:label="사담"` 하드코딩

**해야 할 것:**

```
android/app/src/main/res/
├── values/
│   └── strings.xml          ← 새로 만들기 (기본값: 한국어)
├── values-en/
│   └── strings.xml          ← 새로 만들기
└── values-ja/
    └── strings.xml          ← 새로 만들기
```

**파일 내용:**

```xml
<!-- values/strings.xml (기본 = 한국어) -->
<resources>
    <string name="app_name">사담</string>
</resources>
```

```xml
<!-- values-en/strings.xml -->
<resources>
    <string name="app_name">SaDam</string>
</resources>
```

```xml
<!-- values-ja/strings.xml -->
<resources>
    <string name="app_name">サダム</string>
</resources>
```

**AndroidManifest.xml 수정:**
```xml
<!-- BEFORE -->
android:label="사담"

<!-- AFTER -->
android:label="@string/app_name"
```

#### iOS

현재: `Info.plist`에 `CFBundleDisplayName = 사담` 하드코딩

**해야 할 것:**

```
ios/Runner/
├── ko.lproj/
│   └── InfoPlist.strings     ← 새로 만들기
├── en.lproj/
│   └── InfoPlist.strings     ← 새로 만들기
├── ja.lproj/
│   └── InfoPlist.strings     ← 새로 만들기
└── Info.plist                ← CFBundleDisplayName 제거 또는 기본값
```

**파일 내용:**

```
/* ko.lproj/InfoPlist.strings */
CFBundleDisplayName = "사담";
CFBundleName = "사담";
```

```
/* en.lproj/InfoPlist.strings */
CFBundleDisplayName = "SaDam";
CFBundleName = "SaDam";
```

```
/* ja.lproj/InfoPlist.strings */
CFBundleDisplayName = "サダム";
CFBundleName = "サダム";
```

**Info.plist 수정:** `CFBundleDisplayName` 키를 제거하면 .lproj 파일이 우선 적용됨.
또는 기본값으로 남겨두면 매칭 안 되는 언어에서 fallback으로 사용.

---

### 2-B. AI 프롬프트 언어 분기 (매우 중요!)

UI만 번역해도 **AI 응답은 여전히 한국어**로 오게 됨. 이게 가장 큰 작업.

**영향 범위:**
```
사용자 폰 언어 = 일본어
       ↓
UI: 日本語로 표시됨 ✅
       ↓
AI한테 보내는 프롬프트: 한국어로 사주 분석해줘... ❌
       ↓
AI 응답: 한국어로 옴 ❌
       ↓
일본 사용자: ??? 뭔 소리야
```

**해야 할 것:**

1. **프롬프트 템플릿 다국어화**
   - `assets/prompts/` 폴더의 프롬프트들을 언어별로 분기
   - 또는 프롬프트에 `"Respond in {language}" 지시를 동적 삽입

2. **가장 현실적인 방법:**
```dart
// AI 호출 시 현재 locale 기반으로 응답 언어 지정
final locale = context.locale.languageCode;
final langInstruction = switch (locale) {
  'ko' => '한국어로 답변해주세요.',
  'en' => 'Please respond in English.',
  'ja' => '日本語で回答してください。',
  _ => '한국어로 답변해주세요.',
};

// 프롬프트에 삽입
final prompt = '''
$langInstruction

사주 정보: $sajuData
질문: $userQuestion
''';
```

3. **사주 용어 처리 (문화 차이)**
   - 한국: "사주팔자", "오행" → 한국식 설명
   - 일본: "四柱推命" (시추추메이) → 일본에서 익숙한 용어로
   - 영어: "Four Pillars of Destiny" → 서양식 설명 스타일

---

### 2-C. 날짜/시간 포맷

```dart
// 한국: 2026년 2월 7일 (금)
// 일본: 2026年2月7日 (金)
// 미국: February 7, 2026 (Fri)

import 'package:intl/intl.dart';

// locale에 맞는 날짜 포맷 자동 적용
final formatted = DateFormat.yMMMMd(context.locale.toString()).format(date);
```

**이미 intl 패키지가 있으므로** `DateFormat`에 locale만 전달하면 됨.
현재 코드에서 날짜를 한국식으로 하드코딩한 부분이 있으면 수정 필요.

---

### 2-D. 숫자/통화 포맷

```dart
// 한국: 4,900원
// 일본: ¥500
// 미국: $3.99

// RevenueCat이 알아서 현지 통화로 보여주므로 IAP 가격은 자동 처리됨
// 단, 앱 내에서 직접 가격을 표시하는 곳이 있다면 NumberFormat 사용
final formatted = NumberFormat.currency(
  locale: context.locale.toString(),
  symbol: currencySymbol,
).format(price);
```

**RevenueCat**: 스토어 가격은 자동으로 현지 통화 표시 (해야 할 것 없음)

---

### 2-E. 스토어 등록 정보 (수동 작업)

이건 코드가 아니라 Google Play Console / App Store Connect에서 직접 입력.

| 항목 | Google Play Console | App Store Connect |
|------|-------------------|------------------|
| 앱 이름 | 스토어 등록정보 > 언어 추가 | 앱 정보 > 현지화 |
| 설명 | 각 언어별 작성 | 각 언어별 작성 |
| 스크린샷 | 언어별 별도 업로드 | 언어별 별도 업로드 |
| 키워드 | - | 언어별 키워드 |

**하나의 앱 등록으로** 여러 언어 추가 가능 (별도 빌드 X).

---

### 2-F. 하드코딩된 한국어 텍스트 제거

`i18n/README.md`에 이미 상세한 매핑이 있음. 아직 실제 적용은 안 된 상태.

**현재 문제:**
- `app_strings.dart`: 전부 한국어 하드코딩 → `.tr()` 로 교체 필요
- `splash_screen.dart`: `AppStrings.appName` 사용 중 → `'common.appName'.tr()` 로 교체

**app_strings.dart 처리 방향:**
- 점진적으로 `.tr()` 호출로 교체
- 모든 파일이 교체 완료되면 `app_strings.dart`는 삭제 가능
- 교체 전까지는 fallback으로 유지

---

### 2-G. Splash 이미지 다국어

현재 Splash는 코드로 그리고 있음 (원형 그라디언트 + 아이콘). 이미지 파일 아님.
→ 텍스트만 `.tr()` 로 바꾸면 자동으로 다국어 적용됨.

만약 나중에 이미지 로고를 쓰게 된다면:
```dart
// assets/images/logo_ko.png, logo_en.png, logo_ja.png 준비 후:
Image.asset('assets/images/logo_${context.locale.languageCode}.png')
```

---

## 3. 전체 체크리스트

### Phase 1: 기반 작업 (필수)

- [ ] **Android 앱 이름 다국어**: `values/strings.xml`, `values-en/strings.xml`, `values-ja/strings.xml` 생성
- [ ] **Android Manifest 수정**: `android:label="사담"` → `android:label="@string/app_name"`
- [ ] **iOS 앱 이름 다국어**: `ko.lproj/InfoPlist.strings`, `en.lproj/`, `ja.lproj/` 생성
- [ ] **iOS Info.plist**: `CFBundleDisplayName` 키 처리
- [ ] **iOS CFBundleLocalizations**: Info.plist에 지원 언어 선언 추가

### Phase 2: Flutter 코드 적용

- [ ] **하드코딩 텍스트 제거**: `i18n/README.md`에 정리된 파일별 `.tr()` 교체 수행
- [ ] **app_strings.dart 단계적 제거**: `.tr()` 교체 완료된 부분부터 삭제
- [ ] **날짜 포맷 수정**: `DateFormat`에 locale 전달
- [ ] **숫자 포맷 수정**: 점수 표시 등에서 locale-aware 포맷 사용

### Phase 3: AI 응답 다국어

- [ ] **AI 프롬프트에 언어 지시 삽입**: `"日本語で回答してください"` 등
- [ ] **프롬프트 템플릿 다국어화**: 운세 프롬프트의 문화권별 조정
- [ ] **사주 용어 매핑**: 한국 "사주" ↔ 일본 "四柱推命" ↔ 영어 "Four Pillars"
- [ ] **AI 응답 품질 테스트**: 각 언어별로 자연스러운지 확인

### Phase 4: 스토어 출시

- [ ] **Google Play 스토어 등록정보**: 일본어/영어 설명, 스크린샷
- [ ] **App Store 등록정보**: 일본어/영어 설명, 스크린샷, 키워드
- [ ] **개인정보처리방침**: 다국어 버전
- [ ] **이용약관**: 다국어 버전

### Phase 5: 선택사항

- [ ] **앱 내 언어 변경 UI**: 폰 설정 안 바꾸고 앱 내에서 직접 언어 선택
- [ ] **RTL 지원**: 아랍어 등 추가 시 (현재 불필요)
- [ ] **폰트**: 언어별 최적 폰트 (일본어는 Noto Sans JP 등)

---

## 4. easy_localization 앱 내 언어 변경 (선택)

유저가 폰 설정을 안 바꾸고 앱 안에서 직접 언어를 바꾸고 싶을 때:

```dart
// 설정 화면에서
ElevatedButton(
  onPressed: () => context.setLocale(const Locale('ja')),
  child: const Text('日本語'),
),

ElevatedButton(
  onPressed: () => context.setLocale(const Locale('en')),
  child: const Text('English'),
),

ElevatedButton(
  onPressed: () => context.setLocale(const Locale('ko')),
  child: const Text('한국어'),
),
```

`easy_localization`이 자동으로 선택된 locale을 SharedPreferences에 저장.
앱 재시작해도 유지됨.

---

## 5. 흐름 요약 (하나의 빌드)

```
[하나의 APK/IPA 빌드]
       │
       ├── 폰 언어 = 한국어 → locale: ko
       │     ├── 앱 이름: "사담" (values/strings.xml)
       │     ├── UI 텍스트: i18n/ko/*.json
       │     ├── AI 응답: 한국어 프롬프트
       │     └── 날짜: 2026년 2월 7일
       │
       ├── 폰 언어 = English → locale: en
       │     ├── 앱 이름: "SaDam" (values-en/strings.xml)
       │     ├── UI 텍스트: i18n/en/*.json
       │     ├── AI 응답: English 프롬프트
       │     └── 날짜: February 7, 2026
       │
       └── 폰 언어 = 日本語 → locale: ja
             ├── 앱 이름: "サダム" (values-ja/strings.xml)
             ├── UI 텍스트: i18n/ja/*.json
             ├── AI 응답: 日本語 プロンプト
             └── 날짜: 2026年2月7日
```

**결론: 빌드는 하나, 실행 시 OS locale에 따라 전부 자동 분기.**

---

## 6. 에뮬레이터에서 다국어 테스트하는 법

**추가 설정 필요 없음.** 에뮬레이터의 시스템 언어만 바꾸면 됨.

### Android 에뮬레이터

#### 방법 1: 시스템 설정에서 변경 (가장 기본)

```
1. 에뮬레이터에서 앱 종료 (홈으로 나가기)
2. Settings (설정) 앱 열기
3. System > Languages & input > Languages
4. + Add a language > 日本語 (또는 English) 선택
5. 추가된 언어를 드래그해서 맨 위로 올리기
   (맨 위에 있는 언어가 시스템 기본 언어)
6. 사담 앱 다시 실행 → 일본어로 표시됨
```

> 원래 한국어로 되돌리려면: 언어 목록에서 "한국어"를 맨 위로 다시 올리면 됨

#### 방법 2: ADB 명령어로 빠르게 전환 (개발자용)

터미널에서 한 줄이면 됨. **앱 재시작 필요.**

```bash
# 일본어로 변경
adb shell settings put system system_locales ja-JP

# 영어로 변경
adb shell settings put system system_locales en-US

# 한국어로 되돌리기
adb shell settings put system system_locales ko-KR

# 변경 후 앱 재시작 (강제 종료 후 실행)
adb shell am force-stop com.example.frontend
adb shell monkey -p com.example.frontend -c android.intent.category.LAUNCHER 1
```

> 패키지명(`com.example.frontend`)은 실제 앱 패키지명으로 교체

#### 방법 3: 코드에서 강제 locale 지정 (개발 중 가장 편함)

에뮬레이터 설정 안 건드리고, **코드 한 줄**로 테스트:

```dart
// main.dart에서 startLocale 지정 (개발 중에만 사용!)
runApp(
  EasyLocalization(
    supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
    path: 'lib/i18n',
    fallbackLocale: const Locale('ko'),
    startLocale: const Locale('ja'),  // ← 이거 추가하면 무조건 일본어로 시작
    assetLoader: MultiFileAssetLoader(),
    child: const ProviderScope(child: MantokApp()),
  ),
);
```

> **주의: 배포 전에 반드시 `startLocale` 줄 제거!** 안 그러면 모든 유저가 일본어로 봄.

#### 방법 4: 앱 내 언어 전환 버튼 (개발 + QA용)

설정 화면이나 디버그 메뉴에 임시로 추가:

```dart
// 디버그용 언어 전환 (kDebugMode에서만 표시)
if (kDebugMode) ...[
  TextButton(
    onPressed: () => context.setLocale(const Locale('ko')),
    child: const Text('🇰🇷 한국어'),
  ),
  TextButton(
    onPressed: () => context.setLocale(const Locale('en')),
    child: const Text('🇺🇸 English'),
  ),
  TextButton(
    onPressed: () => context.setLocale(const Locale('ja')),
    child: const Text('🇯🇵 日本語'),
  ),
],
```

이 방법이 가장 편함: **핫 리로드 없이 즉시 전환**, 에뮬레이터 설정 안 건드림.

---

### iOS 시뮬레이터

```
1. 시뮬레이터에서 Settings (설정) 앱 열기
2. General > Language & Region > iPhone Language
3. 日本語 선택 > Continue
4. 시뮬레이터 재시작됨 (자동)
5. 사담 앱 실행 → 일본어로 표시됨
```

또는 Xcode에서:
```
Product > Scheme > Edit Scheme > Run > Options
  > App Language: Japanese
  > App Region: Japan
```
이 설정은 앱에만 적용되고 시뮬레이터 시스템은 안 바뀜.

---

### 테스트 시 확인할 것

| 확인 항목 | 테스트 방법 |
|----------|-----------|
| UI 텍스트 전환 | 각 화면 돌아다니며 확인 |
| 앱 이름 전환 | 홈 화면에서 아이콘 밑 이름 확인 |
| 날짜 포맷 | 생년월일 입력, 운세 날짜 표시 |
| AI 응답 언어 | 채팅에서 질문 → 답변 언어 확인 |
| 레이아웃 깨짐 | 영어/일본어가 한국어보다 길 수 있음 → overflow 확인 |
| fallback 동작 | 지원 안 하는 언어(중국어 등)로 설정 → ko로 뜨는지 |
| 앱 재시작 | 언어 바꾸고 앱 껐다 켜도 유지되는지 |

### 추천 테스트 순서

```
1. 방법 4 (앱 내 버튼)로 빠르게 UI 텍스트 전환 테스트
2. 방법 3 (startLocale)로 특정 언어 집중 디버깅
3. 방법 1 (시스템 설정)로 앱 이름 + 전체 흐름 최종 확인
```

---

## 7. 담당자 제안

| 작업 | 담당 | 난이도 |
|------|------|:------:|
| Android/iOS 앱 이름 다국어 | DK | 쉬움 |
| 하드코딩 텍스트 → .tr() 교체 | SH + 전체 | 중간 (양 많음) |
| AI 프롬프트 다국어 | JH_AI + Jina | 어려움 |
| 날짜/숫자 포맷 | SH | 쉬움 |
| 스토어 등록정보 번역 | DK + 외주 | 중간 |
| 일본어/영어 번역 검수 | 외주/네이티브 | 중간 |
