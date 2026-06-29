import type { SupabaseClient } from "@supabase/supabase-js";
import type { AiSummaryRow, SajuAnalysisRow, SajuProfileRow } from "./models";
import {
  chatMessageColumns,
  chatMessagesTable,
  chatMessageSelectColumns,
  chatSessionColumns,
  chatSessionsTable,
  chatSessionSelectColumns,
} from "./schema";

export type ChatRole = "user" | "assistant" | "system";

export type ChatSessionRow = {
  id: string;
  profile_id: string;
  title: string;
  chat_type: string;
  message_count: number | null;
  last_message_preview: string | null;
  context_summary: string | null;
  target_profile_id: string | null;
  total_tokens_used: number | null;
  user_message_count: number | null;
  assistant_message_count: number | null;
  chat_persona: string | null;
  mbti_quadrant: string | null;
  locale: string | null;
  created_at: string | null;
  updated_at: string | null;
};

export type ChatMessageRow = {
  id: string;
  session_id: string;
  role: ChatRole;
  content: string;
  suggested_questions: string[] | null;
  tokens_used: number | null;
  status: string | null;
  created_at: string | null;
};

type AiGeminiResponse = {
  success?: boolean;
  content?: string;
  usage?: {
    prompt_tokens?: number;
    completion_tokens?: number;
    total_tokens?: number;
  };
  model?: string;
  finish_reason?: string;
  error?: string;
};

export async function getLatestChatSession(
  client: SupabaseClient,
  profileId: string,
) {
  const { data, error } = await client
    .from(chatSessionsTable)
    .select(chatSessionSelectColumns)
    .eq(chatSessionColumns.profileId, profileId)
    .eq(chatSessionColumns.chatType, "general")
    .order(chatSessionColumns.updatedAt, { ascending: false })
    .limit(1)
    .maybeSingle<ChatSessionRow>();

  if (error) throw new Error(`채팅 세션 조회 실패: ${error.message}`);
  return data;
}

export async function createChatSession(
  client: SupabaseClient,
  profile: SajuProfileRow,
) {
  const now = new Date().toISOString();
  const { data, error } = await client
    .from(chatSessionsTable)
    .insert({
      id: crypto.randomUUID(),
      profile_id: profile.id,
      title: `${profile.display_name} 상담`,
      chat_type: "general",
      message_count: 0,
      last_message_preview: null,
      context_summary: null,
      chat_persona: "basePerson",
      locale: profile.locale || "ko",
      created_at: now,
      updated_at: now,
    })
    .select(chatSessionSelectColumns)
    .single<ChatSessionRow>();

  if (error) throw new Error(`채팅 세션 생성 실패: ${error.message}`);
  return data;
}

export async function getOrCreateChatSession(
  client: SupabaseClient,
  profile: SajuProfileRow,
) {
  const existing = await getLatestChatSession(client, profile.id);
  if (existing) return existing;
  return createChatSession(client, profile);
}

export async function getChatMessages(
  client: SupabaseClient,
  sessionId: string,
  limit = 30,
) {
  const { data, error } = await client
    .from(chatMessagesTable)
    .select(chatMessageSelectColumns)
    .eq(chatMessageColumns.sessionId, sessionId)
    .order(chatMessageColumns.createdAt, { ascending: false })
    .limit(limit)
    .returns<ChatMessageRow[]>();

  if (error) throw new Error(`채팅 메시지 조회 실패: ${error.message}`);
  return [...(data ?? [])].reverse();
}

export async function createChatMessage(
  client: SupabaseClient,
  message: Omit<ChatMessageRow, "created_at"> & { created_at?: string | null },
) {
  const { data, error } = await client
    .from(chatMessagesTable)
    .insert({
      id: message.id,
      session_id: message.session_id,
      role: message.role,
      content: message.content,
      suggested_questions: message.suggested_questions,
      tokens_used: message.tokens_used,
      status: message.status ?? "sent",
      created_at: message.created_at ?? new Date().toISOString(),
    })
    .select(chatMessageSelectColumns)
    .single<ChatMessageRow>();

  if (error) throw new Error(`채팅 메시지 저장 실패: ${error.message}`);
  return data;
}

export async function updateChatSessionAfterMessage(
  client: SupabaseClient,
  sessionId: string,
  lastUserMessage: string,
) {
  await client
    .from(chatSessionsTable)
    .update({
      title:
        lastUserMessage.length > 30
          ? `${lastUserMessage.slice(0, 30)}...`
          : lastUserMessage,
      last_message_preview:
        lastUserMessage.length > 50
          ? `${lastUserMessage.slice(0, 50)}...`
          : lastUserMessage,
      updated_at: new Date().toISOString(),
    })
    .eq(chatSessionColumns.id, sessionId);
}

function safeJson(value: unknown) {
  try {
    return JSON.stringify(value ?? {}, null, 2);
  } catch {
    return "{}";
  }
}

function buildSystemPrompt({
  profile,
  analysis,
  summary,
  contextSummary,
}: {
  profile: SajuProfileRow;
  analysis: SajuAnalysisRow | null;
  summary?: AiSummaryRow | null;
  contextSummary?: string | null;
}) {
  const sajuLine = analysis
    ? `년주 ${analysis.year_gan}${analysis.year_ji}, 월주 ${analysis.month_gan}${analysis.month_ji}, 일주 ${analysis.day_gan}${analysis.day_ji}, 시주 ${analysis.hour_gan ?? ""}${analysis.hour_ji ?? ""}`
    : "저장된 만세력 분석 없음";

  return [
    "너는 SaDam의 AI 사주 상담사다.",
    "한국어로 답하고, 단정적 예언 대신 사용자가 이해하고 선택할 수 있는 상담형 설명을 제공한다.",
    "중요한 의료, 법률, 금융 판단은 전문가 상담을 권한다.",
    "답변 끝에는 사용자가 바로 누를 수 있는 후속 질문 2~3개를 [SUGGESTED_QUESTIONS] 블록에 줄 단위로 넣는다.",
    "",
    `프로필: ${profile.display_name}, 성별 ${profile.gender}, 생년월일 ${profile.birth_date}, ${profile.is_lunar ? "음력" : "양력"}`,
    `사주: ${sajuLine}`,
    `오행 분포: ${safeJson(analysis?.oheng_distribution)}`,
    `용신: ${safeJson(analysis?.yongsin)}`,
    `격국: ${safeJson(analysis?.gyeokguk)}`,
    summary?.content ? `AI 평생 분석 요약: ${safeJson(summary.content)}` : "",
    contextSummary ? `이전 대화 요약: ${contextSummary}` : "",
  ]
    .filter(Boolean)
    .join("\n");
}

export function parseSuggestedQuestions(content: string) {
  const match = content.match(/\[SUGGESTED_QUESTIONS\]([\s\S]*?)(?:\[\/SUGGESTED_QUESTIONS\]|$)/);
  if (!match) return { content: content.trim(), questions: [] as string[] };

  const questions = match[1]
    .split(/\r?\n/)
    .map((line) => line.replace(/^[-*\d.\s]+/, "").trim())
    .filter(Boolean)
    .slice(0, 3);

  return {
    content: content.replace(match[0], "").trim(),
    questions,
  };
}

export async function requestAiChatAnswer({
  client,
  userId,
  profile,
  analysis,
  summary,
  session,
  history,
  message,
}: {
  client: SupabaseClient;
  userId: string;
  profile: SajuProfileRow;
  analysis: SajuAnalysisRow | null;
  summary?: AiSummaryRow | null;
  session: ChatSessionRow;
  history: ChatMessageRow[];
  message: string;
}) {
  const messages = [
    {
      role: "system",
      content: buildSystemPrompt({
        profile,
        analysis,
        summary,
        contextSummary: session.context_summary,
      }),
    },
    ...history.slice(-20).map((item) => ({
      role: item.role === "assistant" ? "assistant" : "user",
      content: item.content,
    })),
    { role: "user", content: message },
  ];

  const { data, error } = await client.functions.invoke<AiGeminiResponse>(
    "ai-gemini",
    {
      body: {
        messages,
        model: "gemini-2.5-flash-lite",
        max_tokens: 2048,
        temperature: 0.8,
        user_id: userId,
        session_id: session.id,
        stream: false,
      },
    },
  );

  if (error) throw new Error(`AI 응답 실패: ${error.message}`);
  if (!data?.success) throw new Error(data?.error ?? "AI 응답 생성 실패");

  const parsed = parseSuggestedQuestions(data.content ?? "");
  return {
    content: parsed.content,
    suggestedQuestions: parsed.questions,
    tokensUsed: data.usage?.completion_tokens ?? null,
  };
}
