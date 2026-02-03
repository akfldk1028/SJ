# menu/presentation/widgets/

메뉴(운세) 화면의 위젯들.

## 파일 목록

| 파일 | 역할 |
|------|------|
| `fortune_category_list.dart` | 운세 카테고리 그리드 (평생운세, 2025, 2026, 한달) |
| `fortune_summary_card.dart` | 오늘의 운세 점수 + 카테고리별 수치 |

## fortune_category_list.dart

- `ConsumerWidget` (v30에서 StatelessWidget에서 전환)
- 4개 카테고리 버튼: 평생운세, 2025운세, 2026운세, 한달운세
- 버튼 탭 흐름:
  1. `_triggerSajuBaseIfNeeded(ref)` — saju_base lazy trigger (fire-and-forget)
  2. `AdService.instance.showInterstitialAd()` — 전면광고 (await)
  3. `context.push(route)` — 페이지 이동

### v30 lazy trigger 동작

```
버튼 탭 → saju_base 트리거 시작 → 광고 표시 (5~30초) → 페이지 이동
              ↓                        ↓
         GPT-5.2 시작 ──── 광고 중 분석 진행 ──→ 페이지 도착 시 분석 완료/진행중
```

- `activeProfileProvider`에서 현재 프로필 ID 조회
- `SajuAnalysisService.analyzeOnProfileSave(runInBackground: true)` 호출
- 이미 캐시 있거나 분석 중이면 즉시 스킵
