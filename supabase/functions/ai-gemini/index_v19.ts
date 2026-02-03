import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * Gemini API 호출 Edge Function (v19)
 *
 * 채팅/일운 분석 + Intent Classification 통합
 * API 키는 서버에만 저장 (보안)
 *
 * v19 변경사항 (2026-01-19):
 * - Intent Classification 기능 추가 (action: "classify-intent")
 * - 사용자 질문의 카테고리를 빠르게 분류 (Gemini Flash 사용)
 * - 토큰 최적화를 위한 Semantic Intent Routing 지원
 *
 * Quota 시스템:
 * - 일반 사용자: 일일 50,000 토큰 제한
 * - Admin 사용자: 무제한 (relation_type = 'admin')
 * - Intent Classification: 소량 토큰 사용 (~200 토큰)
 *
 *  * v18 변경사항 (2026-01-15):
 * - 스트리밍 finishReason 체크 추가 (SAFETY 차단 감지)
 * - SAFETY 차단 시 클라이언트에 알림 메시지 전송
 * - safetySettings 완화: HARASSMENT, HATE_SPEECH → BLOCK_NONE
 *   ("시궁창 술사" 페르소나 차단 방지)
 *
 * v17 변경사항 (2026-01-14):
 * - chat_tokens (legacy) → gemini_chat_tokens (신규 필드)
 * - total_tokens, is_quota_exceeded 직접 UPDATE 제거 (GENERATED 컬럼)
 * - gemini_chat_message_count 증가 추가
 * - gemini_cost_usd 필드 사용
 *
 * v16 변경사항:
 * - 스트리밍 지원 추가 (stream: true)
 * - SSE (Server-Sent Events) 형식으로 실시간 응답
 * - 기존 비스트리밍 모드와 하위 호환 유지
 *
 * v15 변경사항:
 * - 모델명: gemini-3-flash-preview (최신)
 * - responseMimeType 제거 (일반 텍스트 응답)
 * - max_tokens 기본값 4096 → 16384 (응답 잘림 방지 강화)
 * 
 * === 모델 변경 금지 ===
 * 채팅용 모델: gemini-3-flash-preview (변경 금지)
 * Intent Classification: gemini-2.0-flash-exp (빠른 분류용)
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, cache-control",
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Quota 설정
const DAILY_QUOTA = 50000;
const ADMIN_QUOTA = 1000000000; // 10억 (사실상 무제한)

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface GeminiRequest {
  action?: "chat" | "classify-intent"; // v19: Intent Classification 지원
  messages?: ChatMessage[]; // chat 모드
  user_message?: string; // classify-intent 모드
  chat_history?: string[]; // classify-intent 모드
  model?: string;
  max_tokens?: number;
  temperature?: number;
  user_id?: string;
  stream?: boolean;
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
      .eq("profile_type", "primary")
      .single();

    if (error || !data) return false;
    return data.relation_type === "admin";
  } catch {
    return false;
  }
}

/**
 * Quota 확인 및 업데이트
 */
async function checkAndUpdateQuota(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  tokensUsed: number,
  isAdmin: boolean
): Promise<{ allowed: boolean; remaining: number; quotaLimit: number }> {
  const quotaLimit = isAdmin ? ADMIN_QUOTA : DAILY_QUOTA;
  const today = new Date().toISOString().split("T")[0];

  try {
    // 오늘 사용량 조회
    const { data: usage } = await supabase
      .from("user_daily_token_usage")
      .select("total_tokens, daily_quota")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    const currentUsage = usage?.total_tokens || 0;
    const effectiveQuota = isAdmin ? ADMIN_QUOTA : (usage?.daily_quota || DAILY_QUOTA);
    const remaining = effectiveQuota - currentUsage;

    // Admin은 항상 허용
    if (isAdmin) {
      return { allowed: true, remaining: ADMIN_QUOTA, quotaLimit: ADMIN_QUOTA };
    }

    // Quota 초과 체크
    if (currentUsage >= effectiveQuota) {
      return { allowed: false, remaining: 0, quotaLimit: effectiveQuota };
    }

    return { allowed: true, remaining, quotaLimit: effectiveQuota };
  } catch {
    // 에러 시 Admin은 허용, 일반 사용자도 허용 (UX 우선)
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
      .select("id, gemini_chat_tokens, gemini_chat_message_count, gemini_cost_usd")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    if (existing) {
      await supabase
        .from("user_daily_token_usage")
        .update({
          gemini_chat_tokens: (existing.gemini_chat_tokens || 0) + totalTokens,
          gemini_chat_message_count: (existing.gemini_chat_message_count || 0) + 1,
          gemini_cost_usd: parseFloat(existing.gemini_cost_usd || "0") + cost,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existing.id);
    } else {
      await supabase
        .from("user_daily_token_usage")
        .insert({
          user_id: userId,
          usage_date: today,
          gemini_chat_tokens: totalTokens,
          gemini_chat_message_count: 1,
          gemini_cost_usd: cost,
        });
    }
    console.log(`[ai-gemini v19] Recorded ${totalTokens} tokens for user ${userId}`);
  } catch (error) {
    console.error("[ai-gemini v19] Failed to record token usage:", error);
  }
}

/**
 * v19: Intent Classification 처리
 * 사용자 질문의 카테고리를 빠르게 분류 (Gemini 2.0 Flash Exp 사용)
 */
async function handleIntentClassification(
  supabase: ReturnType<typeof createClient>,
  userMessage: string,
  chatHistory: string[] | undefined,
  userId: string | undefined,
  isAdmin: boolean
): Promise<Response> {
  console.log(`[ai-gemini-intent v19] Classifying intent: ${userMessage.substring(0, 50)}...`);

  // Intent Classification용 프롬프트
  const historyContext = chatHistory && chatHistory.length > 0
    ? `\n[최근 대화]\n${chatHistory.slice(-3).join('\n')}\n`
    : '';

  const prompt = `다음 사용자 질문이 어떤 카테고리와 관련이 있는지 판단하세요.
최대 3개까지 선택 가능하며, 관련성이 높은 순서대로 나열하세요.

[카테고리 목록]
- PERSONALITY: 성격, 성향, 기질
- LOVE: 연애, 이성관계, 호감
- MARRIAGE: 결혼, 배우자, 가정
- CAREER: 진로, 직장, 직업
- BUSINESS: 사업, 창업, 자영업
- WEALTH: 재물, 돈, 투자, 재테크
- HEALTH: 건강, 질병, 체질
- GENERAL: 올해 전체 운세, 모든 분야를 한 번에 묻는 질문 (특정 분야가 명확하면 GENERAL 선택 금지!)

⚠️ 중요: 특정 카테고리가 명확한 질문에는 GENERAL을 포함하지 마세요!
${historyContext}
[사용자 질문]
${userMessage}

JSON 형식으로 답변하세요:
{
  "categories": ["LOVE", "MARRIAGE"],
  "reason": "연애와 결혼에 대한 질문"
}`;

  // Gemini 2.0 Flash Exp API 호출 (빠른 분류용)
  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${GEMINI_API_KEY}`;

  try {
    const response = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{
          role: "user",
          parts: [{ text: prompt }],
        }],
        generationConfig: {
          temperature: 0.1, // 일관된 분류를 위해 낮은 temperature
          maxOutputTokens: 200,
        },
      }),
    });

    const data = await response.json();

    // 오류 처리
    if (data.error) {
      console.error("[ai-gemini-intent v19] Gemini API Error:", data.error);
      // Fallback: GENERAL 반환
      return new Response(
        JSON.stringify({
          success: true,
          categories: ["GENERAL"],
          reason: "분류 실패로 전체 정보 제공",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 응답 추출
    const candidate = data.candidates?.[0];
    const content = candidate?.content?.parts?.[0]?.text || "";

    // JSON 파싱 (```json ... ``` 또는 {...} 형식)
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      console.warn("[ai-gemini-intent v19] No JSON found in response:", content);
      return new Response(
        JSON.stringify({
          success: true,
          categories: ["GENERAL"],
          reason: "JSON 파싱 실패로 전체 정보 제공",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const parsed = JSON.parse(jsonMatch[0]);
    const categories = Array.isArray(parsed.categories) ? parsed.categories : ["GENERAL"];
    const reason = parsed.reason || "분류 완료";

    // 토큰 사용량 기록
    if (userId) {
      const usageMetadata = data.usageMetadata || {};
      const promptTokens = usageMetadata.promptTokenCount || 0;
      const completionTokens = usageMetadata.candidatesTokenCount || 0;
      // gemini-2.0-flash-exp: 입력 $0.075/1M, 출력 $0.30/1M
      const cost = (promptTokens * 0.075 / 1000000) + (completionTokens * 0.30 / 1000000);
      await recordTokenUsage(supabase, userId, promptTokens, completionTokens, cost, isAdmin);
      console.log(`[ai-gemini-intent v19] Tokens used: prompt=${promptTokens}, completion=${completionTokens}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        categories,
        reason,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[ai-gemini-intent v19] Error:", error);
    // Fallback: GENERAL 반환
    return new Response(
      JSON.stringify({
        success: true,
        categories: ["GENERAL"],
        reason: "오류 발생으로 전체 정보 제공",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
}

/**
 * 스트리밍 응답 처리 (v18)
 */
async function handleStreamingRequest(
  supabase: ReturnType<typeof createClient>,
  messages: ChatMessage[],
  model: string,
  maxTokens: number,
  temperature: number,
  userId: string | undefined,
  isAdmin: boolean
): Promise<Response> {
  // messages를 Gemini 형식으로 변환
  const systemInstruction = messages
    .filter((m) => m.role === "system")
    .map((m) => m.content)
    .join("\n");

  const contents = messages
    .filter((m) => m.role !== "system")
    .map((m) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: m.content }],
    }));

  // Gemini 스트리밍 API 호출
  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?key=${GEMINI_API_KEY}&alt=sse`;

  console.log(`[ai-gemini-stream v19] Calling Gemini streaming API: model=${model}`);

  const geminiResponse = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents,
      systemInstruction: systemInstruction
        ? { parts: [{ text: systemInstruction }] }
        : undefined,
      generationConfig: {
        temperature: 1.0,
        maxOutputTokens: maxTokens,
        topP: 0.9,
        topK: 40,
        stopSequences: ["[/SUGGESTED_QUESTIONS]"],
      },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
      ],
    }),
  });

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    console.error("[ai-gemini-stream v19] Gemini API error:", errorText);
    throw new Error(`Gemini API error: ${geminiResponse.status}`);
  }

  // 토큰 정보 수집용 변수
  let totalPromptTokens = 0;
  let totalCompletionTokens = 0;

  // ReadableStream으로 Gemini 응답을 클라이언트에 릴레이
  const stream = new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      const reader = geminiResponse.body!.getReader();
      const decoder = new TextDecoder();
      let buffer = "";

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          buffer += decoder.decode(value, { stream: true });

          // SSE 이벤트 파싱 (data: ... 형식)
          const lines = buffer.split("\n");
          buffer = lines.pop() || "";

          for (const line of lines) {
            if (line.startsWith("data: ")) {
              const jsonStr = line.slice(6).trim();
              if (!jsonStr || jsonStr === "[DONE]") continue;

              try {
                const data = JSON.parse(jsonStr);
                const candidate = data.candidates?.[0];

                // finishReason 체크 - SAFETY 차단 감지
                const finishReason = candidate?.finishReason;
                if (finishReason && finishReason !== "STOP") {
                  console.warn(`[ai-gemini-stream v19] finishReason: ${finishReason}`);
                  if (finishReason === "SAFETY") {
                    console.error("[ai-gemini-stream v19] Response blocked by SAFETY filter");
                    const safetyData = JSON.stringify({
                      text: "\n\n[안전 필터에 의해 응답이 차단되었습니다. 다른 질문을 해주세요.]",
                      done: false,
                      finish_reason: "SAFETY"
                    });
                    controller.enqueue(encoder.encode(`data: ${safetyData}\n\n`));
                  }
                }

                // 텍스트 추출
                const text = candidate?.content?.parts?.[0]?.text || "";

                // 토큰 정보 (마지막 청크에 포함)
                if (data.usageMetadata) {
                  totalPromptTokens = data.usageMetadata.promptTokenCount || 0;
                  totalCompletionTokens = data.usageMetadata.candidatesTokenCount || 0;
                }

                // 클라이언트에 SSE 형식으로 전송
                if (text) {
                  const sseData = JSON.stringify({ text, done: false, finish_reason: finishReason });
                  controller.enqueue(encoder.encode(`data: ${sseData}\n\n`));
                }
              } catch (parseError) {
                console.error("[ai-gemini-stream v19] Parse error:", parseError);
              }
            }
          }
        }

        // 스트림 완료 시 토큰 정보 전송
        const doneData = JSON.stringify({
          text: "",
          done: true,
          usage: {
            prompt_tokens: totalPromptTokens,
            completion_tokens: totalCompletionTokens,
            total_tokens: totalPromptTokens + totalCompletionTokens,
          },
        });
        controller.enqueue(encoder.encode(`data: ${doneData}\n\n`));

        // 토큰 사용량 기록
        if (userId && (totalPromptTokens > 0 || totalCompletionTokens > 0)) {
          const cost = (totalPromptTokens * 0.075 / 1000000) + (totalCompletionTokens * 0.30 / 1000000);
          await recordTokenUsage(supabase, userId, totalPromptTokens, totalCompletionTokens, cost, isAdmin);
          console.log(`[ai-gemini-stream v19] Token usage recorded: prompt=${totalPromptTokens}, completion=${totalCompletionTokens}`);
        }

      } catch (error) {
        console.error("[ai-gemini-stream v19] Stream error:", error);
        const errorData = JSON.stringify({ error: "Stream error", done: true });
        controller.enqueue(encoder.encode(`data: ${errorData}\n\n`));
      } finally {
        controller.close();
      }
    },
  });

  return new Response(stream, {
    headers: {
      ...corsHeaders,
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
    },
  });
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // API 키 확인
    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is not configured");
    }

    // Supabase 클라이언트 생성
    const supabase = createClient(
      SUPABASE_URL!,
      SUPABASE_SERVICE_ROLE_KEY!
    );

    const requestData: GeminiRequest = await req.json();
    const action = requestData.action || "chat"; // v19: 기본값 "chat"

    // v19: Intent Classification 분기
    if (action === "classify-intent") {
      const { user_message, chat_history, user_id } = requestData;

      if (!user_message) {
        throw new Error("user_message is required for intent classification");
      }

      // Admin 여부 확인
      let isAdmin = false;
      if (user_id) {
        isAdmin = await isAdminUser(supabase, user_id);
      }

      // Intent Classification 처리
      return await handleIntentClassification(
        supabase,
        user_message,
        chat_history,
        user_id,
        isAdmin
      );
    }

    // ===== 기존 채팅 로직 =====
    const {
      messages,
      model = "gemini-3-flash-preview",
      max_tokens = 16384,
      temperature = 0.8,
      user_id,
      stream = false,
    } = requestData;

    // 필수 파라미터 검증
    if (!messages || messages.length === 0) {
      throw new Error("messages is required");
    }

    // Admin 여부 확인
    let isAdmin = false;
    if (user_id) {
      isAdmin = await isAdminUser(supabase, user_id);
      console.log(`[ai-gemini v19] User ${user_id} isAdmin: ${isAdmin}`);

      // Quota 확인
      if (!isAdmin) {
        const quota = await checkAndUpdateQuota(supabase, user_id, 0, isAdmin);
        if (!quota.allowed) {
          console.log(`[ai-gemini v19] Quota exceeded for user ${user_id}`);
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

    // 스트리밍 모드 분기
    if (stream) {
      console.log(`[ai-gemini v19] Streaming mode enabled: model=${model}`);
      return await handleStreamingRequest(
        supabase,
        messages,
        model,
        max_tokens,
        temperature,
        user_id,
        isAdmin
      );
    }

    // ===== 비스트리밍 로직 =====
    console.log(`[ai-gemini v19] Calling Gemini: model=${model}, isAdmin=${isAdmin}`);

    // messages를 Gemini 형식으로 변환
    const systemInstruction = messages
      .filter((m) => m.role === "system")
      .map((m) => m.content)
      .join("\n");

    const contents = messages
      .filter((m) => m.role !== "system")
      .map((m) => ({
        role: m.role === "assistant" ? "model" : "user",
        parts: [{ text: m.content }],
      }));

    // Gemini API 호출
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`;

    const response = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents,
        systemInstruction: systemInstruction
          ? { parts: [{ text: systemInstruction }] }
          : undefined,
        generationConfig: {
          temperature: 1.0,
          maxOutputTokens: max_tokens,
          topP: 0.9,
          topK: 40,
          stopSequences: ["[/SUGGESTED_QUESTIONS]"],
        },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
          {
            category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            threshold: "BLOCK_ONLY_HIGH",
          },
          {
            category: "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold: "BLOCK_ONLY_HIGH",
          },
        ],
      }),
    });

    const data = await response.json();

    // 오류 처리
    if (data.error) {
      console.error("[ai-gemini v19] Gemini API Error:", data.error);
      return new Response(
        JSON.stringify({
          success: false,
          error: data.error.message || "Gemini API error",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 응답 추출
    const candidate = data.candidates?.[0];
    if (!candidate) {
      throw new Error("No response from Gemini");
    }

    if (candidate.finishReason === "SAFETY") {
      throw new Error("Response blocked due to safety settings");
    }

    const content = candidate.content?.parts?.[0]?.text || "";

    // 토큰 사용량 추출
    const usageMetadata = data.usageMetadata || {};
    const promptTokens = usageMetadata.promptTokenCount || 0;
    const completionTokens = usageMetadata.candidatesTokenCount || 0;
    const totalTokens = usageMetadata.totalTokenCount || 0;

    // 비용 계산
    const cost = (promptTokens * 0.075 / 1000000) + (completionTokens * 0.30 / 1000000);

    // 토큰 사용량 기록
    if (user_id) {
      await recordTokenUsage(supabase, user_id, promptTokens, completionTokens, cost, isAdmin);
    }

    console.log(
      `[ai-gemini v19] Success: prompt=${promptTokens}, completion=${completionTokens}, isAdmin=${isAdmin}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        content,
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_tokens: totalTokens,
        },
        model,
        finish_reason: candidate.finishReason,
        is_admin: isAdmin,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[ai-gemini v19] Error:", error);

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
