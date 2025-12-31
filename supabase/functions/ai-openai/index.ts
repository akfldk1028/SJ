import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * OpenAI API 호출 Edge Function
 *
 * 평생 사주 분석 (GPT-5.2) 전용
 * API 키는 서버에만 저장 (보안)
 *
 * Quota 시스템:
 * - 일반 사용자: 일일 50,000 토큰 제한
 * - Admin 사용자: 무제한 (relation_type = 'admin')
 *
 * v15 변경사항:
 * - gpt-5.2-thinking → gpt-5.2 변경 (thinking 제거)
 * - Background Task + Polling 제거 → 직접 응답 방식
 * - 스트리밍으로 응답 수집 후 즉시 반환
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const OPENAI_BASE_URL = "https://api.openai.com/v1/chat/completions";
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
      .select("id, ai_analysis_tokens, total_tokens, total_cost_usd")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    if (existing) {
      await supabase
        .from("user_daily_token_usage")
        .update({
          ai_analysis_tokens: (existing.ai_analysis_tokens || 0) + totalTokens,
          total_tokens: (existing.total_tokens || 0) + totalTokens,
          total_cost_usd: parseFloat(existing.total_cost_usd || "0") + cost,
          daily_quota: isAdmin ? ADMIN_QUOTA : DAILY_QUOTA,
          is_quota_exceeded: !isAdmin && ((existing.total_tokens || 0) + totalTokens) >= DAILY_QUOTA,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existing.id);
    } else {
      await supabase
        .from("user_daily_token_usage")
        .insert({
          user_id: userId,
          usage_date: today,
          chat_tokens: 0,
          ai_analysis_tokens: totalTokens,
          ai_chat_tokens: 0,
          total_tokens: totalTokens,
          total_cost_usd: cost,
          daily_quota: isAdmin ? ADMIN_QUOTA : DAILY_QUOTA,
          is_quota_exceeded: !isAdmin && totalTokens >= DAILY_QUOTA,
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

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // API 키 확인
    if (!OPENAI_API_KEY) {
      throw new Error("OPENAI_API_KEY is not configured");
    }

    // Supabase 클라이언트 생성
    const supabase = createClient(
      SUPABASE_URL!,
      SUPABASE_SERVICE_ROLE_KEY!
    );

    const requestData: OpenAIRequest = await req.json();
    const {
      messages,
      model = "gpt-5.2",  // 기본 모델: gpt-5.2 (thinking 아님)
      max_tokens = 10000,
      temperature = 0.7,
      response_format,
      user_id,
    } = requestData;

    // 필수 파라미터 검증
    if (!messages || messages.length === 0) {
      throw new Error("messages is required");
    }

    // Admin 여부 확인 (user_id가 있는 경우)
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

    console.log(`[ai-openai] Calling OpenAI API with model=${model}`);

    // OpenAI API 요청 body 구성
    const requestBody: Record<string, unknown> = {
      model,
      messages,
      max_completion_tokens: max_tokens,
      temperature,
      stream: true,
      stream_options: { include_usage: true },
    };

    if (response_format) {
      requestBody.response_format = response_format;
    }

    const startTime = Date.now();

    // OpenAI API 호출
    const response = await fetch(OPENAI_BASE_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error("[ai-openai] OpenAI API error:", errorData);
      throw new Error(errorData.error?.message || "OpenAI API error");
    }

    // 스트리밍 응답 수집
    const { content, usage } = await collectStreamResponse(response);
    const elapsed = Date.now() - startTime;

    console.log(`[ai-openai] OpenAI responded in ${elapsed}ms`);

    if (!content) {
      throw new Error("No response from OpenAI");
    }

    // 토큰 사용량
    const promptTokens = usage?.prompt_tokens || 0;
    const completionTokens = usage?.completion_tokens || 0;
    const cachedTokens = usage?.prompt_tokens_details?.cached_tokens || 0;

    // 비용 계산 (GPT-5.2 가격: $3/1M input, $12/1M output)
    const cost = (promptTokens * 3.00 / 1000000) + (completionTokens * 12.00 / 1000000);

    // 토큰 사용량 기록 (user_id가 있는 경우)
    if (user_id && promptTokens > 0) {
      await recordTokenUsage(supabase, user_id, promptTokens, completionTokens, cost, isAdmin);
    }

    // 성공 응답
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
        processing_time_ms: elapsed,
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
