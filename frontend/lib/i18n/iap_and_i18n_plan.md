# In-App Purchase + 국제화 구현 계획

> 작성일: 2024-12-29
> 목적: 광고 제거 기능 + 일본/미국 출시 준비

---

## 1. In-App Purchase (광고 제거)

### 1.1 추천 라이브러리

| 라이브러리 | 장점 | 단점 |
|-----------|------|------|
| **`in_app_purchase`** (추천) | 공식 플러그인, 수수료 없음 | 직접 검증 로직 구현 필요 |
| `purchases_flutter` (RevenueCat) | 서버사이드 관리 쉬움 | 월 구독료 + 매출 수수료 |

**결정: `in_app_purchase` 공식 플러그인 사용**

### 1.2 상품 정보

| 항목 | 값 |
|------|-----|
| 상품 ID | `com.mantok.ad_removal` |
| 상품 유형 | Non-Consumable (비소모성) |
| 가격 (한국) | ₩4,900 ~ ₩9,900 |
| 가격 (일본) | ¥500 ~ ¥1,000 |
| 가격 (미국) | $3.99 ~ $6.99 |

### 1.3 구현 단계

```
[ ] 1. pubspec.yaml에 의존성 추가
      in_app_purchase: ^3.2.0

[ ] 2. Google Play Console 설정
      - 인앱 상품 > 관리되는 상품 > "광고 제거" 추가
      - 상품 ID: com.mantok.ad_removal

[ ] 3. App Store Connect 설정
      - 인앱 구입 > 비소모성 상품 추가
      - 동일 상품 ID 사용

[ ] 4. 코드 구현
      lib/ad/ad_removal/
      ├── ad_removal_service.dart    # 구매 로직
      ├── ad_removal_repository.dart # 상태 저장
      └── providers/
          └── ad_removal_provider.dart

[ ] 5. UI 추가
      - 설정 화면에 "광고 제거 구매" 버튼
      - 구매 완료 시 감사 메시지

[ ] 6. 광고 조건부 표시
      - AdProvider에 isAdFree 상태 추가
      - if (!isAdFree) 일 때만 광고 렌더링
```

### 1.4 데이터 저장

```dart
// Hive 로컬 저장 (앱 재설치 대비 복원 가능하게)
class AdRemovalBox {
  static const String boxName = 'ad_removal';
  static const String isPurchasedKey = 'is_purchased';
  static const String purchaseDateKey = 'purchase_date';
}

// Supabase 서버 저장 (계정 연동 시)
// users 테이블에 is_ad_free 컬럼 추가
```

---

## 2. 국제화 (i18n)

### 2.1 지원 언어

| 언어 | 코드 | 출시 버전 |
|------|------|----------|
| 한국어 | ko | v1.0 (현재) |
| 일본어 | ja | v1.1 |
| 영어 (미국) | en_US | v1.2 |

### 2.2 구현 방식

**공식 방식: `flutter_localizations` + `intl`**

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true
```

```yaml
# l10n.yaml (프로젝트 루트)
arb-dir: lib/l10n
template-arb-file: app_ko.arb
output-localization-file: app_localizations.dart
```

### 2.3 폴더 구조

```
lib/l10n/
├── app_ko.arb     # 한국어 (기본)
├── app_ja.arb     # 일본어
└── app_en.arb     # 영어
```

### 2.4 ARB 파일 예시

```json
// app_ko.arb
{
  "@@locale": "ko",
  "appTitle": "만톡",
  "sajuChat": "사주 채팅",
  "profile": "프로필",
  "settings": "설정",
  "removeAds": "광고 제거",
  "fourPillars": "사주팔자",
  "fiveElements": "오행"
}
```

```json
// app_ja.arb
{
  "@@locale": "ja",
  "appTitle": "万トク",
  "sajuChat": "四柱チャット",
  "profile": "プロフィール",
  "settings": "設定",
  "removeAds": "広告削除",
  "fourPillars": "四柱八字",
  "fiveElements": "五行"
}
```

```json
// app_en.arb
{
  "@@locale": "en",
  "appTitle": "Mantok",
  "sajuChat": "Fortune Chat",
  "profile": "Profile",
  "settings": "Settings",
  "removeAds": "Remove Ads",
  "fourPillars": "Four Pillars",
  "fiveElements": "Five Elements"
}
```

### 2.5 사주 용어 번역표

| 한국어 | 일본어 | 영어 |
|--------|--------|------|
| 사주 | 四柱 | Four Pillars |
| 팔자 | 八字 | Eight Characters |
| 오행 | 五行 | Five Elements |
| 천간 | 天干 | Heavenly Stems |
| 지지 | 地支 | Earthly Branches |
| 합 | 合 | Harmony |
| 충 | 沖 | Clash |
| 형 | 刑 | Punishment |
| 파 | 破 | Break |
| 해 | 害 | Harm |
| 용신 | 用神 | Yongshin (Useful God) |
| 희신 | 喜神 | Heeshin (Joy God) |
| 기신 | 忌神 | Gishin (Avoid God) |
| 구신 | 仇神 | Gushin (Enemy God) |
| 신강 | 身強 | Strong Day Master |
| 신약 | 身弱 | Weak Day Master |

---

## 3. 담당자 및 일정

### 3.1 In-App Purchase (DK 담당)

| 단계 | 작업 | 상태 |
|------|------|------|
| 1 | pubspec.yaml 의존성 추가 | [ ] |
| 2 | Google Play Console 상품 등록 | [ ] |
| 3 | App Store Connect 상품 등록 | [ ] |
| 4 | AdRemovalService 구현 | [ ] |
| 5 | AdProvider isAdFree 연동 | [ ] |
| 6 | 설정 화면 UI 추가 | [ ] |
| 7 | 테스트 (Sandbox) | [ ] |

### 3.2 국제화 (SH 담당 + 전체 협업)

| 단계 | 작업 | 담당 | 상태 |
|------|------|------|------|
| 1 | flutter_localizations 설정 | SH | [ ] |
| 2 | l10n.yaml 생성 | SH | [ ] |
| 3 | app_ko.arb 한국어 키 추출 | SH | [ ] |
| 4 | app_ja.arb 일본어 번역 | 외주/팀 | [ ] |
| 5 | app_en.arb 영어 번역 | 외주/팀 | [ ] |
| 6 | 사주 전문용어 검수 | JH_AI | [ ] |

---

## 4. 출시 로드맵

```
v1.0 (한국) ─────► v1.1 (+ 일본) ─────► v1.2 (+ 미국)
     │                    │                    │
     ├─ 한국어만           ├─ 일본어 추가        ├─ 영어 추가
     └─ 광고 + IAP        └─ 일본 스토어        └─ 미국 스토어
```

### 스토어별 준비 사항

| 스토어 | 필요 작업 |
|--------|----------|
| Google Play (한국) | 현재 진행 중 |
| App Store (한국) | 현재 진행 중 |
| Google Play (일본) | 일본어 번역, 일본 개발자 계정 |
| App Store (일본) | 일본어 번역 |
| Google Play (미국) | 영어 번역 |
| App Store (미국) | 영어 번역 |

---

## 5. 참고 자료

### In-App Purchase
- [공식 문서](https://pub.dev/packages/in_app_purchase)
- [Google Codelab](https://codelabs.developers.google.com/codelabs/flutter-in-app-purchases)
- [RevenueCat (대안)](https://www.revenuecat.com/docs/getting-started/installation/flutter)

### 국제화
- [Flutter 공식 i18n 가이드](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [intl 패키지](https://pub.dev/packages/intl)
- [Easy Localization (대안)](https://pub.dev/packages/easy_localization)

---

*이 문서는 팀 회의 후 업데이트될 수 있습니다.*
