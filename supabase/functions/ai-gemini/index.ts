import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
// v76: saju-tools — 동적 import로 실패 시 기존 동작 유지
let sajuToolDeclarations: any[] = [];
let openaiToolDeclarations: any[] = [];
let executeSajuFunction: ((name: string, args: { [k: string]: unknown }) => unknown) | null = null;
try {
  const mod = await import("./saju-tools/index.ts");
  sajuToolDeclarations = mod.sajuToolDeclarations;
  openaiToolDeclarations = mod.openaiToolDeclarations;
  executeSajuFunction = mod.executeSajuFunction;
  console.log(`[ai-gemini v77] saju-tools loaded: gemini=${sajuToolDeclarations[0]?.functionDeclarations?.length || 0}, openai=${openaiToolDeclarations.length} tools`);
} catch (e) {
  console.error("[ai-gemini v77] saju-tools load failed, running without tools:", e);
}

/**
 * Gemini API 호출 Edge Function (v36)
 *
 * v36 변경사항 (2026-03-21):
 * - BUG FIX: Gemini 3 Flash Preview 반복 출력 방어 (공식 known issue)
 *   → 같은 문자 연속 20회 이상 감지 시 스트림 즉시 종료
 *   → 같은 2~4자 패턴 10회 이상 반복 감지 시 스트림 즉시 종료
 *   → 토큰 낭비 방지 + 클라이언트에 REPETITION_DETECTED 에러 전송
 *   → 참고: https://discuss.ai.google.dev/t/gemini-3-flash-preview-infinite-reasoning-loop-causing-max-token-exhaustion-raw-logic-leak/114528
 *   → 참고: https://ai.google.dev/gemini-api/docs/troubleshooting (Repetitive output 섹션)
 *
 * v35.2 변경사항 (2026-03-17):
 * - BUG FIX: 스트리밍 candidatesTokenCount에 thinking 토큰 간헐적 혼입 (쿼타 2.5~3배 과다)
 *   → Gemini 3 Flash: thinkingLevel "minimal" 적용 (generationConfig 내부, 공식 문서 준수)
 *     ※ thinkingBudget은 Gemini 2.5 전용, thinkingLevel은 Gemini 3 전용
 *     ※ Gemini 3 Flash는 thinking 완전 비활성화 불가 ("minimal"이 최저)
 *   → 방어1: thoughts 차감 (thoughtsTokenCount 보고 시)
 *   → 방어2: 텍스트 길이 기반 상한선 (1.5 tokens/char 초과 시 cap)
 *   → 영향: 쿼타 과다 소진 방지
 *
 * v34 변경사항 (2026-03-17):
 * - non-streaming: thinkingConfig { thinkingLevel: "low" } 추가 (운세 JSON에 heavy thinking 불필요)
 * - non-streaming: thought 필터링 강화 (thoughtSignature 스킵 + JSON 추출 fallback)
 *   → "thought" 텍스트가 content에 혼입되어 JSON 파싱 실패하던 버그 수정
 *
 * v33 변경사항 (2026-03-17):
 * - REVERT v32: candidatesTokenCount는 thinking 미포함 (공식 문서 확인)
 *   → thoughtsTokenCount 차감 제거 (v32가 오히려 과소 차감 유발)
 *   → 로그에 thoughtsTokenCount 추가하여 실제 값 추적
 *
 * v31 변경사항 (2026-02-08):
 * - BUG FIX: checkAndUpdateQuota catch 블록 fail-open → fail-closed
 *   → 이전: DB 에러 시 allowed: true → quota 우회 가능
 *   → 수정: DB 에러 시 allowed: false → 안전하게 차단
 *
 * v29 변경사항 (2026-02-08):
 * - BUG FIX: 프리미엄 만료 후 chatting_tokens 리셋이 매 API 호출마다 반복 실행되던 치명적 버그 수정
 *   → premium_quota_reset 플래그로 하루 1회만 리셋하도록 제한
 *   → 이전: expiredSub + chatting_tokens > effectiveQuota → 매번 0으로 리셋 → 쿼타 시스템 무효화
 *   → 수정: premium_quota_reset = true 설정 → 이후 리셋 스킵
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
 * v37 변경사항 (2026-04-04):
 * - 비용 절감: 채팅 모델 gemini-3-flash-preview → gemini-2.5-flash-lite 전환
 *   → Input: $0.50 → $0.10 (5배 절감), Output: $3.00 → $0.40 (7.5배 절감)
 *   → thinkingConfig: thinkingLevel(Gemini3 전용) → thinkingBudget:0(Gemini2.5 전용, thinking 비활성화)
 *   → Context Caching: $0.05 → $0.01 (5배 절감)
 *
 * v38 변경사항 (2026-04-04):
 * - Explicit caching → Implicit caching 전환 (Gemini 2.5+ 자동 지원)
 *   → createGeminiCache/deleteGeminiCache/gemini_cache_name 제거
 *   → 저장 비용 $1.00/1M토큰/시간 → $0 (implicit은 무료)
 *   → Explicit: systemInstruction만 캐시 (8% 절감) → Implicit: prefix 전체 캐시 (최대 89% 절감)
 * - 세션 고정 키 라우팅 (getSessionKey)
 *   → 동일 세션의 연속 요청이 같은 API 키 사용 → implicit cache chain 보장
 *   → Intent는 라운드로빈 유지 (세션 무관 호출)
 * - cachedContentTokenCount 로깅 추가 (캐시 적중률 모니터링)
 * - non-streaming 비용 계산: implicit cache 할인 반영
 *
 * === 모델 설정 ===
 * 채팅용: gemini-2.5-flash-lite
 * Intent: gemini-2.5-flash-lite
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, cache-control",
};

// v77: Qwen 3.5 Flash (DashScope 싱가포르) — primary provider
// GPQA 84.2% vs Gemini Lite 64.6%, 가격 동일 ($0.10/$0.40), explicit cache 90% 할인
const QWEN_API_KEY = Deno.env.get("QWEN_API_KEY");
const QWEN_BASE_URL = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1";
const QWEN_MODEL = "qwen3.5-flash";

// v62: Gemini API Key 로테이션 (fallback용)
const GEMINI_API_KEYS = [
  Deno.env.get("GEMINI_API_KEY"),
  Deno.env.get("GEMINI_API_KEY_2"),
  Deno.env.get("GEMINI_API_KEY_3"),
].filter(Boolean) as string[];

let geminiKeyIndex = 0;

/** 라운드로빈 키 선택 (intent 등 세션 무관한 호출용) */
function getNextGeminiKey(): string {
  if (GEMINI_API_KEYS.length === 0) throw new Error("No GEMINI_API_KEY configured");
  const key = GEMINI_API_KEYS[geminiKeyIndex % GEMINI_API_KEYS.length];
  geminiKeyIndex++;
  return key;
}

/**
 * v38: 세션 고정 키 선택 (implicit caching 최적화)
 * 동일 세션의 연속 요청이 같은 API 키를 사용하면
 * Gemini implicit caching이 prefix 전체를 캐시 → input 비용 최대 90% 절감
 * Intent는 매번 다른 프롬프트이므로 라운드로빈(getNextGeminiKey) 유지
 */
function getSessionKey(sessionId: string): string {
  if (GEMINI_API_KEYS.length === 0) throw new Error("No GEMINI_API_KEY configured");
  // 간단한 해시: sessionId 문자 코드 합 → 키 인덱스
  let hash = 0;
  for (let i = 0; i < sessionId.length; i++) {
    hash = ((hash << 5) - hash + sessionId.charCodeAt(i)) | 0;
  }
  return GEMINI_API_KEYS[((hash % GEMINI_API_KEYS.length) + GEMINI_API_KEYS.length) % GEMINI_API_KEYS.length];
}

// v38: GEMINI_API_KEY 상수 제거 (explicit caching 제거로 불필요)

/**
 * v77: Qwen 3.5 Flash Non-Streaming 호출
 * - OpenAI 호환 API (DashScope 싱가포르)
 * - explicit cache: system message에 cache_control 마커 → 90% 할인
 * - 실패 시 null 반환 → Gemini fallback
 */
async function callQwenNonStreaming(
  messages: { role: string; content: string }[],
  maxTokens: number,
  temperature: number,
): Promise<{ content: string; usage: { [k: string]: number } } | null> {
  if (!QWEN_API_KEY) return null;
  try {
    const systemMsgs = messages.filter((m) => m.role === "system");
    const otherMsgs = messages.filter((m) => m.role !== "system");
    const systemText = systemMsgs.map((m) => m.content).join("\n");

    const qwenMessages: { [k: string]: unknown }[] = [];
    if (systemText) {
      qwenMessages.push({
        role: "system",
        content: [{ type: "text", text: systemText, cache_control: { type: "ephemeral" } }],
      });
    }
    for (const m of otherMsgs) {
      qwenMessages.push({ role: m.role === "assistant" ? "assistant" : "user", content: m.content });
    }

    // v77: Function Calling Loop (최대 6회)
    const MAX_FC = 6;
    const hasTools = openaiToolDeclarations.length > 0 && executeSajuFunction;
    let totalUsage = { prompt_tokens: 0, completion_tokens: 0, cached_tokens: 0 };

    for (let i = 0; i < MAX_FC; i++) {
      const body: { [k: string]: unknown } = {
        model: QWEN_MODEL,
        messages: qwenMessages,
        max_tokens: maxTokens,
        temperature,
        presence_penalty: 0.6,
        stream: false,
        enable_thinking: false,
        stop: ["[/SUGGESTED_QUESTIONS]"],
      };
      if (hasTools) body.tools = openaiToolDeclarations;

      const resp = await fetch(`${QWEN_BASE_URL}/chat/completions`, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${QWEN_API_KEY}` },
        body: JSON.stringify(body),
      });
      if (!resp.ok) {
        const errText = await resp.text();
        console.error(`[ai-gemini v77] Qwen non-stream error ${resp.status}: ${errText}`);
        return null;
      }
      const data = await resp.json();
      const usage = data.usage || {};
      totalUsage.prompt_tokens += usage.prompt_tokens || 0;
      totalUsage.completion_tokens += usage.completion_tokens || 0;
      totalUsage.cached_tokens += usage.prompt_tokens_details?.cached_tokens || 0;

      const choice = data.choices?.[0];
      if (!choice) return null;

      // Function call 감지
      const toolCalls = choice.message?.tool_calls;
      if (toolCalls && toolCalls.length > 0 && executeSajuFunction) {
        // assistant message (tool_calls 포함) 추가
        qwenMessages.push(choice.message);
        for (const tc of toolCalls) {
          const fnName = tc.function.name;
          const fnArgs = JSON.parse(tc.function.arguments || "{}");
          const result = executeSajuFunction(fnName, fnArgs);
          console.log(`[ai-gemini v77] Qwen FC[${i}]: ${fnName}(${JSON.stringify(fnArgs)}) → ${JSON.stringify(result).substring(0, 100)}`);
          qwenMessages.push({ role: "tool", tool_call_id: tc.id, content: JSON.stringify(result) });
        }
        continue; // 다음 루프에서 결과 포함하여 재호출
      }

      // 텍스트 응답
      const content = choice.message?.content || "";
      console.log(`[ai-gemini v77] Qwen non-stream OK: prompt=${totalUsage.prompt_tokens}, comp=${totalUsage.completion_tokens}, cached=${totalUsage.cached_tokens}, fc=${i}`);
      return { content, usage: totalUsage };
    }
    console.error("[ai-gemini v77] Qwen FC loop exhausted");
    return null;
  } catch (e) {
    console.error("[ai-gemini v77] Qwen non-stream exception:", e);
    return null;
  }
}

/**
 * v77: Qwen 3.5 Flash Streaming 호출
 * - OpenAI SSE → 클라이언트 SSE 형식 변환 ({ text, done, usage })
 * - explicit cache 동일 적용
 * - 실패 시 null 반환 → Gemini streaming fallback
 */
async function handleQwenStreamingRequest(
  supabase: ReturnType<typeof createClient>,
  messages: { role: string; content: string }[],
  maxTokens: number,
  temperature: number,
  userId: string | undefined,
  isAdmin: boolean,
): Promise<Response | null> {
  if (!QWEN_API_KEY) return null;
  try {
    const systemMsgs = messages.filter((m) => m.role === "system");
    const otherMsgs = messages.filter((m) => m.role !== "system");
    const systemText = systemMsgs.map((m) => m.content).join("\n");

    const qwenMessages: { [k: string]: unknown }[] = [];
    if (systemText) {
      qwenMessages.push({
        role: "system",
        content: [{ type: "text", text: systemText, cache_control: { type: "ephemeral" } }],
      });
    }
    for (const m of otherMsgs) {
      qwenMessages.push({ role: m.role === "assistant" ? "assistant" : "user", content: m.content });
    }

    const resp = await fetch(`${QWEN_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${QWEN_API_KEY}` },
      body: JSON.stringify({
        model: QWEN_MODEL,
        messages: qwenMessages,
        max_tokens: maxTokens,
        temperature,
        presence_penalty: 0.6,
        stream: true,
        stream_options: { include_usage: true },
        enable_thinking: false,
        stop: ["[/SUGGESTED_QUESTIONS]"],
      }),
    });
    if (!resp.ok) {
      const errText = await resp.text();
      console.error(`[ai-gemini v77] Qwen stream error ${resp.status}: ${errText}`);
      return null;
    }

    let totalPromptTokens = 0;
    let totalCompletionTokens = 0;
    let totalCachedTokens = 0;
    let totalTextLength = 0;
    let accumulatedText = "";
    let repetitionDetected = false;

    function detectRepetition(text: string): boolean {
      if (text.length < 20) return false;
      const tail = text.slice(-100);
      if (/(.)\1{19,}/.test(tail)) return true;
      if (/(.{2,4})\1{9,}/.test(tail)) return true;
      return false;
    }

    const stream = new ReadableStream({
      async start(controller) {
        const encoder = new TextEncoder();
        const reader = resp.body!.getReader();
        const decoder = new TextDecoder();
        let buffer = "";

        function processLine(line: string) {
          if (repetitionDetected) return;
          if (!line.startsWith("data: ")) return;
          const jsonStr = line.slice(6).trim();
          if (!jsonStr || jsonStr === "[DONE]") return;
          try {
            const data = JSON.parse(jsonStr);
            // usage 캡처 (마지막 청크에 포함)
            if (data.usage) {
              totalPromptTokens = data.usage.prompt_tokens || 0;
              totalCompletionTokens = data.usage.completion_tokens || 0;
              totalCachedTokens = data.usage.prompt_tokens_details?.cached_tokens || 0;
            }
            const choice = data.choices?.[0];
            if (!choice) return;
            const text = choice.delta?.content || "";
            const finishReason = choice.finish_reason;

            if (text) {
              accumulatedText += text;
              if (accumulatedText.length > 200) accumulatedText = accumulatedText.slice(-200);
              if (detectRepetition(accumulatedText)) {
                repetitionDetected = true;
                console.error(`[ai-gemini v77] Qwen REPETITION DETECTED! Last 50: "${accumulatedText.slice(-50)}"`);
                controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: "\n\n[AI 응답에 오류가 발생했습니다. 다시 질문해주세요.]", done: false, finish_reason: "REPETITION_DETECTED" })}\n\n`));
                controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: "", done: true, error: "REPETITION_DETECTED", usage: { prompt_tokens: totalPromptTokens, completion_tokens: totalCompletionTokens, cached_tokens: totalCachedTokens } })}\n\n`));
                return;
              }
              totalTextLength += text.length;
              controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text, done: false, finish_reason: finishReason })}\n\n`));
            }
            if (finishReason === "stop" && !text) {
              // finish만 온 경우 (텍스트 없이)
            }
          } catch (e) {
            console.error("[ai-gemini v77] Qwen SSE parse error:", e);
          }
        }

        try {
          while (true) {
            if (repetitionDetected) { await reader.cancel(); break; }
            const { done, value } = await reader.read();
            if (done) break;
            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split("\n");
            buffer = lines.pop() || "";
            for (const line of lines) {
              processLine(line);
              if (repetitionDetected) break;
            }
          }
          if (!repetitionDetected) {
            buffer += decoder.decode(new Uint8Array(), { stream: false });
            if (buffer.trim()) {
              for (const line of buffer.split("\n")) processLine(line);
            }
          }
          // done 전송
          if (!repetitionDetected) {
            const cacheHitPct = totalPromptTokens > 0 ? Math.round(totalCachedTokens / totalPromptTokens * 100) : 0;
            console.log(`[ai-gemini v77] Qwen stream done: prompt=${totalPromptTokens}, comp=${totalCompletionTokens}, cached=${totalCachedTokens} (${cacheHitPct}%), textLen=${totalTextLength}`);
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: "", done: true, usage: { prompt_tokens: totalPromptTokens, completion_tokens: totalCompletionTokens, total_tokens: totalPromptTokens + totalCompletionTokens, cached_tokens: totalCachedTokens } })}\n\n`));
          }
          // 비용 기록 (Qwen 가격 = Gemini와 동일 $0.10/$0.40, explicit cache $0.01)
          if (userId && (totalPromptTokens > 0 || totalCompletionTokens > 0)) {
            const nonCached = totalPromptTokens - totalCachedTokens;
            const cost = (nonCached * 0.10 / 1000000) + (totalCachedTokens * 0.01 / 1000000) + (totalCompletionTokens * 0.40 / 1000000);
            await recordGeminiCost(supabase, userId, totalPromptTokens, totalCompletionTokens, cost);
          }
        } catch (e) {
          console.error("[ai-gemini v77] Qwen stream error:", e);
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: "Stream error", done: true })}\n\n`));
        } finally {
          controller.close();
        }
      },
    });
    return new Response(stream, {
      headers: { ...corsHeaders, "Content-Type": "text/event-stream", "Cache-Control": "no-cache", "Connection": "keep-alive" },
    });
  } catch (e) {
    console.error("[ai-gemini v77] Qwen stream setup error:", e);
    return null;
  }
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const DAILY_QUOTA = 5000;
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
 * v29: Quota 확인 - chatting_tokens만 대상, bonus_tokens + rewarded_tokens_earned 포함
 * 운세 토큰(saju_analysis, monthly, yearly 등)은 핵심 콘텐츠이므로 쿼터 면제
 * 채팅만 일일 쿼터 제한 적용
 * effective_quota = daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned
 *
 * v29: Premium 만료 시 chatting_tokens 자동 리셋 (하루 1회만)
 * - premium_quota_reset 플래그로 재리셋 방지
 * - Premium 중 누적된 chatting_tokens가 free quota 초과 → 만료 후 영구 차단 방지
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

    // v28: 만료된 구독이 있는지 확인 (최근 만료)
    // sub이 없거나 isValid가 false인 경우 = 구독 없음 or 만료
    // 최근 만료 구독 확인 → chatting_tokens 리셋 필요 여부 판단
    const { data: expiredSub } = await supabase
      .from("subscriptions")
      .select("product_id, expires_at")
      .eq("user_id", userId)
      .in("product_id", ["sadam_day_pass", "sadam_week_pass", "sadam_monthly"])
      .in("status", ["expired", "active"])
      .order("expires_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const { data: usage } = await supabase
      .from("user_daily_token_usage")
      .select("chatting_tokens, daily_quota, bonus_tokens, rewarded_tokens_earned, native_tokens_earned, premium_quota_reset")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    let currentChatUsage = usage?.chatting_tokens || 0;
    const baseQuota = isAdmin ? ADMIN_QUOTA : (usage?.daily_quota || DAILY_QUOTA);
    const bonusTokens = usage?.bonus_tokens || 0;
    const rewardedTokens = usage?.rewarded_tokens_earned || 0;
    const nativeTokens = usage?.native_tokens_earned || 0;
    const effectiveQuota = baseQuota + bonusTokens + rewardedTokens + nativeTokens;

    // v29: Premium 만료 후 chatting_tokens가 free quota를 크게 초과하면 리셋 (하루 1회만)
    // 케이스: day_pass가 오늘 중간에 만료 → 프리미엄 기간 사용량이 free quota 초과 → 리셋 필요
    // v28 버그: premium_quota_reset 플래그 없이 매 API 호출마다 리셋 반복 → 쿼타 시스템 무효화
    // v29 수정: premium_quota_reset = true 설정하여 하루 1회만 리셋
    if (expiredSub && currentChatUsage > effectiveQuota && !usage?.premium_quota_reset) {
      const expiredAt = expiredSub.expires_at ? new Date(expiredSub.expires_at) : null;
      const isRecentlyExpired = expiredAt && (Date.now() - expiredAt.getTime()) < 7 * 24 * 60 * 60 * 1000; // 7일 이내

      if (isRecentlyExpired) {
        console.log(`[ai-gemini v29] Premium expired (${expiredSub.product_id}), chatting_tokens=${currentChatUsage} > effectiveQuota=${effectiveQuota} → one-time reset`);
        // chatting_tokens를 0으로 리셋 + premium_quota_reset 플래그 설정 (재리셋 방지)
        await supabase
          .from("user_daily_token_usage")
          .update({ chatting_tokens: 0, premium_quota_reset: true, updated_at: new Date().toISOString() })
          .eq("user_id", userId)
          .eq("usage_date", today);
        currentChatUsage = 0;
      }
    }

    const remaining = effectiveQuota - currentChatUsage;
    if (isAdmin) return { allowed: true, remaining: ADMIN_QUOTA, quotaLimit: ADMIN_QUOTA };
    if (currentChatUsage >= effectiveQuota) return { allowed: false, remaining: 0, quotaLimit: effectiveQuota };
    return { allowed: true, remaining, quotaLimit: effectiveQuota };
  } catch (e) {
    console.error(`[ai-gemini v31] checkAndUpdateQuota error → blocking: ${e}`);
    return { allowed: false, remaining: 0, quotaLimit };
  }
}

/**
 * v25: gemini_cost_usd만 기록
 * chatting_tokens는 DB 트리거(update_daily_chat_tokens)가 chat_messages INSERT 시 정확히 기록
 * → 이중 기록 방지 (이전 버전에서는 Edge Function + 트리거 둘 다 chatting_tokens 갱신하여 이중 카운트)
 */
// v62: 원자적 UPSERT RPC — race condition 제거, DB 쿼리 2→1개
async function recordGeminiCost(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  promptTokens: number,
  completionTokens: number,
  cost: number
): Promise<void> {
  const today = getTodayKST();
  try {
    await supabase.rpc('increment_token_usage', {
      p_user_id: userId,
      p_usage_date: today,
      p_column_name: 'chatting_tokens',  // Gemini는 chatting용 → 컬럼은 DB 트리거가 처리, 여기선 cost만
      p_tokens: 0,  // chatting_tokens는 chat_messages INSERT 트리거가 기록 (이중 기록 방지)
      p_gpt_cost: 0,
      p_gemini_cost: cost,
      p_daily_quota: DAILY_QUOTA,
    });
    console.log(`[ai-gemini v62] Recorded gemini_cost=$${cost.toFixed(6)} (prompt=${promptTokens}, completion=${completionTokens}) for user ${userId}`);
  } catch (error) {
    console.error("[ai-gemini v62] Failed to record gemini cost:", error);
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
  // v62: Gemini Key 로테이션
  const intentKey = getNextGeminiKey();
  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${intentKey}`;
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

// v38: Explicit caching 제거 → Implicit caching으로 전환
// Gemini 2.5+ implicit caching: 동일 prefix 자동 캐시, 저장 비용 $0, 90% 할인
// 세션별 고정 키(getSessionKey)로 implicit cache chain 보장
// 이전 createGeminiCache/deleteGeminiCache/gemini_cache_name 관련 코드 제거

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

  // v38: Implicit caching — 세션 고정 키로 prefix 캐시 체인 보장
  // systemInstruction + contents[0..N-1] 이 동일하면 자동 캐시 적중 (90% 할인)
  const streamKey = sessionId ? getSessionKey(sessionId) : getNextGeminiKey();
  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?key=${streamKey}&alt=sse`;
  const requestBody = {
    contents,
    systemInstruction: systemInstruction ? { parts: [{ text: systemInstruction }] } : undefined,
    generationConfig: { temperature: 1.0, maxOutputTokens: maxTokens, topP: 0.9, topK: 40, stopSequences: ["[/SUGGESTED_QUESTIONS]"], thinkingConfig: { thinkingBudget: 0 } },
    safetySettings: [
      { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
      { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
      { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
      { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
    ],
  };
  console.log(`[ai-gemini-stream v38] model=${model}, session=${sessionId || 'none'}, key=session-fixed`);

  let geminiResponse = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(requestBody),
  });

  // v62: 429 rate limit → 다음 키로 retry
  if (geminiResponse.status === 429 && GEMINI_API_KEYS.length > 1) {
    console.warn(`[ai-gemini v38] Rate limited (429), trying next key...`);
    const retryKey = getNextGeminiKey();
    const retryUrl = geminiUrl.replace(/key=[^&]+/, `key=${retryKey}`);
    geminiResponse = await fetch(retryUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(requestBody),
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
  let totalThoughtsTokens = 0;
  let totalTextLength = 0; // v35.2: 응답 텍스트 총 길이 (토큰 보정용)
  const stream = new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      const reader = geminiResponse.body!.getReader();
      const decoder = new TextDecoder();
      let buffer = "";

      // v36: 반복 출력 감지 상태 (Gemini known issue 방어)
      let accumulatedText = ""; // 스트리밍 누적 텍스트 (최근 200자만 유지)
      let repetitionDetected = false;

      /**
       * v36: 반복 패턴 감지
       * - 같은 문자 연속 20회 이상 (예: ㄴㄴㄴㄴㄴㄴ..., \b\b\b..., \n\n\n...)
       * - 같은 2~4자 패턴 10회 이상 반복 (예: "아니요아니요아니요...")
       */
      function detectRepetition(text: string): boolean {
        if (text.length < 20) return false;
        // 검사 대상: 최근 100자
        const tail = text.slice(-100);

        // 감지1: 같은 문자 연속 20회
        const singleCharRepeat = /(.)\1{19,}/;
        if (singleCharRepeat.test(tail)) return true;

        // 감지2: 같은 2~4자 패턴 10회 반복
        const patternRepeat = /(.{2,4})\1{9,}/;
        if (patternRepeat.test(tail)) return true;

        return false;
      }

      // v25: SSE 라인 파싱 헬퍼 (thought 필터링 + v36 반복 감지 포함)
      function processSSELine(line: string) {
        if (repetitionDetected) return; // v36: 이미 감지되면 이후 청크 무시
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
          // v33: usageMetadata 캡처 (candidatesTokenCount는 thinking 미포함 — 공식 문서 확인)
          if (data.usageMetadata) {
            totalPromptTokens = data.usageMetadata.promptTokenCount || 0;
            totalCompletionTokens = data.usageMetadata.candidatesTokenCount || 0;
            totalCachedTokens = data.usageMetadata.cachedContentTokenCount || 0;
            totalThoughtsTokens = data.usageMetadata.thoughtsTokenCount || 0;
          }
          if (text) {
            // v36: 누적 텍스트에 추가 (최근 200자만 유지 — 메모리 절약)
            accumulatedText += text;
            if (accumulatedText.length > 200) {
              accumulatedText = accumulatedText.slice(-200);
            }

            // v36: 반복 패턴 감지
            if (detectRepetition(accumulatedText)) {
              repetitionDetected = true;
              console.error(`[ai-gemini v36] REPETITION DETECTED! Aborting stream. Last 50 chars: "${accumulatedText.slice(-50)}"`);
              // 클라이언트에 에러 알림
              const repData = JSON.stringify({ text: "\n\n[AI 응답에 오류가 발생했습니다. 다시 질문해주세요.]", done: false, finish_reason: "REPETITION_DETECTED" });
              controller.enqueue(encoder.encode(`data: ${repData}\n\n`));
              // 즉시 done 전송
              const doneData = JSON.stringify({ text: "", done: true, error: "REPETITION_DETECTED", usage: { prompt_tokens: totalPromptTokens, completion_tokens: totalCompletionTokens, thoughts_tokens: totalThoughtsTokens, total_tokens: totalPromptTokens + totalCompletionTokens, cached_tokens: totalCachedTokens } });
              controller.enqueue(encoder.encode(`data: ${doneData}\n\n`));
              return;
            }

            totalTextLength += text.length; // v35.2: 텍스트 길이 누적
            const sseData = JSON.stringify({ text, done: false, finish_reason: finishReason });
            controller.enqueue(encoder.encode(`data: ${sseData}\n\n`));
          }
        } catch (parseError) {
          console.error("[ai-gemini-stream v25] Parse error:", parseError);
        }
      }

      try {
        while (true) {
          // v36: 반복 감지되면 reader 취소 + 루프 탈출 (토큰 낭비 방지)
          if (repetitionDetected) {
            console.log("[ai-gemini v36] Cancelling reader due to repetition detection");
            await reader.cancel();
            break;
          }
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split("\n");
          buffer = lines.pop() || "";
          for (const line of lines) {
            processSSELine(line);
            if (repetitionDetected) break; // v36: 즉시 탈출
          }
        }
        // v25 BUG FIX: 잔여 버퍼 처리 (usageMetadata가 마지막 청크에 있음)
        // decoder flush (stream: false로 잔여 바이트 방출)
        if (!repetitionDetected) {
          buffer += decoder.decode(new Uint8Array(), { stream: false });
          if (buffer.trim()) {
            const remainingLines = buffer.split("\n");
            for (const line of remainingLines) {
              processSSELine(line);
            }
          }
        }
        // v36: 반복 감지 시 done/cost는 이미 processSSELine에서 전송됨 — 후처리 스킵
        if (repetitionDetected) {
          if (userId && (totalPromptTokens > 0 || totalCompletionTokens > 0)) {
            const nonCachedPrompt = totalPromptTokens - totalCachedTokens;
            const cost = (nonCachedPrompt * 0.10 / 1000000) + (totalCachedTokens * 0.01 / 1000000) + (totalCompletionTokens * 0.40 / 1000000);
            await recordGeminiCost(supabase, userId, totalPromptTokens, totalCompletionTokens, cost);
          }
          return; // controller.close()는 finally에서 처리
        }
        // v35.2: thinking 토큰 누출 방어 (3단계)
        // Gemini 3 Flash Preview에서 candidatesTokenCount에 thinking 토큰 간헐적 혼입
        // 정상 비율: 한글 0.7~0.8 tokens/char, 최대 1.5 tokens/char
        let actualCompletionTokens = totalCompletionTokens;
        const tokensPerChar = totalTextLength > 0 ? totalCompletionTokens / totalTextLength : 0;

        // 방어1: thoughts 차감 (thoughts가 보고된 경우)
        if (totalThoughtsTokens > 0 && totalCompletionTokens > totalThoughtsTokens) {
          actualCompletionTokens = totalCompletionTokens - totalThoughtsTokens;
          console.log(`[ai-gemini v35.2] Defense1: thoughts subtraction. reported=${totalCompletionTokens}, thoughts=${totalThoughtsTokens}, result=${actualCompletionTokens}`);
        }

        // 방어2: 텍스트 길이 기반 상한선 (tokens/char > 1.5이면 비정상)
        // 한글은 최대 1.0~1.2 tokens/char, 영어 혼합해도 1.5 넘을 수 없음
        if (totalTextLength > 0) {
          const maxReasonableTokens = Math.ceil(totalTextLength * 1.5);
          if (actualCompletionTokens > maxReasonableTokens) {
            console.log(`[ai-gemini v35.2] Defense2: cap by text length. completion=${actualCompletionTokens}, textLen=${totalTextLength}, cap=${maxReasonableTokens}, ratio=${tokensPerChar.toFixed(2)}`);
            actualCompletionTokens = maxReasonableTokens;
          }
        }

        const cacheHitPct = totalPromptTokens > 0 ? Math.round(totalCachedTokens / totalPromptTokens * 100) : 0;
        console.log(`[ai-gemini-stream v38] Stream done. prompt=${totalPromptTokens}, completion=${actualCompletionTokens} (raw=${totalCompletionTokens}), thoughts=${totalThoughtsTokens}, textLen=${totalTextLength}, ratio=${tokensPerChar.toFixed(2)}, cached=${totalCachedTokens} (${cacheHitPct}% hit)`);
        const doneData = JSON.stringify({ text: "", done: true, usage: { prompt_tokens: totalPromptTokens, completion_tokens: actualCompletionTokens, thoughts_tokens: totalThoughtsTokens, total_tokens: totalPromptTokens + actualCompletionTokens, cached_tokens: totalCachedTokens } });
        controller.enqueue(encoder.encode(`data: ${doneData}\n\n`));
        // v26: gemini_cost_usd 기록 (fallback + context caching 할인 포함)
        if (userId) {
          if (totalPromptTokens > 0 || totalCompletionTokens > 0) {
            // v38: gemini-2.5-flash-lite 가격 ($0.10/$0.40, cache $0.01)
            const nonCachedPrompt = totalPromptTokens - totalCachedTokens;
            const cost = (nonCachedPrompt * 0.10 / 1000000) + (totalCachedTokens * 0.01 / 1000000) + (totalCompletionTokens * 0.40 / 1000000);
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
            const estCost = (estPromptTokens * 0.10 / 1000000) + (estCompletionTokens * 0.40 / 1000000);
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
    if (!QWEN_API_KEY && GEMINI_API_KEYS.length === 0) throw new Error("No AI provider configured (QWEN_API_KEY or GEMINI_API_KEY required)");
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
    const { messages, model: _clientModel = "gemini-2.5-flash-lite", max_tokens = 16384, temperature = 0.8, user_id, stream = false, session_id } = requestData;
    // v37: 모델 강제 오버라이드 — 기존 앱이 다른 모델명을 보내도 2.5-flash-lite 사용
    const model = "gemini-2.5-flash-lite";
    if (_clientModel !== model) {
      console.log(`[ai-gemini v37] Model override: ${_clientModel} → ${model}`);
    }
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
    // v77: Qwen → Gemini fallback
    if (stream) {
      // 스트리밍: Qwen 먼저 시도, 실패 시 Gemini fallback
      if (QWEN_API_KEY) {
        console.log(`[ai-gemini v77] Streaming: trying Qwen 3.5 Flash`);
        const qwenResp = await handleQwenStreamingRequest(supabase, messages, max_tokens, temperature, user_id, isAdmin);
        if (qwenResp) return qwenResp;
        console.warn(`[ai-gemini v77] Qwen streaming failed, falling back to Gemini`);
      }
      console.log(`[ai-gemini v77] Streaming fallback: Gemini ${model}, session_id=${session_id || 'none'}`);
      return await handleStreamingRequest(supabase, messages, model, max_tokens, temperature, user_id, isAdmin, session_id);
    }

    // Non-streaming: Qwen 먼저 시도
    if (QWEN_API_KEY) {
      console.log(`[ai-gemini v77] Non-streaming: trying Qwen 3.5 Flash`);
      const qwenResult = await callQwenNonStreaming(messages, max_tokens, temperature);
      if (qwenResult) {
        const { content, usage } = qwenResult;
        // 비용 기록 (Qwen = Gemini 동일 가격)
        if (user_id) {
          const nonCached = (usage.prompt_tokens || 0) - (usage.cached_tokens || 0);
          const cost = (nonCached * 0.10 / 1000000) + ((usage.cached_tokens || 0) * 0.01 / 1000000) + ((usage.completion_tokens || 0) * 0.40 / 1000000);
          await recordGeminiCost(supabase, user_id, usage.prompt_tokens || 0, usage.completion_tokens || 0, cost);
        }
        const cacheHitPct = usage.prompt_tokens ? Math.round((usage.cached_tokens || 0) / usage.prompt_tokens * 100) : 0;
        console.log(`[ai-gemini v77] Qwen non-stream OK: cached=${usage.cached_tokens || 0} (${cacheHitPct}% hit)`);
        return new Response(
          JSON.stringify({ success: true, content, usage: { prompt_tokens: usage.prompt_tokens, completion_tokens: usage.completion_tokens, total_tokens: (usage.prompt_tokens || 0) + (usage.completion_tokens || 0) }, model: QWEN_MODEL, finish_reason: "stop", is_admin: isAdmin }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      console.warn(`[ai-gemini v77] Qwen non-streaming failed, falling back to Gemini`);
    }
    console.log(`[ai-gemini v77] Non-streaming fallback: Gemini ${model}, isAdmin=${isAdmin}`);
    const systemInstruction = messages.filter((m) => m.role === "system").map((m) => m.content).join("\n");
    const contents = messages.filter((m) => m.role !== "system").map((m) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: m.content }],
    }));
    // v38: non-streaming도 세션 고정 키 (implicit caching) + 429 retry
    const nonStreamKey = session_id ? getSessionKey(session_id) : getNextGeminiKey();
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${nonStreamKey}`;
    const safetySettings = [
      { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
      { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
      { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
      { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
    ];
    const genConfig = {
      temperature: 1.0, maxOutputTokens: max_tokens, topP: 0.9, topK: 40,
      stopSequences: ["[/SUGGESTED_QUESTIONS]"],
      thinkingConfig: { thinkingBudget: 0 },
    };
    const geminiBody: Record<string, unknown> = {
      contents,
      systemInstruction: systemInstruction ? { parts: [{ text: systemInstruction }] } : undefined,
      generationConfig: genConfig,
      safetySettings,
      ...(sajuToolDeclarations.length > 0 && !model.includes('lite') ? { tools: sajuToolDeclarations } : {}),
    };

    // v76: Function Calling Loop (최대 6회 — think 5단계 + 최종 답변)
    const MAX_FUNCTION_CALLS = 6;
    let data: Record<string, unknown> = {};
    let functionCallCount = 0;

    for (let i = 0; i < MAX_FUNCTION_CALLS; i++) {
      let response = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(geminiBody),
      });
      // v62: 429 → 다음 키 retry
      if (response.status === 429 && GEMINI_API_KEYS.length > 1) {
        console.warn(`[ai-gemini v62] Non-stream 429, trying next key...`);
        const retryKey = getNextGeminiKey();
        response = await fetch(geminiUrl.replace(/key=[^&]+/, `key=${retryKey}`), {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(geminiBody),
        });
      }
      data = await response.json();
      if ((data as any).error) {
        console.error("[ai-gemini v76] Gemini API Error:", (data as any).error);
        return new Response(JSON.stringify({ success: false, error: (data as any).error?.message || "Gemini API error" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
      }
      const candidate = (data as any).candidates?.[0];
      if (!candidate) throw new Error("No response from Gemini");
      if (candidate.finishReason === "SAFETY") throw new Error("Response blocked due to safety settings");

      // Function Call 감지
      const fcParts = candidate.content?.parts?.filter((p: any) => p.functionCall);
      if (fcParts && fcParts.length > 0) {
        functionCallCount++;
        // 모델의 functionCall 응답을 contents에 추가
        (geminiBody.contents as any[]).push({ role: "model", parts: candidate.content.parts });

        // 각 functionCall 실행 → functionResponse 추가
        const responseParts: any[] = [];
        for (const fc of fcParts) {
          const { name, args, id } = fc.functionCall;
          console.log(`[ai-gemini v76] Function call #${functionCallCount}: ${name}(${JSON.stringify(args)}) id=${id || 'none'}`);
          const result = executeSajuFunction ? executeSajuFunction(name, args || {}) : { error: "saju-tools not loaded" };
          const fnResponse: Record<string, unknown> = { name, response: { content: result } };
          if (id) fnResponse.id = id; // Gemini가 id를 보내면 매칭용으로 포함
          responseParts.push({ functionResponse: fnResponse });
        }
        (geminiBody.contents as any[]).push({ role: "user", parts: responseParts });
        continue; // 다음 루프에서 Gemini 재호출
      }

      // functionCall이 없으면 텍스트 응답 → 루프 종료
      break;
    }
    if (functionCallCount > 0) {
      console.log(`[ai-gemini v76] Total function calls: ${functionCallCount}`);
    }

    const candidate = (data as any).candidates?.[0];
    if (!candidate) throw new Error("No response from Gemini after function calls");
    // v34: thought 파트 필터링 (thought=true만 스킵, thoughtSignature 있는 text는 유지)
    let content = "";
    const parts = candidate.content?.parts;
    if (Array.isArray(parts)) {
      for (const part of parts) {
        if (part.thought === true) continue;
        if (part.functionCall) continue; // 남은 functionCall은 무시
        if (part.text) content += part.text;
      }
    }
    // v34: JSON 추출 안전장치 — thought 텍스트가 섞여 들어온 경우 JSON 블록만 추출
    if (content && !content.trimStart().startsWith('{') && !content.trimStart().startsWith('[')) {
      const jsonBlockMatch = content.match(/```json\s*([\s\S]*?)\s*```/);
      const jsonMatch = jsonBlockMatch ? jsonBlockMatch[1] : content.match(/\{[\s\S]*\}/)?.[0];
      if (jsonMatch) {
        console.log(`[ai-gemini v34] Extracted JSON from mixed content (original started with: "${content.substring(0, 30)}...")`);
        content = jsonMatch;
      }
    }
    const usageMetadata = data.usageMetadata || {};
    const promptTokens = usageMetadata.promptTokenCount || 0;
    const rawCompletionTokens = usageMetadata.candidatesTokenCount || 0;
    const thoughtsTokens = usageMetadata.thoughtsTokenCount || 0;
    const totalTokens = usageMetadata.totalTokenCount || 0;
    const cachedTokens = usageMetadata.cachedContentTokenCount || 0; // v38: implicit cache hit 추적
    // v35.3: 비스트리밍 경로에도 thinking 누출 방어 (스트리밍 fallback 시 이 경로를 탐)
    let completionTokens = rawCompletionTokens;
    if (thoughtsTokens > 0 && completionTokens > thoughtsTokens) {
      completionTokens = completionTokens - thoughtsTokens;
      console.log(`[ai-gemini v35.3] Non-stream defense1: ${rawCompletionTokens} - ${thoughtsTokens} = ${completionTokens}`);
    }
    if (content.length > 0) {
      const maxReasonable = Math.ceil(content.length * 1.5);
      if (completionTokens > maxReasonable) {
        console.log(`[ai-gemini v35.3] Non-stream defense2: cap ${completionTokens} → ${maxReasonable} (textLen=${content.length})`);
        completionTokens = maxReasonable;
      }
    }
    // v38: gemini-2.5-flash-lite 가격 + implicit caching 할인
    const nonCachedPrompt = promptTokens - cachedTokens;
    const cost = (nonCachedPrompt * 0.10 / 1000000) + (cachedTokens * 0.01 / 1000000) + (rawCompletionTokens * 0.40 / 1000000);
    if (user_id) await recordGeminiCost(supabase, user_id, promptTokens, rawCompletionTokens, cost);
    const cacheHitPct = promptTokens > 0 ? Math.round(cachedTokens / promptTokens * 100) : 0;
    console.log(`[ai-gemini v38] Non-stream success: prompt=${promptTokens}, completion=${completionTokens} (raw=${rawCompletionTokens}), thoughts=${thoughtsTokens}, cached=${cachedTokens} (${cacheHitPct}% hit), textLen=${content.length}, isAdmin=${isAdmin}`);
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
