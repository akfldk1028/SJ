# 수정 내역 (2026-01-24)

## 1. 태극 문양 수정 (`yin_yang_illustration.dart`)

### 가운데 줄무늬 제거
- 기존: Clip 기반 방식으로 그려서 중앙에 줄무늬(아티팩트) 발생
- 수정: Path 기반 `addArc`로 양 영역을 그리는 방식으로 변경
  - 오른쪽 반원 (큰 원)
  - 하단 작은 반원 (양 영역 추가)
  - 상단 작은 반원 (양 영역 추가)

### 음양 점 가시성 개선
- 기존: 테마 색상 + alpha 적용 → 어두운 배경에서 안 보임
- 수정:
  - 음 점: 순수 검정 `Color(0xFF000000)`
  - 양 점: 순수 흰색 `Color(0xFFFFFFFF)`
  - 점 크기: `radius * 0.1` → `radius * 0.15`로 확대

---

## 2. 운세분석 카드 세로 폭 축소 (`fortune_summary_card.dart`)

### 로딩/분석 중 카드
- 카드 높이: `320` → `220`
- 음양 태극 크기: `120`/`100` → `80`
- 태극 아래 간격: `20`/`24` → `16`

### 카테고리 통계 그리드 (`_buildCategoryStatsGrid`)
- 헤더-그리드 간격: `scaledPadding(16)` → `scaledPadding(8)`
- 컨테이너 패딩: `scaledPadding(16)` → `scaledPadding(12)`

### 행운 아이템 (`_buildLuckyItemsRow`)
- 헤더-그리드 간격: `scaledPadding(12)` → `scaledPadding(8)`

---

## 3. 메인 메뉴 섹션 간격 축소 (`menu_screen.dart`)

- FortuneSummaryCard → SectionHeader: `scaledPadding(24)` → `scaledPadding(16)`
- SectionHeader → FortuneCategoryList: `scaledPadding(12)` → `scaledPadding(8)`
- FortuneCategoryList → SajuMiniCard: `scaledPadding(24)` → `scaledPadding(16)`
- SajuMiniCard → TodayMessageCard: `scaledPadding(24)` → `scaledPadding(16)`

---

## 4. iOS 코드 서명 설정 (`project.pbxproj`)

### Bundle ID 변경
- `com.example.frontend` → `com.sadam.sj`

### DEVELOPMENT_TEAM 추가
- 3개 빌드 설정(Debug, Release, Profile)에 `DEVELOPMENT_TEAM = H9P7RZBUL3;` 추가
- 서명 인증서: `Apple Development: sonsh980318@gmail.com (Y4JB5NUT55)`

---

## 5. 코드 생성 (build_runner)
- `dart run build_runner build --delete-conflicting-outputs` 실행
- freezed/json_serializable 파일 81개 재생성
