# 운세 화면 진입 시 전면 광고 제거

## 문제
평생운세 / 2025운세 / 2026운세 / 한달운세 화면에 진입할 때 interstitial(전면) 광고가 뜸.
사용자 경험 저하 → 제거 필요.

## 영향 범위

| 경로 | Feature | 화면 |
|------|---------|------|
| `/fortune/traditional-saju` | traditional_saju | 평생운세 |
| `/fortune/yearly-2025` | yearly_2025_fortune | 2025운세 |
| `/fortune/new-year` | new_year_fortune | 2026운세 |
| `/fortune/monthly` | monthly_fortune | 한달운세 |

## 원인 분석

전면 광고는 **4개 feature 내부가 아니라 호출하는 쪽**에서 발생.

### 트리거 위치

**파일:** `frontend/lib/features/menu/presentation/widgets/fortune_category_list.dart`
**라인:** 78-82

```dart
// 수정 전
onTap: () async {
  _triggerSajuBaseIfNeeded(ref);
  // 프리미엄 유저는 광고 스킵
  final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;
  if (!isPremium) {
    await AdService.instance.showInterstitialAd();  // ← 이 줄이 전면 광고
  }
  if (context.mounted) {
    context.push(route);
  }
},
```

### 동작 흐름
```
메뉴 화면 → 카테고리 탭 → showInterstitialAd() → 광고 닫힘 → context.push(route)
```

## 수정 내용

### 변경 파일: 1개
`frontend/lib/features/menu/presentation/widgets/fortune_category_list.dart`

### 변경 사항
- 라인 78-82: `isPremium` 체크 + `showInterstitialAd()` 호출 **삭제**
- `AdService` import **삭제** (다른 곳에서 안 쓰이므로)
- `purchaseNotifierProvider` import **삭제** (다른 곳에서 안 쓰이므로)

```dart
// 수정 후
onTap: () async {
  _triggerSajuBaseIfNeeded(ref);
  if (context.mounted) {
    context.push(route);
  }
},
```

### 삭제되는 코드
- `import '../../../../ad/ad_service.dart';`
- `import '../../../../purchase/providers/purchase_provider.dart';`
- 전면 광고 호출 블록 (4줄)

## 참고: 화면 내부 광고 (별도)

아래는 **화면 진입 시 광고가 아님** (카테고리 잠금 해제용 rewarded 광고). 이번 수정 대상 아님.

| 파일 | 광고 유형 | 용도 |
|------|----------|------|
| `shared/widgets/fortune_category_chip_section.dart` | Rewarded | 카테고리별 잠금 해제 |
| `shared/widgets/fortune_monthly_chip_section.dart` | Rewarded | 월별 카테고리 잠금 해제 |
| `shared/widgets/fortune_monthly_step_section.dart` | Rewarded | 월별 스텝 잠금 해제 |
| `traditional_saju/.../lifetime_fortune_screen.dart` | Rewarded | 섹션별 잠금 해제 |
