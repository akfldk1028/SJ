import type { SupabaseClient } from "@supabase/supabase-js";
import {
  analysisSelectColumns,
  analysesTable,
  aiSummariesTable,
  aiSummaryColumns,
  aiSummarySelectColumns,
  profileColumns,
  profileSelectColumns,
  profilesTable,
} from "./schema";
import type { AiSummaryRow, SajuAnalysisRow, SajuProfileRow } from "./models";

export async function getProfileById(
  client: SupabaseClient,
  profileId: string,
) {
  const { data, error } = await client
    .from(profilesTable)
    .select(profileSelectColumns)
    .eq(profileColumns.id, profileId)
    .maybeSingle<SajuProfileRow>();

  if (error) throw new Error(`프로필 조회 실패: ${error.message}`);
  return data;
}

export async function getPrimaryProfile(client: SupabaseClient, userId: string) {
  const { data, error } = await client
    .from(profilesTable)
    .select(profileSelectColumns)
    .eq(profileColumns.userId, userId)
    .eq(profileColumns.profileType, "primary")
    .maybeSingle<SajuProfileRow>();

  if (error) throw new Error(`기본 프로필 조회 실패: ${error.message}`);
  return data;
}

export async function getAnalysisByProfileId(
  client: SupabaseClient,
  profileId: string,
) {
  const { data, error } = await client
    .from(analysesTable)
    .select(analysisSelectColumns)
    .eq("profile_id", profileId)
    .maybeSingle<SajuAnalysisRow>();

  if (error) throw new Error(`사주 분석 조회 실패: ${error.message}`);
  return data;
}

export async function getOwnedProfileWithAnalysis(
  client: SupabaseClient,
  profileId: string,
) {
  const profile = await getProfileById(client, profileId);
  if (!profile) return null;

  const analysis = await getAnalysisByProfileId(client, profileId);
  return { profile, analysis };
}

export async function getSajuBaseSummary(
  client: SupabaseClient,
  profileId: string,
  locale = "ko",
) {
  const { data, error } = await client
    .from(aiSummariesTable)
    .select(aiSummarySelectColumns)
    .eq(aiSummaryColumns.profileId, profileId)
    .eq(aiSummaryColumns.summaryType, "saju_base")
    .eq(aiSummaryColumns.locale, locale)
    .maybeSingle<AiSummaryRow>();

  if (error) throw new Error(`AI 요약 조회 실패: ${error.message}`);
  return data;
}
