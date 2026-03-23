# HANDOFF — 사주 상세 UI 다국어 레이아웃 대수술 (진행 중)

> 작성: 2026-03-22 23:20 | DK-DD 브랜치 | v64+ 다국어 UI

---

## Goal

사담(SaDam) 앱의 사주 상세 9탭 + 홈 화면에서 **다국어 레이아웃 전면 수정**.
독일어/인도네시아어 등 긴 언어에서 UI가 깨지는 문제 해결.

**핵심 규칙 (DK 확정, 메모리에 저장됨)**:
- CJK(한/중/일) → 한자 표시
- 나머지 14개 언어 → 한자 대신 **한글** 표시 (외국인이 한글 좋아함)
- FittedBox 절대 금지 (글씨 크기가 셀마다 달라짐)
- maxLines 넉넉하게 (5 이상), 높이를 늘려서 대응

---

## 완료된 작업 (이번 세션)

### 1. FittedBox 전면 제거 ✅
모든 사주 상세 위젯에서 FittedBox(scaleDown) 16개 제거.
대신 `maxLines` + `overflow: TextOverflow.ellipsis` + 통일된 폰트 사이즈 적용.

**수정 파일**: possteller_style_table, fortune_display, pillar_column_widget, sinsal_display, gilseong_display, gongmang_display, day_strength_display, sipsung_display, oheng_analysis_display, pillar_display

### 2. 한자→한글 CJK 분기 ✅
- `possteller_style_table.dart` — _buildGanJiCell: CJK=한자, 나머지=한글 큰 글씨 + locale 이름 작은 글씨
- `pillar_display.dart` — _buildCharWithHanja: 동일 CJK 분기
- `fortune_display.dart` — 대운/세운/월운 카드: `_buildGanJiBox()` + `_buildGanJiText()` 헬퍼
- `personalized_oheng_widget.dart` — 오행 관계 카드: 水→Wasser 등 locale별 표시
- `home_screen.dart` — 사자성어: CJK=한자, 나머지=한글
- `calendar_screen.dart`, `fortune_summary_card.dart` — 동일 적용

### 3. 번역 축약 ✅ (17개 언어)
기둥 이름 짧게 줄임 (모든 언어):
- de: "Stundenpfeiler"→"Stunde", "Himmelsstamm"→"Stamm"
- en: "Hour Pillar"→"Hour"
- fr/es/it/pt/ru/ar/hi/id/ms/th/my — 전부 축약 완료

**수정 파일**: 17개 `saju_chart.json`

### 4. 오행 i18n 17개 언어 추가 ✅
`_ohengI18n` 맵: 기존 en만 → 17개 언어 전부 추가 (Holz, Feuer, Erde, Metall, Wasser 등)

### 5. 특수 신살 i18n 30+ 항목 추가 ✅
`_specialSinsalI18n`: 11개 → 40+개로 확장 (월덕귀인, 천덕귀인, 태극귀인, 현침살, 천문성, 학당귀인, 백호대살 등 전부 영어 번역)

### 6. Row overflow 수정 ✅
- 합충 카드: Row→Wrap, 흰배경→테마색, 한글 description 숨김
- 신살 상세 카드: Wrap→Column 2줄 고정 (1행: 궁성+지지, 2행: 신살+길흉)
- 공망 카드: Row+Spacer→Column (overflow 제거)
- 공망 "normalEnergyDesc" Row: Expanded 추가
- 설명 카드 제목 5곳: Expanded + maxLines:3 추가
- 운성 요약 제목: Expanded 추가

### 7. maxLines 전면 증가 ✅
모든 위젯 파일에서 maxLines: 2 → 5로 변경 (총 30+곳)
fortune_display SizedBox height: 28→42, 전체 높이 205→230

### 8. fortuneType 한글 누출 수정 ✅
`_buildKeySinsalCard`에서 `fortuneType` 한글 → `SajuI18n.fortuneType()` 호출로 변경

### 9. 공망 summary "월지" 한글 누출 수정 ✅
`result.summary` 대신 UI에서 `gongmangPillars.map(SajuI18n.pillarName)` 직접 조합

---

## 남은 문제 (Next Steps)

### Priority 1: 신살 summary 한글 하드코딩
- **증상**: "역마살(월지), 화개살(년지)" 한글 그대로 표시
- **원인**: `twelve_sinsal_service.dart:225-230` — `summary` getter가 한글로 조합
- **해결**: UI(saju_detail_tabs.dart)에서 `result.summary` 사용처를 찾아서, `SajuI18n.sinsal()` + `SajuI18n.pillarName()`으로 locale 변환
- **파일**: `saju_detail_tabs.dart` 1528행 근처

### Priority 2: `_pillarNameI18n` Dart맵 축약 안 됨
- **증상**: "Cabang Tahun" (인도네시아어) 등 Dart 맵의 기둥 이름이 아직 길음
- **원인**: JSON `saju_chart.json`은 축약했지만, `cheongan_jiji_i18n.dart`의 `_pillarNameI18n` 맵은 안 바꿈
- **해결**: `_pillarNameI18n`에서 '년지'→'Tahun', '월지'→'Bulan' 등 축약
- **파일**: `cheongan_jiji_i18n.dart` 1193~1208행

### Priority 3: 합충 description 한글 잔여
- **증상**: hapchung_service.dart에서 `'$gan1$gan2충'` 한글 생성
- **현재 처리**: regex로 한글만인 description 숨김 (임시)
- **해결**: hapchung_service에서 description을 i18n 키로 바꾸거나, UI에서 SajuI18n.hapchungDesc() 적용

### Priority 4: Stat box "Tidak Menguntungkan" 레이아웃
- **증상**: 인도네시아어 "Tidak Menguntungkan"이 stat box에 안 맞음
- **해결**: stat box 내 텍스트 fontSize 줄이거나 maxLines 증가

### Priority 5: 합충 카드 locale+한글(한자) 병기
- **DK 피드백**: "locale 하고 진(한자) 이렇게. 외국인은 한글을 좋아해"
- 합충 _buildCharacterBox에서 locale명 + 한글(한자) 2줄 표시

---

## What Worked
1. **CJK 분기 패턴** — `final isCjk = locale == 'ko' || locale == 'ja' || locale == 'zh'` → 한자/한글 분기. 깔끔하고 모든 위젯에서 재사용
2. **Column 2줄 고정** — Wrap보다 깔끔 (Wrap은 들쭉날쭉)
3. **maxLines 5 + Expanded** — overflow 근본 해결
4. **번역 축약** — "Stundenpfeiler"→"Stunde" 같은 축약이 가장 효과적

## What Didn't Work
1. **FittedBox** — 셀마다 글씨 크기 달라져서 최악. 절대 쓰지 말 것
2. **Wrap** — 자동 줄바꿈이 들쭉날쭉해서 보기 흉함. Column 2줄 고정이 나음
3. **maxLines: 1** — 독일어 같은 긴 언어에서 무조건 잘림. 최소 2, 가능하면 5
4. **Spacer() in Row** — 요소가 넓으면 overflow 원인. 제거하거나 Expanded로 대체

---

## 수정 파일 목록 (이번 세션)

| 파일 | 변경 |
|------|------|
| `possteller_style_table.dart` | FittedBox 4곳 제거, CJK 한자/한글 분기, maxLines 5 |
| `pillar_display.dart` | CJK 분기, 라벨 11px, maxLines 5 |
| `fortune_display.dart` | 한글 큰 글씨, CJK 분기, 카드 96px, height 42/230 |
| `personalized_oheng_widget.dart` | 오행명 locale별, 한자 CJK 분기 |
| `home_screen.dart` | 사자성어 CJK 분기 2곳 |
| `calendar_screen.dart` | 사자성어 CJK 분기 |
| `fortune_summary_card.dart` | 사자성어 CJK 분기 |
| `saju_detail_tabs.dart` | Row→Column, Expanded 추가 6곳, maxLines 5, fortuneType i18n, gongmang summary locale |
| `hapchung_tab.dart` | 흰배경→테마, 한글 description 숨김, maxLines 5 |
| `gilseong_display.dart` | FittedBox 제거, SpecialSinsalBadge overflow, maxLines 5 |
| `sinsal_display.dart` | 라벨 80px, maxLines 5 |
| `gongmang_display.dart` | 라벨 80px, maxLines 5 |
| `day_strength_display.dart` | FittedBox→Flexible, maxLines 5 |
| `sipsung_display.dart` | FittedBox 제거, maxLines 5 |
| `oheng_analysis_display.dart` | FittedBox 제거, 너비 110px, maxLines 5 |
| `pillar_column_widget.dart` | FittedBox 4곳 제거, maxLines 5 |
| `saju_detail_sheet.dart` | 오행바 라벨 70px, maxLines 2 |
| `cheongan_jiji_i18n.dart` | 오행 17개 언어, 특수신살 40+, 음양 17개 언어 |
| 17개 `saju_chart.json` | 기둥 이름 축약 |
