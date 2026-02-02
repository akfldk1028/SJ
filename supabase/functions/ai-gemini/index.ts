import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * Gemini API 호출 Edge Function (v27)
 *
 * v27 변경사항 (2026-02-02):
 * - BUG FIX: cachedTokens → totalCachedTokens 변수명 오타 수정 (ReferenceError 방지)
 * - BUG FIX: createGeminiCache()에서 불필요한 contents 필드 제거 (API 에러 방지)
 * - BUG FIX: 캐시 만료 시 캐시 없이 표준 요청으로 fallback 재시도
 *
 * v26 변경사항 (2026-02-02):
 * - BUG FIX: usageMetadata 누락 시 fallback 비용 추산 (응답 텍스트 길이 기반)
 *   → 19% 레코드의 gemini_cost_usd=0 누락 해소
 * - Context Caching 지원 (cachedContent 파라미터)
 *   → system prompt + saju 데이터 캐싱으로 input 비용 90% 절감
 *
 * v25 변경사항 (2026-02-01):
 * - BUG FIX: 스트리밍 버퍼 미처리 → 루프 후 잔여 buffer 파싱 (usageMetadata 유실 방지)
 * - BUG FIX: chatting_tokens 이중 기록 → recordTokenUsage에서 chatting_tokens 제거
 *   (DB 트리거 update_daily_chat_tokens가 chat_messages INSERT 시 정확히 기록)
 *   recordTokenUsage는 gemini_cost_usd만 기록
 * - BUG FIX: 스트리밍 thought 파트 필터링 (Gemini 3.0 thinking 내용 제외)
 *
 * v24 변경사항 (2026-02-01):
 * - checkAndUpdateQuota: rewarded_tokens_earned 포함 (광고 보상 토큰 반영)
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

const DAILY_QUOTA = 20000;
const ADMIN_QUOTA = 1000000000;

/** KST(UTC+9) 기준 오늘 날짜 (YYYY-MM-DD) */
function getTodayKST(): string {
  return new Date().toLocaleString("sv-SE", { timeZone: "Asia/Seoul" }).split(" ")[0];
}

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
  session_id?: string;
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
 * v24: Quota 확인 - chatting_tokens만 대상, bonus_tokens + rewarded_tokens_earned 포함
 * 운세 토큰(saju_analysis, monthly, yearly 등)은 핵심 콘텐츠이므로 쿼터 면제
 * 채팅만 일일 쿼터 제한 적용
 * effective_quota = daily_quota + bonus_tokens + rewarded_tokens_earned
 */
async function checkAndUpdateQuota(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  tokensUsed: number,
  isAdmin: boolean
): Promise<{ allowed: boolean; remaining: number; quotaLimit: number }> {
  const quotaLimit = isAdmin ? ADMIN_QUOTA : DAILY_QUOTA;
  const today = getTodayKST();
  try {
    // v26: IAP 구독 확인 - day_pass/week_pass/monthly 활성 구독이면 quota 면제
    const { data: sub } = await supabase
      .from("subscriptions")
      .select("status, product_id, expires_at, is_lifetime")
      .eq("user_id", userId)
      .in("product_id", ["sadam_day_pass", "sadam_week_pass", "sadam_monthly"])
      .eq("status", "active")
      .maybeSingle();

    if (sub) {
      // 만료 시간 체크 (is_lifetime이면 항상 유효)
      const isValid = sub.is_lifetime ||
        !sub.expires_at ||
        new Date(sub.expires_at) > new Date();
      if (isValid) {
        console.log(`[ai-gemini v26] Premium subscriber: ${sub.product_id} → quota exempt`);
        return { allowed: true, remaining: ADMIN_QUOTA, quotaLimit: ADMIN_QUOTA };
      }
    }

    const { data: usage } = await supabase
      .from("user_daily_token_usage")
      .select("chatting_tokens, daily_quota, bonus_tokens, rewarded_tokens_earned, native_tokens_earned")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();
    // v27: chatting_tokens만 쿼터 대상, bonus_tokens + rewarded_tokens_earned + native_tokens_earned 포함
    const currentChatUsage = usage?.chatting_tokens || 0;
    const baseQuota = isAdmin ? ADMIN_QUOTA : (usage?.daily_quota || DAILY_QUOTA);
    const bonusTokens = usage?.bonus_tokens || 0;
    const rewardedTokens = usage?.rewarded_tokens_earned || 0;
    const nativeTokens = usage?.native_tokens_earned || 0;
    const effectiveQuota = baseQuota + bonusTokens + rewardedTokens + nativeTokens;
    const remaining = effectiveQuota - currentChatUsage;
    if (isAdmin) return { allowed: true, remaining: ADMIN_QUOTA, quotaLimit: ADMIN_QUOTA };
    if (currentChatUsage >= effectiveQuota) return { allowed: false, remaining: 0, quotaLimit: effectiveQuota };
    return { allowed: true, remaining, quotaLimit: effectiveQuota };
  } catch {
    return { allowed: true, remaining: quotaLimit, quotaLimit };
  }
}

/**
 * v25: gemini_cost_usd만 기록
 * chatting_tokens는 DB 트리거(update_daily_chat_tokens)가 chat_messages INSERT 시 정확히 기록
 * → 이중 기록 방지 (이전 버전에서는 Edge Function + 트리거 둘 다 chatting_tokens 갱신하여 이중 카운트)
 */
async function recordGeminiCost(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  promptTokens: number,
  completionTokens: number,
  cost: number
): Promise<void> {
  const today = getTodayKST();
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
    console.log(`[ai-gemini v25] Recorded gemini_cost=$${cost.toFixed(6)} (prompt=${promptTokens}, completion=${completionTokens}) for user ${userId}`);
  } catch (error) {
    console.error("[ai-gemini v25] Failed to record gemini cost:", error);
  }
}

async function handleIntentClassification(
  supabase: ReturnType<typeof createClient>,
  userMessage: string,
  chatHistory: string[] | undefined,
  userId: string | undefined,
  isAdmin: boolean
): Promise<Response> {
  console.log(`[ai-gemini-intent v23] Classifying intent: ${userMessage.substring(0, 50)}...`);
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
      console.error("[ai-gemini-intent v23] Gemini API Error:", data.error);
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
      // Gemini 2.5 Flash Lite: $0.10/$0.40 (공식 가격 2026-02)
      const cost = (promptTokens * 0.10 / 1000000) + (completionTokens * 0.40 / 1000000);
      await recordGeminiCost(supabase, userId, promptTokens, completionTokens, cost);
    }
    return new Response(JSON.stringify({ success: true, categories, reason }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    console.error("[ai-gemini-intent v23] Error:", error);
    return new Response(JSON.stringify({ success: true, categories: ["GENERAL"], reason: "오류 발생" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
}

/**
 * v26: Gemini Context Caching — 세션별 system prompt + saju 데이터 캐싱
 * 캐시된 토큰은 $0.05/1M (표준 $0.50의 90% 할인)
 * 최소 1,024 토큰 필요 (system prompt + saju 데이터 = 4~6K → 충족)
 */
async function createGeminiCache(
  systemContent: string,
  model: string,
  ttlSeconds: number = 3600
): Promise<string | null> {
  try {
    const cacheUrl = `https://generativelanguage.googleapis.com/v1beta/cachedContents?key=${GEMINI_API_KEY}`;
    const response = await fetch(cacheUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: `models/${model}`,
        systemInstruction: { parts: [{ text: systemContent }] },
        ttl: `${ttlSeconds}s`,
      }),
    });
    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[ai-gemini v26] Cache creation failed: ${response.status}`, errorText);
      return null;
    }
    const data = await response.json();
    console.log(`[ai-gemini v26] Cache created: ${data.name}, expireTime=${data.expireTime}`);
    return data.name;
  } catch (error) {
    console.error("[ai-gemini v26] Cache creation error:", error);
    return null;
  }
}

async function deleteGeminiCache(cacheName: string): Promise<void> {
  try {
    const deleteUrl = `https://generativelanguage.googleapis.com/v1beta/${cacheName}?key=${GEMINI_API_KEY}`;
    await fetch(deleteUrl, { method: "DELETE" });
    console.log(`[ai-gemini v26] Cache deleted: ${cacheName}`);
  } catch (error) {
    console.error("[ai-gemini v26] Cache deletion error:", error);
  }
}

async function handleStreamingRequest(
  supabase: ReturnType<typeof createClient>,
  messages: ChatMessage[],
  model: string,
  maxTokens: number,
  temperature: number,
  userId: string | undefined,
  isAdmin: boolean,
  sessionId?: string
): Promise<Response> {
  const systemInstruction = messages.filter((m) => m.role === "system").map((m) => m.content).join("\n");
  const contents = messages.filter((m) => m.role !== "system").map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }],
  }));

  // v30: 빈 contents 방어 — user 메시지 없으면 Gemini 400 에러 방지
  if (contents.length === 0) {
    console.error("[ai-gemini v30] Empty contents — no user/assistant messages. Returning error.");
    return new Response(
      JSON.stringify({ error: "No user message provided", code: "EMPTY_CONTENTS" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // v26: Context Caching — 세션에 캐시가 있으면 사용, 없으면 생성
  let cacheName: string | null = null;
  if (sessionId && systemInstruction.length > 500) {
    // 세션에 기존 캐시가 있는지 확인
    const { data: session } = await supabase
      .from("chat_sessions")
      .select("gemini_cache_name")
      .eq("id", sessionId)
      .single();

    if (session?.gemini_cache_name) {
      cacheName = session.gemini_cache_name;
      console.log(`[ai-gemini v26] Using existing cache: ${cacheName}`);
    } else {
      // 캐시 생성 (system prompt가 충분히 길 때만 — 1024 tokens ≈ 400자 이상)
      cacheName = await createGeminiCache(systemInstruction, model);
      if (cacheName) {
        await supabase
          .from("chat_sessions")
          .update({ gemini_cache_name: cacheName })
          .eq("id", sessionId);
      }
    }
  }

  // 캐시 사용 시 다른 엔드포인트 (cachedContent 참조)
  let geminiUrl: string;
  let requestBody: Record<string, unknown>;

  if (cacheName) {
    geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?key=${GEMINI_API_KEY}&alt=sse`;
    requestBody = {
      cachedContent: cacheName,
      contents,
      generationConfig: { temperature: 1.0, maxOutputTokens: maxTokens, topP: 0.9, topK: 40, stopSequences: ["[/SUGGESTED_QUESTIONS]"] },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
      ],
    };
    console.log(`[ai-gemini-stream v26] Using cached content: ${cacheName}`);
  } else {
    geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?key=${GEMINI_API_KEY}&alt=sse`;
    requestBody = {
      contents,
      systemInstruction: systemInstruction ? { parts: [{ text: systemInstruction }] } : undefined,
      generationConfig: { temperature: 1.0, maxOutputTokens: maxTokens, topP: 0.9, topK: 40, stopSequences: ["[/SUGGESTED_QUESTIONS]"] },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
      ],
    };
    console.log(`[ai-gemini-stream v26] No cache, standard request: model=${model}`);
  }
  let geminiResponse = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(requestBody),
  });
  // v27: 캐시 에러 시 캐시 삭제 + 캐시 없이 재시도 (fallback)
  if (!geminiResponse.ok && cacheName) {
    const errorText = await geminiResponse.text();
    console.warn(`[ai-gemini v27] Cache request failed (${geminiResponse.status}), falling back to standard request. Error: ${errorText}`);
    if (sessionId) {
      await supabase.from("chat_sessions").update({ gemini_cache_name: null }).eq("id", sessionId);
    }
    cacheName = null;
    // 캐시 없이 표준 요청으로 재시도
    const fallbackBody = {
      contents,
      systemInstruction: systemInstruction ? { parts: [{ text: systemInstruction }] } : undefined,
      generationConfig: { temperature: 1.0, maxOutputTokens: maxTokens, topP: 0.9, topK: 40, stopSequences: ["[/SUGGESTED_QUESTIONS]"] },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
      ],
    };
    console.log(`[ai-gemini v27] [FALLBACK] Retrying without cache: model=${model}`);
    geminiResponse = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(fallbackBody),
    });
  }
  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    console.error("[ai-gemini-stream v27] Gemini API error:", errorText);
    throw new Error(`Gemini API error: ${geminiResponse.status}`);
  }
  let totalPromptTokens = 0;
  let totalCompletionTokens = 0;
  let totalCachedTokens = 0;
  const stream = new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      const reader = geminiResponse.body!.getReader();
      const decoder = new TextDecoder();
      let buffer = "";

      // v25: SSE 라인 파싱 헬퍼 (thought 필터링 포함)
      function processSSELine(line: string) {
        if (!line.startsWith("data: ")) return;
        const jsonStr = line.slice(6).trim();
        if (!jsonStr || jsonStr === "[DONE]") return;
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
          // v25: thought 파트 필터링 (Gemini 3.0 thinking 내용 제외)
          let text = "";
          const parts = candidate?.content?.parts;
          if (Array.isArray(parts)) {
            for (const part of parts) {
              if (part.thought === true) continue; // thinking 파트 스킵
              if (part.text) text += part.text;
            }
          }
          // v26: usageMetadata 캡처 (마지막 청크에 포함, cachedContentTokenCount 추가)
          if (data.usageMetadata) {
            totalPromptTokens = data.usageMetadata.promptTokenCount || 0;
            totalCompletionTokens = data.usageMetadata.candidatesTokenCount || 0;
            totalCachedTokens = data.usageMetadata.cachedContentTokenCount || 0;
          }
          if (text) {
            const sseData = JSON.stringify({ text, done: false, finish_reason: finishReason });
            controller.enqueue(encoder.encode(`data: ${sseData}\n\n`));
          }
        } catch (parseError) {
          console.error("[ai-gemini-stream v25] Parse error:", parseError);
        }
      }

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split("\n");
          buffer = lines.pop() || "";
          for (const line of lines) {
            processSSELine(line);
          }
        }
        // v25 BUG FIX: 잔여 버퍼 처리 (usageMetadata가 마지막 청크에 있음)
        // decoder flush (stream: false로 잔여 바이트 방출)
        buffer += decoder.decode(new Uint8Array(), { stream: false });
        if (buffer.trim()) {
          const remainingLines = buffer.split("\n");
          for (const line of remainingLines) {
            processSSELine(line);
          }
        }
        console.log(`[ai-gemini-stream v26] Stream done. prompt=${totalPromptTokens}, completion=${totalCompletionTokens}, cached=${totalCachedTokens}`);
        const doneData = JSON.stringify({ text: "", done: true, usage: { prompt_tokens: totalPromptTokens, completion_tokens: totalCompletionTokens, total_tokens: totalPromptTokens + totalCompletionTokens, cached_tokens: totalCachedTokens } });
        controller.enqueue(encoder.encode(`data: ${doneData}\n\n`));
        // v26: gemini_cost_usd 기록 (fallback + context caching 할인 포함)
        if (userId) {
          if (totalPromptTokens > 0 || totalCompletionTokens > 0) {
            // v26: cachedContentTokenCount가 있으면 캐시 할인 적용 ($0.05/1M vs $0.50/1M)
            const nonCachedPrompt = totalPromptTokens - totalCachedTokens;
            const cost = (nonCachedPrompt * 0.50 / 1000000) + (totalCachedTokens * 0.05 / 1000000) + (totalCompletionTokens * 3.00 / 1000000);
            await recordGeminiCost(supabase, userId, totalPromptTokens, totalCompletionTokens, cost);
          } else {
            // v26 FALLBACK: usageMetadata 누락 시 응답 텍스트 길이 기반 추산
            // 수집된 SSE 텍스트로 completion tokens 추산, system prompt로 prompt tokens 추산
            const systemPromptLength = messages.filter((m) => m.role === "system").reduce((sum, m) => sum + m.content.length, 0);
            const chatHistoryLength = messages.filter((m) => m.role !== "system").reduce((sum, m) => sum + m.content.length, 0);
            // 한글 기준: 1자 ≈ 2~3 tokens, 보수적으로 2.5 적용
            const estPromptTokens = Math.round((systemPromptLength + chatHistoryLength) * 2.5);
            // completion은 클라이언트에서 tokens_used로 정확히 잡히므로 여기선 평균값 사용
            const estCompletionTokens = Math.round(1500); // 평균 응답 길이 기반
            const estCost = (estPromptTokens * 0.50 / 1000000) + (estCompletionTokens * 3.00 / 1000000);
            console.log(`[ai-gemini v26] [FALLBACK] usageMetadata missing. Estimated prompt=${estPromptTokens}, completion=${estCompletionTokens}, cost=$${estCost.toFixed(6)}`);
            await recordGeminiCost(supabase, userId, estPromptTokens, estCompletionTokens, estCost);
          }
        }
      } catch (error) {
        console.error("[ai-gemini-stream v26] Stream error:", error);
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
    const { messages, model = "gemini-3-flash-preview", max_tokens = 16384, temperature = 0.8, user_id, stream = false, session_id } = requestData;
    if (!messages || messages.length === 0) throw new Error("messages is required");
    let isAdmin = false;
    if (user_id) {
      isAdmin = await isAdminUser(supabase, user_id);
      console.log(`[ai-gemini v23] User ${user_id} isAdmin: ${isAdmin}`);
      if (!isAdmin) {
        // v22: chatting_tokens만 쿼터 대상 (운세 토큰 제외)
        const quota = await checkAndUpdateQuota(supabase, user_id, 0, isAdmin);
        if (!quota.allowed) {
          console.log(`[ai-gemini v23] Chat quota exceeded for user ${user_id} (chatting_tokens only)`);
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
      console.log(`[ai-gemini v26] Streaming mode: model=${model}, session_id=${session_id || 'none'}`);
      return await handleStreamingRequest(supabase, messages, model, max_tokens, temperature, user_id, isAdmin, session_id);
    }
    console.log(`[ai-gemini v23] Non-streaming: model=${model}, isAdmin=${isAdmin}`);
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
      console.error("[ai-gemini v23] Gemini API Error:", data.error);
      return new Response(JSON.stringify({ success: false, error: data.error.message || "Gemini API error" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    const candidate = data.candidates?.[0];
    if (!candidate) throw new Error("No response from Gemini");
    if (candidate.finishReason === "SAFETY") throw new Error("Response blocked due to safety settings");
    // v25: thought 파트 필터링 (스트리밍과 동일하게)
    let content = "";
    const parts = candidate.content?.parts;
    if (Array.isArray(parts)) {
      for (const part of parts) {
        if (part.thought === true) continue;
        if (part.text) content += part.text;
      }
    }
    const usageMetadata = data.usageMetadata || {};
    const promptTokens = usageMetadata.promptTokenCount || 0;
    const completionTokens = usageMetadata.candidatesTokenCount || 0;
    const totalTokens = usageMetadata.totalTokenCount || 0;
    // Gemini 3.0 Flash: $0.50/$3.00
    const cost = (promptTokens * 0.50 / 1000000) + (completionTokens * 3.00 / 1000000);
    if (user_id) await recordGeminiCost(supabase, user_id, promptTokens, completionTokens, cost);
    console.log(`[ai-gemini v25] Success: prompt=${promptTokens}, completion=${completionTokens}, isAdmin=${isAdmin}`);
    return new Response(
      JSON.stringify({ success: true, content, usage: { prompt_tokens: promptTokens, completion_tokens: completionTokens, total_tokens: totalTokens }, model, finish_reason: candidate.finishReason, is_admin: isAdmin }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[ai-gemini v23] Error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
