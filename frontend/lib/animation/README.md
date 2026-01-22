# Animation 모듈

사주 앱의 로딩 애니메이션 위젯 모음

## 파일 구조

```
animation/
├── README.md                      # 이 파일
└── saju_loading_animation.dart    # 사주팔자 8글자 로딩 애니메이션
```

## saju_loading_animation.dart

### 개요
평생운세 분석 중 표시되는 로딩 애니메이션.
사용자의 사주팔자 8글자(천간/지지)를 시각적으로 표현.

### 기능
- **8글자 순차 등장**: fade-in + scale 애니메이션
- **오행 색상**: 각 글자의 오행에 따른 색상 적용
  - 木: 초록 (#4CAF50)
  - 火: 빨강 (#F44336)
  - 土: 노랑 (#FFC107)
  - 金: 금색 (#FFD700)
  - 水: 파랑 (#2196F3)
- **글로우 효과**: 용신 강조
- **Phase 진행률**: 4단계 분석 상태 표시

### 사용법

```dart
SajuLoadingAnimation(
  yearGan: '갑(甲)',
  yearJi: '술(戌)',
  monthGan: '병(丙)',
  monthJi: '자(子)',
  dayGan: '경(庚)',
  dayJi: '인(寅)',
  hourGan: '경(庚)',
  hourJi: '진(辰)',
  currentPhase: 2,
  totalPhases: 4,
  statusMessage: '재물/직업운 분석 중...',
)
```

### 데이터 소스
- `saju_analyses` 테이블의 `year_gan`, `year_ji`, `month_gan` 등 8개 컬럼
- `sajuPaljaProvider`에서 조회

### 표시 위치
- `lifetime_fortune_screen.dart` → `_buildAnalyzing()` 메서드

---

작성일: 2026-01-21
