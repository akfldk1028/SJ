import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * GPT-5-mini 테스트용 Edge Function
 *
 * 2026년 신년운세 스토리텔링 프롬프트 테스트
 * - 모델: gpt-5-mini (비용 효율적)
 * - 가격: 입력 $0.25/1M, 출력 $2.00/1M tokens
 * - 목표: 5-7문장 상세 응답 생성 테스트
 * - 주의: max_tokens 대신 max_completion_tokens 사용!
 *
 * v1: 초기 버전 (2026-01-18)
 * v2: gpt-4o-mini 테스트
 * v3: gpt-5-mini로 복원, max_completion_tokens 사용
 * v4: gpt-5-mini는 temperature 미지원 (기본값 1만 허용)
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const OPENAI_CHAT_URL = "https://api.openai.com/v1/chat/completions";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface OpenAIRequest {
  messages: ChatMessage[];
  model?: string;
  max_tokens?: number;
  temperature?: number;
  response_format?: { type: "json_object" | "text" };
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
          const delta = parsed.choices?.[0]?.delta?.content;
          if (delta) content += delta;
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
    if (!OPENAI_API_KEY) {
      throw new Error("OPENAI_API_KEY is not configured");
    }

    const requestData: OpenAIRequest = await req.json();
    const {
      messages,
      model = "gpt-5-mini",   // 기본 모델: gpt-5-mini
      max_tokens = 16000,     // 스토리텔링 상세 응답용 (5-7문장 × 여러 섹션)
      temperature = 0.7,
      response_format,
    } = requestData;

    console.log(`[ai-openai-mini] Request: model=${model}, max_tokens=${max_tokens}, temperature=${temperature}`);
    console.log(`[ai-openai-mini] Messages count: ${messages.length}`);

    if (!messages || messages.length === 0) {
      throw new Error("messages is required");
    }

    // GPT-5-mini 파라미터 (max_completion_tokens 사용, temperature 미지원!)
    const requestBody: Record<string, unknown> = {
      model,
      messages,
      max_completion_tokens: max_tokens,  // gpt-5-mini는 max_completion_tokens 사용
      stream: true,
      stream_options: { include_usage: true },
    };

    // gpt-5-mini는 temperature를 지원하지 않음 (기본값 1만 허용)
    // gpt-4o-mini 등 다른 모델은 temperature 지원
    if (!model.startsWith("gpt-5")) {
      requestBody.temperature = temperature;
    }

    if (response_format) {
      requestBody.response_format = response_format;
    }

    const startTime = Date.now();
    console.log(`[ai-openai-mini] Sending request to OpenAI...`);

    const response = await fetch(OPENAI_CHAT_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify(requestBody),
    });

    console.log(`[ai-openai-mini] OpenAI response status: ${response.status}`);

    if (!response.ok) {
      const errorData = await response.json();
      console.error("[ai-openai-mini] OpenAI API Error:", JSON.stringify(errorData));
      return new Response(
        JSON.stringify({
          success: false,
          error: errorData.error?.message || "OpenAI API error",
          details: errorData,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { content, usage } = await collectStreamResponse(response);
    const elapsed = Date.now() - startTime;

    console.log(`[ai-openai-mini] Response received in ${elapsed}ms`);
    console.log(`[ai-openai-mini] Content length: ${content?.length || 0} chars`);

    if (!content) {
      throw new Error("No response from OpenAI");
    }

    const promptTokens = usage?.prompt_tokens || 0;
    const completionTokens = usage?.completion_tokens || 0;

    // 비용 계산 (gpt-5-mini 가격: 입력 $0.25/1M, 출력 $2.00/1M)
    const cost = (promptTokens * 0.25 / 1000000) + (completionTokens * 2.00 / 1000000);

    console.log(`[ai-openai-mini] Usage: prompt=${promptTokens}, completion=${completionTokens}, cost=$${cost.toFixed(6)}`);
    console.log(`[ai-openai-mini] Content preview: ${content.substring(0, 300)}...`);

    return new Response(
      JSON.stringify({
        success: true,
        content,
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_tokens: promptTokens + completionTokens,
        },
        model,
        cost_usd: cost,
        elapsed_ms: elapsed,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[ai-openai-mini] Error:", error);

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
