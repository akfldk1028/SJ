# HANDOFF: 십이지신 AI 페르소나 + 대화형 온보딩

> 작성: 2026-03-25 | zodiac-persona 브랜치 | 3커밋 push 완료

---

## Goal

Apple App Store **4.3(b) "Design: Spam" 최종 거절** 돌파.
Apple은 fortune telling을 명시적 포화 카테고리로 지정 → "사주 앱"으로 인식되면 무조건 리젝.
**해결**: 앱 첫인상을 "AI 동물 캐릭터 챗봇"으로 전환하는 십이지신 페르소나 시스템 구축.

---

## Current Progress

### 브랜치: `zodiac-persona` (DK-DD에서 분기, 3커밋 push 완료)

### 완료 (3 커밋)

**커밋 1: 12개 동물 페르소나 + 매처 + 레지스트리**
- `frontend/lib/AI/jina/personas/zodiac/` — 12개 동물 .dart (PersonaBase 상속)
- `zodiac_persona_matcher.dart` — 생년→띠 매칭, 올해 동물 자동 결정
- `persona_registry.dart` — 12개 등록 추가
- `persona_selector.dart` — `getByBirthYear()`, `currentYearPersona`, `zodiacPersonas` 추가

**커밋 2: 60갑자 색+동물 시스템**
- `zodiac_identity.dart` — 천간 오행→색 매핑 ("푸른 말", "흰 호랑이" 등 60조합)
- 5색 오행별 AI 프롬프트 보정 (한/영): 목=성장, 화=열정, 토=안정, 금=결단, 수=지혜
- `zodiac.dart` — barrel export
- 12개 파일 수정 없이 모디파이어 패턴으로 60갑자 구현

**커밋 3: 시각 위젯 4개**
- `frontend/lib/features/onboarding/presentation/widgets/zodiac/`
  - `zodiac_element_background.dart` — 오행 그라데이션 + 떠다니는 빛 파티클
  - `zodiac_animal_avatar.dart` — 이모지 + 글로우 + 등장/호흡 애니메이션
  - `zodiac_chat_bubble.dart` — 대화 버블 + 타이핑 효과 + 입력 임베드
  - `zodiac_reveal_animation.dart` — 수호동물 공개 파티클 폭발 + 이름 표시
- 패키지 의존 없음 (순수 Flutter), Lottie/Rive 교체 가능

---

## Next Steps (우선순위)

### 1. 메인 온보딩 스크린 작성 (가장 급함)
**파일**: `frontend/lib/features/onboarding/presentation/screens/zodiac_onboarding_screen.dart` (신규)

위젯 4개를 조합한 전체 온보딩 플로우:
```
[Phase 1] 올해 동물(2026=붉은 말) 풀스크린 등장
  → ZodiacElementBackground(elementName: '화') + ZodiacAnimalAvatar

[Phase 2] AI 대화로 프로필 수집 (ZodiacChatBubble)
  → "이름이 뭐야?" → 이름 입력 (채팅 버블 안 TextField)
  → "생년월일 알려줘!" → 날짜 피커 임베드
  → "태어난 시간은?" → 시간 선택 임베드
  → "성별은?" → 토글 버튼 임베드

[Phase 3] 내 수호동물 공개 (ZodiacRevealAnimation)
  → 만세력 계산 → 띠 결정 → ZodiacIdentity.fromBirthYear()
  → "잠깐, 네 수호신을 불러올게..." → 파티클 + 색 전환 → 내 동물!
  → 프로필 저장 → context.go(Routes.menu)
```

**재활용할 기존 코드**:
- `birth_date_input_widget.dart`, `birth_time_input_widget.dart`, `gender_toggle_buttons.dart`
- `profileFormProvider` — 폼 상태 관리 + 저장
- `TrueSolarTimeService.defaultCityForLocale()` — 도시 자동 설정
- 기존 `OnboardingScreen._onSave()` 로직 참고

### 2. 라우터 연결
- `routes.dart`에 `zodiacOnboarding` 경로 추가
- `app_router.dart`에 라우트 등록
- `splash_provider.dart`의 `shouldGoToOnboarding` → zodiac 온보딩으로 변경

### 3. 페르소나 선택 UI
- 기존 채팅 페르소나 선택 UI에 "수호동물" 탭 추가
- 내 띠 ⭐, 올해 동물 🔥 표시

### 4. i18n (17개 언어)
- `i18n/*/saju_chat.json`에 zodiac 키 추가

### 5. App Store 메타데이터 리브랜딩

---

## What Worked

- **모디파이어 패턴**: 12동물 × 5색 = 60파일 대신, ZodiacIdentity 데이터 클래스
- **하위폴더 격리**: zodiac/ → 기존 Google Play 코드 무변경
- **PersonaBase 상속**: 기존 시스템과 100% 호환
- **패키지 무의존**: 순수 Flutter 애니메이션

## What Didn't Work

- **Explore 에이전트**: 컨텍스트 길어서 에러 → 직접 Read/Grep
- **검색 에이전트 출력**: JSON lines 파싱 어려움

---

## Key Files

| 파일 | 역할 |
|------|------|
| `AI/jina/personas/zodiac/zodiac.dart` | barrel export |
| `AI/jina/personas/zodiac/zodiac_identity.dart` | 60갑자 데이터 클래스 |
| `AI/jina/personas/zodiac/zodiac_persona_matcher.dart` | 매칭 API |
| `AI/jina/personas/zodiac/zodiac_*.dart` (12개) | 동물 페르소나 |
| `AI/jina/personas/persona_registry.dart` | 레지스트리 (수정됨) |
| `AI/jina/personas/persona_selector.dart` | 셀렉터 (수정됨) |
| `features/onboarding/presentation/widgets/zodiac/` | 시각 위젯 4개 |
| `features/onboarding/presentation/screens/onboarding_screen.dart` | 기존 온보딩 (참고) |
| `router/routes.dart` + `app_router.dart` | 라우팅 |
| `features/splash/presentation/providers/splash_provider.dart` | 온보딩 분기 |

## 메모리
`D:\DevCache\claude-data\projects\D--Data-20-Flutter-01-SJ\memory\apple-review/` — 6개 파일
