# saju_chat/data/services

Backend services for chat data processing: ad triggers, token management, prompt building, streaming.

## Key Files

| File | Purpose |
|------|---------|
| `ad_trigger_service.dart` | Determines when to show ads. Token thresholds: 80% (native ad), 100% (rewarded ad). Interval ads every 3 messages. Reward amounts: depleted=3000 tokens, impression=1500 tokens. |
| `conversation_window_manager.dart` | Manages conversation context window. Trims old messages to stay within token limits. Tracks bonus tokens. Exports `TokenUsageInfo` class with current/max token state. |
| `system_prompt_builder.dart` | Builds the full system prompt with saju analysis data. Assembles: date + persona + base prompt + profile info + saju 8-char + ohaeng + compatibility data. See detailed flow below. |
| `sse_stream_client.dart` | SSE streaming client for Gemini Edge Function (`ai-gemini`). Parses `text/event-stream` responses into dart Stream. |
| `token_counter.dart` | Estimates token counts for messages. Used by conversation_window_manager for trimming decisions. |
| `ai_summary_prompt_builder.dart` | Builds prompts for AI summary generation (legacy). |
| `chat_realtime_service.dart` | Supabase Realtime subscription for chat updates. |
| `message_queue_service.dart` | Queues messages for retry on network failure. |

## System Prompt Assembly Order

```
system_prompt_builder.dart builds prompt in this order:
  1. Current date + ganzi (heavenly stems)
  2. Persona instructions
  3. Base prompt (saju.md or compatibility.md)
  4. Person1 profile (name, gender, birth, age)
  5. Person1 saju 8-char table + ohaeng + yongshin
  6. AI Summary (GPT-5.2 cached analysis)
  7. Person2 profile (compatibility mode only)
  8. Person2 saju 8-char (compatibility mode only)
  9. Compatibility analysis results (scores, pair_hapchung)
 10. Response format instructions
 11. Closing instructions
```

## Ad Trigger Flow

```
User sends message
    |
ad_trigger_service.checkTrigger(tokenUsageInfo)
    |
    +-- 80% threshold -> AdTrigger.native (show native ad bubble)
    +-- 100% threshold -> AdTrigger.rewarded (show rewarded ad offer)
    +-- Every 3 messages -> AdTrigger.interval (inline ad)
    +-- Otherwise -> AdTrigger.none
```

## Compatibility Chat Prompt Flow

See the detailed data flow for compatibility (2-person) chat mode:
- Person selection -> chat_mentions table -> auto-restore on subsequent messages
- v8.0 fix: chat_mentions auto-recovery prevents mode reset after first message

## Connections

- **Upstream**: `datasources/` call these services for prompt building and streaming
- **Downstream**: `presentation/providers/chat_provider.dart` is the main consumer
- **AI module**: `AI/jina/personas/` for persona text, `AI/services/` for compatibility calculation
- **Supabase tables**: `saju_profiles`, `saju_analyses`, `compatibility_analyses`, `chat_mentions`
