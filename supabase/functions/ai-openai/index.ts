import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * OpenAI API 호출 Edge Function
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
 * === 모델 변경 금지 ===
 * 이 Edge Function의 기본 모델은 반드시 gpt-5.2 유지
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

const DAILY_QUOTA = 20000;
const ADMIN_QUOTA = 1000000000;

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
  response_format?: { type: "json_object" | "text" };
  user_id?: string;
  run_in_background?: boolean;
  task_type?: string;
}

interface UsageInfo {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
  prompt_tokens_details?: {
    cached_tokens?: number;
  };
}

async function isAdminUser(supabase: ReturnType<typeof createClient>, userId: string): Promise<boolean> {
  try {
    const { data, error } = await supabase
      .from("saju_profiles")
      .select("relation_type")
      .eq("user_id", userId)
      .eq("profile_type", "primary")
      .single();
    if (error || !data) return false;
    return data.relation_type === "admin";
  } catch {
    return false;
  }
}

async function checkQuota(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  isAdmin: boolean
): Promise<{ allowed: boolean; remaining: number; quotaLimit: number }> {
  const quotaLimit = isAdmin ? ADMIN_QUOTA : DAILY_QUOTA;
  const today = getTodayKST();
  try {
    const { data: usage } = await supabase
      .from("user_daily_token_usage")
      .select("chatting_tokens, daily_quota, bonus_tokens, rewarded_tokens_earned, native_tokens_earned")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();
    // v42: chatting_tokens만 쿼터 대상, bonus_tokens + rewarded_tokens_earned + native_tokens_earned 포함
    const currentUsage = usage?.chatting_tokens || 0;
    const baseQuota = isAdmin ? ADMIN_QUOTA : (usage?.daily_quota || DAILY_QUOTA);
    const bonusTokens = usage?.bonus_tokens || 0;
    const rewardedTokens = usage?.rewarded_tokens_earned || 0;
    const nativeTokens = usage?.native_tokens_earned || 0;
    const effectiveQuota = baseQuota + bonusTokens + rewardedTokens + nativeTokens;
    const remaining = effectiveQuota - currentUsage;
    if (isAdmin) return { allowed: true, remaining: ADMIN_QUOTA, quotaLimit: ADMIN_QUOTA };
    if (currentUsage >= effectiveQuota) return { allowed: false, remaining: 0, quotaLimit: effectiveQuota };
    return { allowed: true, remaining, quotaLimit: effectiveQuota };
  } catch {
    return { allowed: true, remaining: quotaLimit, quotaLimit };
  }
}

function getTokenColumnForTaskType(taskType: string): string {
  if (taskType === 'monthly_fortune') return 'monthly_fortune_tokens';
  if (taskType === 'yearly_2025') return 'yearly_fortune_2025_tokens';
  if (taskType === 'yearly_2026') return 'yearly_fortune_2026_tokens';
  return 'saju_analysis_tokens';
}

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
  console.log(`[ai-openai v39] Recording ${totalTokens} tokens to ${tokenColumn} (task_type: ${taskType})`);
  try {
    const { data: existing } = await supabase
      .from("user_daily_token_usage")
      .select(`id, ${tokenColumn}, gpt_cost_usd`)
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();
    if (existing) {
      const updateData: Record<string, unknown> = {
        gpt_cost_usd: parseFloat(existing.gpt_cost_usd || "0") + cost,
        // daily_quota는 덮어쓰지 않음 (광고 보상으로 증가된 값 보존)
        updated_at: new Date().toISOString(),
      };
      updateData[tokenColumn] = (existing[tokenColumn] || 0) + totalTokens;
      await supabase.from("user_daily_token_usage").update(updateData).eq("id", existing.id);
    } else {
      const insertData: Record<string, unknown> = {
        user_id: userId,
        usage_date: today,
        gpt_cost_usd: cost,
        daily_quota: isAdmin ? ADMIN_QUOTA : DAILY_QUOTA,
      };
      insertData[tokenColumn] = totalTokens;
      await supabase.from("user_daily_token_usage").insert(insertData);
    }
  } catch (error) {
    console.error("[ai-openai v39] Failed to record token usage:", error);
  }
}

async function collectStreamResponse(response: Response): Promise<{ content: string; usage: UsageInfo | null; finishReason: string | null }> {
  const reader = response.body?.getReader();
  if (!reader) throw new Error("No response body");
  const decoder = new TextDecoder();
  let content = "";
  let usage: UsageInfo | null = null;
  let finishReason: string | null = null;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    const chunk = decoder.decode(value, { stream: true });
    const lines = chunk.split("\n");
    for (const line of lines) {
      if (line.startsWith("data: ")) {
        const data = line.slice(6);
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
        } catch { /* ignore */ }
      }
    }
  }
  return { content, usage, finishReason };
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
  taskType: string = 'saju_analysis'
): Promise<void> {
  const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
  try {
    await supabase.from("ai_tasks").update({ status: "processing", started_at: new Date().toISOString() }).eq("id", taskId);
    console.log(`[ai-openai] Background task ${taskId}: Starting OpenAI call`);
    const startTime = Date.now();
    const requestBody: Record<string, unknown> = {
      model, messages, max_completion_tokens: maxTokens,
      reasoning_effort: "medium", stream: true, stream_options: { include_usage: true },
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
    const cost = (promptTokens * 1.75 / 1000000) + (completionTokens * 14.00 / 1000000);

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
      model = "gpt-5.2",
      max_tokens = 10000,
      temperature = 0.7,
      response_format,
      user_id,
      run_in_background = true,
      task_type = "saju_analysis",
    } = requestData;

    console.log(`[ai-openai v39] Request: run_in_background=${run_in_background}, model=${model}, task_type=${task_type}, user_id=${user_id}`);

    if (!messages || messages.length === 0) throw new Error("messages is required");

    // Admin 여부 확인
    let isAdmin = false;
    if (user_id) {
      isAdmin = await isAdminUser(supabase, user_id);
      console.log(`[ai-openai v39] User ${user_id} isAdmin: ${isAdmin}`);

      // v39: 운세 분석은 쿼터 면제 (핵심 콘텐츠, 1회성 캐시)
      // 채팅만 쿼터 제한 적용
      const isQuotaExempt = QUOTA_EXEMPT_TASK_TYPES.has(task_type);

      if (!isAdmin && !isQuotaExempt) {
        const quota = await checkQuota(supabase, user_id, isAdmin);
        if (!quota.allowed) {
          console.log(`[ai-openai v39] Quota exceeded for user ${user_id} (task_type: ${task_type})`);
          return new Response(
            JSON.stringify({
              success: false,
              error: "QUOTA_EXCEEDED",
              message: "오늘 사용 가능한 토큰을 모두 사용했습니다. 광고를 시청하면 추가 토큰을 받을 수 있습니다.",
              tokens_used: DAILY_QUOTA - quota.remaining,
              quota_limit: quota.quotaLimit,
              ads_required: true,
            }),
            { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      } else if (isQuotaExempt) {
        console.log(`[ai-openai v39] Quota check SKIPPED for ${task_type} (fortune exempt)`);
      }
    }

    // === Background 모드 ===
    if (run_in_background) {
      console.log(`[ai-openai v39] *** RESPONSES API BACKGROUND MODE ***`);

      if (user_id) {
        // v39: 중복 방지 강화 - 진행 중 OR 오늘 완료된 task 재사용
        // 1단계: 진행 중인 task 체크 (기존)
        const { data: inProgressTask } = await supabase
          .from("ai_tasks")
          .select("id, status, openai_response_id, created_at")
          .eq("user_id", user_id)
          .eq("task_type", task_type)
          .in("status", ["pending", "processing", "queued", "in_progress"])
          .order("created_at", { ascending: false })
          .limit(1)
          .single();

        if (inProgressTask) {
          console.log(`[ai-openai v39] Found in-progress ${task_type} task ${inProgressTask.id} (${inProgressTask.status})`);
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

        // 2단계: 오늘 완료된 task 체크 (v39 신규)
        // 앱이 결과 저장 실패해서 반복 호출해도 기존 completed 결과 재사용
        // → 토큰 중복 차감 완전 방지
        const today = getTodayKST();
        const { data: completedTask } = await supabase
          .from("ai_tasks")
          .select("id, status, openai_response_id, result_data, completed_at")
          .eq("user_id", user_id)
          .eq("task_type", task_type)
          .eq("status", "completed")
          .gte("completed_at", `${today}T00:00:00Z`)
          .order("completed_at", { ascending: false })
          .limit(1)
          .single();

        if (completedTask) {
          console.log(`[ai-openai v39] Found today's completed ${task_type} task ${completedTask.id} → reusing (no new tokens)`);
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

      console.log(`[ai-openai v39] Calling OpenAI Responses API...`);

      const responsesApiBody: Record<string, unknown> = {
        model, input: inputText, background: true, store: true, max_output_tokens: max_tokens,
      };
      if (response_format?.type === "json_object") {
        responsesApiBody.text = { format: { type: "json_object" } };
      }

      let openaiResponse: Response | null = null;
      let selectedKeyIndex = getKeyIndexByTaskType(task_type);
      for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
        const currentKey = getApiKeyByIndex(selectedKeyIndex + attempt);
        const actualKeyIdx = (selectedKeyIndex + attempt) % API_KEYS.length;
        console.log(`[ai-openai v39] Using API key ${actualKeyIdx + 1}/${API_KEYS.length} (task: ${task_type})`);
        openaiResponse = await fetch(OPENAI_RESPONSES_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json", "Authorization": `Bearer ${currentKey}` },
          body: JSON.stringify(responsesApiBody),
        });
        if (openaiResponse.status === 429) { console.warn(`[ai-openai v39] Key ${actualKeyIdx + 1} rate limited (429), trying next key...`); continue; }
        break;
      }
      if (!openaiResponse) throw new Error("All API keys exhausted (rate limited)");

      const responseData = await openaiResponse.json();
      console.log(`[ai-openai v39] OpenAI response status: ${openaiResponse.status}`);

      if (!openaiResponse.ok) {
        console.error("[ai-openai v39] OpenAI Responses API Error:", responseData);
        throw new Error(responseData.error?.message || "OpenAI Responses API error");
      }

      const openaiResponseId = responseData.id;
      const openaiStatus = responseData.status;
      console.log(`[ai-openai v39] Got OpenAI response_id: ${openaiResponseId}, status: ${openaiStatus}`);

      const { data: task, error: insertError } = await supabase
        .from("ai_tasks")
        .insert({
          user_id: user_id || null,
          task_type: task_type,
          status: openaiStatus,
          openai_response_id: openaiResponseId,
          request_data: { messages, model, max_tokens, response_format, task_type, key_index: selectedKeyIndex },
          model,
          phase: 1,
          total_phases: 4,
          partial_result: {},
          started_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (insertError || !task) {
        console.error("[ai-openai v39] Failed to create task:", insertError);
        throw new Error("Failed to create task record");
      }

      console.log(`[ai-openai v39] Created ${task_type} task ${task.id} with openai_response_id ${openaiResponseId}`);

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
    console.log(`[ai-openai v39] *** SYNC MODE ***`);
    const requestBody: Record<string, unknown> = {
      model, messages, max_completion_tokens: max_tokens,
      reasoning_effort: "medium", stream: true, stream_options: { include_usage: true },
    };
    if (response_format) requestBody.response_format = response_format;

    const startTime = Date.now();
    let response: Response | null = null;
    const syncKeyStart = getKeyIndexByTaskType(task_type);
    for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
      const currentKey = getApiKeyByIndex(syncKeyStart + attempt);
      const actualKeyIdx = (syncKeyStart + attempt) % API_KEYS.length;
      console.log(`[ai-openai v39] Sync: Using API key ${actualKeyIdx + 1}/${API_KEYS.length} (task: ${task_type})`);
      response = await fetch(OPENAI_CHAT_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${currentKey}` },
        body: JSON.stringify(requestBody),
      });
      if (response.status === 429) { console.warn(`[ai-openai v39] Key ${actualKeyIdx + 1} rate limited, trying next...`); continue; }
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
    const cost = (promptTokens * 1.75 / 1000000) + (completionTokens * 14.00 / 1000000);
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
    console.error("[ai-openai v39] Error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
