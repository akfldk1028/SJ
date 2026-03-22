# HANDOFF — 다국어 i18n 레이아웃 수정 (진행 중)

> 작성: 2026-03-22 | DK-DD 브랜치 | v63→v64 다국어 수정

---

## Goal

사담(SaDam) 앱의 사주 상세 9탭 + 메뉴 화면에서 한글 하드코딩 제거 및 다국어 레이아웃 최적화.

---

## 완료된 작업 (이번 세션)

### 1. 서비스 레이어 i18n ✅
- `unsung_service.dart` — 19개 한글 → `.tr()` (12 상세해석 + 3 요약 + 4 궁성)
- `twelve_sinsal_service.dart` — 12개 한글 → `.tr()` (12 신살 상세해석)
- `gongmang_service.dart` — 13개 한글 → `.tr()` (요약, 상태, 운세, 강도)
- `gongmang_table.dart` — 8개 reason 한글 → `.tr()` + namedArgs (const 제거!)

### 2. SajuI18n 확장 (cheongan_jiji_i18n.dart) ✅
- `_pillarNameI18n` — 년주/월주/일주/시주/년지/월지/일지/시지 × 17언어
- `_directionI18n` — 동/서/남/북 × 17언어
- `_seasonI18n` — 봄/여름/가을/겨울 × 17언어
- `pillarName()`, `direction()`, `season()`, `_localizeGanJi()` 메서드

### 3. 위젯 한글 → locale 변환 ✅
- `pillar_display.dart` — `pillar.gan`/`.ji` → `SajuI18n.cheongan()`/`.jiji()`
- `saju_detail_tabs.dart` — pillarName, jiji, dayGan 5곳+ SajuI18n 적용
- `hapchung_tab.dart` — 설명카드 7곳 `.tr()`, _buildCharacterBox→_localizeGanJi(), pillar→SajuI18n.pillarName(), 방향/계절→SajuI18n
- `fortune_display.dart` — 대운/세운/월운 한자 fallback 7곳 → SajuI18n
- `day_strength_display.dart` — dayGan → SajuI18n.cheongan()
- `saju_mini_card.dart`, `saju_detail_sheet.dart` — PillarDisplay에 Flexible 추가

### 4. 기타 페이지 한글 제거 ✅
- `quota_exceeded_dialog.dart` — 3곳 → `.tr()`
- `fortune_weekly_chip_section.dart` — 4곳 → `.tr()`
- `daily_fortune_card.dart` — `'파랑'` → `'-'`
- `home_screen.dart` — `'사자성어없음'` → `'—'`
- `compatibility_promo_card.dart` — `'상대방'` → `.tr()`
- `saju_chat_shell.dart` — 토큰 에러 감지에 영어 키워드 추가
- `saju_profile_repository.dart` — `'이름없음'` → `'—'`
- `compatibility_context.dart` — `'상대방'`/`'나'` → `'—'`

### 5. JSON 번역 파일 ✅
- `saju_detail.json` — +54키 (unsung 19, sinsal_detail 12, gongmang 23) × 17언어
- `saju_chart.json` — +7키 (hapchungDetailBody, hapTerm 6) × 17언어
- `menu.json` — +1키 (defaultPartner) × 17언어

### 6. 레이아웃 수정 ✅
- `possteller_style_table.dart` — 헤더/십성/뱃지 셀 FittedBox 복원
- `saju_detail_tabs.dart` — _buildSectionHeader Column→Expanded 3곳, 궁성카드 flex 레이아웃
- `day_strength_display.dart` — 바차트 라벨 IntrinsicHeight + maxLines:3
- 6개 display 위젯 — Row>Text→Expanded, SizedBox(40~50)→SizedBox(60)+FittedBox

---

## 남은 문제 (Next Steps)

### Priority 1: 합충 카드 description 한글 잔여
- **증상**: "묘해" 같은 한글이 합충 카드에 표시됨
- **원인**: `hapchung_service.dart`에서 `'$ji1$ji2해'` 같은 description을 생성 → `SajuI18n.hapchungDesc()` lookup에 매칭 안 되는 조합 존재
- **해결**: `_hapchungDescI18n` 맵에 누락된 조합 추가 필요 (cheongan_jiji_i18n.dart)
- **파일**: `cheongan_jiji_i18n.dart` `_hapchungDescI18n` 맵 확장

### Priority 2: 합충 카드 — locale명 + 한글(한자) 병기
- **DK 피드백**: "locale 하고 진(한자) 이렇게. 외국인은 한글을 좋아해"
- **현재**: `_buildCharacterBox`에서 locale명만 표시 ("Jin")
- **변경**: locale명 + 한글(한자) 형식으로 2줄 표시
  - ko: `진(辰)` (한글=locale이므로 1줄)
  - en: `Jin` + `진(辰)`
  - ja: `しん` + `진(辰)`
  - de: `Jin` + `진(辰)`
- **핵심**: 한글 원문은 항상 표시 (외국인이 한글을 좋아함) + 한자도 병기
- **구현**: `_buildCharacterBox`를 2줄 구조로 변경 — 윗줄 locale명 (크게), 아랫줄 한글(한자) (작게)
- **파일**: `hapchung_tab.dart` `_buildCharacterBox()`, 호출부 전체

### Priority 3: 테이블 FittedBox vs 가독성 밸런스
- **현상**: FittedBox.scaleDown으로 긴 텍스트 축소 → 일부 언어에서 너무 작아질 수 있음
- **대안**: 테이블을 가로 스크롤로 전환하거나, 비CJK 언어용 축약 번역 키 추가
- **유저 피드백**: "글씨 크기 막 줄이지 말고, 차라리 높이를 높여라, 3줄까지 OK"

### Priority 4: 외국인용 사주 개념 설명 — 하이브리드 방식 (DK 확정)
- **방식**: 하이브리드 (방법 3)
  - **공통 개념 설명** → JSON 정적 텍스트 (비용 0, 빠름)
    - 각 탭 설명 카드에 "오행이란?", "십성이란?" 등 초보자용 설명 추가
    - 17개 언어 번역 필요 → saju_chart.json 또는 saju_detail.json에 키 추가
  - **개인 결과 해석** → AI 채팅으로 유도
    - 각 분석 카드에 "이 결과가 궁금하면 AI에게 물어보세요" 버튼
    - 탭하면 해당 분석 결과를 context로 넘겨서 saju_chat으로 이동
- **메모리**: `project/global_saju_explanation_plan.md` 참조

---

## 빌드 에러 해결 기록

| 에러 | 원인 | 해결 |
|------|------|------|
| `library directive must appear before all other directives` | import를 library 앞에 배치 | library; 를 import 위로 이동 |
| `Method invocation is not a constant expression` | const 안에서 .tr() 호출 | const 제거 |
| `Too few positional arguments: 4 required, 3 given` | _buildGungseongRow 파라미터 변경 | 시그니처에서 palace 제거 |

---

## What Worked
1. **SajuI18n 패턴** — 한글 키를 내부 유지 + UI에서 SajuI18n.xxx(korean, locale) 변환. JSON 파일 불필요.
2. **병렬 에이전트** — 17개 언어 JSON/키 추가를 4개 에이전트로 병렬 처리 → 빠름
3. **_localizeGanJi()** 헬퍼 — 천간/지지 자동 구분 변환

## What Didn't Work
1. **FittedBox 제거** — maxLines:2로 교체했더니 독일어 복합단어가 중간에서 끊어져 더 못생겨짐. FittedBox 복원 필요.
2. **폰트 사이즈 변경** — 일부 셀만 12px로 변경하면 전체가 들쭉날쭉해 보임. 사이즈 통일 필수.
3. **고정 너비 제거** — Expanded로 바꾸면 Row 전체 높이가 셀별로 달라져 불균형. IntrinsicHeight 필요.

---

## 수정된 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `AI/fortune/common/locale_utils.dart` | (이전 세션) |
| `AI/fortune/lifetime/lifetime_unified_schema.dart` | oheng enum |
| `AI/services/saju_analysis_service.dart` | locale 전달 6곳 |
| `features/saju_chart/data/constants/cheongan_jiji_i18n.dart` | pillarName/direction/season 맵+메서드, _localizeGanJi |
| `features/saju_chart/data/constants/gongmang_table.dart` | reason 8곳 .tr(), library 순서, const 제거 |
| `features/saju_chart/domain/services/unsung_service.dart` | 19곳 .tr() |
| `features/saju_chart/domain/services/twelve_sinsal_service.dart` | 12곳 .tr() |
| `features/saju_chart/domain/services/gongmang_service.dart` | 13곳 .tr() |
| `features/saju_chart/presentation/widgets/pillar_display.dart` | SajuI18n.cheongan/jiji, Flexible label |
| `features/saju_chart/presentation/widgets/possteller_style_table.dart` | FittedBox 복원, 셀 패딩 증가 |
| `features/saju_chart/presentation/widgets/saju_detail_tabs.dart` | pillarName/jiji SajuI18n 5곳+, _buildSectionHeader Expanded 3곳, 궁성 flex |
| `features/saju_chart/presentation/widgets/hapchung_tab.dart` | 설명카드 .tr() 7곳, _localizeGanJi, pillar/direction/season SajuI18n |
| `features/saju_chart/presentation/widgets/fortune_display.dart` | 한자 fallback SajuI18n 7곳 |
| `features/saju_chart/presentation/widgets/day_strength_display.dart` | dayGan SajuI18n, 바차트 라벨 IntrinsicHeight |
| `features/saju_chart/presentation/widgets/sinsal_display.dart` | SizedBox(60)+FittedBox, Expanded |
| `features/saju_chart/presentation/widgets/gilseong_display.dart` | SizedBox(60)+FittedBox, Expanded 3곳, FixedWidth(65) |
| `features/saju_chart/presentation/widgets/gongmang_display.dart` | SizedBox(60)+FittedBox, Expanded 4곳 |
| `features/saju_chart/presentation/widgets/saju_mini_card.dart` | PillarDisplay Flexible |
| `features/saju_chart/presentation/widgets/saju_detail_sheet.dart` | PillarDisplay Flexible |
| `features/saju_chart/presentation/widgets/oheng_analysis_display.dart` | _buildSectionTitle Expanded |
| `shared/widgets/quota_exceeded_dialog.dart` | 3곳 .tr() |
| `shared/widgets/fortune_weekly_chip_section.dart` | 4곳 .tr() |
| `features/home/presentation/widgets/daily_fortune_card.dart` | 폴백 '-' |
| `features/home/presentation/screens/home_screen.dart` | 폴백 '—' |
| `features/menu/presentation/widgets/compatibility_promo_card.dart` | .tr() |
| `features/saju_chat/presentation/screens/saju_chat_shell.dart` | 영어 키워드 추가 |
| `core/repositories/saju_profile_repository.dart` | 폴백 '—' |
| `features/saju_chat/domain/models/compatibility_context.dart` | 폴백 '—' |
| `i18n/{17개}/saju_detail.json` | +54키 |
| `i18n/{17개}/saju_chart.json` | +7키 |
| `i18n/{17개}/menu.json` | +1키 |
