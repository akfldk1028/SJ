import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * AI Task 결과 조회 Edge Function (v30)
 *
 * OpenAI Responses API의 background task 결과 조회
 * task_id로 조회 → openai_response_id로 OpenAI polling
 *
 * v30 변경사항 (2026-02-01):
 * - output 배열에서 reasoning 타입 명시적 필터링 추가
 * - GPT-5.2 thinking 내용(type: "reasoning")은 사용자에게 노출하지 않음
 * - completed 및 incomplete 케이스 모두 적용
 *
 * v29 변경사항 (2026-01-30):
 * - API Key 로드밸런싱 지원
 * - ai_tasks.request_data.key_index로 ai-openai에서 사용한 동일 키로 polling
 * - OPENAI_API_KEY, OPENAI_API_KEY_2, OPENAI_API_KEY_3 지원
 *
 * v28 변경사항 (2026-01-24):
 * - parseResultToPhases 필드명을 saju_base_prompt.dart 스키마와 일치시킴
 *
 * v27 변경사항 (2026-01-23):
 * - Phase 기반 Progressive Disclosure 지원
 *
 * v26 변경사항 (2026-01-19):
 * - 'incomplete' 상태 처리 추가
 *
 * v25 변경사항 (2026-01-14):
 * - gpt_saju_analysis_tokens 신규 필드
 *
 * v24 변경사항:
 * - OpenAI /v1/responses/{id} 직접 polling
 *
 * 사용법:
 * POST /ai-openai-result
 * { "task_id": "uuid" }
 *
 * 응답:
 * - queued/in_progress: { status: "in_progress", phase: 1-3, total_phases: 4 }
 * - completed: { status: "completed", content: "...", usage: {...}, phase: 4, total_phases: 4 }
 * - failed: { status: "failed", error: "..." }
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// v29: API Key Load Balancing - ai-openai에서 사용한 동일 키로 polling
const API_KEYS = [
  Deno.env.get("OPENAI_API_KEY"),
  Deno.env.get("OPENAI_API_KEY_2"),
  Deno.env.get("OPENAI_API_KEY_3"),
].filter(Boolean) as string[];

function getApiKeyByIndex(idx: number): string {
  if (API_KEYS.length === 0) throw new Error("No OPENAI_API_KEY configured");
  return API_KEYS[idx % API_KEYS.length];
}

const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

interface ResultRequest {
  task_id: string;
}

/**
 * v28: AI 결과를 4개 Phase로 분할 (saju_base_prompt.dart 스키마 기준)
 *
 * Phase 구조 (실제 GPT 응답 필드 기준):
 * - Phase 1: 핵심 정체성 (summary, my_saju_characters, personality, wonGuk_analysis)
 * - Phase 2: 재물/관계 운세 (wealth, love, marriage, health)
 * - Phase 3: 커리어/분석 (career, business, sipsung_analysis, hapchung_analysis)
 * - Phase 4: 대운/미래 (daeun_detail, peak_years, life_cycles, sinsal_gilseong, lucky_elements)
 */
function parseResultToPhases(content: string): Record<string, unknown> {
  try {
    const parsed = JSON.parse(content);

    // Phase 1: 핵심 정체성 - "나는 누구인가?"
    const phase1 = {
      summary: parsed.summary,
      my_saju_characters: parsed.my_saju_characters,
      personality: parsed.personality,
      wonGuk_analysis: parsed.wonGuk_analysis,
    };

    // Phase 2: 재물/관계 운세 - "돈과 사랑"
    const phase2 = {
      wealth: parsed.wealth,
      love: parsed.love,
      marriage: parsed.marriage,
      health: parsed.health,
    };

    // Phase 3: 커리어 & 심층 분석 - "직업과 사업"
    const phase3 = {
      career: parsed.career,
      business: parsed.business,
      sipsung_analysis: parsed.sipsung_analysis,
      hapchung_analysis: parsed.hapchung_analysis,
    };

    // Phase 4: 대운 & 미래 전망 - "언제 어떻게?"
    const phase4 = {
      daeun_detail: parsed.daeun_detail,
      peak_years: parsed.peak_years,
      life_cycles: parsed.life_cycles,
      sinsal_gilseong: parsed.sinsal_gilseong,
      lucky_elements: parsed.lucky_elements,
    };

    return {
      phase1,
      phase2,
      phase3,
      phase4,
      completed_phases: 4,
    };
  } catch (e) {
    console.error("[ai-openai-result v30] Failed to parse phases:", e);
    // 파싱 실패 시 원본 content를 phase1에 저장
    return {
      phase1: { raw_content: content },
      completed_phases: 1,
    };
  }
}

/**
 * v30: OpenAI output 배열에서 텍스트 추출 (reasoning 타입 필터링)
 * GPT-5.2 thinking 내용(type: "reasoning")은 제외하고 실제 응답만 추출
 */
function extractOutputText(responseData: Record<string, unknown>): string {
  let outputText = "";

  if (responseData.output && Array.isArray(responseData.output)) {
    for (const outputItem of responseData.output) {
      // reasoning 타입은 GPT thinking 내용이므로 제외
      if (outputItem.type === "reasoning") {
        console.log(`[ai-openai-result v30] Skipping reasoning output item`);
        continue;
      }

      if (outputItem.type === "message" && outputItem.content) {
        for (const contentItem of outputItem.content) {
          // reasoning 타입 content도 제외
          if (contentItem.type === "reasoning") continue;
          if (contentItem.type === "output_text" && contentItem.text) {
            outputText += contentItem.text;
          } else if (contentItem.type === "text" && contentItem.text) {
            outputText += contentItem.text;
          }
        }
      } else if (outputItem.type === "text" && outputItem.text) {
        outputText += outputItem.text;
      }
    }
  } else if (typeof responseData.output_text === "string") {
    outputText = responseData.output_text;
  }

  return outputText;
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    const { task_id }: ResultRequest = await req.json();

    if (!task_id) {
      return new Response(
        JSON.stringify({ success: false, error: "task_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`[ai-openai-result v30] Checking task ${task_id}`);

    // Task 조회 (openai_response_id 포함)
    const { data: task, error } = await supabase
      .from("ai_tasks")
      .select("id, status, openai_response_id, result_data, error_message, user_id, model, created_at, started_at, completed_at, request_data")
      .eq("id", task_id)
      .single();

    if (error || !task) {
      console.log(`[ai-openai-result v30] Task ${task_id} not found`);
      return new Response(
        JSON.stringify({ success: false, error: "Task not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 이미 완료된 경우 캐시된 결과 반환
    if (task.status === "completed" && task.result_data) {
      console.log(`[ai-openai-result v30] Task ${task_id}: returning cached result`);
      return new Response(
        JSON.stringify({
          success: true,
          status: "completed",
          content: task.result_data.content,
          usage: task.result_data.usage,
          model: task.model,
          completed_at: task.completed_at,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 이미 실패한 경우
    if (task.status === "failed") {
      console.log(`[ai-openai-result v30] Task ${task_id}: failed - ${task.error_message}`);
      return new Response(
        JSON.stringify({
          success: false,
          status: "failed",
          error: task.error_message || "Unknown error",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // openai_response_id가 없는 경우 (레거시 또는 오류)
    if (!task.openai_response_id) {
      console.log(`[ai-openai-result v30] Task ${task_id}: no openai_response_id`);
      return new Response(
        JSON.stringify({
          success: true,
          status: task.status || "pending",
          message: "Task is being processed (legacy mode)",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // === OpenAI Responses API 폴링 ===
    // v29: ai-openai에서 사용한 동일 API 키로 polling (key_index from request_data)
    const keyIdx = task.request_data?.key_index ?? 0;
    const apiKey = getApiKeyByIndex(keyIdx);
    console.log(`[ai-openai-result v30] Polling OpenAI: ${task.openai_response_id} (key_index: ${keyIdx})`);

    const openaiResponse = await fetch(`${OPENAI_RESPONSES_URL}/${task.openai_response_id}`, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
    });

    const responseData = await openaiResponse.json();
    console.log(`[ai-openai-result v30] OpenAI status: ${openaiResponse.status}`);
    console.log(`[ai-openai-result v30] OpenAI response status: ${responseData.status}`);

    if (!openaiResponse.ok) {
      console.error("[ai-openai-result v30] OpenAI API Error:", responseData);

      // 에러 저장
      await supabase
        .from("ai_tasks")
        .update({
          status: "failed",
          error_message: responseData.error?.message || "OpenAI API error",
          completed_at: new Date().toISOString(),
        })
        .eq("id", task_id);

      return new Response(
        JSON.stringify({
          success: false,
          status: "failed",
          error: responseData.error?.message || "OpenAI API error",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const openaiStatus = responseData.status;

    // OpenAI 상태별 처리
    switch (openaiStatus) {
      case "queued":
      case "in_progress":
        // 아직 처리 중
        console.log(`[ai-openai-result v30] OpenAI task ${task.openai_response_id}: ${openaiStatus}`);

        // v27: 경과 시간 기반 예상 Phase 계산 (UI 진행 표시용)
        // GPT-5.2 평균 처리 시간: ~60-90초, Phase당 ~15-22초
        let estimatedPhase = 1;
        if (task.started_at) {
          const elapsed = Date.now() - new Date(task.started_at).getTime();
          const phaseInterval = 20000; // 20초당 1 Phase
          estimatedPhase = Math.min(3, Math.floor(elapsed / phaseInterval) + 1);
        }

        // ai_tasks 상태 업데이트 + Phase 정보
        await supabase
          .from("ai_tasks")
          .update({
            status: openaiStatus,
            phase: estimatedPhase,      // v27: 예상 진행 Phase
            total_phases: 4,            // v27: 총 4개 Phase
          })
          .eq("id", task_id);

        return new Response(
          JSON.stringify({
            success: true,
            status: openaiStatus,
            phase: estimatedPhase,      // v27: 예상 진행 Phase
            total_phases: 4,            // v27: 총 4개 Phase
            message: openaiStatus === "queued"
              ? "Task is queued in OpenAI"
              : `Phase ${estimatedPhase}/4 분석 중...`,
            created_at: task.created_at,
            started_at: task.started_at,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );

      case "completed":
        // 완료! 결과 추출
        console.log(`[ai-openai-result v30] OpenAI task completed!`);
        console.log(`[ai-openai-result v30] Full response keys:`, Object.keys(responseData));

        // v30: extractOutputText 사용 (reasoning 필터링 포함)
        const outputText = extractOutputText(responseData);
        console.log(`[ai-openai-result v30] Extracted outputText length: ${outputText.length}`);

        const usage = responseData.usage || {};

        // v27: Phase별 데이터 파싱
        const partialResult = parseResultToPhases(outputText);
        console.log(`[ai-openai-result v30] Parsed ${partialResult.completed_phases} phases`);

        // ai_tasks 결과 저장 (캐싱) + Phase 정보
        await supabase
          .from("ai_tasks")
          .update({
            status: "completed",
            phase: 4,
            total_phases: 4,
            partial_result: partialResult,
            result_data: {
              success: true,
              content: outputText,
              usage: {
                prompt_tokens: usage.input_tokens || 0,
                completion_tokens: usage.output_tokens || 0,
                total_tokens: (usage.input_tokens || 0) + (usage.output_tokens || 0),
              },
              model: responseData.model || task.model,
              finish_reason: "stop",
            },
            completed_at: new Date().toISOString(),
          })
          .eq("id", task_id);

        // 토큰 사용량 기록 (user_id가 있는 경우)
        if (task.user_id && usage.input_tokens) {
          await recordTokenUsage(
            supabase,
            task.user_id,
            usage.input_tokens || 0,
            usage.output_tokens || 0,
            task.model
          );
        }

        return new Response(
          JSON.stringify({
            success: true,
            status: "completed",
            phase: 4,
            total_phases: 4,
            partial_result: partialResult,
            content: outputText,
            usage: {
              prompt_tokens: usage.input_tokens || 0,
              completion_tokens: usage.output_tokens || 0,
              total_tokens: (usage.input_tokens || 0) + (usage.output_tokens || 0),
            },
            model: responseData.model || task.model,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );

      case "incomplete":
        // v26: incomplete 상태 처리 (max_tokens 도달로 응답이 잘림)
        console.log(`[ai-openai-result v30] OpenAI task incomplete - extracting partial content`);
        console.log(`[ai-openai-result v30] Full response keys:`, Object.keys(responseData));

        // v30: extractOutputText 사용 (reasoning 필터링 포함)
        const partialText = extractOutputText(responseData);
        console.log(`[ai-openai-result v30] Extracted partialText length: ${partialText.length}`);

        if (partialText.length > 0) {
          const partialUsage = responseData.usage || {};

          const incompletePartialResult = parseResultToPhases(partialText);
          console.log(`[ai-openai-result v30] Parsed ${incompletePartialResult.completed_phases} phases (incomplete)`);

          await supabase
            .from("ai_tasks")
            .update({
              status: "completed",
              phase: 4,
              total_phases: 4,
              partial_result: incompletePartialResult,
              result_data: {
                success: true,
                content: partialText,
                usage: {
                  prompt_tokens: partialUsage.input_tokens || 0,
                  completion_tokens: partialUsage.output_tokens || 0,
                  total_tokens: (partialUsage.input_tokens || 0) + (partialUsage.output_tokens || 0),
                },
                model: responseData.model || task.model,
                finish_reason: "incomplete",
              },
              completed_at: new Date().toISOString(),
            })
            .eq("id", task_id);

          if (task.user_id && partialUsage.input_tokens) {
            await recordTokenUsage(
              supabase,
              task.user_id,
              partialUsage.input_tokens || 0,
              partialUsage.output_tokens || 0,
              task.model
            );
          }

          return new Response(
            JSON.stringify({
              success: true,
              status: "completed",
              phase: 4,
              total_phases: 4,
              partial_result: incompletePartialResult,
              content: partialText,
              usage: {
                prompt_tokens: partialUsage.input_tokens || 0,
                completion_tokens: partialUsage.output_tokens || 0,
                total_tokens: (partialUsage.input_tokens || 0) + (partialUsage.output_tokens || 0),
              },
              model: responseData.model || task.model,
              finish_reason: "incomplete",
            }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 부분 콘텐츠도 없으면 실패 처리
        console.log(`[ai-openai-result v30] No partial content available, treating as failed`);
        const incompleteError = "Task incomplete: no content available";

        await supabase
          .from("ai_tasks")
          .update({
            status: "failed",
            error_message: incompleteError,
            completed_at: new Date().toISOString(),
          })
          .eq("id", task_id);

        return new Response(
          JSON.stringify({
            success: false,
            status: "failed",
            error: incompleteError,
          }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );

      case "failed":
      case "cancelled":
        console.log(`[ai-openai-result v30] OpenAI task ${openaiStatus}: ${responseData.error?.message}`);

        const errorMessage = responseData.error?.message || `Task ${openaiStatus}`;

        await supabase
          .from("ai_tasks")
          .update({
            status: "failed",
            error_message: errorMessage,
            completed_at: new Date().toISOString(),
          })
          .eq("id", task_id);

        return new Response(
          JSON.stringify({
            success: false,
            status: "failed",
            error: errorMessage,
          }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );

      default:
        console.log(`[ai-openai-result v30] Unknown OpenAI status: ${openaiStatus}`);
        return new Response(
          JSON.stringify({
            success: true,
            status: openaiStatus,
            message: "Unknown status, please retry",
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
  } catch (error) {
    console.error("[ai-openai-result v30] Error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

/**
 * 토큰 사용량 기록
 */
async function recordTokenUsage(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  promptTokens: number,
  completionTokens: number,
  model: string
): Promise<void> {
  const today = new Date().toISOString().split("T")[0];
  const totalTokens = promptTokens + completionTokens;

  // GPT-5.2 비용: $3/1M input, $12/1M output
  const cost = (promptTokens * 3.00 / 1000000) + (completionTokens * 12.00 / 1000000);

  try {
    const { data: existing } = await supabase
      .from("user_daily_token_usage")
      .select("id, gpt_saju_analysis_tokens, gpt_saju_analysis_count, gpt_cost_usd")
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    if (existing) {
      await supabase
        .from("user_daily_token_usage")
        .update({
          gpt_saju_analysis_tokens: (existing.gpt_saju_analysis_tokens || 0) + totalTokens,
          gpt_saju_analysis_count: (existing.gpt_saju_analysis_count || 0) + 1,
          gpt_cost_usd: parseFloat(existing.gpt_cost_usd || "0") + cost,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existing.id);
    } else {
      await supabase
        .from("user_daily_token_usage")
        .insert({
          user_id: userId,
          usage_date: today,
          gpt_saju_analysis_tokens: totalTokens,
          gpt_saju_analysis_count: 1,
          gpt_cost_usd: cost,
        });
    }
    console.log(`[ai-openai-result v30] Recorded ${totalTokens} tokens for user ${userId}`);
  } catch (error) {
    console.error("[ai-openai-result v30] Failed to record token usage:", error);
  }
}
