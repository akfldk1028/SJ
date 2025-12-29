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
// Gemini API 설정
// ─────────────────────────────────────────────────────────────────────────────
// GEMINI_API_KEY는 Supabase Secrets에 저장됨
// 설정 방법: npx supabase secrets set GEMINI_API_KEY=your_key
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");

// Gemini 3.0 Flash Preview (2025-12 업데이트)
// - 빠른 응답 속도
// - 한국어 지원 우수
// - JSON 출력 지원
const GEMINI_MODEL = "gemini-3-flash-preview";

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
  model: string;         // 사용 모델 (gemini-3-flash-preview)
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
// Gemini API 호출
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Gemini API로 AI 요약 생성
 *
 * @param prompt - 사주 분석 프롬프트 (한국어)
 * @returns AiSummary JSON 객체
 * @throws Error - API 오류 또는 JSON 파싱 실패 시
 *
 * ## Gemini API 특징
 * - responseMimeType: "application/json" → 항상 JSON 형식 응답
 * - systemInstruction → 시스템 프롬프트 (역할 지정)
 * - safetySettings → 안전 필터 (BLOCK_ONLY_HIGH: 높은 위험만 차단)
 */
async function generateWithGemini(prompt: string): Promise<AiSummary> {
  // Gemini API 엔드포인트 (v1beta)
  const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      // 사용자 메시지 (사주 데이터 포함)
      contents: [
        {
          role: "user",
          parts: [{ text: prompt }],
        },
      ],

      // 시스템 프롬프트 (사주 전문가 역할)
      // @see prompts.ts의 AI_SUMMARY_SYSTEM_PROMPT
      systemInstruction: {
        parts: [{ text: AI_SUMMARY_SYSTEM_PROMPT }],
      },

      // 생성 설정
      generationConfig: {
        temperature: 0.7,        // 창의성 (0=보수적, 1=창의적)
        maxOutputTokens: 1024,   // 최대 출력 토큰
        topP: 0.9,               // 확률 기반 샘플링
        topK: 40,                // 상위 K개 토큰 고려
        responseMimeType: "application/json",  // JSON 형식 강제
      },

      // 안전 설정 (사주는 민감한 내용 없으므로 관대하게)
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
      ],
    }),
  });

  const data = await response.json();

  // ─────────────────────────────────────────────────────────────────────────
  // 에러 처리
  // ─────────────────────────────────────────────────────────────────────────

  // API 에러 (인증 실패, 할당량 초과 등)
  if (data.error) {
    console.error("[generate-ai-summary] Gemini API Error:", data.error);
    throw new Error(data.error.message || "Gemini API error");
  }

  // 응답 없음
  if (!data.candidates || data.candidates.length === 0) {
    throw new Error("No response generated from Gemini");
  }

  const candidate = data.candidates[0];

  // 안전 필터에 의해 차단됨
  if (candidate.finishReason === "SAFETY") {
    throw new Error("Response blocked due to safety settings");
  }

  // 응답 텍스트 추출
  const rawText = candidate.content?.parts?.[0]?.text || "";

  // 토큰 사용량 로깅 (비용 추적용)
  const usage = data.usageMetadata || {};
  console.log(
    `[generate-ai-summary] Tokens: prompt=${usage.promptTokenCount || 0}, completion=${usage.candidatesTokenCount || 0}`
  );

  // ─────────────────────────────────────────────────────────────────────────
  // JSON 파싱
  // ─────────────────────────────────────────────────────────────────────────
  try {
    const parsed = JSON.parse(rawText);
    return parsed as AiSummary;
  } catch (parseError) {
    // JSON 파싱 실패 시 디버그 정보 출력
    console.error("[generate-ai-summary] JSON parse error:", parseError);
    console.error("[generate-ai-summary] Raw text:", rawText);
    throw new Error("Failed to parse AI response as JSON");
  }
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
    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is not set. Run: npx supabase secrets set GEMINI_API_KEY=your_key");
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

    // Gemini로 AI 요약 생성
    let aiSummary: AiSummary;
    try {
      aiSummary = await generateWithGemini(analysisPrompt);

      // 메타 정보 추가
      aiSummary.generated_at = new Date().toISOString();
      aiSummary.model = GEMINI_MODEL;
      aiSummary.version = "1.0";
    } catch (geminiError) {
      // Gemini 실패 시 fallback 사용
      console.error("[generate-ai-summary] Gemini 실패, fallback 사용:", geminiError);
      aiSummary = createFallbackSummary(saju_analysis);
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
