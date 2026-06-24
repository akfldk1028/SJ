import type { SupabaseClient } from "@supabase/supabase-js";
import type { AiSummaryRow, SajuAnalysisRow, SajuProfileRow } from "./models";
import { toGenerateSummaryInput } from "./models";
import {
  aiSummariesTable,
  aiSummaryColumns,
  aiSummarySelectColumns,
} from "./schema";

type GenerateSummaryResponse = {
  success?: boolean;
  ai_summary?: Record<string, unknown>;
  error?: string;
};

export async function generateAiSummary(
  client: SupabaseClient,
  profile: SajuProfileRow,
  analysis: SajuAnalysisRow,
) {
  const { data, error } = await client.functions.invoke<GenerateSummaryResponse>(
    "generate-ai-summary",
    {
      body: {
        profile_id: profile.id,
        profile_name: profile.display_name,
        birth_date: profile.birth_time_minutes == null
          ? profile.birth_date
          : `${profile.birth_date} ${String(Math.floor(profile.birth_time_minutes / 60)).padStart(2, "0")}:${String(profile.birth_time_minutes % 60).padStart(2, "0")}`,
        saju_analysis: toGenerateSummaryInput(analysis),
      },
    },
  );

  if (error) throw new Error(`AI 요약 생성 실패: ${error.message}`);
  if (!data?.success || !data.ai_summary) {
    throw new Error(data?.error ?? "AI 요약 생성 실패");
  }

  return data.ai_summary;
}

export async function saveSajuBaseSummary({
  client,
  userId,
  profile,
  analysis,
  content,
}: {
  client: SupabaseClient;
  userId: string;
  profile: SajuProfileRow;
  analysis: SajuAnalysisRow;
  content: Record<string, unknown>;
}) {
  const now = new Date().toISOString();
  const locale = profile.locale || "ko";

  await client
    .from(aiSummariesTable)
    .delete()
    .eq(aiSummaryColumns.profileId, profile.id)
    .eq(aiSummaryColumns.summaryType, "saju_base")
    .eq(aiSummaryColumns.locale, locale);

  const { data, error } = await client
    .from(aiSummariesTable)
    .insert({
      user_id: userId,
      profile_id: profile.id,
      summary_type: "saju_base",
      content,
      input_data: {
        source: "toss-miniapp",
        saju_analysis: toGenerateSummaryInput(analysis),
      },
      model_provider: String(content.model ?? "").includes("gemini") ? "google" : "qwen",
      model_name: typeof content.model === "string" ? content.model : null,
      status: "completed",
      is_cached: false,
      prompt_version: "generate-ai-summary",
      locale,
      created_at: now,
      updated_at: now,
    })
    .select(aiSummarySelectColumns)
    .single<AiSummaryRow>();

  if (error) throw new Error(`AI 요약 저장 실패: ${error.message}`);
  return data;
}

export async function ensureSajuBaseSummary({
  client,
  userId,
  profile,
  analysis,
}: {
  client: SupabaseClient;
  userId: string;
  profile: SajuProfileRow;
  analysis: SajuAnalysisRow;
}) {
  const { data: cached, error: cachedError } = await client
    .from(aiSummariesTable)
    .select(aiSummarySelectColumns)
    .eq(aiSummaryColumns.profileId, profile.id)
    .eq(aiSummaryColumns.summaryType, "saju_base")
    .eq(aiSummaryColumns.locale, profile.locale || "ko")
    .maybeSingle<AiSummaryRow>();

  if (cachedError) throw new Error(`AI 요약 캐시 조회 실패: ${cachedError.message}`);
  if (cached) return cached;

  const content = await generateAiSummary(client, profile, analysis);
  return saveSajuBaseSummary({ client, userId, profile, analysis, content });
}
