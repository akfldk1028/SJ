import "jsr:@supabase/functions-js/edge-runtime.d.ts";

/**
 * OpenAI API 호출 Edge Function
 *
 * 평생 사주 분석 (GPT-5.2) 전용
 * API 키는 서버에만 저장 (보안)
 *
 * GPT-5.2 모델 (2025-12-11 출시):
 * - gpt-5.2: Thinking (추론 특화) - 사주 분석용
 * - gpt-5.2-chat-latest: Instant (빠른 응답)
 * - gpt-5.2-pro: Pro (최고 품질)
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const OPENAI_BASE_URL = "https://api.openai.com/v1/chat/completions";

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
}

interface UsageInfo {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
  prompt_tokens_details?: {
    cached_tokens?: number;
  };
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

    const requestData: OpenAIRequest = await req.json();
    const {
      messages,
      model = "gpt-5.2", // GPT-5.2 Thinking (추론 특화)
      max_tokens = 2000,
      temperature = 0.7,
      response_format,
    } = requestData;

    // 필수 파라미터 검증
    if (!messages || messages.length === 0) {
      throw new Error("messages is required");
    }

    console.log(`[ai-openai] Calling OpenAI: model=${model}`);

    // GPT-5.2 모델 여부 확인 (max_completion_tokens 사용)
    const isGpt52 = model.startsWith("gpt-5");

    // OpenAI API 요청 body 구성
    const requestBody: Record<string, unknown> = {
      model,
      messages,
    };

    // GPT-5.2는 max_completion_tokens 사용, 다른 모델은 max_tokens
    if (isGpt52) {
      requestBody.max_completion_tokens = max_tokens;
      // GPT-5.2 Thinking 모델은 temperature 미지원 (기본값 1만 허용)
    } else {
      requestBody.max_tokens = max_tokens;
      requestBody.temperature = temperature;
      requestBody.response_format = response_format || { type: "json_object" };
    }

    // OpenAI API 호출
    const response = await fetch(OPENAI_BASE_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();

    // 오류 처리
    if (data.error) {
      console.error("[ai-openai] OpenAI API Error:", data.error);
      return new Response(
        JSON.stringify({
          success: false,
          error: data.error.message || "OpenAI API error",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 응답 추출
    const choice = data.choices?.[0];
    if (!choice) {
      throw new Error("No response from OpenAI");
    }

    const content = choice.message?.content || "";
    const usage: UsageInfo = data.usage || {};

    // 캐시된 토큰 추출 (OpenAI의 prompt_tokens_details)
    const cachedTokens = usage.prompt_tokens_details?.cached_tokens || 0;

    console.log(
      `[ai-openai] Success: prompt=${usage.prompt_tokens}, completion=${usage.completion_tokens}, cached=${cachedTokens}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        content,
        usage: {
          prompt_tokens: usage.prompt_tokens,
          completion_tokens: usage.completion_tokens,
          total_tokens: usage.total_tokens,
          cached_tokens: cachedTokens,
        },
        model: data.model,
        finish_reason: choice.finish_reason,
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
