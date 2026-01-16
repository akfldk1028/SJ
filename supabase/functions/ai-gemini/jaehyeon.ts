import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * Gemini API 호출 Edge Function (v23)
 *
 * 채팅/일운 분석 전용
 * API 키는 서버에만 저장 (보안)
 *
 * Quota 시스템:
 * - 일반 사용자: 일일 50,000 토큰 제한
 * - Admin 사용자: 무제한 (relation_type = 'admin')
 *
 * v23 변경사항 (2026-01-15):
 * - 반복 문자 감지 로직 추가 (Gemini 고질병 대응)
 * - detectRepetitivePattern() 함수 추가
 * - 스트리밍/비스트리밍 모두에서 반복 감지 적용
 * - 반복 감지 시 스트림 조기 종료
 *
 * === 모델 변경 금지 ===
 * 이 Edge Function의 기본 모델은 반드시 gemini-3-flash-preview 유지
 * 변경 필요 시 EdgeFunction_task.md 참조
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

// 반복 감지 설정
const REPETITION_THRESHOLD = 20; // 같은 문자 20번 이상 반복 시 감지
const REPETITION_PATTERN_THRESHOLD = 5; // 같은 패턴 5번 이상 반복 시 감지

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface GeminiRequest {
  messages: ChatMessage[];
  model?: string;
  max_tokens?: number;
  temperature?: number;
  user_id?: string; // Quota 체크용
  stream?: boolean; // 스트리밍 모드
  is_new_session?: boolean; // 새 세션 여부
}

interface RepetitionResult {
  isRepetitive: boolean;
  cleanedText: string;
  detectedPattern?: string;
}

/**
 * 반복 문자/패턴 감지 함수
 *
 * Gemini의 알려진 버그: 같은 문자나 패턴이 무한히 반복되는 문제
 * 예: "ㄴㄴㄴㄴㄴㄴㄴ...", "\n\n\n\n...", "하하하하하..."
 *
 * 감지 방식:
 * 1. 단일 문자 연속 반복 (ㄴㄴㄴㄴ...)
 * 2. 짧은 패턴 연속 반복 (하하하하..., 네네네네...)
 * 3. 줄바꿈 연속 반복 (\n\n\n...)
 */
function detectRepetitivePattern(text: string): RepetitionResult {
  if (!text || text.length < REPETITION_THRESHOLD) {
    return { isRepetitive: false, cleanedText: text };
  }

  // 1. 단일 문자 연속 반복 감지 (예: ㄴㄴㄴㄴㄴ)
  const singleCharPattern = /(.)\1{19,}/g; // 같은 문자 20번 이상
  const singleMatch = text.match(singleCharPattern);
  if (singleMatch) {
    console.log(`[ai-gemini v23] Detected single char repetition: "${singleMatch[0].slice(0, 10)}..." (${singleMatch[0].length} chars)`);
    // 반복 부분을 제거하고 앞부분만 유지
    const cleanedText = text.replace(singleCharPattern, (match) => match[0].repeat(3));
    return {
      isRepetitive: true,
      cleanedText,
      detectedPattern: singleMatch[0][0],
    };
  }

  // 2. 2-5자 짧은 패턴 반복 감지 (예: 하하하하, 네네네네)
  for (let patternLen = 2; patternLen <= 5; patternLen++) {
    const patternRegex = new RegExp(`(.{${patternLen}})\\1{${REPETITION_PATTERN_THRESHOLD - 1},}`, 'g');
    const patternMatch = text.match(patternRegex);
    if (patternMatch) {
      const matchedPattern = patternMatch[0].slice(0, patternLen);
      const repetitionCount = patternMatch[0].length / patternLen;
      console.log(`[ai-gemini v23] Detected pattern repetition: "${matchedPattern}" x ${repetitionCount}`);
      // 반복 부분을 3번만 유지
      const cleanedText = text.replace(patternRegex, (match) => {
        const unit = match.slice(0, patternLen);
        return unit.repeat(3);
      });
      return {
        isRepetitive: true,
        cleanedText,
        detectedPattern: matchedPattern,
      };
    }
  }

  // 3. 줄바꿈 연속 반복 감지
  const newlinePattern = /\n{10,}/g; // 연속 줄바꿈 10번 이상
  const newlineMatch = text.match(newlinePattern);
  if (newlineMatch) {
    console.log(`[ai-gemini v23] Detected newline repetition: ${newlineMatch[0].length} newlines`);
    const cleanedText = text.replace(newlinePattern, '\n\n');
    return {
      isRepetitive: true,
      cleanedText,
      detectedPattern: '\\n',
    };
  }

  // 4. 텍스트 끝부분에서 반복 시작점 감지 (진행 중인 반복)
  // 마지막 50자에서 같은 문자가 절반 이상인 경우
  if (text.length > 50) {
    const tail = text.slice(-50);
    const charCounts = new Map<string, number>();
    for (const char of tail) {
      charCounts.set(char, (charCounts.get(char) || 0) + 1);
    }
    for (const [char, count] of charCounts) {
      if (count > 25 && char !== ' ' && char !== '\n') { // 50자 중 25자 이상이 같은 문자
        console.log(`[ai-gemini v23] Detected tail repetition: "${char}" appears ${count}/50 times`);
        // 반복 시작점 찾기
        const lastGoodIndex = text.lastIndexOf(text.slice(-51, -50));
        if (lastGoodIndex > 0) {
          return {
            isRepetitive: true,
            cleanedText: text.slice(0, lastGoodIndex + 1),
            detectedPattern: char,
          };
        }
      }
    }
  }

  return { isRepetitive: false, cleanedText: text };
}

/**
 * 스트리밍용 실시간 반복 감지기
 * 누적된 텍스트에서 반복 패턴을 감지
 */
class StreamRepetitionDetector {
  private buffer: string = '';
  private lastChars: string[] = [];
  private repetitionCount: number = 0;
  private detectedRepetition: boolean = false;

  addChunk(text: string): { shouldStop: boolean; cleanedText: string } {
    if (this.detectedRepetition) {
      return { shouldStop: true, cleanedText: '' };
    }

    this.buffer += text;

    // 최근 문자 추적
    for (const char of text) {
      if (this.lastChars.length > 0 && this.lastChars[this.lastChars.length - 1] === char) {
        this.repetitionCount++;
      } else {
        this.repetitionCount = 1;
      }
      this.lastChars.push(char);
      if (this.lastChars.length > 100) {
        this.lastChars.shift();
      }

      // 단일 문자 20번 이상 연속 반복
      if (this.repetitionCount >= REPETITION_THRESHOLD) {
        console.log(`[ai-gemini v23] Stream: Detected repetition of "${char}" (${this.repetitionCount}x)`);
        this.detectedRepetition = true;
        // 반복 시작 전까지의 텍스트만 반환
        const cleanedText = this.buffer.slice(0, -(this.repetitionCount - 3));
        return { shouldStop: true, cleanedText };
      }
    }

    // 전체 버퍼에서 패턴 체크 (1000자마다)
    if (this.buffer.length % 1000 < text.length) {
      const result = detectRepetitivePattern(this.buffer);
      if (result.isRepetitive) {
        this.detectedRepetition = true;
        return { shouldStop: true, cleanedText: result.cleanedText };
      }
    }

    return { shouldStop: false, cleanedText: text };
  }

  isRepetitive(): boolean {
    return this.detectedRepetition;
  }

  getCleanedBuffer(): string {
    const result = detectRepetitivePattern(this.buffer);
    return result.cleanedText;
  }
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
  isAdmin: boolean,
  isNewSession: boolean = false
): Promise<void> {
  const today = new Date().toISOString().split("T")[0];
  const totalTokens = promptTokens + completionTokens;

  try {
    // UPSERT: 오늘 기록이 있으면 업데이트, 없으면 생성
    const { data: existing } = await supabase
      .from("user_daily_token_usage")
      .select("id, chatting_tokens, chatting_session_count, chatting_message_count, gemini_cost_usd")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    if (existing) {
      // UPDATE: 개별 필드만 업데이트 (total_tokens는 GENERATED 컬럼)
      const updateData: Record<string, unknown> = {
        chatting_tokens: (existing.chatting_tokens || 0) + totalTokens,
        chatting_message_count: (existing.chatting_message_count || 0) + 1,
        gemini_cost_usd: parseFloat(existing.gemini_cost_usd || "0") + cost,
        updated_at: new Date().toISOString(),
      };

      // 새 세션일 때만 session_count 증가
      if (isNewSession) {
        updateData.chatting_session_count = (existing.chatting_session_count || 0) + 1;
        console.log(`[ai-gemini v23] New session started for user ${userId}`);
      }

      await supabase
        .from("user_daily_token_usage")
        .update(updateData)
        .eq("id", existing.id);
    } else {
      // INSERT: 새 레코드 생성 (total_tokens는 자동 계산)
      // 첫 메시지는 항상 새 세션이므로 session_count = 1
      await supabase
        .from("user_daily_token_usage")
        .insert({
          user_id: userId,
          usage_date: today,
          chatting_tokens: totalTokens,
          chatting_session_count: 1, // 새 레코드 = 새 세션
          chatting_message_count: 1,
          gemini_cost_usd: cost,
        });
    }
    console.log(`[ai-gemini v23] Recorded ${totalTokens} chatting_tokens, session=${isNewSession ? 'new' : 'existing'}`);
  } catch (error) {
    console.error("[ai-gemini v23] Failed to record token usage:", error);
  }
}

/**
 * 스트리밍 응답 처리 (반복 감지 포함)
 * Gemini SSE 응답을 클라이언트에 릴레이
 */
async function handleStreamingRequest(
  supabase: ReturnType<typeof createClient>,
  messages: ChatMessage[],
  model: string,
  maxTokens: number,
  temperature: number,
  userId: string | undefined,
  isAdmin: boolean,
  isNewSession: boolean
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

  console.log(`[ai-gemini-stream v23] Calling Gemini streaming API: model=${model}, isNewSession=${isNewSession}`);

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
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
      ],
    }),
  });

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    console.error("[ai-gemini-stream v23] Gemini API error:", errorText);
    throw new Error(`Gemini API error: ${geminiResponse.status}`);
  }

  // 토큰 정보 수집용 변수
  let totalPromptTokens = 0;
  let totalCompletionTokens = 0;

  // 반복 감지기 초기화
  const repetitionDetector = new StreamRepetitionDetector();

  // ReadableStream으로 Gemini 응답을 클라이언트에 릴레이
  const stream = new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      const reader = geminiResponse.body!.getReader();
      const decoder = new TextDecoder();
      let buffer = "";
      let stoppedDueToRepetition = false;

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

                // 텍스트 추출
                const text = data.candidates?.[0]?.content?.parts?.[0]?.text || "";

                // 토큰 정보 (마지막 청크에 포함)
                if (data.usageMetadata) {
                  totalPromptTokens = data.usageMetadata.promptTokenCount || 0;
                  totalCompletionTokens = data.usageMetadata.candidatesTokenCount || 0;
                }

                // 클라이언트에 SSE 형식으로 전송 (반복 감지 포함)
                if (text) {
                  const detection = repetitionDetector.addChunk(text);

                  if (detection.shouldStop) {
                    console.log(`[ai-gemini-stream v23] Stopping stream due to repetition detected`);
                    stoppedDueToRepetition = true;

                    // 정리된 텍스트가 있으면 전송
                    if (detection.cleanedText) {
                      const sseData = JSON.stringify({ text: detection.cleanedText, done: false });
                      controller.enqueue(encoder.encode(`data: ${sseData}\n\n`));
                    }

                    // 반복 감지 알림 메시지
                    const warningData = JSON.stringify({
                      text: "\n\n[응답이 자동으로 정리되었습니다]",
                      done: false,
                      repetition_detected: true
                    });
                    controller.enqueue(encoder.encode(`data: ${warningData}\n\n`));

                    break;
                  }

                  const sseData = JSON.stringify({ text, done: false });
                  controller.enqueue(encoder.encode(`data: ${sseData}\n\n`));
                }
              } catch (parseError) {
                console.error("[ai-gemini-stream v23] Parse error:", parseError);
              }
            }
          }

          // 반복 감지로 중단된 경우 루프 탈출
          if (stoppedDueToRepetition) break;
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
          repetition_detected: stoppedDueToRepetition,
        });
        controller.enqueue(encoder.encode(`data: ${doneData}\n\n`));

        // 토큰 사용량 기록 (스트림 완료 후)
        if (userId && (totalPromptTokens > 0 || totalCompletionTokens > 0)) {
          const cost = (totalPromptTokens * 0.075 / 1000000) + (totalCompletionTokens * 0.30 / 1000000);
          await recordTokenUsage(supabase, userId, totalPromptTokens, totalCompletionTokens, cost, isAdmin, isNewSession);
          console.log(`[ai-gemini-stream v23] Token usage recorded: prompt=${totalPromptTokens}, completion=${totalCompletionTokens}, newSession=${isNewSession}`);
        }

      } catch (error) {
        console.error("[ai-gemini-stream v23] Stream error:", error);
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

    // Supabase 클라이언트 생성 (service role로 DB 접근)
    const supabase = createClient(
      SUPABASE_URL!,
      SUPABASE_SERVICE_ROLE_KEY!
    );

    const requestData: GeminiRequest = await req.json();
    const {
      messages,
      model = "gemini-3-flash-preview",
      max_tokens = 16384,
      temperature = 0.8,
      user_id,
      stream = false,
      is_new_session = false,
    } = requestData;

    // 필수 파라미터 검증
    if (!messages || messages.length === 0) {
      throw new Error("messages is required");
    }

    // Admin 여부 확인
    let isAdmin = false;
    if (user_id) {
      isAdmin = await isAdminUser(supabase, user_id);
      console.log(`[ai-gemini v23] User ${user_id} isAdmin: ${isAdmin}`);

      // Quota 확인 (Admin은 스킵)
      if (!isAdmin) {
        const quota = await checkAndUpdateQuota(supabase, user_id, 0, isAdmin);
        if (!quota.allowed) {
          console.log(`[ai-gemini v23] Quota exceeded for user ${user_id}`);
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
      console.log(`[ai-gemini v23] Streaming mode enabled: model=${model}, isNewSession=${is_new_session}`);
      return await handleStreamingRequest(
        supabase,
        messages,
        model,
        max_tokens,
        temperature,
        user_id,
        isAdmin,
        is_new_session
      );
    }

    // ===== 비스트리밍 로직 =====
    console.log(`[ai-gemini v23] Calling Gemini: model=${model}, isAdmin=${isAdmin}, isNewSession=${is_new_session}`);

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
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
        ],
      }),
    });

    const data = await response.json();

    // 오류 처리
    if (data.error) {
      console.error("[ai-gemini v23] Gemini API Error:", data.error);
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

    let content = candidate.content?.parts?.[0]?.text || "";

    // 비스트리밍 응답에서도 반복 감지 적용
    const repetitionResult = detectRepetitivePattern(content);
    if (repetitionResult.isRepetitive) {
      console.log(`[ai-gemini v23] Non-streaming: Repetition detected, cleaning response`);
      content = repetitionResult.cleanedText;
    }

    // 토큰 사용량 추출 (usageMetadata)
    const usageMetadata = data.usageMetadata || {};
    const promptTokens = usageMetadata.promptTokenCount || 0;
    const completionTokens = usageMetadata.candidatesTokenCount || 0;
    const totalTokens = usageMetadata.totalTokenCount || 0;

    // Gemini 비용 계산 (USD)
    const cost = (promptTokens * 0.075 / 1000000) + (completionTokens * 0.30 / 1000000);

    // 토큰 사용량 기록
    if (user_id) {
      await recordTokenUsage(supabase, user_id, promptTokens, completionTokens, cost, isAdmin, is_new_session);
    }

    console.log(
      `[ai-gemini v23] Success: prompt=${promptTokens}, completion=${completionTokens}, isNewSession=${is_new_session}, repetition=${repetitionResult.isRepetitive}`
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
        repetition_detected: repetitionResult.isRepetitive,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[ai-gemini v23] Error:", error);

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
