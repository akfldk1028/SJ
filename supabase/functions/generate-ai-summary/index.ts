import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  AI_SUMMARY_SYSTEM_PROMPT,
  buildAnalysisPrompt,
  getFortuneFromYongsin,
  type SajuAnalysisInput,
} from "./prompts.ts";

// ═══════════════════════════════════════════════════════════════════════════════
// generate-ai-summary Edge Function
// ═══════════════════════════════════════════════════════════════════════════════
//
// ## 목적
// Gemini 3.0으로 사주 AI 요약을 생성합니다.
// (성격, 강점, 약점, 진로, 대인관계, 개운법 등)
//
// ## 아키텍처 (Option A)
// ┌─────────────────────────────────────────────────────────────────┐
// │  이 Edge Function은 AI 생성만 담당합니다!                        │
// │  DB 저장은 Flutter 앱에서 ai_summaries 테이블에 직접 처리         │
// └─────────────────────────────────────────────────────────────────┘
//
// ## AI 모델 역할 분담
// ┌──────────────────┬─────────────────┬─────────────────────────────┐
// │ 용도             │ 모델            │ Edge Function               │
// ├──────────────────┼─────────────────┼─────────────────────────────┤
// │ 평생 사주 분석   │ GPT-5.2         │ ai-openai                   │
// │ AI 요약 생성     │ Gemini 3.0      │ generate-ai-summary (여기!) │
// │ 채팅 대화        │ Gemini 3.0      │ ai-gemini                   │
// └──────────────────┴─────────────────┴─────────────────────────────┘
//
// ## 호출 흐름
// Flutter AiSummaryService.generateSummary()
//     ↓
// 1. ai_summaries 테이블에서 캐시 확인 (Flutter에서)
// 2. 캐시 없으면 이 Edge Function 호출
// 3. Gemini 3.0으로 AI 요약 생성
// 4. 결과 반환 (DB 저장 안함!)
// 5. Flutter에서 ai_summaries 테이블에 저장
//
// ## 담당자
// - Jina: AI 대화/요약 담당
// - 수정 시 Jina에게 연락!
//
// ═══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// CORS 설정
// ─────────────────────────────────────────────────────────────────────────────
// Flutter 앱에서 호출할 수 있도록 CORS 허용
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ─────────────────────────────────────────────────────────────────────────────
// Qwen API 설정 (v38: Gemini → Qwen 전환)
// ─────────────────────────────────────────────────────────────────────────────
const QWEN_API_KEY = Deno.env.get("QWEN_API_KEY");
const QWEN_BASE_URL = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1";
const QWEN_MODEL = "qwen3.5-flash";

// Fallback용 Gemini
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-2.5-flash-lite";

// ─────────────────────────────────────────────────────────────────────────────
// 타입 정의
// ─────────────────────────────────────────────────────────────────────────────

/**
 * AI Summary 응답 JSON 구조
 *
 * Flutter의 AiSummary 클래스와 동일한 구조
 * @see frontend/lib/core/services/ai_summary_service.dart
 */
interface AiSummary {
  // 성격 분석
  personality: {
    core: string;      // 핵심 성격 (예: "태양처럼 밝고 열정적입니다")
    traits: string[];  // 성격 특성 목록 (예: ["열정적", "낙천적", "표현력"])
  };

  // 강점/약점
  strengths: string[];   // 강점 목록
  weaknesses: string[];  // 약점 목록

  // 진로/적성
  career: {
    aptitude: string[];  // 적성 분야 목록
    advice: string;      // 진로 조언
  };

  // 대인관계
  relationships: {
    style: string;  // 대인관계 스타일
    tips: string;   // 관계 팁
  };

  // 개운법 (행운을 부르는 방법)
  fortune_tips: {
    colors: string[];      // 행운의 색상
    directions: string[];  // 행운의 방향
    activities: string[];  // 행운을 부르는 활동
  };

  // 메타 정보
  generated_at: string;  // 생성 시간 (ISO 8601)
  model: string;         // 사용 모델 (gemini-2.5-flash-lite)
  version: string;       // 스키마 버전 (1.0)
}

/**
 * 요청 인터페이스
 *
 * Flutter에서 보내는 요청 형식
 * @see AiSummaryService._convertSajuAnalysis()
 */
interface GenerateSummaryRequest {
  profile_id: string;          // 프로필 UUID
  profile_name: string;        // 프로필 이름 (예: "홍길동")
  birth_date: string;          // 생년월일시 (예: "1990-05-15 14:30")
  saju_analysis: SajuAnalysisInput;  // 사주 분석 데이터 (만세력 계산 결과)
}

// ─────────────────────────────────────────────────────────────────────────────
// Qwen API 호출 (v38: primary)
// ─────────────────────────────────────────────────────────────────────────────

async function generateWithQwen(prompt: string): Promise<AiSummary> {
  if (!QWEN_API_KEY) throw new Error("QWEN_API_KEY not set");

  const resp = await fetch(`${QWEN_BASE_URL}/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Authorization": `Bearer ${QWEN_API_KEY}` },
    body: JSON.stringify({
      model: QWEN_MODEL,
      messages: [
        { role: "system", content: AI_SUMMARY_SYSTEM_PROMPT },
        { role: "user", content: prompt },
      ],
      max_tokens: 1024,
      temperature: 0.7,
      top_p: 0.9,
      response_format: { type: "json_object" },
      enable_thinking: false,
    }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    console.error(`[generate-ai-summary] Qwen API ${resp.status}:`, errText);
    throw new Error(`Qwen API error: ${resp.status}`);
  }

  const data = await resp.json();
  const choice = data.choices?.[0];
  if (!choice?.message?.content) {
    throw new Error("No response from Qwen");
  }

  const usage = data.usage || {};
  console.log(`[generate-ai-summary] Qwen tokens: prompt=${usage.prompt_tokens || 0}, completion=${usage.completion_tokens || 0}, cached=${usage.prompt_tokens_details?.cached_tokens || 0}`);

  try {
    return JSON.parse(choice.message.content) as AiSummary;
  } catch (parseError) {
    console.error("[generate-ai-summary] JSON parse error:", parseError);
    console.error("[generate-ai-summary] Raw:", choice.message.content);
    throw new Error("Failed to parse Qwen response as JSON");
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gemini API 호출 (fallback)
// ─────────────────────────────────────────────────────────────────────────────

async function generateWithGemini(prompt: string): Promise<AiSummary> {
  if (!GEMINI_API_KEY) throw new Error("GEMINI_API_KEY not set");
  const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      systemInstruction: { parts: [{ text: AI_SUMMARY_SYSTEM_PROMPT }] },
      generationConfig: {
        temperature: 0.7, maxOutputTokens: 1024, topP: 0.9, topK: 40,
        responseMimeType: "application/json",
      },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
      ],
    }),
  });

  const data = await response.json();
  if (data.error) throw new Error(data.error.message || "Gemini API error");
  if (!data.candidates?.length) throw new Error("No response from Gemini");
  if (data.candidates[0].finishReason === "SAFETY") throw new Error("Blocked by safety");

  const rawText = data.candidates[0].content?.parts?.[0]?.text || "";
  const usage = data.usageMetadata || {};
  console.log(`[generate-ai-summary] Gemini fallback tokens: prompt=${usage.promptTokenCount || 0}, completion=${usage.candidatesTokenCount || 0}`);

  return JSON.parse(rawText) as AiSummary;
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback (비상용)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * AI 생성 실패 시 기본 요약 반환
 *
 * Gemini API 장애 시에도 사용자에게 최소한의 정보 제공
 * 일간(日干)과 용신(用神) 기반으로 기본적인 해석 생성
 *
 * @param analysis - 사주 분석 입력 데이터
 * @returns 기본 AiSummary 객체
 */
function createFallbackSummary(analysis: SajuAnalysisInput): AiSummary {
  // 일간(日干) - 나를 대표하는 천간
  const ilgan = analysis.saju.day.gan;

  // 용신(用神) - 나에게 필요한 오행
  const yongsin = analysis.yongsin?.yongsin || "토(土)";

  // 용신에 따른 개운법
  // @see prompts.ts의 getFortuneFromYongsin
  const fortune = getFortuneFromYongsin(yongsin);

  // 일간별 성격 특성 (간단 버전)
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
    model: "fallback",  // fallback 사용 표시
    version: "1.0",
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// 메인 핸들러
// ═══════════════════════════════════════════════════════════════════════════════

Deno.serve(async (req) => {
  // ─────────────────────────────────────────────────────────────────────────
  // CORS Preflight 처리
  // ─────────────────────────────────────────────────────────────────────────
  // 브라우저가 실제 요청 전에 OPTIONS 요청으로 CORS 확인
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ─────────────────────────────────────────────────────────────────────────
    // 환경 변수 확인
    // ─────────────────────────────────────────────────────────────────────────
    if (!QWEN_API_KEY && !GEMINI_API_KEY) {
      throw new Error("QWEN_API_KEY or GEMINI_API_KEY required");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 요청 파싱
    // ─────────────────────────────────────────────────────────────────────────
    const requestData: GenerateSummaryRequest = await req.json();
    const {
      profile_id,
      profile_name,
      birth_date,
      saju_analysis,
    } = requestData;

    // 필수 파라미터 검증
    if (!profile_id) {
      throw new Error("profile_id is required");
    }
    if (!saju_analysis) {
      throw new Error("saju_analysis is required");
    }

    console.log(`[generate-ai-summary] 요청: profile=${profile_id}, name=${profile_name}`);

    // ─────────────────────────────────────────────────────────────────────────
    // 프롬프트 생성 및 AI 호출
    // ─────────────────────────────────────────────────────────────────────────
    // buildAnalysisPrompt: 사주 데이터를 한국어 프롬프트로 변환
    // @see prompts.ts
    const analysisPrompt = buildAnalysisPrompt(
      profile_name || "사용자",
      birth_date || "미상",
      saju_analysis
    );

    // v38: Qwen 우선 → Gemini fallback → 정적 fallback
    let aiSummary: AiSummary;
    try {
      if (QWEN_API_KEY) {
        aiSummary = await generateWithQwen(analysisPrompt);
        aiSummary.model = QWEN_MODEL;
      } else {
        aiSummary = await generateWithGemini(analysisPrompt);
        aiSummary.model = GEMINI_MODEL;
      }
      aiSummary.generated_at = new Date().toISOString();
      aiSummary.version = "1.0";
    } catch (primaryError) {
      console.error("[generate-ai-summary] Primary 실패:", primaryError);
      // Qwen 실패 시 Gemini fallback 시도
      if (QWEN_API_KEY && GEMINI_API_KEY) {
        try {
          console.log("[generate-ai-summary] Gemini fallback 시도");
          aiSummary = await generateWithGemini(analysisPrompt);
          aiSummary.generated_at = new Date().toISOString();
          aiSummary.model = GEMINI_MODEL + "-fallback";
          aiSummary.version = "1.0";
        } catch (fallbackError) {
          console.error("[generate-ai-summary] Gemini fallback도 실패:", fallbackError);
          aiSummary = createFallbackSummary(saju_analysis);
        }
      } else {
        aiSummary = createFallbackSummary(saju_analysis);
      }
    }

    console.log(`[generate-ai-summary] 완료: profile=${profile_id}, model=${aiSummary.model}`);

    // ─────────────────────────────────────────────────────────────────────────
    // 응답 반환 (DB 저장 없이!)
    // ─────────────────────────────────────────────────────────────────────────
    // Flutter에서 이 응답을 받아서 ai_summaries 테이블에 저장
    return new Response(
      JSON.stringify({
        success: true,
        ai_summary: aiSummary,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    // ─────────────────────────────────────────────────────────────────────────
    // 에러 응답
    // ─────────────────────────────────────────────────────────────────────────
    console.error("[generate-ai-summary] Error:", error);

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
