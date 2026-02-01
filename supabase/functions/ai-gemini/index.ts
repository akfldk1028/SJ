import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * Gemini API 호출 Edge Function (v22)
 *
 * v22 변경사항 (2026-02-01):
 * - Quota 체크: total_tokens → chatting_tokens만 대상
 *   운세 토큰은 핵심 콘텐츠이므로 쿼터 면제
 *   채팅만 일일 쿼터 제한 적용
 *
 * v21 변경사항 (2026-02-01):
 * - recordTokenUsage: gemini_cost_usd만 기록
 *
 * v20 변경사항 (2026-01-30):
 * - Intent Classification 모델: gemini-2.5-flash-lite
 *
 * === 모델 변경 금지 ===
 * 채팅용: gemini-3-flash-preview
 * Intent: gemini-2.5-flash-lite
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, cache-control",
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const DAILY_QUOTA = 50000;
const ADMIN_QUOTA = 1000000000;

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface GeminiRequest {
  action?: "chat" | "classify-intent";
  messages?: ChatMessage[];
  user_message?: string;
  chat_history?: string[];
  model?: string;
  max_tokens?: number;
  temperature?: number;
  user_id?: string;
  stream?: boolean;
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

/**
 * v22: Quota 확인 - chatting_tokens만 대상
 * 운세 토큰(saju_analysis, monthly, yearly 등)은 핵심 콘텐츠이므로 쿼터 면제
 * 채팅만 일일 쿼터 제한 적용
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
    const { data: usage } = await supabase
      .from("user_daily_token_usage")
      .select("chatting_tokens, daily_quota")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();
    // v22: chatting_tokens만 쿼터 대상 (운세 토큰 제외)
    const currentChatUsage = usage?.chatting_tokens || 0;
    const effectiveQuota = isAdmin ? ADMIN_QUOTA : (usage?.daily_quota || DAILY_QUOTA);
    const remaining = effectiveQuota - currentChatUsage;
    if (isAdmin) return { allowed: true, remaining: ADMIN_QUOTA, quotaLimit: ADMIN_QUOTA };
    if (currentChatUsage >= effectiveQuota) return { allowed: false, remaining: 0, quotaLimit: effectiveQuota };
    return { allowed: true, remaining, quotaLimit: effectiveQuota };
  } catch {
    return { allowed: true, remaining: quotaLimit, quotaLimit };
  }
}

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
      .select("id, gemini_cost_usd")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();
    if (existing) {
      await supabase
        .from("user_daily_token_usage")
        .update({
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
          gemini_cost_usd: cost,
        });
    }
    console.log(`[ai-gemini v22] Recorded cost=$${cost.toFixed(6)} (${totalTokens} tokens) for user ${userId}`);
  } catch (error) {
    console.error("[ai-gemini v22] Failed to record token usage:", error);
  }
}

async function handleIntentClassification(
  supabase: ReturnType<typeof createClient>,
  userMessage: string,
  chatHistory: string[] | undefined,
  userId: string | undefined,
  isAdmin: boolean
): Promise<Response> {
  console.log(`[ai-gemini-intent v22] Classifying intent: ${userMessage.substring(0, 50)}...`);
  const historyContext = chatHistory && chatHistory.length > 0
    ? `\n[최근 대화]\n${chatHistory.slice(-3).join('\n')}\n`
    : '';
  const prompt = `다음 사용자 질문이 어떤 카테고리와 관련이 있는지 판단하세요.\n최대 3개까지 선택 가능하며, 관련성이 높은 순서대로 나열하세요.\n\n[카테고리 목록]\n- PERSONALITY: 성격, 성향, 기질\n- LOVE: 연애, 이성관계, 호감\n- MARRIAGE: 결혼, 배우자, 가정\n- CAREER: 진로, 직장, 직업\n- BUSINESS: 사업, 창업, 자영업\n- WEALTH: 재물, 돈, 투자, 재테크\n- HEALTH: 건강, 질병, 체질\n- GENERAL: 올해 전체 운세, 모든 분야를 한 번에 묻는 질문 (특정 분야가 명확하면 GENERAL 선택 금지!)\n\n⚠️ 중요: 특정 카테고리가 명확한 질문에는 GENERAL을 포함하지 마세요!\n${historyContext}\n[사용자 질문]\n${userMessage}\n\nJSON 형식으로 답변하세요:\n{\n  "categories": ["LOVE", "MARRIAGE"],\n  "reason": "연애와 결혼에 대한 질문"\n}`;
  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${GEMINI_API_KEY}`;
  try {
    const response = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.1, maxOutputTokens: 200 },
      }),
    });
    const data = await response.json();
    if (data.error) {
      console.error("[ai-gemini-intent v22] Gemini API Error:", data.error);
      return new Response(JSON.stringify({ success: true, categories: ["GENERAL"], reason: "분류 실패로 전체 정보 제공" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    const candidate = data.candidates?.[0];
    const content = candidate?.content?.parts?.[0]?.text || "";
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      return new Response(JSON.stringify({ success: true, categories: ["GENERAL"], reason: "JSON 파싱 실패" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    const parsed = JSON.parse(jsonMatch[0]);
    const categories = Array.isArray(parsed.categories) ? parsed.categories : ["GENERAL"];
    const reason = parsed.reason || "분류 완료";
    if (userId) {
      const usageMetadata = data.usageMetadata || {};
      const promptTokens = usageMetadata.promptTokenCount || 0;
      const completionTokens = usageMetadata.candidatesTokenCount || 0;
      const cost = (promptTokens * 0.075 / 1000000) + (completionTokens * 0.30 / 1000000);
      await recordTokenUsage(supabase, userId, promptTokens, completionTokens, cost, isAdmin);
    }
    return new Response(JSON.stringify({ success: true, categories, reason }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    console.error("[ai-gemini-intent v22] Error:", error);
    return new Response(JSON.stringify({ success: true, categories: ["GENERAL"], reason: "오류 발생" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
}

async function handleStreamingRequest(
  supabase: ReturnType<typeof createClient>,
  messages: ChatMessage[],
  model: string,
  maxTokens: number,
  temperature: number,
  userId: string | undefined,
  isAdmin: boolean
): Promise<Response> {
  const systemInstruction = messages.filter((m) => m.role === "system").map((m) => m.content).join("\n");
  const contents = messages.filter((m) => m.role !== "system").map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }],
  }));
  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?key=${GEMINI_API_KEY}&alt=sse`;
  console.log(`[ai-gemini-stream v22] Calling Gemini streaming API: model=${model}`);
  const geminiResponse = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents,
      systemInstruction: systemInstruction ? { parts: [{ text: systemInstruction }] } : undefined,
      generationConfig: { temperature: 1.0, maxOutputTokens: maxTokens, topP: 0.9, topK: 40, stopSequences: ["[/SUGGESTED_QUESTIONS]"] },
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
    console.error("[ai-gemini-stream v22] Gemini API error:", errorText);
    throw new Error(`Gemini API error: ${geminiResponse.status}`);
  }
  let totalPromptTokens = 0;
  let totalCompletionTokens = 0;
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
          const lines = buffer.split("\n");
          buffer = lines.pop() || "";
          for (const line of lines) {
            if (line.startsWith("data: ")) {
              const jsonStr = line.slice(6).trim();
              if (!jsonStr || jsonStr === "[DONE]") continue;
              try {
                const data = JSON.parse(jsonStr);
                const candidate = data.candidates?.[0];
                const finishReason = candidate?.finishReason;
                if (finishReason && finishReason !== "STOP") {
                  if (finishReason === "SAFETY") {
                    const safetyData = JSON.stringify({ text: "\n\n[안전 필터에 의해 응답이 차단되었습니다. 다른 질문을 해주세요.]", done: false, finish_reason: "SAFETY" });
                    controller.enqueue(encoder.encode(`data: ${safetyData}\n\n`));
                  }
                }
                const text = candidate?.content?.parts?.[0]?.text || "";
                if (data.usageMetadata) {
                  totalPromptTokens = data.usageMetadata.promptTokenCount || 0;
                  totalCompletionTokens = data.usageMetadata.candidatesTokenCount || 0;
                }
                if (text) {
                  const sseData = JSON.stringify({ text, done: false, finish_reason: finishReason });
                  controller.enqueue(encoder.encode(`data: ${sseData}\n\n`));
                }
              } catch (parseError) {
                console.error("[ai-gemini-stream v22] Parse error:", parseError);
              }
            }
          }
        }
        const doneData = JSON.stringify({ text: "", done: true, usage: { prompt_tokens: totalPromptTokens, completion_tokens: totalCompletionTokens, total_tokens: totalPromptTokens + totalCompletionTokens } });
        controller.enqueue(encoder.encode(`data: ${doneData}\n\n`));
        if (userId && (totalPromptTokens > 0 || totalCompletionTokens > 0)) {
          const cost = (totalPromptTokens * 0.075 / 1000000) + (totalCompletionTokens * 0.30 / 1000000);
          await recordTokenUsage(supabase, userId, totalPromptTokens, totalCompletionTokens, cost, isAdmin);
        }
      } catch (error) {
        console.error("[ai-gemini-stream v22] Stream error:", error);
        const errorData = JSON.stringify({ error: "Stream error", done: true });
        controller.enqueue(encoder.encode(`data: ${errorData}\n\n`));
      } finally {
        controller.close();
      }
    },
  });
  return new Response(stream, {
    headers: { ...corsHeaders, "Content-Type": "text/event-stream", "Cache-Control": "no-cache", "Connection": "keep-alive" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    if (!GEMINI_API_KEY) throw new Error("GEMINI_API_KEY is not configured");
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
    const requestData: GeminiRequest = await req.json();
    const action = requestData.action || "chat";
    if (action === "classify-intent") {
      const { user_message, chat_history, user_id } = requestData;
      if (!user_message) throw new Error("user_message is required for intent classification");
      let isAdmin = false;
      if (user_id) isAdmin = await isAdminUser(supabase, user_id);
      return await handleIntentClassification(supabase, user_message, chat_history, user_id, isAdmin);
    }
    const { messages, model = "gemini-3-flash-preview", max_tokens = 16384, temperature = 0.8, user_id, stream = false } = requestData;
    if (!messages || messages.length === 0) throw new Error("messages is required");
    let isAdmin = false;
    if (user_id) {
      isAdmin = await isAdminUser(supabase, user_id);
      console.log(`[ai-gemini v22] User ${user_id} isAdmin: ${isAdmin}`);
      if (!isAdmin) {
        // v22: chatting_tokens만 쿼터 대상 (운세 토큰 제외)
        const quota = await checkAndUpdateQuota(supabase, user_id, 0, isAdmin);
        if (!quota.allowed) {
          console.log(`[ai-gemini v22] Chat quota exceeded for user ${user_id} (chatting_tokens only)`);
          return new Response(
            JSON.stringify({
              success: false, error: "QUOTA_EXCEEDED",
              message: "오늘 사용 가능한 토큰을 모두 사용했습니다. 광고를 시청하면 추가 토큰을 받을 수 있습니다.",
              tokens_used: DAILY_QUOTA - quota.remaining,
              quota_limit: quota.quotaLimit,
              ads_required: true,
            }),
            { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      }
    }
    if (stream) {
      console.log(`[ai-gemini v22] Streaming mode: model=${model}`);
      return await handleStreamingRequest(supabase, messages, model, max_tokens, temperature, user_id, isAdmin);
    }
    console.log(`[ai-gemini v22] Non-streaming: model=${model}, isAdmin=${isAdmin}`);
    const systemInstruction = messages.filter((m) => m.role === "system").map((m) => m.content).join("\n");
    const contents = messages.filter((m) => m.role !== "system").map((m) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: m.content }],
    }));
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`;
    const response = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents,
        systemInstruction: systemInstruction ? { parts: [{ text: systemInstruction }] } : undefined,
        generationConfig: { temperature: 1.0, maxOutputTokens: max_tokens, topP: 0.9, topK: 40, stopSequences: ["[/SUGGESTED_QUESTIONS]"] },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
          { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
        ],
      }),
    });
    const data = await response.json();
    if (data.error) {
      console.error("[ai-gemini v22] Gemini API Error:", data.error);
      return new Response(JSON.stringify({ success: false, error: data.error.message || "Gemini API error" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    const candidate = data.candidates?.[0];
    if (!candidate) throw new Error("No response from Gemini");
    if (candidate.finishReason === "SAFETY") throw new Error("Response blocked due to safety settings");
    const content = candidate.content?.parts?.[0]?.text || "";
    const usageMetadata = data.usageMetadata || {};
    const promptTokens = usageMetadata.promptTokenCount || 0;
    const completionTokens = usageMetadata.candidatesTokenCount || 0;
    const totalTokens = usageMetadata.totalTokenCount || 0;
    const cost = (promptTokens * 0.075 / 1000000) + (completionTokens * 0.30 / 1000000);
    if (user_id) await recordTokenUsage(supabase, userId, promptTokens, completionTokens, cost, isAdmin);
    console.log(`[ai-gemini v22] Success: prompt=${promptTokens}, completion=${completionTokens}, isAdmin=${isAdmin}`);
    return new Response(
      JSON.stringify({ success: true, content, usage: { prompt_tokens: promptTokens, completion_tokens: completionTokens, total_tokens: totalTokens }, model, finish_reason: candidate.finishReason, is_admin: isAdmin }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[ai-gemini v22] Error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
