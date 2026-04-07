import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * OpenAI API 호출 Edge Function
 *
 * v103 변경사항 (2026-04-07):
 * - Qwen 3.5 Flash 라우팅 추가 (DashScope OpenAI 호환 API)
 *   → model이 "qwen"으로 시작하면 DashScope로 라우팅
 *   → json_schema → json_object 자동 변환 + 스키마 프롬프트 주입
 *   → GPT-5-mini 대비 output 5배 저렴 ($2.00 → $0.40/1M)
 *   → 실패 시 GPT fallback
 *
 * v62 변경사항 (2026-03-22):
 * - 스케일링: collectStreamResponse() SSE 라인 버퍼링 수정
 *   → 청크 경계에서 불완전한 SSE 라인이 JSON.parse 실패하던 문제 해결
 *   → json_schema + stream:true 안정화 (수만 명 동시 사용 대비)
 *   → buffer 패턴: 마지막 불완전 라인 보관 → 다음 청크에서 결합
 *   → 루프 종료 후 잔여 버퍼 파싱 추가
 *
 * v56 변경사항 (2026-03-22):
 * - BUG FIX: MODEL_PRICING에 gpt-5.2-thinking 누락 → gpt-5.2 가격($1.75/$14.00) fallback 적용
 *   → 실제 saju_analysis는 gpt-5-mini phase 1-4로 실행되는데, parent task(gpt-5.2-thinking)가
 *     gpt-5.2 가격으로 비용 기록 → DB gpt_cost_usd가 실제 비용의 ~7배 부풀림
 *   → 수정1: gpt-5.2-thinking을 MODEL_PRICING에 명시적 추가
 *   → 수정2: fallback을 gpt-5.2 → gpt-5-mini로 변경 (알 수 없는 모델은 저가로 추산)
 *
 * v51 변경사항 (2026-02-11):
 * - 모델별 가격 상수 (MODEL_PRICING) + getModelCost() 함수 추가
 *   → gpt-5-mini 등 다른 모델 사용 시 비용이 정확하게 기록됨
 *   → 기존: gpt-5.2 가격($1.75/$14.00) 하드코딩 → 수정: 모델별 동적 계산
 *
 * v50 변경사항 (2026-02-09):
 * - v44(locale) + v48(stuck 정리) + v49(fortune 스킵) 통합 머지
 * - locale 파라미터 추가 (default: 'ko') - 다국어 지원
 * - 중복 task 감지에 locale 필터 추가 (같은 task_type이라도 locale 다르면 별개)
 * - ai_tasks INSERT에 locale 포함
 * - QUOTA_EXCEEDED 메시지 locale별 분기 (ko/ja/en)
 * - v48: 10분 초과 stuck task 자동 failed 처리
 * - v49: fortune task completed 재사용 스킵 (프롬프트 버전 변경 대응)
 *
 * v40 변경사항 (2026-02-01):
 * - checkQuota: rewarded_tokens_earned 포함 (광고 보상 토큰 반영)
 * - recordTokenUsage: daily_quota 덮어쓰기 제거 (광고 보상 증가값 보존)
 *
 * v39 변경사항 (2026-02-01):
 * - 운세 분석(fortune) task_type은 쿼터 체크 면제
 *   (saju_analysis, monthly_fortune, yearly_2025, yearly_2026 등)
 *   운세는 핵심 콘텐츠이며 1회성 캐시 → 쿼터로 차단하면 안 됨
 * - 중복 실행 방지 강화: completed 상태 task도 재사용
 *   오늘 같은 task_type으로 completed된 결과가 있으면 새 task 생성 안 하고 재사용
 *   → 앱이 결과 저장 실패 시 반복 호출해도 토큰 중복 차감 안 됨
 *
 * v38 변경사항 (2026-02-01):
 * - task_type별 토큰 컬럼 라우팅 (getTokenColumnForTaskType)
 *
 * v37 변경사항 (2026-02-01):
 * - isAdminUser: is_primary → profile_type = 'primary'
 * - recordTokenUsage: gpt_saju_analysis_tokens → saju_analysis_tokens
 *
 * v36 변경사항 (2026-02-01):
 * - collectStreamResponse에서 reasoning_content 필터링 추가
 *
 * v32 변경사항 (2026-01-30):
 * - API Key 로드밸런싱 적용 (Round-Robin + Fallback)
 *
 * === 기본 모델: gpt-5.2 ===
 * 클라이언트에서 model 파라미터로 다른 모델 지정 가능 (gpt-5-mini 등)
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// v32: API Key Load Balancing (Round-Robin + Fallback)
const API_KEYS = [
  Deno.env.get("OPENAI_API_KEY"),
  Deno.env.get("OPENAI_API_KEY_2"),
  Deno.env.get("OPENAI_API_KEY_3"),
].filter(Boolean) as string[];

let keyIndex = 0;

function getNextApiKey(): string {
  if (API_KEYS.length === 0) throw new Error("No OPENAI_API_KEY configured");
  const key = API_KEYS[keyIndex % API_KEYS.length];
  keyIndex++;
  return key;
}

function getApiKeyByIndex(idx: number): string {
  if (API_KEYS.length === 0) throw new Error("No OPENAI_API_KEY configured");
  return API_KEYS[idx % API_KEYS.length];
}

function getKeyIndexByTaskType(taskType: string): number {
  let hash = 0;
  for (let i = 0; i < taskType.length; i++) {
    hash = ((hash << 5) - hash) + taskType.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash) % API_KEYS.length;
}

const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";
const OPENAI_CHAT_URL = "https://api.openai.com/v1/chat/completions";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// v103: Qwen 3.5 Flash (DashScope 싱가포르) — saju_base 비용 절감용
const QWEN_API_KEY = Deno.env.get("QWEN_API_KEY");
const QWEN_BASE_URL = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1";

const DAILY_QUOTA = 4000;
const ADMIN_QUOTA = 1000000000;

// v56: 모델별 가격 ($/1M tokens)
// ※ 새 모델 추가 시 반드시 여기에 등록! 미등록 모델은 gpt-5-mini 가격으로 fallback
const MODEL_PRICING: Record<string, { input: number; output: number }> = {
  'gpt-5.2':           { input: 1.75,  output: 14.00 },
  'gpt-5.2-thinking':  { input: 1.75,  output: 14.00 },  // v56: parent orchestrator용 (실제 토큰=0이지만 명시)
  'gpt-5-mini':        { input: 0.25,  output: 2.00 },
  'gpt-4o':            { input: 2.50,  output: 10.00 },
  'gpt-4o-mini':       { input: 0.15,  output: 0.60 },
  'qwen3.5-flash':     { input: 0.10,  output: 0.40 },  // v103: DashScope 싱가포르
};

function getModelCost(model: string, promptTokens: number, completionTokens: number): number {
  // v56: fallback을 gpt-5.2 → gpt-5-mini로 변경 (미등록 모델은 저가로 추산)
  const pricing = MODEL_PRICING[model] || MODEL_PRICING['gpt-5-mini'];
  return (promptTokens * pricing.input / 1000000) + (completionTokens * pricing.output / 1000000);
}

/** KST(UTC+9) 기준 오늘 날짜 (YYYY-MM-DD) */
function getTodayKST(): string {
  return new Date().toLocaleString("sv-SE", { timeZone: "Asia/Seoul" }).split(" ")[0];
}

// v39: 쿼터 면제 task_type 목록
// 운세 분석은 핵심 콘텐츠 (1회성 캐시) → 쿼터로 차단하면 안 됨
const QUOTA_EXEMPT_TASK_TYPES = new Set([
  'saju_analysis',
  'saju_base',
  'saju_base_phase1',
  'saju_base_phase2',
  'saju_base_phase3',
  'saju_base_phase4',
  'monthly_fortune',
  'yearly_2025',
  'yearly_2026',
]);

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface OpenAIRequest {
  messages: ChatMessage[];
  model: string;
  max_tokens?: number;
  temperature?: number;
  response_format?: { type: string; json_schema?: Record<string, unknown> };
  user_id?: string;
  run_in_background?: boolean;
  task_type?: string;
  reasoning_effort?: string;  // "low" | "medium" | "high" (default: "medium")
  locale?: string;  // "ko" | "ja" | "en" (default: "ko") - v50: 다국어 지원
}

interface UsageInfo {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
  prompt_tokens_details?: {
    cached_tokens?: number;
  };
}

// v62: isAdmin + checkQuota를 1 RPC로 통합 (DB 쿼리 3~4개 → 1개)
// 수만 명 스케일링 대비: DB 연결 수 50% 감소
async function checkUserAccess(
  supabase: ReturnType<typeof createClient>,
  userId: string
): Promise<{ isAdmin: boolean; allowed: boolean; remaining: number; quotaLimit: number }> {
  const today = getTodayKST();
  try {
    const { data, error } = await supabase.rpc('check_user_access', {
      p_user_id: userId,
      p_today: today,
    });
    if (error || !data) {
      console.warn(`[ai-openai v62] check_user_access RPC error: ${error?.message}`);
      return { isAdmin: false, allowed: true, remaining: DAILY_QUOTA, quotaLimit: DAILY_QUOTA };
    }
    return {
      isAdmin: data.is_admin || false,
      allowed: data.allowed ?? true,
      remaining: data.remaining ?? DAILY_QUOTA,
      quotaLimit: data.quota_limit ?? DAILY_QUOTA,
    };
  } catch {
    return { isAdmin: false, allowed: true, remaining: DAILY_QUOTA, quotaLimit: DAILY_QUOTA };
  }
}

function getTokenColumnForTaskType(taskType: string): string {
  if (taskType === 'monthly_fortune') return 'monthly_fortune_tokens';
  if (taskType === 'yearly_2025') return 'yearly_fortune_2025_tokens';
  if (taskType === 'yearly_2026') return 'yearly_fortune_2026_tokens';
  return 'saju_analysis_tokens';
}

// v62: 원자적 UPSERT RPC — race condition 제거, DB 쿼리 2→1개
async function recordTokenUsage(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  promptTokens: number,
  completionTokens: number,
  cost: number,
  isAdmin: boolean,
  taskType: string = 'saju_analysis'
): Promise<void> {
  const today = getTodayKST();
  const totalTokens = promptTokens + completionTokens;
  const tokenColumn = getTokenColumnForTaskType(taskType);
  console.log(`[ai-openai v62] Recording ${totalTokens} tokens to ${tokenColumn} (task_type: ${taskType})`);
  try {
    await supabase.rpc('increment_token_usage', {
      p_user_id: userId,
      p_usage_date: today,
      p_column_name: tokenColumn,
      p_tokens: totalTokens,
      p_gpt_cost: cost,
      p_gemini_cost: 0,
      p_daily_quota: isAdmin ? ADMIN_QUOTA : DAILY_QUOTA,
    });
  } catch (error) {
    console.error("[ai-openai v62] Failed to record token usage:", error);
  }
}

// v62: SSE 라인 버퍼링 수정 — 청크 경계에서 불완전한 라인 보존
// 수만 명 스케일링 대비: json_schema + stream:true 안정화
// 이전(v59): chunk.split("\n") 시 마지막 불완전 라인이 JSON.parse 실패
// 수정: buffer에 불완전 라인 보관 → 다음 청크에서 결합
async function collectStreamResponse(response: Response): Promise<{ content: string; usage: UsageInfo | null; finishReason: string | null }> {
  const reader = response.body?.getReader();
  if (!reader) throw new Error("No response body");
  const decoder = new TextDecoder();
  let content = "";
  let usage: UsageInfo | null = null;
  let finishReason: string | null = null;
  let buffer = "";  // v62: 불완전 라인 버퍼

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() || "";  // v62: 마지막 불완전 라인은 버퍼에 보관
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith("data: ")) continue;
      const data = trimmed.slice(6);
      if (data === "[DONE]") continue;
      try {
        const parsed = JSON.parse(data);
        const delta = parsed.choices?.[0]?.delta;
        if (delta) {
          if (delta.content) content += delta.content;
        }
        // v41: capture actual finish_reason
        if (parsed.choices?.[0]?.finish_reason) {
          finishReason = parsed.choices[0].finish_reason;
        }
        if (parsed.usage) usage = parsed.usage;
      } catch { /* ignore — 다음 청크에서 완성될 수 있음 */ }
    }
  }

  // v62: 루프 종료 후 잔여 버퍼 처리
  if (buffer.trim().startsWith("data: ")) {
    const data = buffer.trim().slice(6);
    if (data !== "[DONE]") {
      try {
        const parsed = JSON.parse(data);
        const delta = parsed.choices?.[0]?.delta;
        if (delta?.content) content += delta.content;
        if (parsed.choices?.[0]?.finish_reason) finishReason = parsed.choices[0].finish_reason;
        if (parsed.usage) usage = parsed.usage;
      } catch { /* ignore */ }
    }
  }

  return { content, usage, finishReason };
}

/**
 * v103: Qwen 3.5 Flash Non-Streaming 호출 (saju_base 비용 절감용)
 * - DashScope OpenAI 호환 API (싱가포르)
 * - json_schema → json_object 자동 변환
 * - 실패 시 null 반환 → GPT fallback
 */
async function callQwenSajuBase(
  messages: ChatMessage[],
  maxTokens: number,
  temperature: number,
  responseFormat?: { type: string; json_schema?: Record<string, unknown> },
): Promise<{ content: string; usage: { prompt_tokens: number; completion_tokens: number; cached_tokens: number } } | null> {
  if (!QWEN_API_KEY) {
    console.log("[ai-openai v103] No QWEN_API_KEY, skipping Qwen");
    return null;
  }
  try {
    // json_schema → json_object 변환 + 스키마를 system prompt에 주입
    const qwenMessages: { role: string; content: unknown }[] = [];
    let schemaInjection = "";
    if (responseFormat?.type === "json_schema" && responseFormat.json_schema) {
      const schema = responseFormat.json_schema;
      schemaInjection = `\n\n## JSON Output Schema (MUST follow exactly)\nRespond with a single JSON object matching this schema. Every field is required. Do not add extra fields.\n\`\`\`json\n${JSON.stringify(schema.schema || schema, null, 0)}\n\`\`\``;
    }

    for (const m of messages) {
      if (m.role === "system") {
        // system prompt에 스키마 주입 + cache_control 마커
        qwenMessages.push({
          role: "system",
          content: [{ type: "text", text: m.content + schemaInjection, cache_control: { type: "ephemeral" } }],
        });
      } else {
        qwenMessages.push({ role: m.role, content: m.content });
      }
    }

    const body: Record<string, unknown> = {
      model: "qwen3.5-flash",
      messages: qwenMessages,
      max_tokens: maxTokens,
      temperature,
      stream: false,
      enable_thinking: false,
      response_format: { type: "json_object" },
    };

    console.log("[ai-openai v103] Calling Qwen 3.5 Flash for saju_base...");
    const resp = await fetch(`${QWEN_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${QWEN_API_KEY}` },
      body: JSON.stringify(body),
    });

    if (!resp.ok) {
      const errText = await resp.text();
      console.error(`[ai-openai v103] Qwen error ${resp.status}: ${errText}`);
      return null;
    }

    const data = await resp.json();
    const choice = data.choices?.[0];
    if (!choice?.message?.content) {
      console.error("[ai-openai v103] Qwen: no content in response");
      return null;
    }

    const content = choice.message.content;
    const usage = data.usage || {};

    // 19필드 검증 (saju_base 스키마)
    try {
      const parsed = JSON.parse(content);
      const requiredKeys = [
        'mySajuIntro', 'my_saju_characters', 'wonGuk_analysis',
        'sipsung_analysis', 'hapchung_analysis', 'personality', 'lucky_elements',
        'wealth', 'career', 'business', 'love', 'marriage',
        'sinsal_gilseong', 'health', 'daeun_detail',
        'summary', 'life_cycles', 'peak_years', 'modern_interpretation',
      ];
      const missingKeys = requiredKeys.filter(k => !(k in parsed));
      if (missingKeys.length > 0) {
        console.error(`[ai-openai v103] Qwen JSON missing ${missingKeys.length} keys: ${missingKeys.join(', ')}`);
        return null;  // fallback to GPT
      }
      console.log(`[ai-openai v103] Qwen JSON validated: all 19 keys present`);
    } catch (e) {
      console.error(`[ai-openai v103] Qwen JSON parse failed: ${e}`);
      return null;  // fallback to GPT
    }

    return {
      content,
      usage: {
        prompt_tokens: usage.prompt_tokens || 0,
        completion_tokens: usage.completion_tokens || 0,
        cached_tokens: usage.prompt_tokens_details?.cached_tokens || usage.cached_tokens || 0,
      },
    };
  } catch (e) {
    console.error(`[ai-openai v103] Qwen call failed: ${e}`);
    return null;
  }
}

async function processInBackground(
  taskId: string,
  messages: ChatMessage[],
  model: string,
  maxTokens: number,
  temperature: number,
  responseFormat: { type: string } | undefined,
  userId: string | undefined,
  isAdmin: boolean,
  taskType: string = 'saju_analysis',
  reasoningEffort: string = 'medium'
): Promise<void> {
  const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
  try {
    await supabase.from("ai_tasks").update({ status: "processing", started_at: new Date().toISOString() }).eq("id", taskId);
    console.log(`[ai-openai v50] Background task ${taskId}: Starting OpenAI call (reasoning_effort: ${reasoningEffort})`);
    const startTime = Date.now();
    const requestBody: Record<string, unknown> = {
      model, messages, max_completion_tokens: maxTokens,
      reasoning_effort: reasoningEffort, stream: true, stream_options: { include_usage: true },
    };
    if (responseFormat) requestBody.response_format = responseFormat;
    let response: Response | null = null;
    for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
      const currentKey = getNextApiKey();
      const currentKeyIdx = (keyIndex - 1) % API_KEYS.length;
      console.log(`[ai-openai v32] Background sync: Using API key ${currentKeyIdx + 1}/${API_KEYS.length}`);
      response = await fetch(OPENAI_CHAT_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${currentKey}` },
        body: JSON.stringify(requestBody),
      });
      if (response.status === 429) { console.warn(`[ai-openai v32] Key ${currentKeyIdx + 1} rate limited, trying next...`); continue; }
      break;
    }
    if (!response) throw new Error("All API keys exhausted");
    if (!response.ok) { const errorData = await response.json(); throw new Error(errorData.error?.message || "OpenAI API error"); }
    const { content, usage, finishReason } = await collectStreamResponse(response);
    const elapsed = Date.now() - startTime;
    if (!content) throw new Error("No response from OpenAI");
    const promptTokens = usage?.prompt_tokens || 0;
    const completionTokens = usage?.completion_tokens || 0;
    const cachedTokens = usage?.prompt_tokens_details?.cached_tokens || 0;
    const cost = getModelCost(model, promptTokens, completionTokens);

    // v41: warn on truncated responses
    if (finishReason === "length") {
      console.warn(`[ai-openai] WARNING: Response truncated (max_tokens reached) for task ${taskId}`);
    }

    if (userId && promptTokens > 0) {
      await recordTokenUsage(supabase, userId, promptTokens, completionTokens, cost, isAdmin, taskType);
    }
    await supabase.from("ai_tasks").update({
      status: "completed",
      result_data: { success: true, content, usage: { prompt_tokens: promptTokens, completion_tokens: completionTokens, total_tokens: promptTokens + completionTokens, cached_tokens: cachedTokens }, model, finish_reason: finishReason || "stop", is_admin: isAdmin, elapsed_ms: elapsed },
      completed_at: new Date().toISOString(),
    }).eq("id", taskId);
    console.log(`[ai-openai] Background task ${taskId}: Completed successfully (finish_reason: ${finishReason || "stop"})`);
  } catch (error) {
    console.error(`[ai-openai] Background task ${taskId}: Error:`, error);
    await supabase.from("ai_tasks").update({
      status: "failed", error_message: error instanceof Error ? error.message : "Unknown error", completed_at: new Date().toISOString(),
    }).eq("id", taskId);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (API_KEYS.length === 0) throw new Error("No OPENAI_API_KEY configured");

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
    const requestData: OpenAIRequest = await req.json();
    const {
      messages,
      model: requestModel = "gpt-5.2",
      max_tokens = 10000,
      temperature = 0.7,
      response_format,
      user_id,
      run_in_background = true,
      task_type = "saju_analysis",
      reasoning_effort = "medium",
      locale = "ko",
    } = requestData;
    let model = requestModel;  // v103: Qwen fallback 시 재할당 필요

    console.log(`[ai-openai v50] Request: run_in_background=${run_in_background}, model=${model}, task_type=${task_type}, reasoning_effort=${reasoning_effort}, locale=${locale}, user_id=${user_id}`);

    if (!messages || messages.length === 0) throw new Error("messages is required");

    // v62: isAdmin + checkQuota를 1 RPC로 통합 (DB 쿼리 3~4개 → 1개)
    let isAdmin = false;
    if (user_id) {
      const access = await checkUserAccess(supabase, user_id);
      isAdmin = access.isAdmin;
      console.log(`[ai-openai v62] User ${user_id} isAdmin: ${isAdmin}, allowed: ${access.allowed}`);

      // v39: 운세 분석은 쿼터 면제 (핵심 콘텐츠, 1회성 캐시)
      const isQuotaExempt = QUOTA_EXEMPT_TASK_TYPES.has(task_type);

      if (!isAdmin && !isQuotaExempt && !access.allowed) {
        console.log(`[ai-openai v62] Quota exceeded for user ${user_id} (task_type: ${task_type}, locale: ${locale})`);
        const quotaMessages: Record<string, string> = {
          ko: "오늘 사용 가능한 토큰을 모두 사용했습니다. 광고를 시청하면 추가 토큰을 받을 수 있습니다.",
          ja: "本日のトークンをすべて使用しました。広告を視聴すると追加トークンを獲得できます。",
          en: "You've used all available tokens for today. Watch an ad to earn additional tokens.",
        };
        return new Response(
          JSON.stringify({
            success: false,
            error: "QUOTA_EXCEEDED",
            message: quotaMessages[locale] || quotaMessages.ko,
            tokens_used: DAILY_QUOTA - access.remaining,
            quota_limit: access.quotaLimit,
            ads_required: true,
          }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      } else if (isQuotaExempt) {
        console.log(`[ai-openai v62] Quota check SKIPPED for ${task_type} (fortune exempt)`);
      }
    }

    // === v103: Qwen 라우팅 (model이 "qwen"으로 시작하면) ===
    if (model.startsWith("qwen")) {
      console.log(`[ai-openai v103] *** QWEN MODE *** model=${model}`);
      const qwenResult = await callQwenSajuBase(messages, max_tokens, temperature, response_format);
      if (qwenResult) {
        const { content, usage } = qwenResult;
        const cost = getModelCost("qwen3.5-flash", usage.prompt_tokens, usage.completion_tokens);
        if (user_id && usage.prompt_tokens > 0) {
          await recordTokenUsage(supabase, user_id, usage.prompt_tokens, usage.completion_tokens, cost, isAdmin, task_type);
        }
        console.log(`[ai-openai v103] Qwen success: ${usage.prompt_tokens}+${usage.completion_tokens} tokens, $${cost.toFixed(6)}`);
        return new Response(
          JSON.stringify({
            success: true, content,
            usage: { prompt_tokens: usage.prompt_tokens, completion_tokens: usage.completion_tokens, total_tokens: usage.prompt_tokens + usage.completion_tokens, cached_tokens: usage.cached_tokens },
            model: "qwen3.5-flash", finish_reason: "stop", is_admin: isAdmin,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      // Qwen 실패 → GPT-5-mini fallback
      console.warn("[ai-openai v103] Qwen failed, falling back to gpt-5-mini sync mode");
      model = "gpt-5-mini";
    }

    // === Background 모드 ===
    if (run_in_background && !model.startsWith("qwen")) {
      console.log(`[ai-openai v50] *** RESPONSES API BACKGROUND MODE ***`);

      if (user_id) {
        // v50: 중복 방지 (v44 locale + v48 stuck 정리 + v49 fortune 스킵 통합)
        // 1단계: 진행 중인 task 체크 (v48: 10분 이내 + v44: locale 필터)
        const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
        const { data: inProgressTask } = await supabase
          .from("ai_tasks")
          .select("id, status, openai_response_id, created_at")
          .eq("user_id", user_id)
          .eq("task_type", task_type)
          .eq("locale", locale)
          .in("status", ["pending", "processing", "queued", "in_progress"])
          .gte("created_at", tenMinutesAgo)
          .order("created_at", { ascending: false })
          .limit(1)
          .single();

        if (inProgressTask) {
          console.log(`[ai-openai v50] Found recent in-progress ${task_type} task ${inProgressTask.id} (${inProgressTask.status}, locale: ${locale})`);
          return new Response(
            JSON.stringify({
              success: true,
              task_id: inProgressTask.id,
              openai_response_id: inProgressTask.openai_response_id,
              status: inProgressTask.status,
              message: `Existing ${task_type} task in progress. Poll /ai-openai-result with task_id.`,
              reused: true,
            }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // v48: 10분 초과 stuck tasks 자동 정리 (v50: locale 필터 추가)
        const { data: stuckTasks } = await supabase
          .from("ai_tasks")
          .select("id")
          .eq("user_id", user_id)
          .eq("task_type", task_type)
          .eq("locale", locale)
          .in("status", ["pending", "processing", "queued", "in_progress"])
          .lt("created_at", tenMinutesAgo);

        if (stuckTasks && stuckTasks.length > 0) {
          const stuckIds = stuckTasks.map((t: any) => t.id);
          console.log(`[ai-openai v50] Auto-cleanup ${stuckIds.length} stuck ${task_type} tasks: ${stuckIds.join(", ")}`);
          await supabase
            .from("ai_tasks")
            .update({ status: "failed", error_message: "Auto-cleanup: stuck > 10min (v50)" })
            .in("id", stuckIds);
        }

        // 2단계: 오늘 완료된 task 재사용 (v49: fortune 제외 + v44: locale 필터)
        // fortune 태스크는 completed 재사용 스킵!
        // 이유: 프롬프트 버전 업데이트 시 옛 결과 재사용 버그 방지
        // fortune 캐시는 Flutter ai_summaries에서 prompt_version으로 관리
        const isFortuneTask = QUOTA_EXEMPT_TASK_TYPES.has(task_type);
        if (!isFortuneTask) {
          const today = getTodayKST();
          const { data: completedTask } = await supabase
            .from("ai_tasks")
            .select("id, status, openai_response_id, result_data, completed_at")
            .eq("user_id", user_id)
            .eq("task_type", task_type)
            .eq("locale", locale)
            .eq("status", "completed")
            .gte("completed_at", `${today}T00:00:00Z`)
            .order("completed_at", { ascending: false })
            .limit(1)
            .single();

          if (completedTask) {
            console.log(`[ai-openai v50] Found today's completed ${task_type} task ${completedTask.id} → reusing (locale: ${locale})`);
            return new Response(
              JSON.stringify({
                success: true,
                task_id: completedTask.id,
                openai_response_id: completedTask.openai_response_id,
                status: "completed",
                message: `Reusing today's completed ${task_type} task. Poll /ai-openai-result with task_id.`,
                reused: true,
              }),
              { headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
          }
        } else {
          console.log(`[ai-openai v50] Fortune task ${task_type} → skip completed reuse (prompt version may have changed)`);
        }
      }

      // messages를 Responses API input 형식으로 변환
      let systemContent = "";
      let userContent = "";
      for (const msg of messages) {
        if (msg.role === "system") systemContent = msg.content;
        else if (msg.role === "user") userContent = msg.content;
      }
      const inputText = systemContent
        ? `[System Instructions]\n${systemContent}\n\n[User Request]\n${userContent}`
        : userContent;

      console.log(`[ai-openai v50] Calling OpenAI Responses API...`);

      const responsesApiBody: Record<string, unknown> = {
        model, input: inputText, background: true, store: true, max_output_tokens: max_tokens,
        reasoning: { effort: reasoning_effort },  // v43: reasoning_effort 지원
      };
      // v62: json_schema strict 모드도 Background에서 지원
      if (response_format?.type === "json_schema") {
        responsesApiBody.text = { format: response_format };
      } else if (response_format?.type === "json_object") {
        responsesApiBody.text = { format: { type: "json_object" } };
      }

      let openaiResponse: Response | null = null;
      let selectedKeyIndex = getKeyIndexByTaskType(task_type);
      for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
        const currentKey = getApiKeyByIndex(selectedKeyIndex + attempt);
        const actualKeyIdx = (selectedKeyIndex + attempt) % API_KEYS.length;
        console.log(`[ai-openai v50] Using API key ${actualKeyIdx + 1}/${API_KEYS.length} (task: ${task_type})`);
        openaiResponse = await fetch(OPENAI_RESPONSES_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json", "Authorization": `Bearer ${currentKey}` },
          body: JSON.stringify(responsesApiBody),
        });
        if (openaiResponse.status === 429) { console.warn(`[ai-openai v50] Key ${actualKeyIdx + 1} rate limited (429), trying next key...`); continue; }
        break;
      }
      if (!openaiResponse) throw new Error("All API keys exhausted (rate limited)");

      const responseData = await openaiResponse.json();
      console.log(`[ai-openai v50] OpenAI response status: ${openaiResponse.status}`);

      if (!openaiResponse.ok) {
        console.error("[ai-openai v50] OpenAI Responses API Error:", responseData);
        throw new Error(responseData.error?.message || "OpenAI Responses API error");
      }

      const openaiResponseId = responseData.id;
      const openaiStatus = responseData.status;
      console.log(`[ai-openai v50] Got OpenAI response_id: ${openaiResponseId}, status: ${openaiStatus}`);

      const { data: task, error: insertError } = await supabase
        .from("ai_tasks")
        .insert({
          user_id: user_id || null,
          task_type: task_type,
          locale: locale,
          status: openaiStatus,
          openai_response_id: openaiResponseId,
          request_data: { messages, model, max_tokens, response_format, task_type, reasoning_effort, locale, key_index: selectedKeyIndex },
          model,
          phase: 1,
          total_phases: 4,
          partial_result: {},
          started_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (insertError || !task) {
        console.error("[ai-openai v50] Failed to create task:", insertError);
        throw new Error("Failed to create task record");
      }

      console.log(`[ai-openai v50] Created ${task_type} task ${task.id} with openai_response_id ${openaiResponseId}`);

      return new Response(
        JSON.stringify({
          success: true,
          task_id: task.id,
          openai_response_id: openaiResponseId,
          status: openaiStatus,
          phase: 1,
          total_phases: 4,
          message: "Analysis started in OpenAI cloud. Poll /ai-openai-result with task_id.",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // === Sync 모드 ===
    console.log(`[ai-openai v50] *** SYNC MODE *** (reasoning_effort: ${reasoning_effort})`);
    const requestBody: Record<string, unknown> = {
      model, messages, max_completion_tokens: max_tokens,
      reasoning_effort: reasoning_effort, stream: true, stream_options: { include_usage: true },
    };
    if (response_format) requestBody.response_format = response_format;

    const startTime = Date.now();
    let response: Response | null = null;
    const syncKeyStart = getKeyIndexByTaskType(task_type);
    for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
      const currentKey = getApiKeyByIndex(syncKeyStart + attempt);
      const actualKeyIdx = (syncKeyStart + attempt) % API_KEYS.length;
      console.log(`[ai-openai v50] Sync: Using API key ${actualKeyIdx + 1}/${API_KEYS.length} (task: ${task_type})`);
      response = await fetch(OPENAI_CHAT_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${currentKey}` },
        body: JSON.stringify(requestBody),
      });
      if (response.status === 429) { console.warn(`[ai-openai v50] Key ${actualKeyIdx + 1} rate limited, trying next...`); continue; }
      break;
    }
    if (!response) throw new Error("All API keys exhausted (rate limited)");

    if (!response.ok) {
      const errorData = await response.json();
      return new Response(
        JSON.stringify({ success: false, error: errorData.error?.message || "OpenAI API error" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { content, usage, finishReason } = await collectStreamResponse(response);
    const elapsed = Date.now() - startTime;
    if (!content) throw new Error("No response from OpenAI");

    // v41: warn on truncated responses
    if (finishReason === "length") {
      console.warn(`[ai-openai] WARNING: Sync response truncated (max_tokens reached)`);
    }

    const promptTokens = usage?.prompt_tokens || 0;
    const completionTokens = usage?.completion_tokens || 0;
    const cachedTokens = usage?.prompt_tokens_details?.cached_tokens || 0;
    const cost = getModelCost(model, promptTokens, completionTokens);
    if (user_id && promptTokens > 0) {
      await recordTokenUsage(supabase, user_id, promptTokens, completionTokens, cost, isAdmin, task_type);
    }

    return new Response(
      JSON.stringify({
        success: true, content,
        usage: { prompt_tokens: promptTokens, completion_tokens: completionTokens, total_tokens: promptTokens + completionTokens, cached_tokens: cachedTokens },
        model, finish_reason: finishReason || "stop", is_admin: isAdmin,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[ai-openai v50] Error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
