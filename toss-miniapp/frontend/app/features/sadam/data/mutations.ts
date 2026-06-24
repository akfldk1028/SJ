import type { SupabaseClient } from "@supabase/supabase-js";
import {
  analysisSelectColumns,
  analysesTable,
  profileSelectColumns,
  profilesTable,
} from "./schema";
import type { SajuAnalysisRow, SajuProfileRow } from "./models";

export async function createProfile(
  client: SupabaseClient,
  insertData: Record<string, unknown>,
) {
  const { data, error } = await client
    .from(profilesTable)
    .insert(insertData)
    .select(profileSelectColumns)
    .single<SajuProfileRow>();

  if (error) throw new Error(`프로필 생성 실패: ${error.message}`);
  return data;
}

export async function upsertAnalysis(
  client: SupabaseClient,
  upsertData: Record<string, unknown>,
) {
  const { data, error } = await client
    .from(analysesTable)
    .upsert(upsertData, { onConflict: "profile_id" })
    .select(analysisSelectColumns)
    .single<SajuAnalysisRow>();

  if (error) throw new Error(`사주 분석 저장 실패: ${error.message}`);
  return data;
}
