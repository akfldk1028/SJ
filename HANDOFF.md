# HANDOFF — 다국어 17개 언어 + 하드코딩 정리 + 앱번들

> 작성: 2026-03-17 21:30 | v0.1.6+53 | 앱번들 빌드 완료

---

## Goal

SaDam(사담) 앱 전세계 배포를 위한 17개 언어 완전 대응:
1. ~~JSON 번역 파일 17개 언어 생성~~ **완료**
2. ~~Dart 하드코딩 한국어 → `.tr()` 교체~~ **대부분 완료**
3. ~~AI 채팅(Gemini) 다국어 응답~~ **완료**
4. ~~페르소나/MBTI/ChatType i18n~~ **완료**
5. ~~Supabase locale CHECK 17개 확장~~ **완료**
6. ~~pg_cron 좀비 task 자동 정리~~ **완료**
7. 🔴 운세 화면 하드코딩 한국어 잔존 — **미완료**

---

## Current Progress

### 완료 (이번 세션)

**14개 언어 네이티브 번역** — 238개 JSON 파일 (7개 에이전트 병렬)
- 검증 통과: JSON 파싱 0에러, 키 누락 0, {변수} 불일치 0

**페르소나/MBTI/ChatType i18n** (chat_type.dart, ai_persona.dart)
- `MbtiQuadrant.displayName/description` → `.tr()` (mbti_NF, mbti_NT 등)
- `AiPersona.displayName/description` → `.tr()` (persona_grandma 등)
- `ChatType.title/inputHint` → `.tr()` (chatType_general 등)
- 17개 언어 JSON에 37개 신규 키 추가 완료

**AI 프롬프트 다국어 강화**
- `system_prompt_builder.dart` — CRITICAL LANGUAGE INSTRUCTION (langMap 17개 언어명)
- `prompt_loader.dart` — fallback "한국어로" → "사용자가 보낸 언어로"
- `saju_prompts.dart` — 다국어 지시 추가
- `chat_provider.dart` + `session_restore_service.dart` — `FortuneLocaleUtils.currentLocale` 사용

**Supabase DB**
- 5개 테이블 locale CHECK → 17개 언어 확장
- `pg_cron` job `cleanup-zombie-tasks` — 5분마다 10분 넘은 stuck task 자동 정리
- `cleanup_zombie_tasks()` 함수 생성

**프로필 저장 시 locale 전달**
- `profile_provider.dart` — `locale: FortuneLocaleUtils.currentLocale`

**ja 누락 키 추가**
- `ja/saju_chat.json` — 6개 토큰 관련 키
- `ja/yearly_2025.json` — 4개 제목 키
- `ja/lifetime_fortune.json` — 25개 키

**앱 번들**
- `v0.1.6+53` — `app-release.aab` (67MB) 빌드 완료
- 경로: `frontend/build/app/outputs/bundle/release/app-release.aab`
- 보상형 광고 토큰: 5000 (변경 없음, `ad_strategy.dart:99`)

### 메모리 업데이트
- `architecture/i18n_expansion.md` — 전체 재작성 (v0.1.6+53 기준)
- `project/global_deployment_goal.md` — 전세계 배포 목표 기록
- `MEMORY.md` — 인덱스 정리

---

## 🔴 남은 문제 — 운세 화면 한국어 하드코딩

### 스크린샷 증거
- `docs/Image/화면 캡처 2026-03-17 212421.png`
  - **"탭하여 상세 운세를 확인하세요"** — 하드코딩
  - **"직업운/사업운/재물운/애정운/결혼운/학업운/건강운"** — 하드코딩 버튼
- `docs/Image/화면 캡처 2026-03-17 205509.png`
  - **"2025년", "목용의 해", "오행/띠/음양", "총운"** — DB 저장된 AI 분석 결과 (한국어 캐시)
  - **"목(양) 기운과 용띠의 특성이..."** — AI 분석 결과

### 원인 분류

**1. 코드 하드코딩 (수정 필요)**
파일 위치를 grep으로 찾아서 `.tr()` 교체 필요:
```bash
grep -rn "직업운\|사업운\|재물운\|애정운\|결혼운\|학업운\|건강운\|탭하여" frontend/lib/features/
```

예상 파일:
- `new_year_fortune/presentation/screens/` 또는 `widgets/`
- `yearly_2025_fortune/presentation/`
- 카테고리 이름은 이미 `lifetime_fortune.json`에 `careerFortune`, `wealthFortune` 등 키가 있으므로 해당 키 사용

**2. DB 캐시된 AI 분석 결과 (한국어)**
- 기존 유저의 `ai_summaries.content`가 한국어로 저장됨
- locale 변경 시 새로 분석해야 올바른 언어로 나옴
- `ai_summaries` 테이블에 `locale` 컬럼이 있으므로, locale이 다르면 새 레코드 생성됨
- **해결**: 언어 변경 시 기존 캐시와 locale이 다르면 자동 재분석 트리거

**3. 카테고리 매핑 (운세 provider)**
- 운세 분석 결과의 카테고리 키가 한국어("직업/취업운")인 경우가 있음
- `yearly_2025_fortune_provider.dart`의 dummy data는 이미 `.tr()`로 교체함
- 하지만 실제 AI 응답의 카테고리 제목이 한국어일 수 있음

---

## What Worked

- **7개 에이전트 병렬 번역** — 238파일 약 10분에 완료
- **python3 검증 스크립트** — JSON 파싱 + 키 매칭 + 변수 체크 자동화
- **Supabase MCP** — DB constraint 변경, pg_cron 설정, task 상태 확인
- **FortuneLocaleUtils.currentLocale** — 앱 전역 locale 싱글톤으로 통일

## What Didn't Work

- **`platformDispatcher.locale`** → easy_localization의 앱 내 언어와 불일치 가능. `FortuneLocaleUtils.currentLocale`로 교체함
- **에뮬레이터 wipe 후 테스트** — 프로필 없는 새 유저라 task 생성 안 됨. 온보딩 + 프로필 등록 필수
- **"영어로만" 사고** — 17개 언어 대응인데 영어만 생각하면 안 됨. langMap으로 구체적 언어명 전달 필수

---

## Next Steps

### 1. 🔴 운세 화면 하드코딩 정리 (긴급)
```bash
# 먼저 하드코딩 위치 찾기
grep -rn "직업운\|사업운\|재물운\|애정운\|결혼운\|학업운\|건강운" frontend/lib/features/new_year_fortune/ frontend/lib/features/yearly_2025_fortune/
grep -rn "탭하여\|총운\|목용의" frontend/lib/features/
```
→ 찾은 것들을 `saju_chart.json`이나 `new_year_fortune.json`의 기존 키로 교체

### 2. 십성 UI 리디자인
- `sipsin_relations.dart` 하드코딩 → i18n
- `oheng_analysis_display.dart` UI 개선

### 3. 데이터 레이어 하드코딩 (150+ 키)
- `hapchung_explanations.dart`
- `compatibility_interpreter.dart`

### 4. 에뮬레이터 다국어 테스트
- 각 언어 전환 후 주요 화면 확인
- 텍스트 오버플로우 (독일어/러시아어)
- RTL 아랍어 레이아웃

---

## Key Files

| 파일 | 역할 |
|------|------|
| `frontend/lib/main.dart:128-146` | 17개 locale 등록 |
| `frontend/lib/i18n/{locale}/*.json` | 번역 파일 289개 (17×17) |
| `frontend/lib/AI/fortune/common/locale_utils.dart` | `FortuneLocaleUtils` 앱 전역 locale |
| `frontend/lib/features/saju_chat/data/services/system_prompt_builder.dart` | AI 프롬프트 locale 지시 |
| `frontend/lib/features/saju_chat/domain/models/ai_persona.dart` | 페르소나 i18n |
| `frontend/lib/features/saju_chat/domain/models/chat_type.dart` | 채팅타입 i18n |
| `frontend/lib/ad/ad_strategy.dart:99` | `depletedRewardTokensVideo = 5000` |
| `frontend/build/app/outputs/bundle/release/app-release.aab` | 릴리스 번들 v0.1.6+53 |

## Memory 참조
- `memory/architecture/i18n_expansion.md` — 다국어 전체 구조 (v0.1.6+53 최종)
- `memory/project/global_deployment_goal.md` — 전세계 배포 목표
- `memory/architecture/gemini_token_system.md` — 토큰 시스템
