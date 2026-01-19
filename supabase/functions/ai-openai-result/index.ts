import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * AI Task 결과 조회 Edge Function (v26)
 *
 * OpenAI Responses API의 background task 결과 조회
 * task_id로 조회 → openai_response_id로 OpenAI polling
 *
 * v24 변경사항:
 * - OpenAI /v1/responses/{id} 직접 polling
 * - queued/in_progress → completed 상태 변환
 * - 결과를 ai_tasks에 캐싱
 *
 * v25 변경사항 (2026-01-14):
 * - ai_analysis_tokens (legacy) → gpt_saju_analysis_tokens (신규 필드)
 * - total_tokens, is_quota_exceeded 직접 UPDATE 제거 (GENERATED 컬럼)
 * - gpt_saju_analysis_count 증가 추가
 *
 * v26 변경사항 (2026-01-19):
 * - 'incomplete' 상태 처리 추가 (max_tokens 도달로 응답이 잘린 경우)
 * - 부분 콘텐츠 추출 후 completed로 반환 (finish_reason: incomplete)
 *
 * 사용법:
 * POST /ai-openai-result
 * { "task_id": "uuid" }
 *
 * 응답:
 * - queued/in_progress: { status: "in_progress" }
 * - completed: { status: "completed", content: "...", usage: {...} }
 * - failed: { status: "failed", error: "..." }
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

interface ResultRequest {
  task_id: string;
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

    console.log(`[ai-openai-result v24] Checking task ${task_id}`);

    // Task 조회 (openai_response_id 포함)
    const { data: task, error } = await supabase
      .from("ai_tasks")
      .select("id, status, openai_response_id, result_data, error_message, user_id, model, created_at, started_at, completed_at")
      .eq("id", task_id)
      .single();

    if (error || !task) {
      console.log(`[ai-openai-result v24] Task ${task_id} not found`);
      return new Response(
        JSON.stringify({ success: false, error: "Task not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 이미 완료된 경우 캐시된 결과 반환
    if (task.status === "completed" && task.result_data) {
      console.log(`[ai-openai-result v24] Task ${task_id}: returning cached result`);
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
      console.log(`[ai-openai-result v24] Task ${task_id}: failed - ${task.error_message}`);
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
      console.log(`[ai-openai-result v24] Task ${task_id}: no openai_response_id`);
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
    console.log(`[ai-openai-result v24] Polling OpenAI: ${task.openai_response_id}`);

    const openaiResponse = await fetch(`${OPENAI_RESPONSES_URL}/${task.openai_response_id}`, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
    });

    const responseData = await openaiResponse.json();
    console.log(`[ai-openai-result v24] OpenAI status: ${openaiResponse.status}`);
    console.log(`[ai-openai-result v24] OpenAI response status: ${responseData.status}`);

    if (!openaiResponse.ok) {
      console.error("[ai-openai-result v24] OpenAI API Error:", responseData);

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
        console.log(`[ai-openai-result v24] OpenAI task ${task.openai_response_id}: ${openaiStatus}`);

        // ai_tasks 상태 업데이트
        await supabase
          .from("ai_tasks")
          .update({ status: openaiStatus })
          .eq("id", task_id);

        return new Response(
          JSON.stringify({
            success: true,
            status: openaiStatus,
            message: openaiStatus === "queued" ? "Task is queued in OpenAI" : "Task is being processed",
            created_at: task.created_at,
            started_at: task.started_at,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );

      case "completed":
        // 완료! 결과 추출
        console.log(`[ai-openai-result v24] OpenAI task completed!`);
        console.log(`[ai-openai-result v24] Full response keys:`, Object.keys(responseData));

        // v24 fix: OpenAI Responses API는 output 배열 구조
        // REST API: { output: [{ type: "message", content: [{ type: "output_text", text: "..." }] }] }
        // 또는: { output: [{ type: "text", text: "..." }] }
        let outputText = "";

        if (responseData.output && Array.isArray(responseData.output)) {
          console.log(`[ai-openai-result v24] output is array with ${responseData.output.length} items`);
          for (const outputItem of responseData.output) {
            console.log(`[ai-openai-result v24] output item type: ${outputItem.type}`);

            if (outputItem.type === "message" && outputItem.content) {
              // message 타입: content 배열에서 텍스트 추출
              for (const contentItem of outputItem.content) {
                if (contentItem.type === "output_text" && contentItem.text) {
                  outputText += contentItem.text;
                } else if (contentItem.type === "text" && contentItem.text) {
                  outputText += contentItem.text;
                }
              }
            } else if (outputItem.type === "text" && outputItem.text) {
              // text 타입: 직접 text 필드
              outputText += outputItem.text;
            }
          }
        } else if (responseData.output_text) {
          // 레거시 호환: output_text 직접 존재하는 경우
          outputText = responseData.output_text;
        }

        console.log(`[ai-openai-result v24] Extracted outputText length: ${outputText.length}`);

        const usage = responseData.usage || {};

        console.log(`[ai-openai-result v24] Output length: ${outputText.length}`);

        // ai_tasks 결과 저장 (캐싱)
        await supabase
          .from("ai_tasks")
          .update({
            status: "completed",
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
        // 부분 콘텐츠가 있을 수 있으므로 추출 시도
        console.log(`[ai-openai-result v26] OpenAI task incomplete - extracting partial content`);
        console.log(`[ai-openai-result v26] Full response keys:`, Object.keys(responseData));

        // completed와 동일한 방식으로 부분 콘텐츠 추출
        let partialText = "";

        if (responseData.output && Array.isArray(responseData.output)) {
          console.log(`[ai-openai-result v26] output is array with ${responseData.output.length} items`);
          for (const outputItem of responseData.output) {
            console.log(`[ai-openai-result v26] output item type: ${outputItem.type}`);

            if (outputItem.type === "message" && outputItem.content) {
              for (const contentItem of outputItem.content) {
                if (contentItem.type === "output_text" && contentItem.text) {
                  partialText += contentItem.text;
                } else if (contentItem.type === "text" && contentItem.text) {
                  partialText += contentItem.text;
                }
              }
            } else if (outputItem.type === "text" && outputItem.text) {
              partialText += outputItem.text;
            }
          }
        } else if (responseData.output_text) {
          partialText = responseData.output_text;
        }

        console.log(`[ai-openai-result v26] Extracted partialText length: ${partialText.length}`);

        // 부분 콘텐츠가 있으면 성공으로 처리
        if (partialText.length > 0) {
          const partialUsage = responseData.usage || {};

          // ai_tasks 결과 저장 (부분 완료로 캐싱)
          await supabase
            .from("ai_tasks")
            .update({
              status: "completed", // incomplete → completed로 변환 (부분 완료)
              result_data: {
                success: true,
                content: partialText,
                usage: {
                  prompt_tokens: partialUsage.input_tokens || 0,
                  completion_tokens: partialUsage.output_tokens || 0,
                  total_tokens: (partialUsage.input_tokens || 0) + (partialUsage.output_tokens || 0),
                },
                model: responseData.model || task.model,
                finish_reason: "incomplete", // 원래 상태 기록
              },
              completed_at: new Date().toISOString(),
            })
            .eq("id", task_id);

          // 토큰 사용량 기록
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
              status: "completed", // 클라이언트에서 처리 가능하도록 completed 반환
              content: partialText,
              usage: {
                prompt_tokens: partialUsage.input_tokens || 0,
                completion_tokens: partialUsage.output_tokens || 0,
                total_tokens: (partialUsage.input_tokens || 0) + (partialUsage.output_tokens || 0),
              },
              model: responseData.model || task.model,
              finish_reason: "incomplete", // 원래 상태도 함께 전달
            }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 부분 콘텐츠도 없으면 실패 처리
        console.log(`[ai-openai-result v26] No partial content available, treating as failed`);
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
        // 실패 또는 취소
        console.log(`[ai-openai-result v24] OpenAI task ${openaiStatus}: ${responseData.error?.message}`);

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
        console.log(`[ai-openai-result v24] Unknown OpenAI status: ${openaiStatus}`);
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
    console.error("[ai-openai-result v24] Error:", error);

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
      // UPDATE: 개별 필드만 업데이트 (total_tokens, is_quota_exceeded는 GENERATED 컬럼)
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
      // INSERT: 새 레코드 생성 (total_tokens, is_quota_exceeded는 자동 계산)
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
    console.log(`[ai-openai-result v25] Recorded ${totalTokens} tokens for user ${userId}`);
  } catch (error) {
    console.error("[ai-openai-result v25] Failed to record token usage:", error);
  }
}
