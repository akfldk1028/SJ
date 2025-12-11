import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { SYSTEM_PROMPT, buildSajuContext } from "./prompts.ts";

// CORS 헤더 - Flutter 앱에서 호출 가능하도록
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Gemini API Key from environment variable
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-2.0-flash";

interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

interface SajuPillar {
  gan: string;
  ji: string;
  ganHanja?: string;
  jiHanja?: string;
}

interface SajuData {
  year: SajuPillar;
  month: SajuPillar;
  day: SajuPillar;
  hour: SajuPillar;
}

interface OhengCount {
  wood: number;
  fire: number;
  earth: number;
  metal: number;
  water: number;
}

interface SajuAnalysis {
  saju: SajuData;
  oheng: OhengCount;
  yongsin?: {
    yongsin: string;
    huisin: string;
    gisin: string;
    gusin: string;
  };
  sipsin?: Record<string, string>;
  sibiunseong?: Record<string, string>;
  daeun?: Array<{
    age: number;
    gan: string;
    ji: string;
  }>;
  currentDaeun?: {
    age: number;
    gan: string;
    ji: string;
  };
}

interface ChatRequest {
  messages: ChatMessage[];
  sajuAnalysis?: SajuAnalysis;
  profileName?: string;
  birthDate?: string;
  chatType?: string; // 'general' | 'compatibility' | 'yearly' | 'monthly'
  targetProfile?: {
    name: string;
    birthDate: string;
    sajuAnalysis: SajuAnalysis;
    relationType?: string;
  };
  contextSummary?: string; // 이전 대화 요약
}

Deno.serve(async (req) => {
  // CORS preflight 처리
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is not set");
    }

    const requestData: ChatRequest = await req.json();
    const {
      messages,
      sajuAnalysis,
      profileName,
      birthDate,
      chatType = "general",
      targetProfile,
      contextSummary,
    } = requestData;

    if (!messages || messages.length === 0) {
      throw new Error("Messages are required");
    }

    // 사주 컨텍스트 구축
    const sajuContext = buildSajuContext({
      profileName,
      birthDate,
      sajuAnalysis,
      chatType,
      targetProfile,
      contextSummary,
    });

    // Gemini API용 메시지 변환
    // 첫 번째 메시지에 사주 컨텍스트 주입
    const geminiContents = messages.map((msg, index) => {
      let content = msg.content;

      // 첫 번째 사용자 메시지에 컨텍스트 추가
      if (index === 0 && msg.role === "user" && sajuContext) {
        content = `[사주 분석 데이터]\n${sajuContext}\n\n[사용자 질문]\n${msg.content}`;
      }

      return {
        role: msg.role === "assistant" ? "model" : "user",
        parts: [{ text: content }],
      };
    });

    // Gemini API 호출
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: geminiContents,
          systemInstruction: {
            parts: [{ text: SYSTEM_PROMPT }],
          },
          generationConfig: {
            temperature: 0.8,
            maxOutputTokens: 2048,
            topP: 0.95,
            topK: 40,
          },
          safetySettings: [
            {
              category: "HARM_CATEGORY_HARASSMENT",
              threshold: "BLOCK_ONLY_HIGH",
            },
            {
              category: "HARM_CATEGORY_HATE_SPEECH",
              threshold: "BLOCK_ONLY_HIGH",
            },
            {
              category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              threshold: "BLOCK_ONLY_HIGH",
            },
            {
              category: "HARM_CATEGORY_DANGEROUS_CONTENT",
              threshold: "BLOCK_ONLY_HIGH",
            },
          ],
        }),
      }
    );

    const data = await response.json();

    // 에러 처리
    if (data.error) {
      console.error("Gemini API Error:", data.error);
      throw new Error(data.error.message || "Gemini API error");
    }

    // 응답이 차단된 경우
    if (!data.candidates || data.candidates.length === 0) {
      throw new Error("No response generated");
    }

    const candidate = data.candidates[0];

    // 안전성으로 인한 차단 확인
    if (candidate.finishReason === "SAFETY") {
      return new Response(
        JSON.stringify({
          response:
            "죄송합니다. 해당 질문에 대해 답변드리기 어렵습니다. 다른 질문을 해주세요.",
          blocked: true,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const aiResponse = candidate.content?.parts?.[0]?.text || "";

    // 토큰 사용량 (있는 경우)
    const usage = data.usageMetadata
      ? {
          promptTokens: data.usageMetadata.promptTokenCount,
          responseTokens: data.usageMetadata.candidatesTokenCount,
          totalTokens: data.usageMetadata.totalTokenCount,
        }
      : null;

    return new Response(
      JSON.stringify({
        response: aiResponse,
        usage,
        model: GEMINI_MODEL,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Edge Function Error:", error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
