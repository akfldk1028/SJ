/**
 * AI Summary 생성 프롬프트 및 유틸리티
 */

/**
 * AI Summary 생성용 시스템 프롬프트
 */
export const AI_SUMMARY_SYSTEM_PROMPT = `당신은 사주(四柱) 분석 전문가입니다.
주어진 사주 데이터를 분석하여 JSON 형식의 요약을 생성합니다.

## 역할
- 사주 원국, 오행 분포, 용신, 십신, 12운성 데이터를 종합 분석
- 성격, 강점, 약점, 진로, 관계, 개운법을 도출
- 한국어로 자연스럽고 긍정적인 표현 사용

## 분석 원칙
1. 일간(日干)을 중심으로 성격 분석
2. 오행 균형/불균형에서 강점과 보완점 도출
3. 용신을 활용한 개운법 제시
4. 십신 배치로 사회적 성향 파악
5. 12운성으로 인생 에너지 흐름 파악

## 주의사항
- 부정적/단정적 표현 절대 금지
- "~경향이 있습니다", "~할 수 있습니다" 등 유연한 표현 사용
- 모든 특성은 장점으로 재해석 가능
- 3글자 이내 키워드는 명확하게

## 출력 형식
반드시 아래 JSON 구조만 출력하세요. 다른 텍스트 없이 JSON만:

{
  "personality": {
    "core": "일간 기반 핵심 성격 설명 (50자 이내)",
    "traits": ["특성1", "특성2", "특성3"]
  },
  "strengths": ["강점1", "강점2", "강점3"],
  "weaknesses": ["보완점1", "보완점2"],
  "career": {
    "aptitude": ["적합 분야1", "적합 분야2", "적합 분야3"],
    "advice": "진로 조언 (50자 이내)"
  },
  "relationships": {
    "style": "대인관계 스타일 설명 (40자 이내)",
    "tips": "관계 조언 (40자 이내)"
  },
  "fortune_tips": {
    "colors": ["행운색1", "행운색2"],
    "directions": ["방위1"],
    "activities": ["개운 활동1", "개운 활동2"]
  }
}`;

/**
 * 오행(五行) 이름 변환
 */
const OHENG_NAMES: Record<string, string> = {
  wood: "목(木)",
  fire: "화(火)",
  earth: "토(土)",
  metal: "금(金)",
  water: "수(水)",
};

/**
 * 일간(日干) 성격 기본 정보
 */
const ILGAN_INFO: Record<string, { element: string; yin: boolean; desc: string }> = {
  "갑": { element: "wood", yin: false, desc: "큰 나무 - 곧고 정직하며 리더십이 강함" },
  "을": { element: "wood", yin: true, desc: "풀과 덩굴 - 유연하고 적응력이 뛰어남" },
  "병": { element: "fire", yin: false, desc: "태양 - 밝고 열정적이며 표현력이 뛰어남" },
  "정": { element: "fire", yin: true, desc: "촛불 - 섬세하고 따뜻하며 배려심이 깊음" },
  "무": { element: "earth", yin: false, desc: "산 - 믿음직하고 안정적이며 포용력이 큼" },
  "기": { element: "earth", yin: true, desc: "농토 - 실용적이고 꼼꼼하며 현실적임" },
  "경": { element: "metal", yin: false, desc: "큰 쇠 - 결단력 있고 의리 있으며 강직함" },
  "신": { element: "metal", yin: true, desc: "보석 - 예리하고 섬세하며 완벽주의적" },
  "임": { element: "water", yin: false, desc: "큰 물 - 지혜롭고 포용력 있으며 진취적" },
  "계": { element: "water", yin: true, desc: "이슬 - 감수성이 풍부하고 직관력이 뛰어남" },
};

/**
 * 오행별 행운색/방위/활동
 */
const OHENG_FORTUNE: Record<string, { colors: string[]; directions: string[]; activities: string[] }> = {
  wood: { colors: ["초록", "청록"], directions: ["동쪽"], activities: ["등산", "원예", "독서"] },
  fire: { colors: ["빨강", "보라", "주황"], directions: ["남쪽"], activities: ["운동", "창작 활동", "발표"] },
  earth: { colors: ["노랑", "갈색", "베이지"], directions: ["중앙"], activities: ["명상", "요리", "정리정돈"] },
  metal: { colors: ["흰색", "금색", "은색"], directions: ["서쪽"], activities: ["음악 감상", "글쓰기", "수공예"] },
  water: { colors: ["검정", "남색", "파랑"], directions: ["북쪽"], activities: ["수영", "여행", "명상"] },
};

/**
 * 사주 분석 데이터 인터페이스
 */
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

interface YongsinData {
  yongsin: string;
  huisin: string;
  gisin: string;
  gusin: string;
}

export interface SajuAnalysisInput {
  saju: SajuData;
  oheng: OhengCount;
  yongsin?: YongsinData;
  sipsin?: Record<string, string>;
  sibiunseong?: Record<string, string>;
  singang_singak?: {
    is_singang: boolean;
    score: number;
    factors: {
      deukryeong: boolean;
      deukji: boolean;
      deuksi: boolean;
      deukse: boolean;
    };
  };
}

/**
 * 사주 분석 데이터를 AI가 분석할 수 있는 텍스트로 변환
 */
export function buildAnalysisPrompt(
  profileName: string,
  birthDate: string,
  analysis: SajuAnalysisInput
): string {
  const lines: string[] = [];

  lines.push(`## 분석 대상: ${profileName}`);
  lines.push(`- 생년월일시: ${birthDate}`);
  lines.push("");

  // 사주 원국
  const { saju, oheng, yongsin, sipsin, sibiunseong, singang_singak } = analysis;

  lines.push("## 사주 원국 (四柱)");
  const formatPillar = (pillar: SajuPillar) => {
    const ganStr = pillar.ganHanja ? `${pillar.gan}(${pillar.ganHanja})` : pillar.gan;
    const jiStr = pillar.jiHanja ? `${pillar.ji}(${pillar.jiHanja})` : pillar.ji;
    return `${ganStr}${jiStr}`;
  };

  lines.push(`년주: ${formatPillar(saju.year)}`);
  lines.push(`월주: ${formatPillar(saju.month)}`);
  lines.push(`일주: ${formatPillar(saju.day)} ← 일간(日干): ${saju.day.gan}`);
  lines.push(`시주: ${formatPillar(saju.hour)}`);

  // 일간 정보
  const ilgan = saju.day.gan;
  const ilganInfo = ILGAN_INFO[ilgan];
  if (ilganInfo) {
    lines.push("");
    lines.push(`## 일간 특성`);
    lines.push(`${ilgan}: ${ilganInfo.desc}`);
    lines.push(`오행: ${OHENG_NAMES[ilganInfo.element]}, ${ilganInfo.yin ? "음(陰)" : "양(陽)"}`);
  }

  // 오행 분포
  lines.push("");
  lines.push("## 오행 분포");
  Object.entries(oheng).forEach(([key, val]) => {
    const name = OHENG_NAMES[key] || key;
    const bar = "●".repeat(val) + "○".repeat(Math.max(0, 4 - val));
    lines.push(`${name}: ${bar} (${val}개)`);
  });

  // 오행 분석
  const dominant = Object.entries(oheng).sort((a, b) => b[1] - a[1])[0];
  const lacking = Object.entries(oheng).filter(([_, v]) => v === 0);

  if (dominant[1] >= 3) {
    lines.push(`→ 강한 기운: ${OHENG_NAMES[dominant[0]]}`);
  }
  if (lacking.length > 0) {
    lines.push(`→ 부족한 기운: ${lacking.map(([k]) => OHENG_NAMES[k]).join(", ")}`);
  }

  // 신강/신약
  if (singang_singak) {
    lines.push("");
    lines.push("## 신강/신약");
    lines.push(`판정: ${singang_singak.is_singang ? "신강(身强)" : "신약(身弱)"}`);
    lines.push(`점수: ${singang_singak.score}점`);
    const factors = singang_singak.factors;
    lines.push(`득령: ${factors.deukryeong ? "○" : "×"}, 득지: ${factors.deukji ? "○" : "×"}, 득시: ${factors.deuksi ? "○" : "×"}, 득세: ${factors.deukse ? "○" : "×"}`);
  }

  // 용신
  if (yongsin) {
    lines.push("");
    lines.push("## 용신 (用神)");
    lines.push(`용신: ${yongsin.yongsin} - 가장 필요한 기운`);
    lines.push(`희신: ${yongsin.huisin} - 도움이 되는 기운`);
    lines.push(`기신: ${yongsin.gisin} - 조심해야 할 기운`);
    lines.push(`구신: ${yongsin.gusin} - 피해야 할 기운`);
  }

  // 십신
  if (sipsin && Object.keys(sipsin).length > 0) {
    lines.push("");
    lines.push("## 십신 (十神) 배치");
    Object.entries(sipsin).forEach(([pos, val]) => {
      lines.push(`${pos}: ${val}`);
    });
  }

  // 12운성
  if (sibiunseong && Object.keys(sibiunseong).length > 0) {
    lines.push("");
    lines.push("## 12운성 (十二運星)");
    Object.entries(sibiunseong).forEach(([pos, val]) => {
      lines.push(`${pos}: ${val}`);
    });
  }

  lines.push("");
  lines.push("---");
  lines.push("위 데이터를 종합 분석하여 JSON 형식으로 요약을 생성하세요.");

  return lines.join("\n");
}

/**
 * 용신 오행에서 행운 정보 추출
 */
export function getFortuneFromYongsin(yongsinElement: string): {
  colors: string[];
  directions: string[];
  activities: string[];
} {
  // 용신 문자열에서 오행 추출 (예: "화(火)" → "fire")
  const elementMap: Record<string, string> = {
    "목": "wood", "木": "wood",
    "화": "fire", "火": "fire",
    "토": "earth", "土": "earth",
    "금": "metal", "金": "metal",
    "수": "water", "水": "water",
  };

  for (const [key, value] of Object.entries(elementMap)) {
    if (yongsinElement.includes(key)) {
      return OHENG_FORTUNE[value] || OHENG_FORTUNE.earth;
    }
  }

  return OHENG_FORTUNE.earth; // 기본값
}
