import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * AI Task 결과 조회 Edge Function (v32)
 *
 * v32 변경사항 (2026-02-01):
 * - recordTokenUsage: task_type별 올바른 컬럼에 토큰 기록
 *   - saju_analysis/saju_base/saju_base_phase* → saju_analysis_tokens
 *   - monthly_fortune → monthly_fortune_tokens
 *   - yearly_2025 → yearly_fortune_2025_tokens
 *   - yearly_2026 → yearly_fortune_2026_tokens
 *
 * v31 변경사항 (2026-02-01):
 * - recordTokenUsage: gpt_saju_analysis_tokens → saju_analysis_tokens
 *
 * v30: reasoning 필터링
 * v29: API Key 로드밸런싱
 * v27: Phase 기반 Progressive Disclosure
 * v24: OpenAI /v1/responses/{id} 직접 polling
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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

function parseResultToPhases(content: string): Record<string, unknown> {
  try {
    const parsed = JSON.parse(content);
    const phase1 = {
      summary: parsed.summary,
      my_saju_characters: parsed.my_saju_characters,
      personality: parsed.personality,
      wonGuk_analysis: parsed.wonGuk_analysis,
    };
    const phase2 = {
      wealth: parsed.wealth,
      love: parsed.love,
      marriage: parsed.marriage,
      health: parsed.health,
    };
    const phase3 = {
      career: parsed.career,
      business: parsed.business,
      sipsung_analysis: parsed.sipsung_analysis,
      hapchung_analysis: parsed.hapchung_analysis,
    };
    const phase4 = {
      daeun_detail: parsed.daeun_detail,
      peak_years: parsed.peak_years,
      life_cycles: parsed.life_cycles,
      sinsal_gilseong: parsed.sinsal_gilseong,
      lucky_elements: parsed.lucky_elements,
    };
    return { phase1, phase2, phase3, phase4, completed_phases: 4 };
  } catch (e) {
    console.error("[ai-openai-result v32] Failed to parse phases:", e);
    return { phase1: { raw_content: content }, completed_phases: 1 };
  }
}

function extractOutputText(responseData: Record<string, unknown>): string {
  let outputText = "";
  if (responseData.output && Array.isArray(responseData.output)) {
    for (const outputItem of responseData.output) {
      if (outputItem.type === "reasoning") continue;
      if (outputItem.type === "message" && outputItem.content) {
        for (const contentItem of outputItem.content) {
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

/**
 * v32: task_type별 토큰 컬럼 결정
 */
function getTokenColumnForTaskType(taskType: string): string {
  if (taskType === 'monthly_fortune') return 'monthly_fortune_tokens';
  if (taskType === 'yearly_2025') return 'yearly_fortune_2025_tokens';
  if (taskType === 'yearly_2026') return 'yearly_fortune_2026_tokens';
  // saju_analysis, saju_base, saju_base_phase1~4, default
  return 'saju_analysis_tokens';
}

/**
 * v32: task_type별 올바른 컬럼에 토큰 기록
 */
async function recordTokenUsage(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  promptTokens: number,
  completionTokens: number,
  model: string,
  taskType: string
): Promise<void> {
  const today = new Date().toISOString().split("T")[0];
  const totalTokens = promptTokens + completionTokens;
  const cost = (promptTokens * 1.75 / 1000000) + (completionTokens * 14.00 / 1000000);
  const tokenColumn = getTokenColumnForTaskType(taskType);

  console.log(`[ai-openai-result v32] Recording ${totalTokens} tokens to ${tokenColumn} (task_type: ${taskType})`);

  try {
    const { data: existing } = await supabase
      .from("user_daily_token_usage")
      .select(`id, ${tokenColumn}, gpt_cost_usd`)
      .eq("user_id", userId)
      .eq("usage_date", today)
      .single();

    if (existing) {
      const updateData: Record<string, unknown> = {
        gpt_cost_usd: parseFloat(existing.gpt_cost_usd || "0") + cost,
        updated_at: new Date().toISOString(),
      };
      updateData[tokenColumn] = (existing[tokenColumn] || 0) + totalTokens;

      await supabase
        .from("user_daily_token_usage")
        .update(updateData)
        .eq("id", existing.id);
    } else {
      const insertData: Record<string, unknown> = {
        user_id: userId,
        usage_date: today,
        gpt_cost_usd: cost,
      };
      insertData[tokenColumn] = totalTokens;

      await supabase
        .from("user_daily_token_usage")
        .insert(insertData);
    }
    console.log(`[ai-openai-result v32] Recorded ${totalTokens} tokens to ${tokenColumn} for user ${userId}`);
  } catch (error) {
    console.error("[ai-openai-result v32] Failed to record token usage:", error);
  }
}

Deno.serve(async (req) => {
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

    console.log(`[ai-openai-result v32] Checking task ${task_id}`);

    const { data: task, error } = await supabase
      .from("ai_tasks")
      .select("id, status, openai_response_id, result_data, error_message, user_id, model, task_type, created_at, started_at, completed_at, request_data")
      .eq("id", task_id)
      .single();

    if (error || !task) {
      return new Response(
        JSON.stringify({ success: false, error: "Task not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (task.status === "completed" && task.result_data) {
      return new Response(
        JSON.stringify({
          success: true, status: "completed",
          content: task.result_data.content, usage: task.result_data.usage,
          model: task.model, completed_at: task.completed_at,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (task.status === "failed") {
      return new Response(
        JSON.stringify({ success: false, status: "failed", error: task.error_message || "Unknown error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!task.openai_response_id) {
      return new Response(
        JSON.stringify({ success: true, status: task.status || "pending", message: "Task is being processed" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const keyIdx = task.request_data?.key_index ?? 0;
    const apiKey = getApiKeyByIndex(keyIdx);
    const taskType = task.task_type || task.request_data?.task_type || 'saju_analysis';

    console.log(`[ai-openai-result v32] Polling OpenAI: ${task.openai_response_id} (task_type: ${taskType})`);

    const openaiResponse = await fetch(`${OPENAI_RESPONSES_URL}/${task.openai_response_id}`, {
      method: "GET",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${apiKey}` },
    });

    const responseData = await openaiResponse.json();

    if (!openaiResponse.ok) {
      await supabase.from("ai_tasks").update({
        status: "failed", error_message: responseData.error?.message || "OpenAI API error",
        completed_at: new Date().toISOString(),
      }).eq("id", task_id);

      return new Response(
        JSON.stringify({ success: false, status: "failed", error: responseData.error?.message || "OpenAI API error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const openaiStatus = responseData.status;

    switch (openaiStatus) {
      case "queued":
      case "in_progress": {
        let estimatedPhase = 1;
        if (task.started_at) {
          const elapsed = Date.now() - new Date(task.started_at).getTime();
          estimatedPhase = Math.min(3, Math.floor(elapsed / 20000) + 1);
        }
        await supabase.from("ai_tasks").update({ status: openaiStatus, phase: estimatedPhase, total_phases: 4 }).eq("id", task_id);
        return new Response(
          JSON.stringify({
            success: true, status: openaiStatus, phase: estimatedPhase, total_phases: 4,
            message: openaiStatus === "queued" ? "Task is queued in OpenAI" : `Phase ${estimatedPhase}/4 분석 중...`,
            created_at: task.created_at, started_at: task.started_at,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "completed": {
        const outputText = extractOutputText(responseData);
        const usage = responseData.usage || {};
        const partialResult = parseResultToPhases(outputText);

        await supabase.from("ai_tasks").update({
          status: "completed", phase: 4, total_phases: 4, partial_result: partialResult,
          result_data: {
            success: true, content: outputText,
            usage: { prompt_tokens: usage.input_tokens || 0, completion_tokens: usage.output_tokens || 0, total_tokens: (usage.input_tokens || 0) + (usage.output_tokens || 0) },
            model: responseData.model || task.model, finish_reason: "stop",
          },
          completed_at: new Date().toISOString(),
        }).eq("id", task_id);

        if (task.user_id && usage.input_tokens) {
          await recordTokenUsage(supabase, task.user_id, usage.input_tokens || 0, usage.output_tokens || 0, task.model, taskType);
        }

        return new Response(
          JSON.stringify({
            success: true, status: "completed", phase: 4, total_phases: 4,
            partial_result: partialResult, content: outputText,
            usage: { prompt_tokens: usage.input_tokens || 0, completion_tokens: usage.output_tokens || 0, total_tokens: (usage.input_tokens || 0) + (usage.output_tokens || 0) },
            model: responseData.model || task.model,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "incomplete": {
        const partialText = extractOutputText(responseData);
        if (partialText.length > 0) {
          const partialUsage = responseData.usage || {};
          const incompletePartialResult = parseResultToPhases(partialText);

          await supabase.from("ai_tasks").update({
            status: "completed", phase: 4, total_phases: 4, partial_result: incompletePartialResult,
            result_data: {
              success: true, content: partialText,
              usage: { prompt_tokens: partialUsage.input_tokens || 0, completion_tokens: partialUsage.output_tokens || 0, total_tokens: (partialUsage.input_tokens || 0) + (partialUsage.output_tokens || 0) },
              model: responseData.model || task.model, finish_reason: "incomplete",
            },
            completed_at: new Date().toISOString(),
          }).eq("id", task_id);

          if (task.user_id && partialUsage.input_tokens) {
            await recordTokenUsage(supabase, task.user_id, partialUsage.input_tokens || 0, partialUsage.output_tokens || 0, task.model, taskType);
          }

          return new Response(
            JSON.stringify({
              success: true, status: "completed", phase: 4, total_phases: 4,
              partial_result: incompletePartialResult, content: partialText,
              usage: { prompt_tokens: partialUsage.input_tokens || 0, completion_tokens: partialUsage.output_tokens || 0, total_tokens: (partialUsage.input_tokens || 0) + (partialUsage.output_tokens || 0) },
              model: responseData.model || task.model, finish_reason: "incomplete",
            }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        await supabase.from("ai_tasks").update({
          status: "failed", error_message: "Task incomplete: no content available", completed_at: new Date().toISOString(),
        }).eq("id", task_id);

        return new Response(
          JSON.stringify({ success: false, status: "failed", error: "Task incomplete: no content available" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "failed":
      case "cancelled": {
        const errorMessage = responseData.error?.message || `Task ${openaiStatus}`;
        await supabase.from("ai_tasks").update({
          status: "failed", error_message: errorMessage, completed_at: new Date().toISOString(),
        }).eq("id", task_id);

        return new Response(
          JSON.stringify({ success: false, status: "failed", error: errorMessage }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      default:
        return new Response(
          JSON.stringify({ success: true, status: openaiStatus, message: "Unknown status, please retry" }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
  } catch (error) {
    console.error("[ai-openai-result v32] Error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
