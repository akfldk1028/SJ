# 만톡 - Jaehyeon 작업 목록

> 개인 작업 노트 (협업자와 충돌 방지용)
> 작업 브랜치: Jaehyeon(Test)
> 우선순위: **만세력 로직 구현 완성**

---

## 현재 집중 과제

| 항목 | 상태 | 우선순위 |
|------|------|----------|
| **만세력 로직 검증 및 완성** | 🔄 진행중 | **P0 최우선** |
| 음양력 변환 실제 구현 | ⏳ 대기 | P0 |
| 절기 테이블 확장 | ⏳ 대기 | P1 |
| 대운(大運) 계산 | ⏳ 대기 | P2 |
| 채팅 히스토리 사이드바 | ✅ 구현됨 | 완료 |

---

## Phase 8: 만세력 (Saju Chart) - 핵심 작업

### 현재 완료된 파일 (19개)

#### Constants
- [x] `data/constants/cheongan_jiji.dart` - 천간(10), 지지(12), 오행
- [x] `data/constants/gapja_60.dart` - 60갑자
- [x] `data/constants/solar_term_table.dart` - 절기 시각 (2024-2025)
- [x] `data/constants/dst_periods.dart` - 서머타임 기간

#### Domain Entities
- [x] `domain/entities/pillar.dart` - 기둥 (천간+지지)
- [x] `domain/entities/saju_chart.dart` - 사주 차트
- [x] `domain/entities/lunar_date.dart` - 음력 날짜
- [x] `domain/entities/solar_term.dart` - 24절기 enum

#### Domain Services (핵심)
- [x] `domain/services/saju_calculation_service.dart` - 통합 계산 (메인)
- [x] `domain/services/lunar_solar_converter.dart` - 음양력 변환 (**Stub - 구현 필요**)
- [x] `domain/services/solar_term_service.dart` - 절입시간
- [x] `domain/services/true_solar_time_service.dart` - 진태양시 (25개 도시)
- [x] `domain/services/dst_service.dart` - 서머타임
- [x] `domain/services/jasi_service.dart` - 야자시/조자시

#### Data Models
- [x] `data/models/pillar_model.dart` - JSON 직렬화
- [x] `data/models/saju_chart_model.dart` - JSON 직렬화

---

## 만세력 TODO (우선순위 순)

### 1. 음양력 변환 실제 구현 (P0 - 최우선)
> 현재 `lunar_solar_converter.dart`가 Stub 상태

**옵션:**
- [ ] 한국천문연구원 API 연동
- [ ] 오프라인 음양력 테이블 구현 (1900-2100년)
- [ ] 외부 라이브러리 활용 검토

**참고 자료:**
- 한국천문연구원: https://astro.kasi.re.kr/
- GitHub: bikul-manseryeok 프로젝트

### 2. 절기 테이블 확장 (P1)
> 현재 2024-2025년만 포함

- [ ] 1900-2100년 절기 테이블 생성
- [ ] 절기 시각 정밀도 확보 (분 단위)

### 3. 대운(大運) 계산 (P2)
- [ ] `domain/entities/daewoon.dart` 생성
- [ ] 대운 시작 나이 계산
- [ ] 10년 단위 대운 배열

### 4. 검증 및 테스트
- [ ] 포스텔러 만세력 2.2와 비교 검증
- [ ] 경계 케이스 테스트 (자시, 절기 변경 시점)

---

## 만세력 정확도 핵심 요소

### 1. 진태양시 보정 ✅ 구현됨
```
한국 표준시: 동경 135도 기준
실제 한반도: 약 127도 → ~32분 차이

예시:
- 창원: -26분
- 서울: -30분
- 부산: -25분
```

### 2. 절입시간 ✅ 구현됨 (2024-2025)
```
월주 변경 시점 = 절기 시작 시간
예: 입춘(2024) = 2024-02-04 16:27 → 이때부터 인월(寅月)
```

### 3. 서머타임 ✅ 구현됨
```
적용 기간:
- 1948-1951
- 1955-1960
- 1987-1988
해당 기간 출생자 +1시간 보정
```

### 4. 야자시/조자시 ✅ 구현됨
```
자시(子時): 23:00-01:00
- 야자시: 23:00-24:00 당일로 계산
- 조자시: 00:00-01:00 익일로 계산
```

---

## 채팅 기능 현황

### Saju Chat (Phase 5) ✅ 대부분 완료
- [x] Gemini 3.0 REST API 연동
- [x] SSE 스트리밍 응답
- [x] 메시지 버블 UI
- [x] 타이핑 인디케이터
- [x] 면책 배너

### 채팅 히스토리 사이드바 ✅ 신규 구현
- [x] `chat_history_sidebar.dart`
- [x] `session_list_tile.dart`
- [x] `session_group_header.dart`
- [x] `sidebar_header.dart`
- [x] `sidebar_footer.dart`
- [x] `chat_session_provider.dart`
- [x] `chat_session_model.dart`
- [x] `chat_message_model.dart`

---

## 작업 규칙

### Git
- **작업 브랜치**: Jaehyeon(Test)
- master 건들지 않음
- 협업자(DK)와 충돌 시 이 파일 참조

### 우선순위
1. **만세력 로직 완성** ← 현재 집중
2. Profile/Chat 통합 테스트
3. 나머지 UI 개선

---

## 진행 기록

| 날짜 | 작업 내용 | 상태 |
|------|-----------|------|
| 2025-12-02 | 만세력 계산 로직 19개 파일 구현 | ✅ |
| 2025-12-05 | Gemini 3.0 REST API 연동 | ✅ |
| 2025-12-05 | 채팅 히스토리 사이드바 구현 | ✅ |
| 2025-12-06 | TASKS_JAEHYEON.md 분리 생성 | ✅ |
| 2025-12-06 | 만세력 로직 검증 시작 | 🔄 |

---

## 메모

### 다음 작업 계획
1. `lunar_solar_converter.dart` 실제 구현
2. 테스트 케이스 작성 (특정 생년월일 → 사주 검증)
3. 포스텔러 만세력과 결과 비교

### 협업 노트
- 협업자(DK)가 master 브랜치에서 메인 작업 중
- TASKS.md는 협업자가 관리
- 이 파일(TASKS_JAEHYEON.md)로 개인 작업 추적
