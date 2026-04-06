/**
 * 사주 검증 도구 모듈 — Gemini Function Calling용
 *
 * 6개 도구:
 * 1. verify_interaction — 지지 관계 (충/원진/해/합/형/파)
 * 2. get_spouse_star — 육친 배우자성 (일간×성별)
 * 3. verify_cheongan_hap — 천간합
 * 4. get_sipsin — 십성 계산
 * 5. get_gungwi — 궁위
 * 6. think — Sequential Thinking (단계별 추론)
 */

import { verifyInteraction } from "./interactions.ts";
import { getSpouseStar } from "./spouse.ts";
import { getSipsin } from "./sipsin.ts";
import { verifyCheonganHap } from "./cheongan.ts";
import { getGungwi } from "./gungwi.ts";

// ═══════════════════════════════════════════════════════════════
// Gemini tools 선언 (requestBody.tools에 추가)
// ═══════════════════════════════════════════════════════════════

export const sajuToolDeclarations = [
  {
    functionDeclarations: [
      {
        name: "verify_interaction",
        description: "두 지지(地支) 간 관계 확인. 충/원진/해/육합/삼합/방합/형/파 여부를 정확히 판별. 합/충/원진/해를 언급하기 전에 반드시 이 도구로 확인해야 함.",
        parameters: {
          type: "OBJECT",
          properties: {
            ji1: { type: "STRING", description: "첫째 지지 한글 1자 (자/축/인/묘/진/사/오/미/신/유/술/해)" },
            ji2: { type: "STRING", description: "둘째 지지 한글 1자" },
          },
          required: ["ji1", "ji2"],
        },
      },
      {
        name: "get_spouse_star",
        description: "일간과 성별로 배우자성(配偶星)을 정확히 조회. 남자=재성, 여자=관성. 배우자/결혼운을 언급할 때 반드시 확인.",
        parameters: {
          type: "OBJECT",
          properties: {
            ilgan: { type: "STRING", description: "일간 한글 1자 (갑/을/병/정/무/기/경/신/임/계)" },
            gender: { type: "STRING", enum: ["male", "female"], description: "성별" },
          },
          required: ["ilgan", "gender"],
        },
      },
      {
        name: "verify_cheongan_hap",
        description: "두 천간 간 천간합(天干合) 여부 확인. 5쌍만 존재.",
        parameters: {
          type: "OBJECT",
          properties: {
            gan1: { type: "STRING", description: "첫째 천간 한글 1자" },
            gan2: { type: "STRING", description: "둘째 천간 한글 1자" },
          },
          required: ["gan1", "gan2"],
        },
      },
      {
        name: "get_sipsin",
        description: "일간 기준 특정 천간/지지의 십성(十星)을 정확히 계산.",
        parameters: {
          type: "OBJECT",
          properties: {
            ilgan: { type: "STRING", description: "일간 한글 1자" },
            target: { type: "STRING", description: "확인할 천간 또는 지지 한글 1자" },
          },
          required: ["ilgan", "target"],
        },
      },
      {
        name: "get_gungwi",
        description: "주(柱) 위치의 궁위(宮位) 의미 조회. 어떤 주가 무엇을 대표하는지 확인.",
        parameters: {
          type: "OBJECT",
          properties: {
            pillar: { type: "STRING", enum: ["year", "month", "day_gan", "day_ji", "hour"], description: "주 위치" },
          },
          required: ["pillar"],
        },
      },
      {
        name: "think",
        description: `A detailed tool for dynamic and reflective problem-solving through thoughts.
This tool helps analyze problems through a flexible thinking process that can adapt and evolve.
Each thought can build on, question, or revise previous insights as understanding deepens.

When to use this tool:
- Breaking down complex problems into steps
- Planning and design with room for revision
- Analysis that might need course correction
- Problems where the full scope might not be clear initially
- Problems that require a multi-step solution
- Tasks that need to maintain context over multiple steps
- Situations where irrelevant information needs to be filtered out

Key features:
- You can adjust total_thoughts up or down as you progress
- You can question or revise previous thoughts
- You can add more thoughts even after reaching what seemed like the end
- You can express uncertainty and explore alternative approaches
- Not every thought needs to build linearly - you can branch or backtrack
- Generates a solution hypothesis
- Verifies the hypothesis based on the Chain of Thought steps
- Repeats the process until satisfied
- Provides a correct answer`,
        parameters: {
          type: "OBJECT",
          properties: {
            thought: { type: "STRING", description: "현재 추론 단계의 내용" },
            thoughtNumber: { type: "INTEGER", description: "현재 단계 번호 (1부터 시작)" },
            totalThoughts: { type: "INTEGER", description: "예상 총 단계 수 (진행하면서 조정 가능)" },
            nextThoughtNeeded: { type: "BOOLEAN", description: "추가 추론이 필요하면 true, 완료면 false" },
            isRevision: { type: "BOOLEAN", description: "이전 단계를 수정하는 경우 true" },
            revisesThought: { type: "INTEGER", description: "수정 대상 단계 번호" },
            branchFromThought: { type: "INTEGER", description: "분기 시작점 단계 번호" },
            branchId: { type: "STRING", description: "분기 식별자" },
          },
          required: ["thought", "thoughtNumber", "totalThoughts", "nextThoughtNeeded"],
        },
      },
    ],
  },
];

// ═══════════════════════════════════════════════════════════════
// 함수 실행 디스패처
// ═══════════════════════════════════════════════════════════════

// Sequential Thinking 상태 (공식 MCP 구현 기반)
interface ThoughtData {
  thought: string;
  thoughtNumber: number;
  totalThoughts: number;
  nextThoughtNeeded: boolean;
  isRevision?: boolean;
  revisesThought?: number;
  branchFromThought?: number;
  branchId?: string;
}

const thoughtHistory: ThoughtData[] = [];
const branches: Record<string, ThoughtData[]> = {};

function processThought(input: ThoughtData): Record<string, unknown> {
  // 공식 MCP 로직: totalThoughts 자동 조정
  if (input.thoughtNumber > input.totalThoughts) {
    input.totalThoughts = input.thoughtNumber;
  }

  thoughtHistory.push(input);

  // 분기 처리
  if (input.branchFromThought && input.branchId) {
    if (!branches[input.branchId]) {
      branches[input.branchId] = [];
    }
    branches[input.branchId].push(input);
  }

  console.log(`[saju-tools] think #${input.thoughtNumber}/${input.totalThoughts}${input.isRevision ? ' (revision)' : ''}${input.branchId ? ` [branch:${input.branchId}]` : ''}: ${input.thought.substring(0, 80)}...`);

  return {
    thoughtNumber: input.thoughtNumber,
    totalThoughts: input.totalThoughts,
    nextThoughtNeeded: input.nextThoughtNeeded,
    branches: Object.keys(branches),
    thoughtHistoryLength: thoughtHistory.length,
  };
}

export function executeSajuFunction(name: string, args: Record<string, unknown>): unknown {
  switch (name) {
    case "verify_interaction":
      return verifyInteraction(args.ji1 as string, args.ji2 as string);

    case "get_spouse_star":
      return getSpouseStar(args.ilgan as string, args.gender as string);

    case "verify_cheongan_hap":
      return verifyCheonganHap(args.gan1 as string, args.gan2 as string);

    case "get_sipsin":
      return getSipsin(args.ilgan as string, args.target as string);

    case "get_gungwi":
      return getGungwi(args.pillar as string);

    case "think":
      return processThought({
        thought: args.thought as string,
        thoughtNumber: args.thoughtNumber as number,
        totalThoughts: args.totalThoughts as number,
        nextThoughtNeeded: args.nextThoughtNeeded as boolean,
        isRevision: args.isRevision as boolean | undefined,
        revisesThought: args.revisesThought as number | undefined,
        branchFromThought: args.branchFromThought as number | undefined,
        branchId: args.branchId as string | undefined,
      });

    default:
      return { error: `알 수 없는 도구: ${name}` };
  }
}
