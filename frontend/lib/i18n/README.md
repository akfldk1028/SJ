# i18n 적용 가이드

> 이 문서를 읽고 각 dart 파일의 하드코딩된 한국어를 `.tr()` 호출로 교체하세요.

---

## 시스템 구조

```
lib/i18n/
├── ko/          # 한국어 (기본)
├── en/          # 영어
├── ja/          # 일본어
├── multi_file_asset_loader.dart  # 커스텀 AssetLoader
└── README.md    # ← 이 파일
```

### 사용법

```dart
import 'package:easy_localization/easy_localization.dart';

// 기본
'common.appName'.tr()                    // → "사담"
'purchase.title'.tr()                    // → "프리미엄"

// named 파라미터
'common.unlocked'.tr(namedArgs: {'name': '직업운'})   // → "직업운 운세가 해제되었습니다!"
'common.scoreUnit'.tr(namedArgs: {'score': '85'})     // → "85점"
'daily_fortune.monthUnit'.tr(namedArgs: {'month': '3'}) // → "3월"

// const 제거 필수: .tr()은 런타임 호출이므로 Text 위젯에 const 사용 불가
// BEFORE: const Text('프리미엄')
// AFTER:  Text('purchase.title'.tr())
```

### 키 네이밍: `{파일명}.{키}`

| JSON 파일 | prefix | 용도 |
|-----------|--------|------|
| common.json | `common.` | 공통 (버튼, 에러, 광고, 카테고리명) |
| purchase.json | `purchase.` | 결제/구독 관련 |
| daily_fortune.json | `daily_fortune.` | 오늘의 운세, 등급, 홈화면 |
| monthly_fortune.json | `monthly_fortune.` | 월별/주간 운세 섹션 |
| saju_chart.json | `saju_chart.` | 사주차트, 평생운세, 카테고리 상세 |
| menu.json | `menu.` | 메뉴/탭 |
| settings.json | `settings.` | 설정 화면 |

---

## 파일별 적용 매핑

### 1. ad 위젯 (3파일) — 단순

**대상 파일:**
- `lib/ad/widgets/card_native_ad_widget.dart`
- `lib/ad/widgets/inline_ad_widget.dart`
- `lib/ad/widgets/native_ad_widget.dart`

**공통 작업:**
1. import 추가: `import 'package:easy_localization/easy_localization.dart';`
2. 모든 `'광고'` → `'common.ad'.tr()`
3. `const Text('광고' ...)` → `Text('common.ad'.tr() ...)` (const 제거)

| 파일 | 라인 | BEFORE | AFTER |
|------|------|--------|-------|
| card_native_ad_widget.dart | 215 | `'광고'` | `'common.ad'.tr()` |
| inline_ad_widget.dart | 126 | `'광고'` | `'common.ad'.tr()` |
| native_ad_widget.dart | 248 | `'광고'` | `'common.ad'.tr()` |
| native_ad_widget.dart | 431 | `const Text('광고' ...)` | `Text('common.ad'.tr() ...)` |

---

### 2. paywall_screen.dart

**파일:** `lib/purchase/widgets/paywall_screen.dart`

**작업:**
1. import 추가: `import 'package:easy_localization/easy_localization.dart';`
2. `_productMeta`의 하드코딩 문자열은 **static const이므로 직접 .tr() 불가** → `build()` 메서드 안에서 동적으로 구성하거나, 별도 helper 메서드로 분리 필요

| 라인 | BEFORE | AFTER | 비고 |
|------|--------|-------|------|
| 63 | `const Text('프리미엄')` | `Text('purchase.title'.tr())` | const 제거 |
| 74 | `'상품 정보를 불러올 수 없습니다.'` | `'purchase.errorLoadProducts'.tr()` | |
| 80 | `const Text('다시 시도')` | `Text('common.buttonRetry'.tr())` | const 제거 |
| 89 | `'상품이 준비 중입니다.'` | `'purchase.productsLoading'.tr()` | |
| 126 | `'프리미엄 이용권'` | `'purchase.premiumPass'.tr()` | |
| 136 | `'광고 제거 + AI 무제한 대화'` | `'purchase.premiumSubtitle'.tr()` | |
| 159 | `'구매 즉시 적용'` | `'purchase.instantApply'.tr()` | |
| 201-202 | 자동갱신 안내문 | `'purchase.termsAutoRenew'.tr()` | |
| 404 | `'구독하기'` / `'구매하기'` | `'purchase.subscribe'.tr()` / `'purchase.purchase'.tr()` | |

**_productMeta 내 문자열 처리 방법:**

`_productMeta`가 `static const`이므로 `.tr()` 호출 불가. 두 가지 방법 중 선택:

**방법 A (추천): i18n 키를 _productMeta에 저장하고, 빌드 시점에 .tr()**
```dart
// features에 i18n 키를 저장
features: ['purchase.featureNoAds', 'purchase.featureAiUnlimitedChat', 'purchase.feature24Hour'],

// _ProductCard.build() 에서:
...meta.features.map((fKey) => Text(fKey.tr()))
```

**방법 B: _productMeta를 getter로 변경**
```dart
static Map<String, _ProductMeta> get _productMeta => { ... }; // const 제거
```

| _productMeta 내 값 | i18n 키 |
|---|---|
| `'인기'` | `purchase.badgePopular` |
| `'BEST'` | `purchase.badgeBest` |
| `'/1일'` | `purchase.perDay` |
| `'/1주'` | `purchase.perWeek` |
| `'/월'` | `purchase.perMonth` |
| `'일 ₩700'` | `purchase.dailyPrice` (named: price) |
| `'일 ₩297'` | `purchase.dailyPrice` (named: price) |
| `'광고 제거'` | `purchase.featureNoAds` |
| `'AI 무제한 대화'` | `purchase.featureAiUnlimitedChat` |
| `'24시간 이용'` | `purchase.feature24Hour` |
| `'7일 이용'` | `purchase.feature7Day` |
| `'자동 갱신'` | `purchase.featureAutoRenew` |
| `'일일 패스 대비 할인'` | `purchase.featureDayPassDiscount` |
| `'가장 저렴한 일일 단가'` | `purchase.featureCheapestDaily` |

---

### 3. fortune_category_chip_section.dart

**파일:** `lib/shared/widgets/fortune_category_chip_section.dart`

**작업:**
1. import 추가: `import 'package:easy_localization/easy_localization.dart';`
2. `_getCategoryName()` 메서드 → i18n 키 사용

**_getCategoryName 변경:**
```dart
String _getCategoryName(String key) {
  return 'common.category_$key'.tr();
}
```

| 라인 | BEFORE | AFTER |
|------|--------|-------|
| 237 | `'분야별 운세'` | `'saju_chart.categoryFortune'.tr()` |
| 248 | `'탭하여 상세 운세를 확인하세요'` | `'saju_chart.tapToCheckCategory'.tr()` |
| 349 | `'$score점'` | `'common.scoreUnit'.tr(namedArgs: {'score': '$score'})` |
| 461 | `'좋은 달: ${...}'` | `'saju_chart.goodMonths'.tr(namedArgs: {'months': monthsStr})` |
| 471 | `'주의할 달: ${...}'` | `'saju_chart.cautionMonths'.tr(namedArgs: {'months': monthsStr})` |
| 482 | `'실천 팁'` | `'saju_chart.sectionActionTip'.tr()` |
| 489 | `'집중 영역:'` | `'saju_chart.sectionFocusAreas'.tr()` |
| 528 | `'조언'` | `'saju_chart.sectionAdvice'.tr()` |
| 554 | `'타이밍'` | `'saju_chart.sectionTiming'.tr()` |
| 561 | `'강점:'` | `'saju_chart.sectionStrengths'.tr()` |
| 576 | `'주의할 점:'` | `'saju_chart.sectionWeaknesses'.tr()` |
| 591 | `'적합한 분야:'` | `'saju_chart.sectionSuitableFields'.tr()` |
| 606 | `'피해야 할 분야:'` | `'saju_chart.sectionUnsuitableFields'.tr()` |
| 641 | `'주의사항'` | `'saju_chart.sectionCautions'.tr()` |
| 689 | `'업무 스타일'` | `'saju_chart.workStyle'.tr()` |
| 693 | `'리더십 잠재력'` | `'saju_chart.leadershipPotential'.tr()` |
| 699 | `'연애 패턴'` | `'saju_chart.datingPattern'.tr()` |
| 703 | `'끌리는 유형'` | `'saju_chart.attractionStyle'.tr()` |
| 709 | `'이상형 특성:'` | `'saju_chart.idealPartnerTraits'.tr()` |
| 722 | `'전반적 경향'` | `'saju_chart.overallTendency'.tr()` |
| 726 | `'돈 버는 방식'` | `'saju_chart.earningStyle'.tr()` |
| 730 | `'소비 성향'` | `'saju_chart.spendingTendency'.tr()` |
| 734 | `'투자 적성'` | `'saju_chart.investmentAptitude'.tr()` |
| 740 | `'창업 적성'` | `'saju_chart.entrepreneurshipAptitude'.tr()` |
| 744 | `'사업 파트너 특성'` | `'saju_chart.businessPartnerTraits'.tr()` |
| 750 | `'배우자궁 분석'` | `'saju_chart.spousePalaceAnalysis'.tr()` |
| 754 | `'배우자 특성'` | `'saju_chart.spouseCharacteristics'.tr()` |
| 758 | `'결혼 생활 경향'` | `'saju_chart.marriedLifeTendency'.tr()` |
| 764 | `'정신 건강'` | `'saju_chart.mentalHealth'.tr()` |
| 770 | `'생활 습관 조언:'` | `'saju_chart.lifestyleAdvice'.tr()` |
| 873 | `'$categoryName 운세가 해제되었습니다!'` | `'common.unlocked'.tr(namedArgs: {'name': categoryName})` |
| 897 | `'... (웹 테스트)'` | `'common.unlockedWebTest'.tr(namedArgs: {'name': categoryName})` |
| 997 | `'광고 준비 중'` | `'common.adNotReady'.tr()` |
| 999 | `'$categoryName 운세를 보려면...'` | `'common.adRequired'.tr(namedArgs: {'name': categoryName})` |
| 1003 | `'확인'` | `'common.buttonConfirm'.tr()` |

---

### 4. fortune_monthly_chip_section.dart

**파일:** `lib/shared/widgets/fortune_monthly_chip_section.dart`

동일 패턴. `_getCategoryName()` → `'common.category_$key'.tr()`

| 라인 | BEFORE | AFTER |
|------|--------|-------|
| 263 | `'월별 운세'` | `'monthly_fortune.sectionTitle'.tr()` |
| 274 | `'탭하여 각 달의 운세를 확인하세요'` | `'monthly_fortune.tapToCheck'.tr()` |
| 295 | `'$monthNum월'` | `'daily_fortune.monthUnit'.tr(namedArgs: {'month': monthNum})` |
| 405 | `'$monthNum월 운세'` | `'monthly_fortune.monthFortune'.tr(namedArgs: {'month': monthNum})` |
| 421 | `'${month.score}점'` | `'common.scoreUnit'.tr(namedArgs: {'score': '${month.score}'})` |
| 447 | `'키워드: ${month.keyword}'` | `'monthly_fortune.keyword'.tr(namedArgs: {'value': month.keyword})` |
| 482 | `'분야별 요약'` | `'monthly_fortune.highlightTitle'.tr()` |
| 500 | `'분야별 상세 운세'` | `'monthly_fortune.detailedTitle'.tr()` |
| 569 | `'$monthNum월 운세'` | `'monthly_fortune.monthFortune'.tr(namedArgs: {'month': monthNum})` |
| 591 | `'$monthNum월 운세를 분석하고 있습니다...'` | `'common.analyzingInProgress'.tr(namedArgs: {'name': '$monthNum월'})` |
| 637 | `'${category.score}점'` | `'common.scoreUnit'.tr(namedArgs: {'score': '${category.score}'})` |
| 748 | `'${highlight.score}점'` | `'common.scoreUnit'.tr(namedArgs: {'score': '${highlight.score}'})` |
| 802 | `'이달의 사자성어'` | `'monthly_fortune.monthlyIdiom'.tr()` |
| 850 | `'행운'` | `'daily_fortune.lucky'.tr()` |
| 933 | `'$monthName 운세가 해제되었습니다!'` | `'common.unlocked'.tr(namedArgs: {'name': monthName})` |
| 955 | `'... (웹 테스트)'` | `'common.unlockedWebTest'.tr(namedArgs: {'name': monthName})` |
| 981, 1021 | `'$monthName 운세를 분석합니다...'` | `'common.analyzing'.tr(namedArgs: {'name': monthName})` |
| 1044 | `'광고 준비 중'` | `'common.adNotReady'.tr()` |
| 1046 | `'$monthName 운세를 보려면...'` | `'common.adRequired'.tr(namedArgs: {'name': monthName})` |
| 1050 | `'확인'` | `'common.buttonConfirm'.tr()` |

---

### 5. fortune_weekly_chip_section.dart

**파일:** `lib/shared/widgets/fortune_weekly_chip_section.dart`

| 라인 | BEFORE | AFTER |
|------|--------|-------|
| 102 | `'주간별 운세'` | `'saju_chart.weeklyFortune'.tr()` |
| 113 | `'탭하여 주간 운세를 확인하세요'` | `'saju_chart.tapToCheckWeekly'.tr()` |
| 134 | `'$weekNum주차'` | `'daily_fortune.weekUnit'.tr(namedArgs: {'week': weekNum})` |
| 237 | `'$weekNum주차'` | `'daily_fortune.weekUnit'.tr(namedArgs: {'week': weekNum})` |
| 261 | `'테마: ${week.theme}'` | `'monthly_fortune.theme'.tr(namedArgs: {'value': week.theme})` |
| 275 | `'집중 포인트: ${week.focus}'` | `'saju_chart.focusPoint'.tr(namedArgs: {'value': week.focus})` |
| 287 | `'팁: ${week.tip}'` | `'saju_chart.tip'.tr(namedArgs: {'value': week.tip})` |
| 336, 383, 416 | `'$weekName 운세가 해제되었습니다!'` | `'common.unlocked'.tr(namedArgs: {'name': weekName})` |
| 358 | `'... (웹 테스트)'` | `'common.unlockedWebTest'.tr(namedArgs: {'name': weekName})` |
| 435 | `'광고 준비 중'` | `'common.adNotReady'.tr()` |
| 437 | `'$weekName 운세를 보려면...'` | `'common.adRequired'.tr(namedArgs: {'name': weekName})` |
| 441 | `'확인'` | `'common.buttonConfirm'.tr()` |

---

### 6. fortune_monthly_step_section.dart

**파일:** `lib/shared/widgets/fortune_monthly_step_section.dart`

| 라인 | BEFORE | AFTER |
|------|--------|-------|
| 181 | `'월별 상세 운세'` | `'monthly_fortune.detailedMonthly'.tr()` |
| 191 | `'월을 선택하면 광고 시청 후...'` | `'monthly_fortune.tapMonthToCheck'.tr()` |
| 239 | `'$_selectedMonth월 운세를 확인하려면\n광고를 시청해주세요'` | `'monthly_fortune.lockedMonthMsg'.tr(namedArgs: {'month': '$_selectedMonth'})` |
| 251 | `'광고 보고 해금하기'` / `'광고 로딩 중...'` | `'common.adWatchToUnlock'.tr()` / `'common.adLoading'.tr()` |
| 283 | `'위에서 월을 선택하면\n해당 월의 상세 운세를...'` | `'monthly_fortune.selectMonthMsg'.tr()` |
| 346 | `'$month월'` | `'daily_fortune.monthUnit'.tr(namedArgs: {'month': '$month'})` |
| 400, 440, 468 | `'$month월 운세가 해제되었습니다!'` | `'common.unlocked'.tr(namedArgs: {'name': '$month월'})` |
| 419 | `'... (웹 테스트)'` | `'common.unlockedWebTest'.tr(namedArgs: {'name': '$month월'})` |
| 498 | `'$month월 운세 요약'` | `'monthly_fortune.quarterSummary'.tr(namedArgs: {'month': '$month'})` |
| 514 | `'${quarter.score}점'` | `'common.scoreUnit'.tr(namedArgs: {'score': '${quarter.score}'})` |
| 527 | `'테마: ${quarter.theme}'` | `'monthly_fortune.theme'.tr(namedArgs: {'value': quarter.theme})` |
| 556 | `'분야별 상세 운세'` | `'monthly_fortune.detailedTitle'.tr()` |
| 677 | `'위의 분야를 선택하면...'` | `'monthly_fortune.selectCategoryMsg'.tr()` |
| 728 | `'${_selectedMonth ?? ""}월 $categoryName'` | `'monthly_fortune.monthCategoryTitle'.tr(namedArgs: {'month': '${_selectedMonth ?? ""}', 'category': categoryName})` |
| 875 | `'광고 보고 $nextCategoryName 확인하기'` | `'monthly_fortune.nextCategoryButton'.tr(namedArgs: {'category': nextCategoryName})` |
| 915, 954, 982 | 해제 메시지 | `'common.unlocked'.tr(...)` |
| 934 | 웹 테스트 | `'common.unlockedWebTest'.tr(...)` |
| 1001 | `'광고 준비 중'` | `'common.adNotReady'.tr()` |
| 1003 | `'$categoryName 운세를 보려면...'` | `'common.adRequired'.tr(namedArgs: {'name': categoryName})` |
| 1007 | `'확인'` | `'common.buttonConfirm'.tr()` |

---

### 7. home_screen.dart

**파일:** `lib/features/home/presentation/screens/home_screen.dart`

| 라인 | BEFORE | AFTER |
|------|--------|-------|
| 55 | `'오늘의 운세'` | `'daily_fortune.title'.tr()` |
| 87 | `'프로필'` | `'menu.profile'.tr()` |
| 97 | `'로딩...'` | `'common.loading'.tr()` |
| 116 | `'오늘의 운세'` | `'daily_fortune.title'.tr()` |
| 124 | `'전체보기'` | `'daily_fortune.viewAll'.tr()` |
| 162 | `'오늘의 조언'` | `'daily_fortune.todayAdvice'.tr()` |
| 321 | `'대길(大吉)'` | `'daily_fortune.gradeGreat'.tr()` |
| 323 | `'길(吉)'` | `'daily_fortune.gradeGood'.tr()` |
| 325 | `'소길(小吉)'` | `'daily_fortune.gradeSmallGood'.tr()` |
| 328 | `'보통(普通)'` | `'daily_fortune.gradeNormal'.tr()` |
| 331 | `'주의(注意)'` | `'daily_fortune.gradeCaution'.tr()` |
| 350, 504 | `'오늘의 총운'` | `'daily_fortune.todayOverall'.tr()` |
| 393, 529 | `'운세 분석 중...'` | `'daily_fortune.fortuneAnalyzing'.tr()` |
| 421 | `'종합 운세 점수'` | `'daily_fortune.overallScore'.tr()` |
| 561 | `'운세를 불러올 수 없습니다'` | `'daily_fortune.errorLoadFortune'.tr()` |
| 584 | `'재물운'` | `'common.category_wealth'.tr()` |
| 585 | `'애정운'` | `'common.category_love'.tr()` |
| 586 | `'직장운'` | `'common.category_work'.tr()` |
| 587 | `'건강운'` | `'common.category_health'.tr()` |
| 652 | `'$score점'` | `'common.scoreUnit'.tr(namedArgs: {'score': '$score'})` |
| 836 | `'사자성어를 불러올 수 없습니다.'` | `'daily_fortune.errorLoadIdiom'.tr()` |
| 922 | `'조언을 불러올 수 없습니다.'` | `'daily_fortune.errorLoadAdvice'.tr()` |
| 967 | `'프로필을 등록해주세요'` | `'daily_fortune.noProfile'.tr()` |
| 976 | `'생년월일을 입력하면 사주팔자를...'` | `'daily_fortune.noProfileDesc'.tr()` |

**categoryMap 변경:**
```dart
// BEFORE (const)
const categoryMap = [
  {'key': 'wealth', 'icon': '💰', 'name': '재물운'},
  ...
];

// AFTER (const 제거, .tr() 사용)
final categoryMap = [
  {'key': 'wealth', 'icon': '💰', 'name': 'common.category_wealth'.tr()},
  {'key': 'love', 'icon': '💕', 'name': 'common.category_love'.tr()},
  {'key': 'work', 'icon': '💼', 'name': 'common.category_work'.tr()},
  {'key': 'health', 'icon': '🏥', 'name': 'common.category_health'.tr()},
];
```

---

### 8. lifetime_fortune_screen.dart

**파일:** `lib/features/traditional_saju/presentation/screens/lifetime_fortune_screen.dart`

이 파일은 가장 크고 복잡. 주요 패턴:

| 패턴 | BEFORE | AFTER |
|------|--------|-------|
| 사주 기둥 | `'시주'`, `'일주'`, `'월주'`, `'연주'` | `'saju_chart.hourPillar'.tr()` 등 |
| 오행 | `'목'`, `'화'`, `'토'`, `'금'`, `'수'` | `'saju_chart.elementWood'.tr()` 등 |
| 평생운세 제목 | `'평생운세'` | `'saju_chart.lifetimeFortune'.tr()` |
| 잠김 | `'잠김'` | `'common.locked'.tr()` |
| 최적기/주의기 | `'최적기'` / `'주의기'` | `'saju_chart.bestPeriod'.tr()` / `'saju_chart.cautionPeriod'.tr()` |
| 격국/일간 | `'격국'` / `'일간'` | `'saju_chart.lifeStage'.tr()` / `'saju_chart.dayStem'.tr()` |
| 띠/계절 | `'띠'` / `'계절'` | `'saju_chart.zodiacSign'.tr()` / `'saju_chart.season'.tr()` |
| 등급 | `'상'`~`'하'` | `'saju_chart.rankTop'.tr()` ~ `'saju_chart.rankBottom'.tr()` |
| 기회/도전 | `'기회'` / `'도전'` | `'saju_chart.opportunity'.tr()` / `'saju_chart.challenge'.tr()` |
| 확인 | `'확인'` | `'common.buttonConfirm'.tr()` |

---

## 주의사항

1. **const 제거**: `.tr()`은 런타임 호출. `const Text(...)` → `Text(...)`, `const Text('...')` 사용 불가
2. **static const Map/List 내부**: static const에서는 .tr() 불가. 두 가지 방법:
   - i18n 키 문자열을 저장하고 build() 시점에 `.tr()` 호출
   - static const를 getter로 변경
3. **named 파라미터**: `{name}`, `{score}` 등은 `namedArgs` Map으로 전달
4. **import**: 모든 파일에 `import 'package:easy_localization/easy_localization.dart';` 필요
5. **debugPrint 제외**: 디버그 로그의 한국어는 변환 불필요

---

## 검증 체크리스트

적용 후 확인사항:
- [ ] `flutter pub get` 성공
- [ ] 컴파일 에러 없음
- [ ] ko 로케일에서 기존과 동일한 텍스트 표시
- [ ] en 로케일에서 영어 텍스트 표시
- [ ] ja 로케일에서 일본어 텍스트 표시
- [ ] `{name}`, `{score}` 등 동적 파라미터 정상 치환
