import { cheongan, jiji } from "../personas";

export type OhengKey = "wood" | "fire" | "earth" | "metal" | "water";
export type YinYang = "양" | "음";

export const cheonganHanja: Record<string, string> = {
  갑: "甲",
  을: "乙",
  병: "丙",
  정: "丁",
  무: "戊",
  기: "己",
  경: "庚",
  신: "辛",
  임: "壬",
  계: "癸",
};

export const jijiHanja: Record<string, string> = {
  자: "子",
  축: "丑",
  인: "寅",
  묘: "卯",
  진: "辰",
  사: "巳",
  오: "午",
  미: "未",
  신: "申",
  유: "酉",
  술: "戌",
  해: "亥",
};

export const ohengKorean: Record<OhengKey, string> = {
  wood: "목",
  fire: "화",
  earth: "토",
  metal: "금",
  water: "수",
};

export const ohengDbKeys: Record<OhengKey, string> = {
  wood: "목(木)",
  fire: "화(火)",
  earth: "토(土)",
  metal: "금(金)",
  water: "수(水)",
};

export const cheonganOheng: Record<string, OhengKey> = {
  갑: "wood",
  을: "wood",
  병: "fire",
  정: "fire",
  무: "earth",
  기: "earth",
  경: "metal",
  신: "metal",
  임: "water",
  계: "water",
};

export const cheonganYinYang: Record<string, YinYang> = {
  갑: "양",
  을: "음",
  병: "양",
  정: "음",
  무: "양",
  기: "음",
  경: "양",
  신: "음",
  임: "양",
  계: "음",
};

export const jijiOheng: Record<string, OhengKey> = {
  자: "water",
  축: "earth",
  인: "wood",
  묘: "wood",
  진: "earth",
  사: "fire",
  오: "fire",
  미: "earth",
  신: "metal",
  유: "metal",
  술: "earth",
  해: "water",
};

export const jijiYinYang: Record<string, YinYang> = {
  자: "양",
  축: "음",
  인: "양",
  묘: "음",
  진: "양",
  사: "음",
  오: "양",
  미: "음",
  신: "양",
  유: "음",
  술: "양",
  해: "음",
};

export const generating: Record<OhengKey, OhengKey> = {
  wood: "fire",
  fire: "earth",
  earth: "metal",
  metal: "water",
  water: "wood",
};

export const overcoming: Record<OhengKey, OhengKey> = {
  wood: "earth",
  earth: "water",
  water: "fire",
  fire: "metal",
  metal: "wood",
};

export const exhausting = generating;

export type HiddenStemType = "여기" | "중기" | "정기";

export type HiddenStem = {
  gan: string;
  type: HiddenStemType;
  strength: number;
};

export const hiddenStems: Record<string, HiddenStem[]> = {
  자: [
    { gan: "임", type: "여기", strength: 30 },
    { gan: "계", type: "정기", strength: 70 },
  ],
  축: [
    { gan: "계", type: "여기", strength: 30 },
    { gan: "신", type: "중기", strength: 20 },
    { gan: "기", type: "정기", strength: 50 },
  ],
  인: [
    { gan: "무", type: "여기", strength: 20 },
    { gan: "병", type: "중기", strength: 30 },
    { gan: "갑", type: "정기", strength: 50 },
  ],
  묘: [
    { gan: "갑", type: "여기", strength: 30 },
    { gan: "을", type: "정기", strength: 70 },
  ],
  진: [
    { gan: "을", type: "여기", strength: 30 },
    { gan: "계", type: "중기", strength: 20 },
    { gan: "무", type: "정기", strength: 50 },
  ],
  사: [
    { gan: "무", type: "여기", strength: 20 },
    { gan: "경", type: "중기", strength: 30 },
    { gan: "병", type: "정기", strength: 50 },
  ],
  오: [
    { gan: "병", type: "여기", strength: 30 },
    { gan: "기", type: "중기", strength: 20 },
    { gan: "정", type: "정기", strength: 50 },
  ],
  미: [
    { gan: "정", type: "여기", strength: 30 },
    { gan: "을", type: "중기", strength: 20 },
    { gan: "기", type: "정기", strength: 50 },
  ],
  신: [
    { gan: "무", type: "여기", strength: 20 },
    { gan: "임", type: "중기", strength: 30 },
    { gan: "경", type: "정기", strength: 50 },
  ],
  유: [
    { gan: "경", type: "여기", strength: 30 },
    { gan: "신", type: "정기", strength: 70 },
  ],
  술: [
    { gan: "신", type: "여기", strength: 30 },
    { gan: "정", type: "중기", strength: 20 },
    { gan: "무", type: "정기", strength: 50 },
  ],
  해: [
    { gan: "무", type: "여기", strength: 20 },
    { gan: "갑", type: "중기", strength: 30 },
    { gan: "임", type: "정기", strength: 50 },
  ],
};

export const jeongGiByJi = Object.fromEntries(
  jiji.map((ji) => [ji, hiddenStems[ji]?.find((stem) => stem.type === "정기")?.gan ?? ""]),
) as Record<string, string>;

export const zodiacAnimalByJi: Record<string, string> = {
  자: "rat",
  축: "ox",
  인: "tiger",
  묘: "rabbit",
  진: "dragon",
  사: "snake",
  오: "horse",
  미: "sheep",
  신: "monkey",
  유: "rooster",
  술: "dog",
  해: "pig",
};

export { cheongan, jiji };
