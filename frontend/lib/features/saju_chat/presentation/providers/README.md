# saju_chat/presentation/providers

Chat state management layer. Riverpod providers that drive the saju chat UI.

## Key Files

| File | Purpose |
|------|---------|
| `chat_provider.dart` | Main chat state manager. Orchestrates AI pipeline (GPT analysis -> Gemini conversation). Manages token usage, ad triggers, bonus tokens. Key methods: `sendMessage()`, `addBonusTokens(tokens, {isRewardedAd})`. v26: `isRewardedAd` flag prevents double-counting `bonus_tokens` + `rewarded_tokens_earned`. |
| `conversational_ad_provider.dart` | Ad state management. Checks token usage triggers (80%, 100% thresholds), loads Native/Rewarded ads, tracks impressions. v26: native impression calls `AdTrackingService.trackNativeImpression()`. |
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

## Connections

- **Upstream**: `data/datasources/` (AI API calls), `data/services/` (prompt building, token counting)
- **Downstream**: `widgets/` and `screens/` consume these providers
- **Cross-feature**: `ad/` module for ad tracking, `AI/jina/personas/` for persona definitions
- **Supabase**: `chat_sessions`, `chat_messages`, `chat_mentions`, `user_daily_token_usage`
