export type CalendarType = "solar" | "lunar";
export type GenderType = "male" | "female";

type ElementInfo = {
  elementName: string;
  elementNameEn: string;
  colorName: string;
  colorEmoji: string;
  colorClass: string;
  eumYang: string;
  modifier: string;
};

type AnimalInfo = {
  personaId: string;
  animalName: string;
  animalEmoji: string;
  title: string;
  tone: string;
  summary: string;
  keywords: string[];
  advice: string;
};

export type ZodiacIdentityLite = ElementInfo &
  AnimalInfo & {
    cheongan: string;
    jiji: string;
    ganji: string;
    ganjiHanja: string;
    fullName: string;
    displayName: string;
    combinedEmoji: string;
    calculationMode: "day-pillar-lite" | "birth-year-cycle";
  };

export type SadamProfileInput = {
  name: string;
  birthDate: string;
  calendar: CalendarType;
  birthTime: string;
  birthTimeUnknown: boolean;
  gender: GenderType;
  focus: string;
};

const cheongan = ["갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"];
const jiji = ["자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해"];
const birthYearCheongan = ["경", "신", "임", "계", "갑", "을", "병", "정", "무", "기"];

const cheonganHanja: Record<string, string> = {
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

const jijiHanja: Record<string, string> = {
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

const elementByCheongan: Record<string, ElementInfo> = {
  갑: {
    elementName: "목",
    elementNameEn: "Wood",
    colorName: "푸른",
    colorEmoji: "🟢",
    colorClass: "bg-emerald-600",
    eumYang: "양",
    modifier: "성장, 시작, 확장 에너지가 강합니다.",
  },
  을: {
    elementName: "목",
    elementNameEn: "Wood",
    colorName: "푸른",
    colorEmoji: "🟢",
    colorClass: "bg-emerald-500",
    eumYang: "음",
    modifier: "섬세하게 자라고 연결하는 힘이 강합니다.",
  },
  병: {
    elementName: "화",
    elementNameEn: "Fire",
    colorName: "붉은",
    colorEmoji: "🔴",
    colorClass: "bg-red-600",
    eumYang: "양",
    modifier: "표현, 열정, 추진 에너지가 강합니다.",
  },
  정: {
    elementName: "화",
    elementNameEn: "Fire",
    colorName: "붉은",
    colorEmoji: "🔴",
    colorClass: "bg-rose-600",
    eumYang: "음",
    modifier: "따뜻하게 비추고 오래 살피는 힘이 강합니다.",
  },
  무: {
    elementName: "토",
    elementNameEn: "Earth",
    colorName: "황금",
    colorEmoji: "🟡",
    colorClass: "bg-amber-600",
    eumYang: "양",
    modifier: "중심을 잡고 현실을 버티는 힘이 강합니다.",
  },
  기: {
    elementName: "토",
    elementNameEn: "Earth",
    colorName: "황금",
    colorEmoji: "🟡",
    colorClass: "bg-yellow-600",
    eumYang: "음",
    modifier: "흩어진 것을 품고 조율하는 힘이 강합니다.",
  },
  경: {
    elementName: "금",
    elementNameEn: "Metal",
    colorName: "흰",
    colorEmoji: "⚪",
    colorClass: "bg-slate-600",
    eumYang: "양",
    modifier: "판단, 결단, 기준을 세우는 힘이 강합니다.",
  },
  신: {
    elementName: "금",
    elementNameEn: "Metal",
    colorName: "흰",
    colorEmoji: "⚪",
    colorClass: "bg-zinc-600",
    eumYang: "음",
    modifier: "정교함, 감각, 완성도를 높이는 힘이 강합니다.",
  },
  임: {
    elementName: "수",
    elementNameEn: "Water",
    colorName: "검은",
    colorEmoji: "⚫",
    colorClass: "bg-slate-900",
    eumYang: "양",
    modifier: "깊은 사고와 큰 흐름을 읽는 힘이 강합니다.",
  },
  계: {
    elementName: "수",
    elementNameEn: "Water",
    colorName: "검은",
    colorEmoji: "⚫",
    colorClass: "bg-cyan-900",
    eumYang: "음",
    modifier: "직감, 유연함, 숨은 맥락을 보는 힘이 강합니다.",
  },
};

const animalByJiji: Record<string, AnimalInfo> = {
  자: {
    personaId: "zodiac_rat",
    animalName: "쥐",
    animalEmoji: "🐭",
    title: "빠른 감각의 전략가",
    tone: "정보를 빨리 읽고 기회를 놓치지 않는 타입",
    summary: "새로운 흐름을 먼저 보고, 복잡한 상황에서도 실리를 찾습니다.",
    keywords: ["관찰력", "속도", "기회"],
    advice: "오늘은 먼저 움직이기보다 판을 읽고 한 번에 결정하는 쪽이 좋습니다.",
  },
  축: {
    personaId: "zodiac_ox",
    animalName: "소",
    animalEmoji: "🐮",
    title: "꾸준히 쌓는 완성형",
    tone: "느려 보여도 끝까지 밀어붙이는 타입",
    summary: "신뢰와 반복으로 성과를 만드는 힘이 강합니다.",
    keywords: ["지속력", "책임감", "안정"],
    advice: "오늘은 해야 할 일을 작게 나누면 성취감이 빠르게 올라옵니다.",
  },
  인: {
    personaId: "zodiac_tiger",
    animalName: "호랑이",
    animalEmoji: "🐯",
    title: "대담한 개척자",
    tone: "막힌 길보다 새 길을 찾는 타입",
    summary: "결정이 빠르고, 분위기를 바꾸는 추진력이 있습니다.",
    keywords: ["용기", "리더십", "돌파"],
    advice: "오늘은 말보다 행동으로 신뢰를 보여주는 편이 유리합니다.",
  },
  묘: {
    personaId: "zodiac_rabbit",
    animalName: "토끼",
    animalEmoji: "🐰",
    title: "섬세한 조율가",
    tone: "관계의 온도와 타이밍을 잘 읽는 타입",
    summary: "부드럽게 설득하고, 갈등을 크게 만들지 않는 장점이 있습니다.",
    keywords: ["공감", "균형", "감각"],
    advice: "오늘은 무리하게 맞추기보다 내 기준을 한 문장으로 정리하세요.",
  },
  진: {
    personaId: "zodiac_dragon",
    animalName: "용",
    animalEmoji: "🐲",
    title: "크게 그리는 설계자",
    tone: "작은 일도 큰 방향 안에서 보는 타입",
    summary: "상상력과 자신감으로 사람들의 기대를 모읍니다.",
    keywords: ["비전", "확장", "자신감"],
    advice: "오늘은 목표를 크게 잡되, 첫 실행 단계를 아주 작게 시작하세요.",
  },
  사: {
    personaId: "zodiac_snake",
    animalName: "뱀",
    animalEmoji: "🐍",
    title: "깊게 보는 분석가",
    tone: "표면보다 숨은 맥락을 읽는 타입",
    summary: "말은 적어도 판단은 날카롭고, 선택의 질이 높습니다.",
    keywords: ["통찰", "집중", "선택"],
    advice: "오늘은 모든 걸 설명하려 하지 말고 핵심 근거만 남기세요.",
  },
  오: {
    personaId: "zodiac_horse",
    animalName: "말",
    animalEmoji: "🐴",
    title: "흐름을 만드는 활동가",
    tone: "멈춰 있으면 에너지가 떨어지는 타입",
    summary: "움직이면서 생각이 정리되고, 사람을 끌어당기는 활력이 있습니다.",
    keywords: ["활력", "자유", "속도"],
    advice: "오늘은 답답한 일을 오래 붙잡기보다 장소나 리듬을 바꿔보세요.",
  },
  미: {
    personaId: "zodiac_sheep",
    animalName: "양",
    animalEmoji: "🐑",
    title: "분위기를 다듬는 크리에이터",
    tone: "디테일과 감성을 놓치지 않는 타입",
    summary: "사람과 공간의 결을 살피며 더 나은 형태로 다듬습니다.",
    keywords: ["감성", "배려", "창의"],
    advice: "오늘은 결과보다 과정의 질을 높이면 좋은 반응이 따라옵니다.",
  },
  신: {
    personaId: "zodiac_monkey",
    animalName: "원숭이",
    animalEmoji: "🐵",
    title: "문제를 푸는 실험가",
    tone: "답이 없을수록 재밌어지는 타입",
    summary: "아이디어가 빠르고, 여러 방법을 시험하며 길을 찾습니다.",
    keywords: ["재치", "실험", "응용"],
    advice: "오늘은 완벽한 답보다 빠른 실험 하나가 더 큰 힌트를 줍니다.",
  },
  유: {
    personaId: "zodiac_rooster",
    animalName: "닭",
    animalEmoji: "🐔",
    title: "기준이 선명한 정리자",
    tone: "흐릿한 것을 명확하게 만드는 타입",
    summary: "기준과 디테일을 세워 일이 흩어지지 않게 만듭니다.",
    keywords: ["정확성", "정돈", "표현"],
    advice: "오늘은 기준을 낮추기보다 우선순위를 줄이는 쪽이 좋습니다.",
  },
  술: {
    personaId: "zodiac_dog",
    animalName: "개",
    animalEmoji: "🐶",
    title: "믿음을 지키는 보호자",
    tone: "관계와 원칙을 쉽게 포기하지 않는 타입",
    summary: "책임감이 강하고, 중요한 사람에게 안정감을 줍니다.",
    keywords: ["신뢰", "원칙", "보호"],
    advice: "오늘은 모든 책임을 혼자 들지 말고 역할을 나누세요.",
  },
  해: {
    personaId: "zodiac_pig",
    animalName: "돼지",
    animalEmoji: "🐷",
    title: "여유를 만드는 현실가",
    tone: "편안함 속에서 실속을 챙기는 타입",
    summary: "사람을 편하게 만들고, 복잡한 일을 현실적으로 풀어냅니다.",
    keywords: ["여유", "실속", "친화"],
    advice: "오늘은 급하게 증명하려 하지 않아도 충분히 설득력이 있습니다.",
  },
};

function normalizeCycle(index: number, length: number) {
  return ((index % length) + length) % length;
}

export function parseBirthDate(text: string) {
  const digits = text.replace(/\D/g, "");
  if (digits.length !== 8) return null;

  const year = Number(digits.slice(0, 4));
  const month = Number(digits.slice(4, 6));
  const day = Number(digits.slice(6, 8));
  const date = new Date(year, month - 1, day);

  if (
    date.getFullYear() !== year ||
    date.getMonth() !== month - 1 ||
    date.getDate() !== day
  ) {
    return null;
  }

  return { year, month, day, compact: digits };
}

export function resolveIdentityFromBirthDate(
  birthDate: string,
): ZodiacIdentityLite {
  const parsed = parseBirthDate(birthDate) ?? parseBirthDate("19950101")!;
  const baseDate = new Date(1900, 0, 1);
  const targetDate = new Date(parsed.year, parsed.month - 1, parsed.day);
  const daysDiff = Math.floor(
    (targetDate.getTime() - baseDate.getTime()) / 86_400_000,
  );
  const dayIndex = normalizeCycle(10 + daysDiff, 60);
  const gan = cheongan[dayIndex % 10];
  const ji = jiji[dayIndex % 12];
  const element = elementByCheongan[gan];
  const animal = animalByJiji[ji];
  const ganji = `${gan}${ji}`;
  const ganjiHanja = `${cheonganHanja[gan]}${jijiHanja[ji]}`;
  const fullName = `${element.colorName} ${animal.animalName}`;

  return {
    ...element,
    ...animal,
    cheongan: gan,
    jiji: ji,
    ganji,
    ganjiHanja,
    fullName,
    displayName: `${fullName} (${ganjiHanja})`,
    combinedEmoji: `${element.colorEmoji}${animal.animalEmoji}`,
    calculationMode: "birth-year-cycle",
  };
}

export function resolveIdentityFromBirthYear(year: number): ZodiacIdentityLite {
  const gan = birthYearCheongan[normalizeCycle(year - 2020, 10)];
  const ji = jiji[normalizeCycle(year - 2020, 12)];
  const element = elementByCheongan[gan];
  const animal = animalByJiji[ji];
  const ganji = `${gan}${ji}`;
  const ganjiHanja = `${cheonganHanja[gan]}${jijiHanja[ji]}`;
  const fullName = `${element.colorName} ${animal.animalName}`;

  return {
    ...element,
    ...animal,
    cheongan: gan,
    jiji: ji,
    ganji,
    ganjiHanja,
    fullName,
    displayName: `${fullName} (${ganjiHanja})`,
    combinedEmoji: `${element.colorEmoji}${animal.animalEmoji}`,
    calculationMode: "day-pillar-lite",
  };
}

export function buildResultParams(input: SadamProfileInput) {
  const params = new URLSearchParams();
  params.set("name", input.name.trim());
  params.set("birthDate", input.birthDate.trim());
  params.set("calendar", input.calendar);
  params.set("birthTime", input.birthTime.trim());
  params.set("birthTimeUnknown", String(input.birthTimeUnknown));
  params.set("gender", input.gender);
  params.set("focus", input.focus.trim());
  return params.toString();
}
