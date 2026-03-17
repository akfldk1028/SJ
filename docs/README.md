# 만톡: AI 사주 챗봇 - 기획 문서

> Supabase + Gemini 기반 사주 상담 앱 기획 문서

---

## 문서 구조

```
docs/
├── README.md                    # ← 지금 보고 있는 파일 (가이드)
│
├── 01_overview.md               # 프로젝트 개요 ⭐ 필수
│
├── 02_features/                 # 기능별 상세 명세 ⭐ 필수
│   ├── _template.md             # 기능 명세 템플릿
│   ├── profile_input.md         # P0: 사주 프로필 입력
│   ├── saju_chat.md             # P0: AI 사주 챗봇 (핵심)
│   └── auth.md                  # P1: 인증 (v0.2 이후)
│
├── 03_architecture.md           # 시스템 아키텍처 + Supabase 연동
├── 04_data_models.md            # 데이터 모델 + PostgreSQL 스키마
├── 05_api_spec.md               # Edge Functions API 명세
├── 06_navigation.md             # 화면 흐름 + go_router 설계
├── 07_design_system.md          # 디자인 가이드
├── 08_backend_comparison.md     # Firebase vs Supabase 비교
├── 09_state_management.md       # Riverpod 3.0 상태관리 가이드
├── 10_widget_tree_optimization.md # Flutter 위젯 트리 최적화
└── 11_multi_agent_design.md     # Claude CLI 멀티에이전트 설계
```

---

## 기술 스택 (확정)

| 분류 | 기술 | 비고 |
|------|------|------|
| Frontend | Flutter 3.x | Dart |
| Backend | **Supabase** | PostgreSQL + Edge Functions |
| AI 분석 | **GPT-5.2** | 사주 분석 (OpenAI Responses API background mode) |
| AI 대화 | **Gemini 3.0 Flash** | SSE 스트리밍 채팅 |
| 상태관리 | **Riverpod 3.0** | @riverpod annotation |
| 라우팅 | go_router | 선언적 라우팅 |
| 로컬 저장 | Hive | 오프라인 캐시 |

---

## 핵심 기능 (MVP)

| 우선순위 | 기능 | 문서 | 상태 |
|----------|------|------|------|
| P0 | 사주 프로필 입력 | `02_features/profile_input.md` | ✅ 기획 완료 |
| P0 | AI 사주 챗봇 | `02_features/saju_chat.md` | ✅ 기획 완료 |
| P1 | 인증 (v0.2) | `02_features/auth.md` | 📝 기획중 |

---

## 문서 요약

### 필수 문서
- `01_overview.md` - 프로젝트 개요, 목표, 기술 스택
- `02_features/` - 기능별 상세 명세 (화면, 수락조건, 흐름)
- `03_architecture.md` - MVVM + Supabase 연동 패턴

### 기술 문서
- `04_data_models.md` - PostgreSQL 테이블 스키마 + RLS
- `05_api_spec.md` - Edge Functions (saju-chat, calculate-saju)
- `06_navigation.md` - go_router 설정 + 화면 흐름
- `07_design_system.md` - 컬러, 타이포, 컴포넌트 가이드

### 설계 가이드
- `08_backend_comparison.md` - Firebase vs Supabase 비교
- `09_state_management.md` - Riverpod 3.0 패턴 + 베스트 프랙티스
- `10_widget_tree_optimization.md` - 위젯 트리 최적화 원칙

---

## AI에게 전달하는 방법

### 기본 명령
```
docs/ 폴더의 기획 문서를 읽고,
profile_input 기능부터 순차적으로 구현해줘.
03_architecture.md의 폴더 구조를 따라서 작업해.
```

### 구현 순서 (권장)
```
1. profile_input (사주 프로필 입력) - 먼저 구현
2. saju_chat (AI 사주 챗봇) - 핵심 기능
3. auth (인증) - v0.2 이후
```

---

## 체크리스트

### 기획 완료 확인

- [x] 01_overview.md - 프로젝트 개요 작성
- [x] 02_features/profile_input.md - P0 기능 명세
- [x] 02_features/saju_chat.md - P0 기능 명세
- [x] 03_architecture.md - Supabase 연동 패턴
- [x] 04_data_models.md - PostgreSQL 스키마
- [x] 05_api_spec.md - Edge Functions 명세
- [x] 06_navigation.md - go_router 설정
- [x] 09_state_management.md - Riverpod 3.0 가이드
- [x] 10_widget_tree_optimization.md - 위젯 최적화

### 구현 전 준비

- [ ] Supabase 프로젝트 생성
- [ ] 04_data_models.md 기반 테이블 생성
- [ ] Edge Functions 배포 (05_api_spec.md)
- [ ] Gemini API 키 발급
- [ ] 07_design_system.md 컬러 확정
