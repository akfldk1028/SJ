import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * AI Task Status 조회 Edge Function
 *
 * Background Task + Polling 패턴의 폴링 엔드포인트
 * 클라이언트가 5초마다 호출하여 GPT-5.2 작업 상태 확인
 *
 * 사용법:
 * POST /ai-task-status
 * { "task_id": "uuid" }
 *
 * 응답:
 * - pending: 작업 대기 중
 * - processing: GPT-5.2 호출 중
 * - completed: 완료 (result_data에 결과)
 * - failed: 실패 (error_message에 원인)
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

interface TaskStatusRequest {
  task_id: string;
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    const { task_id }: TaskStatusRequest = await req.json();

    if (!task_id) {
      throw new Error("task_id is required");
    }

    // 작업 상태 조회
    const { data: task, error } = await supabase
      .from("ai_tasks")
      .select("id, status, result_data, error_message, created_at, started_at, completed_at")
      .eq("id", task_id)
      .single();

    if (error || !task) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Task not found",
          task_id,
        }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 상태별 응답 구성
    const response: Record<string, unknown> = {
      success: true,
      task_id: task.id,
      status: task.status,
      created_at: task.created_at,
    };

    if (task.status === "processing") {
      response.started_at = task.started_at;
      response.message = "GPT-5.2 분석 중입니다. 잠시만 기다려주세요...";

      // 예상 대기 시간 계산 (시작 후 경과 시간 기준)
      if (task.started_at) {
        const elapsed = Date.now() - new Date(task.started_at).getTime();
        const estimatedTotal = 150000; // 150초 예상
        const remaining = Math.max(0, estimatedTotal - elapsed);
        response.estimated_remaining_ms = remaining;
        response.elapsed_ms = elapsed;
      }
    }

    if (task.status === "completed") {
      response.completed_at = task.completed_at;
      response.result = task.result_data;

      // 처리 시간 계산
      if (task.started_at && task.completed_at) {
        response.processing_time_ms =
          new Date(task.completed_at).getTime() - new Date(task.started_at).getTime();
      }
    }

    if (task.status === "failed") {
      response.completed_at = task.completed_at;
      response.error_message = task.error_message;
      response.result = task.result_data;
    }

    if (task.status === "pending") {
      response.message = "작업이 대기 중입니다...";
    }

    return new Response(
      JSON.stringify(response),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("[ai-task-status] Error:", error);

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
