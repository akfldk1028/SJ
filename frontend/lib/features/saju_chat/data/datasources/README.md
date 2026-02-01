# saju_chat/data/datasources

Data sources for AI communication. Handles Edge Function calls, direct API calls, and the orchestration pipeline.

## Key Files

| File | Purpose |
|------|---------|
| `ai_pipeline_manager.dart` | Orchestrates the full AI pipeline: GPT-5.2 saju analysis (background) -> poll for result -> inject into Gemini system prompt -> Gemini streaming chat. Entry point for all AI-powered chat. |
| `gemini_edge_datasource.dart` | Calls `ai-gemini` Edge Function via Supabase. Supports both streaming (SSE) and non-streaming modes. Main production chat path. |
| `gemini_rest_datasource.dart` | Direct Gemini API call (fallback/local dev). Has thought part filtering (v25). Bypasses Edge Function for faster local iteration. |
| `openai_edge_datasource.dart` | Calls `ai-openai` Edge Function for saju analysis. Uses background mode: sends request -> receives task_id -> polls `ai-openai-result` for completion. |
| `openai_datasource.dart` | Direct OpenAI API call (fallback). |
| `saju_chat_edge_datasource.dart` | Legacy combined saju+chat edge function call. |
| `chat_local_datasource.dart` | Hive local storage for chat messages (offline cache). |
| `chat_session_local_datasource.dart` | Hive local storage for chat sessions. |

## AI Pipeline Flow

```
ai_pipeline_manager.dart orchestrates:

1. GPT-5.2 Analysis (background)
   openai_edge_datasource -> ai-openai Edge Function
       -> Returns task_id immediately
       -> Polls ai-openai-result until completed
       -> Returns saju analysis text

2. Gemini Conversation (streaming)
   gemini_edge_datasource -> ai-gemini Edge Function
       -> System prompt includes GPT analysis result
       -> SSE streaming response
       -> Real-time text to UI via StreamController
```

## Production vs Development

| Mode | GPT Path | Gemini Path |
|------|----------|-------------|
| Production | `openai_edge_datasource` -> Edge Function | `gemini_edge_datasource` -> Edge Function |
| Local Dev | `openai_datasource` -> Direct API | `gemini_rest_datasource` -> Direct API |

## Connections

- **Upstream**: `presentation/providers/chat_provider.dart` calls `ai_pipeline_manager`
- **Downstream**: Supabase Edge Functions (`ai-openai`, `ai-openai-result`, `ai-gemini`)
- **Services**: Uses `system_prompt_builder.dart` for prompt construction, `sse_stream_client.dart` for streaming
- **Local storage**: `chat_local_datasource` and `chat_session_local_datasource` for Hive caching
