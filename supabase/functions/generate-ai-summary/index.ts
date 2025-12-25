import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  AI_SUMMARY_SYSTEM_PROMPT,
  buildAnalysisPrompt,
  getFortuneFromYongsin,
  type SajuAnalysisInput,
} from "./prompts.ts";

// CORS 헤더
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Gemini API 설정
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-2.0-flash";

// Supabase 설정
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

/**
 * AI Summary JSON 구조
 */
interface AiSummary {
  personality: {
    core: string;
    traits: string[];
  };
  strengths: string[];
  weaknesses: string[];
  career: {
    aptitude: string[];
    advice: string;
  };
  relationships: {
    style: string;
    tips: string;
  };
  fortune_tips: {
    colors: string[];
    directions: string[];
    activities: string[];
  };
  generated_at: string;
  model: string;
  version: string;
}

/**
 * 요청 인터페이스
 */
interface GenerateSummaryRequest {
  profile_id: string;
  profile_name: string;
  birth_date: string;
  saju_analysis: SajuAnalysisInput;
  force_regenerate?: boolean;
}

/**
 * Gemini API로 JSON 생성 요청
 */
async function generateWithGemini(prompt: string): Promise<AiSummary> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [{ text: prompt }],
          },
        ],
        systemInstruction: {
          parts: [{ text: AI_SUMMARY_SYSTEM_PROMPT }],
        },
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 1024,
          topP: 0.9,
          topK: 40,
          responseMimeType: "application/json",
        },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
        ],
      }),
    }
  );

  const data = await response.json();

  if (data.error) {
    console.error("Gemini API Error:", data.error);
    throw new Error(data.error.message || "Gemini API error");
  }

  if (!data.candidates || data.candidates.length === 0) {
    throw new Error("No response generated from Gemini");
  }

  const candidate = data.candidates[0];
  if (candidate.finishReason === "SAFETY") {
    throw new Error("Response blocked due to safety settings");
  }

  const rawText = candidate.content?.parts?.[0]?.text || "";

  try {
    const parsed = JSON.parse(rawText);
    return parsed as AiSummary;
  } catch (parseError) {
    console.error("JSON parse error:", parseError);
    console.error("Raw text:", rawText);
    throw new Error("Failed to parse AI response as JSON");
  }
}

/**
 * 기본 AI Summary 생성 (fallback)
 */
function createFallbackSummary(analysis: SajuAnalysisInput): AiSummary {
  const ilgan = analysis.saju.day.gan;
  const yongsin = analysis.yongsin?.yongsin || "토(土)";
  const fortune = getFortuneFromYongsin(yongsin);

  const ilganTraits: Record<string, { core: string; traits: string[] }> = {
    "갑": { core: "곧은 나무처럼 정직하고 리더십이 있습니다", traits: ["정직함", "리더십", "진취적"] },
    "을": { core: "유연한 덩굴처럼 적응력이 뛰어납니다", traits: ["유연함", "적응력", "인내심"] },
    "병": { core: "태양처럼 밝고 열정적입니다", traits: ["열정적", "낙천적", "표현력"] },
    "정": { core: "촛불처럼 따뜻하고 섬세합니다", traits: ["섬세함", "배려심", "창의적"] },
    "무": { core: "산처럼 믿음직하고 포용력이 있습니다", traits: ["신뢰감", "포용력", "안정적"] },
    "기": { core: "기름진 땅처럼 실용적이고 꼼꼼합니다", traits: ["실용적", "꼼꼼함", "현실적"] },
    "경": { core: "강철처럼 결단력 있고 의리가 있습니다", traits: ["결단력", "의리", "강직함"] },
    "신": { core: "보석처럼 예리하고 완벽을 추구합니다", traits: ["예리함", "완벽주의", "세련됨"] },
    "임": { core: "큰 강처럼 지혜롭고 진취적입니다", traits: ["지혜로움", "진취적", "포용력"] },
    "계": { core: "이슬처럼 감수성이 풍부합니다", traits: ["감수성", "직관력", "유연함"] },
  };

  const personality = ilganTraits[ilgan] || {
    core: "균형 잡힌 성품을 가지고 있습니다",
    traits: ["균형감", "조화로움", "성실함"],
  };

  return {
    personality,
    strengths: ["책임감", "성실함", "배려심"],
    weaknesses: ["완벽주의 성향", "걱정이 많음"],
    career: {
      aptitude: ["기획", "상담", "교육"],
      advice: `용신인 ${yongsin} 기운을 활용하는 분야가 적합합니다`,
    },
    relationships: {
      style: "조화를 중시하며 배려심이 깊습니다",
      tips: "자신의 의견도 적극적으로 표현해보세요",
    },
    fortune_tips: fortune,
    generated_at: new Date().toISOString(),
    model: "fallback",
    version: "1.0",
  };
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 환경 변수 확인
    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is not set");
    }
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("Supabase credentials are not set");
    }

    const requestData: GenerateSummaryRequest = await req.json();
    const {
      profile_id,
      profile_name,
      birth_date,
      saju_analysis,
      force_regenerate = false,
    } = requestData;

    // 필수 파라미터 검증
    if (!profile_id) {
      throw new Error("profile_id is required");
    }
    if (!saju_analysis) {
      throw new Error("saju_analysis is required");
    }

    // Supabase 클라이언트 생성 (service role - RLS 우회)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // 기존 레코드 확인
    const { data: existing, error: selectError } = await supabase
      .from("saju_analyses")
      .select("id, ai_summary")
      .eq("profile_id", profile_id)
      .single();

    // 기존 ai_summary가 있고 force_regenerate가 아니면 캐시 반환
    if (!force_regenerate && existing?.ai_summary) {
      console.log(`AI summary already exists for profile: ${profile_id}`);
      return new Response(
        JSON.stringify({
          success: true,
          ai_summary: existing.ai_summary,
          cached: true,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 분석 프롬프트 생성
    const analysisPrompt = buildAnalysisPrompt(
      profile_name || "사용자",
      birth_date || "미상",
      saju_analysis
    );

    console.log("Generating AI summary for profile:", profile_id);

    // Gemini로 AI Summary 생성
    let aiSummary: AiSummary;
    try {
      aiSummary = await generateWithGemini(analysisPrompt);
      aiSummary.generated_at = new Date().toISOString();
      aiSummary.model = GEMINI_MODEL;
      aiSummary.version = "1.0";
    } catch (geminiError) {
      console.error("Gemini generation failed, using fallback:", geminiError);
      aiSummary = createFallbackSummary(saju_analysis);
    }

    let dbSaved = false;
    let dbError: string | null = null;

    // DB에 저장: 기존 레코드가 있으면 UPDATE, 없으면 INSERT
    if (existing) {
      // UPDATE: ai_summary만 업데이트
      console.log("Updating existing record for profile:", profile_id);
      const { error: updateError } = await supabase
        .from("saju_analyses")
        .update({
          ai_summary: aiSummary,
          updated_at: new Date().toISOString(),
        })
        .eq("profile_id", profile_id);

      if (updateError) {
        console.error("Failed to update AI summary:", JSON.stringify(updateError));
        dbError = updateError.message;
      } else {
        console.log("AI summary updated successfully for profile:", profile_id);
        dbSaved = true;
      }
    } else {
      // INSERT: 새 레코드 생성
      console.log("Inserting new record for profile:", profile_id);
      const insertData = {
        profile_id: profile_id,
        year_gan: saju_analysis.saju.year.gan,
        year_ji: saju_analysis.saju.year.ji,
        month_gan: saju_analysis.saju.month.gan,
        month_ji: saju_analysis.saju.month.ji,
        day_gan: saju_analysis.saju.day.gan,
        day_ji: saju_analysis.saju.day.ji,
        hour_gan: saju_analysis.saju.hour?.gan || null,
        hour_ji: saju_analysis.saju.hour?.ji || null,
        oheng_distribution: {
          mok: saju_analysis.oheng.wood,
          hwa: saju_analysis.oheng.fire,
          to: saju_analysis.oheng.earth,
          geum: saju_analysis.oheng.metal,
          su: saju_analysis.oheng.water,
        },
        yongsin: saju_analysis.yongsin ? {
          yongsin: saju_analysis.yongsin.yongsin,
          heesin: saju_analysis.yongsin.huisin,
          gisin: saju_analysis.yongsin.gisin,
          gusin: saju_analysis.yongsin.gusin,
        } : null,
        day_strength: saju_analysis.singang_singak ? {
          isStrong: saju_analysis.singang_singak.is_singang,
          score: saju_analysis.singang_singak.score,
          factors: saju_analysis.singang_singak.factors,
        } : null,
        ai_summary: aiSummary,
        updated_at: new Date().toISOString(),
      };

      const { error: insertError } = await supabase
        .from("saju_analyses")
        .insert(insertData);

      if (insertError) {
        console.error("Failed to insert AI summary:", JSON.stringify(insertError));
        dbError = insertError.message;
      } else {
        console.log("AI summary inserted successfully for profile:", profile_id);
        dbSaved = true;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        ai_summary: aiSummary,
        cached: false,
        db_saved: dbSaved,
        db_error: dbError,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Edge Function Error:", error);

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
