# saju_chat/presentation/providers

Chat state management layer. Riverpod providers that drive the saju chat UI.

## Key Files

| File | Purpose |
|------|---------|
| `chat_provider.dart` | Main chat state manager. Orchestrates AI pipeline (GPT analysis -> Gemini conversation). Manages token usage, ad triggers, bonus tokens. Key methods: `sendMessage()`, `addBonusTokens(tokens, {isRewardedAd})`. v0.1.2: QUOTA_EXCEEDED(429) catch → state.error + 광고 재트리거 + ErrorLoggingService 기록. |
| `conversational_ad_provider.dart` | Ad state management. Checks token usage triggers (80%, 100% thresholds), loads Native/Rewarded ads, tracks impressions. v0.1.2: `_onAdClicked()` race condition 수정 → `unawaited(_grantNativeTokensAndUpdateState())` 패턴으로 서버 저장 완료 후 상태 업데이트. |
| `chat_session_provider.dart` | Session CRUD. Creates, loads, deletes chat sessions. Manages `pendingParticipantIds` for compatibility mode. |
| `persona_provider.dart` | Manages AI persona selection (base personality). |
| `base_persona_provider.dart` | Base persona loading from `AI/jina/personas/`. |
| `chat_persona_provider.dart` | Active persona state for current chat session. |
| `combined_persona_provider.dart` | Merges base persona + character overlays. |
| `mbti_quadrant_provider.dart` | MBTI quadrant (NF/NT/SF/ST) persona routing. |
| `character_provider.dart` | Special character system (unlockable characters). |
| `special_character_provider.dart` | Special character availability and selection. |

## Data Flow

```
User sends message
    |
chat_provider.sendMessage()
    |
    +-- [2] _ensureAiSummary() (Gemini Flash, fire-and-forget)
    +-- [2-1] _ensureSajuBase() (GPT-5.2, fire-and-forget, v30 lazy trigger)
    +-- Build system prompt (SystemPromptBuilder)
    +-- Call AI pipeline (GPT analysis -> Gemini streaming)
    +-- Update token usage
    +-- Check ad triggers (conversational_ad_provider)
    +-- Stream response to UI
```

## v30 Lazy saju_base

`_ensureSajuBase(profileId)` — 첫 메시지 전송 시 GPT-5.2 saju_base 생성 트리거.

- `state.messages.isEmpty && profileId != null` 조건으로 첫 메시지만
- `SajuAnalysisService.analyzeOnProfileSave(runInBackground: true)` 호출
- 내부에서 캐시 확인 → 있으면 즉시 반환, 없으면 분석 시작
- `_analyzingProfiles` Set으로 중복 방지
- 다른 진입점(main_bottom_nav, fortune_category_list)에서 이미 트리거했으면 스킵

## v0.1.2 Bug Fixes

### Native Ad Race Condition (BUG-2)
- **Before**: `_onAdClicked()` fire-and-forget → 서버 업데이트 전에 `adWatched=true` → 유저 즉시 메시지 → 서버 구 값으로 quota 실패
- **After**: `unawaited(_grantNativeTokensAndUpdateState(rewardTokens))` → 내부에서 `await TokenRewardService.grantNativeAdTokens()` 완료 후 `state = state.copyWith(adWatched: true)`

### QUOTA_EXCEEDED Error Handling
- `chat_provider.dart` sendMessage에서 429 에러 catch
- `state = state.copyWith(error: '토큰이 부족합니다...')` 설정
- `checkAndTriggerAdIfNeeded()` 재호출 → 광고 배너 재표시
- `ErrorLoggingService.logError()` → `chat_error_logs` 테이블 기록

## Connections

- **Upstream**: `data/datasources/` (AI API calls), `data/services/` (prompt building, token counting)
- **Downstream**: `widgets/` and `screens/` consume these providers
- **Cross-feature**: `ad/` module for ad tracking, `AI/jina/personas/` for persona definitions
- **Supabase**: `chat_sessions`, `chat_messages`, `chat_mentions`, `user_daily_token_usage`
- **Error logging**: `core/services/error_logging_service.dart` → `chat_error_logs` table
