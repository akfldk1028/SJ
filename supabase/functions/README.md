# Supabase Edge Functions

AI backend for Mantok saju chat service.

> **Last updated**: 2026-02-01 (DK)
> **Related docs**: `EdgeFunction_task.md` (deployment), `docs/04_data_models.md` (DB schema)

## Functions

| Function | Model | Version | Purpose |
|----------|-------|---------|---------|
| `ai-openai` | GPT-5.2 | **v42** | Saju analysis (background mode) |
| `ai-openai-result` | - | **v32** | Poll GPT background task results |
| `ai-gemini` | gemini-3-flash-preview | **v43** | Chat streaming (SSE) |
| `ai-openai-mini` | - | - | Lightweight OpenAI tasks |
| `ai-task-status` | - | - | Task status check endpoint |
| `generate-ai-summary` | gemini-2.0-flash | v4 | Legacy (do not use for new features) |
| `purchase-webhook` | - | - | Purchase verification webhook |

## ai-gemini (v43)

Gemini 3.0 Flash chat with SSE streaming.

- **Model**: `gemini-3-flash-preview`, max_tokens=16384, temperature=0.8
- **Streaming**: Server-Sent Events (SSE) for real-time response delivery
- **Token recording**: Records `gemini_cost_usd` directly. `chatting_tokens` and `chatting_message_count` recorded by Edge Function (no DB trigger).
- **Thought filtering**: Filters out Gemini thinking/reasoning content from streamed output
- **Buffer flush fix**: Ensures partial buffers are flushed on stream end
- **Quota**: Only `chatting_tokens` count toward daily quota. Fortune tokens (saju, monthly, yearly) are exempt.
- **Intent classification**: Uses `gemini-2.5-flash-lite` for intent detection (`countAsMessage: false`)

## ai-openai (v42)

GPT-5.2 saju analysis via Responses API background mode.

- **Model**: `gpt-5.2`, max_tokens=10000, reasoning_effort="medium"
- **Background mode**: Returns task_id immediately; client polls `ai-openai-result` for completion
- **Load balancing**: 3 API keys rotated randomly (`OPENAI_API_KEY`, `_2`, `_3`)
- **Quota exempt**: Fortune tasks (saju_base, monthly_fortune, yearly_2025, yearly_2026) skip quota check
- **Task reuse**: Reuses same-day completed tasks of same task_type to avoid duplicate API calls
- **Token recording**: `saju_analysis_tokens`, `gpt_cost_usd` to `user_daily_token_usage`
- **Reasoning filter**: `delta.reasoning_content` stripped from output (GPT thinking hidden)

## ai-openai-result (v32)

Polls OpenAI Responses API for background task completion.

- **Flow**: Receives task_id -> queries `ai_tasks` table -> calls OpenAI `/v1/responses/{id}` -> returns status or result
- **Phase-based progressive disclosure**: queued/in_progress -> "processing", completed -> full result
- **Reasoning output filtering**: Skips `type === "reasoning"` from both output and content arrays
- **Token column routing by task_type**:
  - `monthly_fortune` -> `monthly_fortune_tokens`
  - `yearly_2025` -> `yearly_fortune_2025_tokens`
  - `yearly_2026` -> `yearly_fortune_2026_tokens`
  - default -> `saju_analysis_tokens`
- **Flutter polling**: 120 attempts x 2s interval = max 4 min wait

## Architecture

```
Flutter App
  ai_pipeline_manager.dart
    1. POST ai-openai -> task_id
    2. Poll ai-openai-result -> GPT analysis
    3. POST ai-gemini (SSE) -> streaming chat
         |              |              |
    ai-openai      ai-openai-     ai-gemini
    GPT-5.2        result         Gemini 3.0
    Background     Polling        SSE Stream
         |              |              |
    OpenAI API     ai_tasks DB    Google Gemini API
```

## Environment Variables

```
OPENAI_API_KEY, OPENAI_API_KEY_2, OPENAI_API_KEY_3
GEMINI_API_KEY
SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
```

## DB Reference (user_daily_token_usage)

| Column | Source |
|--------|--------|
| `saju_analysis_tokens` | ai-openai-result |
| `chatting_tokens` | ai-gemini |
| `monthly_fortune_tokens` | ai-openai-result |
| `yearly_fortune_2025_tokens` | ai-openai-result |
| `yearly_fortune_2026_tokens` | ai-openai-result |
| `gpt_cost_usd` | ai-openai |
| `gemini_cost_usd` | ai-gemini |

## Deployment

```bash
npx supabase functions deploy ai-openai --project-ref kfciluyxkomskyxjaeat
npx supabase functions deploy ai-openai-result --project-ref kfciluyxkomskyxjaeat
npx supabase functions deploy ai-gemini --project-ref kfciluyxkomskyxjaeat
```

## Flutter Client Files

- `datasources/openai_edge_datasource.dart` - GPT calls + polling
- `datasources/gemini_edge_datasource.dart` - Gemini SSE streaming
- `datasources/ai_pipeline_manager.dart` - Full pipeline orchestration
- `services/sse_stream_client.dart` - SSE parser
