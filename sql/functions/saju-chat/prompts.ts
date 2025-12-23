/**
 * 사주 AI 챗봇 프롬프트 및 컨텍스트 빌더
 */

export const SYSTEM_PROMPT = `당신은 '만톡'의 AI 사주 상담사입니다.
사용자의 사주(만세력) 데이터를 바탕으로 운세, 성격, 관계(궁합)를 분석해주는 전문가입니다.

## 역할 및 페르소나
- 친근하고 공감 능력이 뛰어난 사주 상담사입니다.
- 전문적인 사주 용어(오행, 십신, 12운성 등)를 사용하되, 일반인이 이해하기 쉽게 풀어서 설명합니다.
- 단정적인 어조보다는 조언과 가이드 형태로 답변합니다.
- 사용자의 고민을 경청하고, 사주적 관점에서 해결책을 제시합니다.

## 사주 용어 해설
### 천간(天干) - 하늘의 기운
- 갑(甲), 을(乙): 목(木) - 성장, 시작, 창의성
- 병(丙), 정(丁): 화(火) - 열정, 표현, 에너지
- 무(戊), 기(己): 토(土) - 안정, 중재, 신뢰
- 경(庚), 신(辛): 금(金) - 결단, 정의, 변화
- 임(壬), 계(癸): 수(水) - 지혜, 유연함, 소통

### 지지(地支) - 땅의 기운
- 자(子), 해(亥): 수(水)
- 인(寅), 묘(卯): 목(木)
- 사(巳), 오(午): 화(火)
- 신(申), 유(酉): 금(金)
- 진(辰), 술(戌), 축(丑), 미(未): 토(土)

### 십신(十神) - 일간과의 관계
- 비겁(比劫): 비견, 겁재 - 자아, 경쟁
- 식상(食傷): 식신, 상관 - 표현, 재능
- 재성(財星): 편재, 정재 - 재물, 현실
- 관성(官星): 편관, 정관 - 명예, 직장
- 인성(印星): 편인, 정인 - 학문, 지원

## 분석 가이드라인

### 1. 개인 분석
- 일주(Day Pillar)를 중심으로 성향을 분석합니다.
- 오행의 균형/불균형을 통해 강점과 보완점을 찾습니다.
- 용신(用神)을 활용한 개운법을 제시합니다.
- 현재 대운(大運)의 흐름을 고려하여 조언합니다.

### 2. 궁합 분석 (상대방 정보가 있는 경우)
- 두 사람의 일간(日干) 관계: 생(生)/극(剋)/합(合)/충(沖)
- 서로의 용신이 상대에게 어떤 영향을 주는지
- 관계 유형별 조언:
  - 연인/부부: 애정운, 결혼 적합성
  - 친구/동료: 협력, 갈등 요소
  - 가족: 유대감, 소통 방법

## 응답 스타일
- 간결하지만 핵심을 담아 답변합니다.
- 질문에 직접적으로 답하고, 필요시 추가 설명을 덧붙입니다.
- 이모지를 적절히 사용해 친근한 분위기를 만듭니다.
- "~입니다", "~하세요" 등 정중하지만 따뜻한 어투를 사용합니다.

## 주의사항
- "죽을 운명", "망한다" 등 부정적이고 단정적인 표현은 절대 삼가합니다.
- 사주는 경향성일 뿐, 노력으로 바꿀 수 있음을 강조합니다.
- 의학적, 법률적, 투자 관련 조언은 하지 않습니다.
- 구체적인 날짜를 예언하지 않습니다.`;

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
 * 사주 컨텍스트 구축 파라미터
 */
interface SajuContextParams {
  profileName?: string;
  birthDate?: string;
  sajuAnalysis?: {
    saju: {
      year: { gan: string; ji: string; ganHanja?: string; jiHanja?: string };
      month: { gan: string; ji: string; ganHanja?: string; jiHanja?: string };
      day: { gan: string; ji: string; ganHanja?: string; jiHanja?: string };
      hour: { gan: string; ji: string; ganHanja?: string; jiHanja?: string };
    };
    oheng: {
      wood: number;
      fire: number;
      earth: number;
      metal: number;
      water: number;
    };
    yongsin?: {
      yongsin: string;
      huisin: string;
      gisin: string;
      gusin: string;
    };
    sipsin?: Record<string, string>;
    sibiunseong?: Record<string, string>;
    daeun?: Array<{ age: number; gan: string; ji: string }>;
    currentDaeun?: { age: number; gan: string; ji: string };
  };
  chatType?: string;
  targetProfile?: {
    name: string;
    birthDate: string;
    sajuAnalysis: SajuContextParams["sajuAnalysis"];
    relationType?: string;
  };
  contextSummary?: string;
}

/**
 * 사주 분석 데이터를 AI가 이해하기 쉬운 텍스트로 변환
 */
export function buildSajuContext(params: SajuContextParams): string {
  const {
    profileName,
    birthDate,
    sajuAnalysis,
    chatType,
    targetProfile,
    contextSummary,
  } = params;

  const lines: string[] = [];

  // 기본 정보
  if (profileName) {
    lines.push(`## 상담자: ${profileName}`);
  }
  if (birthDate) {
    lines.push(`- 생년월일: ${birthDate}`);
  }

  // 사주 분석 데이터
  if (sajuAnalysis) {
    lines.push("");
    lines.push("## 사주 원국 (四柱)");

    const { saju, oheng, yongsin, sipsin, sibiunseong, currentDaeun } =
      sajuAnalysis;

    // 사주 팔자
    if (saju) {
      const formatPillar = (pillar: {
        gan: string;
        ji: string;
        ganHanja?: string;
        jiHanja?: string;
      }) => {
        const ganStr = pillar.ganHanja
          ? `${pillar.gan}(${pillar.ganHanja})`
          : pillar.gan;
        const jiStr = pillar.jiHanja
          ? `${pillar.ji}(${pillar.jiHanja})`
          : pillar.ji;
        return `${ganStr}${jiStr}`;
      };

      lines.push(
        `- 년주: ${formatPillar(saju.year)} | 월주: ${formatPillar(saju.month)} | 일주: ${formatPillar(saju.day)} | 시주: ${formatPillar(saju.hour)}`
      );
      lines.push(`- 일간(日干): ${saju.day.gan} - 이 분의 본질적 성향`);
    }

    // 오행 분포
    if (oheng) {
      lines.push("");
      lines.push("## 오행 분포");
      const ohengList = Object.entries(oheng)
        .map(([key, val]) => `${OHENG_NAMES[key] || key}: ${val}개`)
        .join(", ");
      lines.push(`- ${ohengList}`);

      // 오행 분석 코멘트
      const dominant = Object.entries(oheng).sort((a, b) => b[1] - a[1])[0];
      const lacking = Object.entries(oheng).filter(([_, v]) => v === 0);

      if (dominant[1] >= 3) {
        lines.push(`- 강한 기운: ${OHENG_NAMES[dominant[0]]} (${dominant[1]}개)`);
      }
      if (lacking.length > 0) {
        lines.push(
          `- 부족한 기운: ${lacking.map(([k]) => OHENG_NAMES[k]).join(", ")}`
        );
      }
    }

    // 용신
    if (yongsin) {
      lines.push("");
      lines.push("## 용신 (用神)");
      lines.push(`- 용신: ${yongsin.yongsin} (가장 필요한 기운)`);
      lines.push(`- 희신: ${yongsin.huisin} (도움이 되는 기운)`);
      lines.push(`- 기신: ${yongsin.gisin} (조심해야 할 기운)`);
      lines.push(`- 구신: ${yongsin.gusin} (피해야 할 기운)`);
    }

    // 십신
    if (sipsin && Object.keys(sipsin).length > 0) {
      lines.push("");
      lines.push("## 십신 (十神) 배치");
      const sipsinStr = Object.entries(sipsin)
        .map(([pos, val]) => `${pos}: ${val}`)
        .join(", ");
      lines.push(`- ${sipsinStr}`);
    }

    // 12운성
    if (sibiunseong && Object.keys(sibiunseong).length > 0) {
      lines.push("");
      lines.push("## 12운성 (十二運星)");
      const unseongStr = Object.entries(sibiunseong)
        .map(([pos, val]) => `${pos}: ${val}`)
        .join(", ");
      lines.push(`- ${unseongStr}`);
    }

    // 현재 대운
    if (currentDaeun) {
      lines.push("");
      lines.push("## 현재 대운 (大運)");
      lines.push(
        `- ${currentDaeun.age}세부터: ${currentDaeun.gan}${currentDaeun.ji}`
      );
    }
  }

  // 궁합 분석 (상대방 정보)
  if (targetProfile) {
    lines.push("");
    lines.push("---");
    lines.push(`## 상대방: ${targetProfile.name}`);
    if (targetProfile.relationType) {
      lines.push(`- 관계: ${targetProfile.relationType}`);
    }
    if (targetProfile.birthDate) {
      lines.push(`- 생년월일: ${targetProfile.birthDate}`);
    }

    if (targetProfile.sajuAnalysis?.saju) {
      const targetSaju = targetProfile.sajuAnalysis.saju;
      const formatPillar = (pillar: { gan: string; ji: string }) =>
        `${pillar.gan}${pillar.ji}`;
      lines.push(
        `- 사주: ${formatPillar(targetSaju.year)} ${formatPillar(targetSaju.month)} ${formatPillar(targetSaju.day)} ${formatPillar(targetSaju.hour)}`
      );
      lines.push(`- 일간: ${targetSaju.day.gan}`);
    }

    if (targetProfile.sajuAnalysis?.yongsin) {
      lines.push(`- 용신: ${targetProfile.sajuAnalysis.yongsin.yongsin}`);
    }
  }

  // 채팅 유형
  if (chatType && chatType !== "general") {
    lines.push("");
    lines.push(`## 상담 유형: ${getChatTypeName(chatType)}`);
  }

  // 이전 대화 요약
  if (contextSummary) {
    lines.push("");
    lines.push("## 이전 대화 요약");
    lines.push(contextSummary);
  }

  return lines.join("\n");
}

/**
 * 채팅 유형 이름 변환
 */
function getChatTypeName(chatType: string): string {
  const typeNames: Record<string, string> = {
    general: "일반 상담",
    compatibility: "궁합 분석",
    yearly: "올해 운세",
    monthly: "이번 달 운세",
    career: "직업/진로 상담",
    love: "연애/결혼 상담",
    health: "건강 운세",
    wealth: "재물 운세",
  };
  return typeNames[chatType] || chatType;
}
