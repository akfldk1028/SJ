import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * AI Task 결과 조회 Edge Function (v24)
 *
 * OpenAI Responses API의 background task 결과 조회
 * task_id로 조회 → openai_response_id로 OpenAI polling
 *
 * v24 변경사항:
 * - OpenAI /v1/responses/{id} 직접 polling
 * - queued/in_progress → completed 상태 변환
 * - 결과를 ai_tasks에 캐싱
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
        });
    }
    console.log(`[ai-openai-result v24] Recorded ${totalTokens} tokens for user ${userId}`);
  } catch (error) {
    console.error("[ai-openai-result v24] Failed to record token usage:", error);
  }
}
