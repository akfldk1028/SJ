import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * OpenAI API 호출 Edge Function
 *
 * v32 변경사항 (2026-01-30):
 * - API Key 로드밸런싱 적용 (Round-Robin + Fallback)
 * - OPENAI_API_KEY, OPENAI_API_KEY_2, OPENAI_API_KEY_3 순환 사용
 * - 429 (Rate Limit) 시 자동으로 다음 키로 전환
 * - ai_tasks에 key_index 저장 (ai-openai-result에서 같은 키 사용)
 *
 * 평생 사주 분석 (GPT-5.2 Thinking) 전용
 * API 키는 서버에만 저장 (보안)
 *
 * Quota 시스템:
 * - 일반 사용자: 일일 50,000 토큰 제한
 * - Admin 사용자: 무제한 (relation_type = 'admin')
 *
 * v24 변경사항 (2024-12-31):
 * - OpenAI Responses API (/v1/responses) 사용
 * - background: true 모드로 Supabase 150초 walltime 제한 완전 회피
 * - OpenAI 클라우드에서 비동기 처리 (시간 제한 없음)
 * - response.id 반환 → 클라이언트가 ai-openai-result로 폴링
 *
 * v25 변경사항 (2026-01-14):
 * - ai_analysis_tokens (legacy) → gpt_saju_analysis_tokens (신규 필드)
 * - total_tokens, is_quota_exceeded 직접 UPDATE 제거 (GENERATED 컬럼)
 * - gpt_saju_analysis_count 증가 추가
 *
 * v27 변경사항 (2026-01-23):
 * - Phase 기반 Progressive Disclosure 지원
 * - 작업 생성 시 phase=1, total_phases=4 설정
 * - Flutter UI에서 Phase별 진행 상태 표시 가능
 *
 * === 모델 변경 금지 ===
 * 이 Edge Function의 기본 모델은 반드시 gpt-5.2 유지
 * (GPT-5.2 Thinking = API ID: gpt-5.2)
 * 변경 필요 시 EdgeFunction_task.md 참조
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

// v32.1: task_type 기반 결정적 키 분배 (서버리스 병렬 호출 대응)
// Round-robin은 같은 인스턴스 내에서만 동작하므로,
// task_type을 해시하여 키를 결정적으로 선택
function getKeyIndexByTaskType(taskType: string): number {
  let hash = 0;
  for (let i = 0; i < taskType.length; i++) {
    hash = ((hash << 5) - hash) + taskType.charCodeAt(i);
    hash |= 0; // Convert to 32bit integer
  }
  return Math.abs(hash) % API_KEYS.length;
}

// v24: Responses API 사용 (background 모드로 Supabase 타임아웃 완전 회피)
const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";
const OPENAI_CHAT_URL = "https://api.openai.com/v1/chat/completions"; // fallback용
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Quota 설정
const DAILY_QUOTA = 50000;
const ADMIN_QUOTA = 1000000000; // 10억 (사실상 무제한)

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
  user_id?: string; // Quota 체크용
  run_in_background?: boolean; // Background Task 모드 (GPT-5.2 전용)
  task_type?: string; // v29: 병렬 실행 시 task 분리용
}

interface UsageInfo {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
  prompt_tokens_details?: {
    cached_tokens?: number;
  };
}

/**
 * Admin 사용자 여부 확인
 */
async function isAdminUser(supabase: ReturnType<typeof createClient>, userId: string): Promise<boolean> {
  try {
    const { data, error } = await supabase
      .from("saju_profiles")
      .select("relation_type")
      .eq("user_id", userId)
      .eq("is_primary", true)
      .single();

    if (error || !data) return false;
    return data.relation_type === "admin";
  } catch {
    return false;
  }
}

/**
 * Quota 확인
 */
async function checkQuota(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  isAdmin: boolean
): Promise<{ allowed: boolean; remaining: number; quotaLimit: number }> {
  const quotaLimit = isAdmin ? ADMIN_QUOTA : DAILY_QUOTA;
  const today = new Date().toISOString().split("T")[0];

  try {
    const { data: usage } = await supabase
      .from("user_daily_token_usage")
      .select("total_tokens, daily_quota")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    const currentUsage = usage?.total_tokens || 0;
    const effectiveQuota = isAdmin ? ADMIN_QUOTA : (usage?.daily_quota || DAILY_QUOTA);
    const remaining = effectiveQuota - currentUsage;

    if (isAdmin) {
      return { allowed: true, remaining: ADMIN_QUOTA, quotaLimit: ADMIN_QUOTA };
    }

    if (currentUsage >= effectiveQuota) {
      return { allowed: false, remaining: 0, quotaLimit: effectiveQuota };
    }

    return { allowed: true, remaining, quotaLimit: effectiveQuota };
  } catch {
    return { allowed: true, remaining: quotaLimit, quotaLimit };
  }
}

/**
 * 토큰 사용량 기록
 *
 * v25 변경사항 (2026-01-14):
 * - ai_analysis_tokens (legacy) → gpt_saju_analysis_tokens (신규)
 * - total_tokens, is_quota_exceeded 직접 UPDATE 제거 (GENERATED 컬럼)
 * - gpt_saju_analysis_count 증가 추가
 */
async function recordTokenUsage(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  promptTokens: number,
  completionTokens: number,
  cost: number,
  isAdmin: boolean
): Promise<void> {
  const today = new Date().toISOString().split("T")[0];
  const totalTokens = promptTokens + completionTokens;

  try {
    const { data: existing } = await supabase
      .from("user_daily_token_usage")
      .select("id, gpt_saju_analysis_tokens, gpt_saju_analysis_count, gpt_cost_usd")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    if (existing) {
      // UPDATE: 개별 필드만 업데이트 (total_tokens, is_quota_exceeded는 GENERATED 컬럼)
      await supabase
        .from("user_daily_token_usage")
        .update({
          gpt_saju_analysis_tokens: (existing.gpt_saju_analysis_tokens || 0) + totalTokens,
          gpt_saju_analysis_count: (existing.gpt_saju_analysis_count || 0) + 1,
          gpt_cost_usd: parseFloat(existing.gpt_cost_usd || "0") + cost,
          daily_quota: isAdmin ? ADMIN_QUOTA : DAILY_QUOTA,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existing.id);
    } else {
      // INSERT: 새 레코드 생성 (total_tokens, is_quota_exceeded는 자동 계산)
      await supabase
        .from("user_daily_token_usage")
        .insert({
          user_id: userId,
          usage_date: today,
          gpt_saju_analysis_tokens: totalTokens,
          gpt_saju_analysis_count: 1,
          gpt_cost_usd: cost,
          daily_quota: isAdmin ? ADMIN_QUOTA : DAILY_QUOTA,
        });
    }
  } catch (error) {
    console.error("[ai-openai] Failed to record token usage:", error);
  }
}

/**
 * OpenAI 스트리밍 응답에서 content 수집
 */
async function collectStreamResponse(response: Response): Promise<{ content: string; usage: UsageInfo | null }> {
  const reader = response.body?.getReader();
  if (!reader) throw new Error("No response body");

  const decoder = new TextDecoder();
  let content = "";
  let usage: UsageInfo | null = null;

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
          // content 수집
          const delta = parsed.choices?.[0]?.delta?.content;
          if (delta) content += delta;
          // usage 수집 (마지막 청크에 포함)
          if (parsed.usage) usage = parsed.usage;
        } catch {
          // JSON 파싱 실패 무시
        }
      }
    }
  }

  return { content, usage };
}

/**
 * Background에서 OpenAI 호출 및 결과 저장
 */
async function processInBackground(
  taskId: string,
  messages: ChatMessage[],
  model: string,
  maxTokens: number,
  temperature: number,
  responseFormat: { type: string } | undefined,
  userId: string | undefined,
  isAdmin: boolean
): Promise<void> {
  const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

  try {
    // 작업 시작 상태 업데이트
    await supabase
      .from("ai_tasks")
      .update({
        status: "processing",
        started_at: new Date().toISOString()
      })
      .eq("id", taskId);

    console.log(`[ai-openai] Background task ${taskId}: Starting OpenAI call`);
    const startTime = Date.now();

    // OpenAI API 요청 body 구성
    // GPT-5.2는 reasoning_effort 파라미터로 추론 깊이 조절
    // medium: Supabase 150초 walltime 제한 내 완료 가능 (30-60초)
    // NOTE: GPT-5.2는 temperature 지원 안함 (기본값 1만 허용)
    const requestBody: Record<string, unknown> = {
      model,
      messages,
      max_completion_tokens: maxTokens,
      // temperature 제거 - GPT-5.2는 기본값(1)만 지원
      reasoning_effort: "medium",  // GPT-5.2 추론 강도 (medium: 30-60초, Supabase 타임아웃 내)
      stream: true,
      stream_options: { include_usage: true },
    };

    if (responseFormat) {
      requestBody.response_format = responseFormat;
    }

    // v32: Load Balancing
    let response: Response | null = null;

    for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
      const currentKey = getNextApiKey();
      const currentKeyIdx = (keyIndex - 1) % API_KEYS.length;
      console.log(`[ai-openai v32] Background sync: Using API key ${currentKeyIdx + 1}/${API_KEYS.length}`);

      response = await fetch(OPENAI_CHAT_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${currentKey}`,
        },
        body: JSON.stringify(requestBody),
      });

      if (response.status === 429) {
        console.warn(`[ai-openai v32] Key ${currentKeyIdx + 1} rate limited, trying next...`);
        continue;
      }
      break;
    }

    if (!response) {
      throw new Error("All API keys exhausted");
    }

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error?.message || "OpenAI API error");
    }

    // 스트리밍 응답 수집
    const { content, usage } = await collectStreamResponse(response);
    const elapsed = Date.now() - startTime;
    console.log(`[ai-openai] Background task ${taskId}: OpenAI responded in ${elapsed}ms`);

    if (!content) {
      throw new Error("No response from OpenAI");
    }

    // 토큰 사용량
    const promptTokens = usage?.prompt_tokens || 0;
    const completionTokens = usage?.completion_tokens || 0;
    const cachedTokens = usage?.prompt_tokens_details?.cached_tokens || 0;

    // 비용 계산 및 기록
    const cost = (promptTokens * 3.00 / 1000000) + (completionTokens * 12.00 / 1000000);
    if (userId && promptTokens > 0) {
      await recordTokenUsage(supabase, userId, promptTokens, completionTokens, cost, isAdmin);
    }

    // 결과 저장
    await supabase
      .from("ai_tasks")
      .update({
        status: "completed",
        result_data: {
          success: true,
          content,
          usage: {
            prompt_tokens: promptTokens,
            completion_tokens: completionTokens,
            total_tokens: promptTokens + completionTokens,
            cached_tokens: cachedTokens,
          },
          model,
          finish_reason: "stop",
          is_admin: isAdmin,
          elapsed_ms: elapsed,
        },
        completed_at: new Date().toISOString(),
      })
      .eq("id", taskId);

    console.log(`[ai-openai] Background task ${taskId}: Completed successfully`);
  } catch (error) {
    console.error(`[ai-openai] Background task ${taskId}: Error:`, error);

    // 에러 저장
    await supabase
      .from("ai_tasks")
      .update({
        status: "failed",
        error_message: error instanceof Error ? error.message : "Unknown error",
        completed_at: new Date().toISOString(),
      })
      .eq("id", taskId);
  }
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // API 키 확인
    if (API_KEYS.length === 0) {
      throw new Error("No OPENAI_API_KEY configured");
    }

    // Supabase 클라이언트 생성
    const supabase = createClient(
      SUPABASE_URL!,
      SUPABASE_SERVICE_ROLE_KEY!
    );

    const requestData: OpenAIRequest = await req.json();
    const {
      messages,
      model = "gpt-5.2",  // GPT-5.2 Thinking (API ID: gpt-5.2) - 변경 금지
      max_tokens = 10000,           // 전체 응답 보장
      temperature = 0.7,
      response_format,
      user_id,
      run_in_background = true,    // v24: 기본값 true (Responses API background 모드)
      task_type = "saju_analysis", // v29: 병렬 실행 시 task 분리! (기본값 유지)
    } = requestData;

    // Debug: 요청 파라미터 로그
    console.log(`[ai-openai v32] Request: run_in_background=${run_in_background}, model=${model}, task_type=${task_type}, user_id=${user_id}`);

    // 필수 파라미터 검증
    if (!messages || messages.length === 0) {
      throw new Error("messages is required");
    }

    // Admin 여부 확인
    let isAdmin = false;
    if (user_id) {
      isAdmin = await isAdminUser(supabase, user_id);
      console.log(`[ai-openai] User ${user_id} isAdmin: ${isAdmin}`);

      // Quota 확인 (Admin은 스킵)
      if (!isAdmin) {
        const quota = await checkQuota(supabase, user_id, isAdmin);
        if (!quota.allowed) {
          console.log(`[ai-openai] Quota exceeded for user ${user_id}`);
          return new Response(
            JSON.stringify({
              success: false,
              error: "QUOTA_EXCEEDED",
              message: "오늘 사용 가능한 토큰을 모두 사용했습니다. 광고를 시청하면 추가 토큰을 받을 수 있습니다.",
              tokens_used: DAILY_QUOTA - quota.remaining,
              quota_limit: quota.quotaLimit,
              ads_required: true,
            }),
            {
              status: 429,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }
      }
    }

    // === v24: OpenAI Responses API Background 모드 ===
    // Supabase 150초 walltime 제한 완전 회피!
    // OpenAI 클라우드에서 비동기 처리 → 시간 제한 없음
    if (run_in_background) {
      console.log(`[ai-openai v32] *** RESPONSES API BACKGROUND MODE ***`);
      console.log(`[ai-openai v32] Using /v1/responses with background=true`);

      // v29: 중복 방지 - 동일 user + 동일 task_type만 체크!
      // 이전: 모든 운세가 "saju_analysis"로 충돌
      // 이후: 각 운세별로 task_type 분리 (monthly_fortune, yearly_2026, etc.)
      if (user_id) {
        const { data: existingTask } = await supabase
          .from("ai_tasks")
          .select("id, status, openai_response_id, created_at")
          .eq("user_id", user_id)
          .eq("task_type", task_type)  // v29: 동적 task_type 사용!
          .in("status", ["pending", "processing", "queued", "in_progress"])
          .order("created_at", { ascending: false })
          .limit(1)
          .single();

        if (existingTask) {
          console.log(`[ai-openai v32] Found existing ${task_type} task ${existingTask.id} (${existingTask.status})`);
          return new Response(
            JSON.stringify({
              success: true,
              task_id: existingTask.id,
              openai_response_id: existingTask.openai_response_id,
              status: existingTask.status,
              message: `Existing ${task_type} task in progress. Poll /ai-openai-result with task_id.`,
              reused: true,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }
      }

      // messages를 Responses API input 형식으로 변환
      // system + user 메시지를 하나의 input 문자열로 결합
      let systemContent = "";
      let userContent = "";
      for (const msg of messages) {
        if (msg.role === "system") {
          systemContent = msg.content;
        } else if (msg.role === "user") {
          userContent = msg.content;
        }
      }

      const inputText = systemContent
        ? `[System Instructions]\n${systemContent}\n\n[User Request]\n${userContent}`
        : userContent;

      // OpenAI Responses API 호출 (background: true)
      // 즉시 response.id 반환, OpenAI 클라우드에서 비동기 처리
      console.log(`[ai-openai v32] Calling OpenAI Responses API...`);

      const responsesApiBody: Record<string, unknown> = {
        model,
        input: inputText,
        background: true,  // 핵심! OpenAI 클라우드에서 비동기 처리
        store: true,       // background 모드 필수
        max_output_tokens: max_tokens,
      };

      // JSON 응답 형식 요청 시 instructions 추가
      if (response_format?.type === "json_object") {
        responsesApiBody.text = {
          format: { type: "json_object" }
        };
      }

      // v32.1: task_type 기반 결정적 키 분배 + fallback on 429
      // 서버리스 환경에서 병렬 호출 시에도 키가 분산됨
      let openaiResponse: Response | null = null;
      let selectedKeyIndex = getKeyIndexByTaskType(task_type);

      for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
        const currentKey = getApiKeyByIndex(selectedKeyIndex + attempt);
        const actualKeyIdx = (selectedKeyIndex + attempt) % API_KEYS.length;
        console.log(`[ai-openai v32.1] Using API key ${actualKeyIdx + 1}/${API_KEYS.length} (task: ${task_type})`);

        openaiResponse = await fetch(OPENAI_RESPONSES_URL, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${currentKey}`,
          },
          body: JSON.stringify(responsesApiBody),
        });

        if (openaiResponse.status === 429) {
          console.warn(`[ai-openai v32.1] Key ${actualKeyIdx + 1} rate limited (429), trying next key...`);
          continue;
        }
        break;
      }

      if (!openaiResponse) {
        throw new Error("All API keys exhausted (rate limited)");
      }

      const responseData = await openaiResponse.json();
      console.log(`[ai-openai v32] OpenAI response status: ${openaiResponse.status}`);
      console.log(`[ai-openai v32] Response: ${JSON.stringify(responseData)}`);

      if (!openaiResponse.ok) {
        console.error("[ai-openai v32] OpenAI Responses API Error:", responseData);
        throw new Error(responseData.error?.message || "OpenAI Responses API error");
      }

      const openaiResponseId = responseData.id;
      const openaiStatus = responseData.status; // "queued" or "in_progress"

      console.log(`[ai-openai v32] Got OpenAI response_id: ${openaiResponseId}, status: ${openaiStatus}`);

      // ai_tasks 테이블에 저장 (v29: task_type 동적 지정, v32: key_index 추가)
      const { data: task, error: insertError } = await supabase
        .from("ai_tasks")
        .insert({
          user_id: user_id || null,
          task_type: task_type,  // v29: 동적 task_type 사용!
          status: openaiStatus, // OpenAI 상태 그대로 저장 (queued/in_progress)
          openai_response_id: openaiResponseId, // 핵심! OpenAI response ID
          request_data: { messages, model, max_tokens, response_format, task_type, key_index: selectedKeyIndex },
          model,
          phase: 1,            // v27: 시작 Phase
          total_phases: 4,     // v27: 총 4개 Phase
          partial_result: {},  // v27: 초기 빈 객체
          started_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (insertError || !task) {
        console.error("[ai-openai v32] Failed to create task:", insertError);
        throw new Error("Failed to create task record");
      }

      console.log(`[ai-openai v32] Created ${task_type} task ${task.id} with openai_response_id ${openaiResponseId}`);

      // 즉시 응답 반환 (Supabase 타임아웃 전에!)
      return new Response(
        JSON.stringify({
          success: true,
          task_id: task.id,
          openai_response_id: openaiResponseId,
          status: openaiStatus,
          phase: 1,            // v27: 시작 Phase
          total_phases: 4,     // v27: 총 4개 Phase
          message: "Analysis started in OpenAI cloud. Poll /ai-openai-result with task_id.",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // === Sync 모드 (기본, GPT-5.2 medium reasoning 30-60초) ===
    console.log(`[ai-openai v32] *** SYNC MODE (default) ***`);
    console.log(`[ai-openai v32] Calling OpenAI ${model} with ${messages.length} messages`);

    // GPT-5.2는 reasoning_effort 파라미터 필요
    // NOTE: GPT-5.2는 temperature 지원 안함 (기본값 1만 허용)
    const requestBody: Record<string, unknown> = {
      model,
      messages,
      max_completion_tokens: max_tokens,
      // temperature 제거 - GPT-5.2는 기본값(1)만 지원
      reasoning_effort: "medium",  // GPT-5.2 추론 강도 (medium: 30-60초)
      stream: true,
      stream_options: { include_usage: true },
    };

    if (response_format) {
      requestBody.response_format = response_format;
    }

    const startTime = Date.now();
    console.log(`[ai-openai] Sync mode: Sending request to OpenAI...`);
    console.log(`[ai-openai] Request body: ${JSON.stringify(requestBody).substring(0, 500)}...`);

    // v32.1: task_type 기반 결정적 키 분배 + fallback on 429
    let response: Response | null = null;
    const syncKeyStart = getKeyIndexByTaskType(task_type);

    for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
      const currentKey = getApiKeyByIndex(syncKeyStart + attempt);
      const actualKeyIdx = (syncKeyStart + attempt) % API_KEYS.length;
      console.log(`[ai-openai v32.1] Sync mode: Using API key ${actualKeyIdx + 1}/${API_KEYS.length} (task: ${task_type})`);

      response = await fetch(OPENAI_CHAT_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${currentKey}`,
        },
        body: JSON.stringify(requestBody),
      });

      if (response.status === 429) {
        console.warn(`[ai-openai v32.1] Key ${actualKeyIdx + 1} rate limited (429), trying next key...`);
        continue;
      }
      break;
    }

    if (!response) {
      throw new Error("All API keys exhausted (rate limited)");
    }

    console.log(`[ai-openai] Sync mode: OpenAI response status ${response.status}`);

    if (!response.ok) {
      const errorData = await response.json();
      console.error("[ai-openai] OpenAI API Error:", JSON.stringify(errorData));
      return new Response(
        JSON.stringify({
          success: false,
          error: errorData.error?.message || "OpenAI API error",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { content, usage } = await collectStreamResponse(response);
    const elapsed = Date.now() - startTime;
    console.log(`[ai-openai] Sync mode: OpenAI responded in ${elapsed}ms`);
    console.log(`[ai-openai] Sync mode: Content length=${content?.length || 0}, has usage=${!!usage}`);

    if (!content) {
      console.error(`[ai-openai] Sync mode: No content received!`);
      throw new Error("No response from OpenAI");
    }

    console.log(`[ai-openai] Sync mode: Content preview: ${content.substring(0, 200)}...`);

    const promptTokens = usage?.prompt_tokens || 0;
    const completionTokens = usage?.completion_tokens || 0;
    const cachedTokens = usage?.prompt_tokens_details?.cached_tokens || 0;

    const cost = (promptTokens * 3.00 / 1000000) + (completionTokens * 12.00 / 1000000);
    if (user_id && promptTokens > 0) {
      await recordTokenUsage(supabase, user_id, promptTokens, completionTokens, cost, isAdmin);
    }

    return new Response(
      JSON.stringify({
        success: true,
        content,
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_tokens: promptTokens + completionTokens,
          cached_tokens: cachedTokens,
        },
        model,
        finish_reason: "stop",
        is_admin: isAdmin,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[ai-openai] Error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
