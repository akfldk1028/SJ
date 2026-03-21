# HANDOFF — 운세 화면 하드코딩 i18n + iOS 심사 + 레이아웃

> 작성: 2026-03-21 16:30 | DK-DD 브랜치 | 미커밋 상태

---

## Goal

1. 운세 화면 한국어 하드코딩 → `.tr()` i18n 전환 (17개 언어)
2. iOS App Store 심사 통과 (4.3(b) 이의 신청 완료, Apple 응답 대기)
3. 레이아웃/가독성 개선

---

## Current Progress

### ✅ 이번 세션 완료

**iOS App Store 심사 대응**
- 2.1 회신 완료 (영상 + 6가지 답변)
- 4.3(b) 이의 신청 3건 (Resolution Center 2건 + App Review Board 1건)
- RevenueCat S2S URL 설정 완료
- IAP 심사 스크린샷 3개 상품 업로드 (paywall_review_1.png, paywall_review_2.png)
- 메모리: `memory/project/ios_app_store_rejection.md`

**코드 수정 완료 (미커밋)**
- `paywall_screen.dart` — 이용약관 + 개인정보 처리방침 링크 추가 (Guideline 3.1.2)
- `ios/Runner/17개 .lproj/InfoPlist.strings` — ATT Purpose String 다국어

**i18n JSON 생성 (17개 언어 전부)**
- `year_info.json` — 오행, 음양, 12간지, 특수연도 (청뱀/붉은말/청룡의 해)
- `fortune_common.json` — 운세 카테고리 칩 (직업/사업/재물/애정/결혼/학업/건강운), 분석 상태 메시지

**Dart 코드 i18n 변환 완료 (7개 파일)**
- `fortune_year_info_card.dart` — 전체 (오행, 띠, 음양, 특수연도, 12간지)
- `fortune_title_header.dart` — '총운' + 키워드 overflow
- `fortune_category_chip_section.dart` — `_getCategoryName()` 칩 11개
- `fortune_monthly_chip_section.dart` — `_getCategoryName()` 칩 8개
- `fortune_monthly_step_section.dart` — `_getCategoryName()` 칩 7개
- `lifetime_fortune_provider.dart` — 분석 상태 5개 + 12간지 매핑
- `monthly_fortune_provider.dart` — 에러 메시지

**레이아웃 개선**
- `FortuneHighlightBox` — 아이콘을 제목 옆으로 이동, 텍스트 전체 너비 사용 (Row→Column)
- `FortuneSectionCard` 헤더 — 아이콘 컴팩트화 (padding 10→8, size 20→18)
- `FortuneKeywordBadge` — `Flexible` + overflow 방지
- `FortuneTitleHeader` standard/hero — 키워드 overflow 방지

### 🔴 미완료 — 다음 세션에서 해야 할 것

---

## Next Steps (우선순위 순)

### 1. 🔴 운세 위젯 3개 파일 한국어 하드코딩 전환 (긴급)

코드 리뷰에서 발견된 잔존 하드코딩. 각 파일에 20~30개씩.

**fortune_monthly_chip_section.dart** — 하드코딩 목록:
- `'월별 운세'`, `'탭하여 각 달의 운세를 확인하세요'`
- `'$monthNum월'`, `'$monthNum월 운세'`
- `'키워드: ${month.keyword}'`
- `'분야별 요약'`, `'분야별 상세 운세'`
- `'행운'`, `'이달의 사자성어'`
- `'$monthNum월 운세를 분석하고 있습니다...'`
- SnackBar/Dialog 한국어 텍스트

**fortune_category_chip_section.dart** — 하드코딩 목록:
- `'분야별 운세'`, `'탭하여 상세 운세를 확인하세요'`
- `'${cat.score}점'` (여러 곳)
- `'조언'`, `'타이밍'`, `'강점:'`, `'주의할 점:'`
- `'적합한 분야:'`, `'피해야 할 분야:'`, `'주의사항'`
- `'집중 영역:'`, `'실천 팁'`
- 카테고리별 상세: `'업무 스타일'`, `'리더십 잠재력'`, `'연애 패턴'` 등
- SnackBar/Dialog 텍스트 (프리미엄 안내)

**fortune_monthly_step_section.dart** — 하드코딩 목록:
- `'좋은 달:'`, `'주의할 달:'`
- `'다음: $nextCategoryName'`
- `'광고 보고 $nextCategoryName 확인하기'`
- `'${category.score}점'`
- `'$categoryName 운세가 해제되었습니다!'`
- Dialog 텍스트 (`'프리미엄으로 바로 보기'`, `'닫기'`, `'프리미엄 보기'`)

**fortune_keyword_badge.dart** — `'$score점'` 하드코딩

**작업 방법:**
1. `fortune_common.json`에 키 추가 (ko + en)
2. 에이전트로 15개 언어 번역
3. Dart 파일에서 `.tr()` 교체

### 2. 프리미엄 다이얼로그 공통 함수 추출
- 3개 파일에서 동일한 프리미엄 안내 다이얼로그 반복
- `shared/utils/premium_dialog.dart`로 추출 가능

### 3. mock 데이터 i18n (후순위)
- `new_year_fortune_provider.dart` 700~830줄 — fallback/mock 데이터 한국어
- 실서비스에서는 AI 응답으로 대체되므로 우선순위 낮음

### 4. 데이터 레이어 하드코딩 (150+ 키)
- `hapchung_explanations.dart`
- `compatibility_interpreter.dart`
- `sipsin_relations.dart`

### 5. 버전업 + Google Play 앱번들
- 현재 `0.1.6+56` → 버전 올리고 빌드

### 6. iOS App Store 응답 대기
- 4.3(b) 이의 응답 예상: 1~3 영업일
- 거절 시 → 추가 대응 필요
- 메모리: `memory/project/ios_app_store_rejection.md` 참조

---

## What Worked

- **에이전트 병렬 번역** — year_info.json, fortune_common.json 각각 15개 언어를 백그라운드 에이전트로 생성
- **Playwright 브라우저 자동화** — App Store Connect + RevenueCat 대시보드 조작
- **Sequential Thinking MCP** — Apple 이의 신청 전략 수립에 효과적
- **코드 리뷰 에이전트** — 빌드 에러/import 누락 사전 검출

## What Didn't Work

- **하드코딩 전수조사 에이전트** — 프롬프트 길이 초과로 실패. `grep`으로 직접 검색이 더 빠름
- **카톡 이미지 → IAP 스크린샷** — 카톡 압축으로 크기 안 맞음. Python Pillow로 리사이즈 필요 (1290x2796)
- **App Store Connect 파일 업로드** — 파일 선택기 열릴 때 다른 모달이 남아있으면 실패. 순차적으로 처리 필요

---

## Key Files

| 파일 | 역할 |
|------|------|
| `frontend/lib/i18n/{locale}/year_info.json` | 연도 정보 i18n (17개 언어) |
| `frontend/lib/i18n/{locale}/fortune_common.json` | 운세 카테고리/상태 i18n (17개 언어) |
| `frontend/lib/shared/widgets/fortune_*.dart` | 운세 공유 위젯 (수정 완료) |
| `frontend/lib/purchase/widgets/paywall_screen.dart` | 페이월 (이용약관 링크 추가) |
| `frontend/ios/Runner/*.lproj/InfoPlist.strings` | ATT 다국어 (17개) |
| `docs/Image/paywall_review_*.png` | IAP 심사 스크린샷 (1290x2796) |

## Memory 참조
- `memory/project/ios_app_store_rejection.md` — iOS 심사 전체 이력
- `memory/i18n/fortune_hardcoding_fix.md` — 하드코딩 수정 진행 상태
- `memory/architecture/i18n_expansion.md` — 다국어 전체 구조
