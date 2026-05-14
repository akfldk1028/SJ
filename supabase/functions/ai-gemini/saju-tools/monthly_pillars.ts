/**
 * 월주(月柱) 계산 도구 — 오호둔법 기반
 *
 * 입력: 사주년 (절기 기준 입춘 후의 년도)
 * 출력: 12개월 전체 간지(천간/지지) + 오행 + 절기 시작일
 *
 * ## 알고리즘
 * - 년간 = (year - 4) % 10
 * - 오호둔: 갑/기→丙寅, 을/경→戊寅, 병/신→庚寅, 정/임→壬寅, 무/계→甲寅
 * - 12개월 천간: 인월부터 +1씩 순환 (mod 10)
 * - 12개월 지지: 寅 卯 辰 巳 午 未 申 酉 戌 亥 子 丑 (고정)
 *
 * ## 검증
 * 2026 = 병오년 → 인월 시작 庚寅 → 4월(사월) = 癸巳 ✓
 * 2025 = 을사년 → 인월 시작 戊寅 → 1월(인월) = 戊寅, 5월(사월) = 辛巳 ✓
 */

const STEMS_KO = ["갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"];
const STEMS_HJ = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];
const STEM_ELEMENTS = ["목", "목", "화", "화", "토", "토", "금", "금", "수", "수"];

const BRANCHES_KO = ["인", "묘", "진", "사", "오", "미", "신", "유", "술", "해", "자", "축"];
const BRANCHES_HJ = ["寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥", "子", "丑"];
const BRANCH_ELEMENTS = ["목", "목", "토", "화", "화", "토", "금", "금", "토", "수", "수", "토"];

// 오호둔: 년간 index → 인월 첫 천간 index
// 갑(0)/기(5)→병(2), 을(1)/경(6)→무(4), 병(2)/신(7)→경(6), 정(3)/임(8)→임(8), 무(4)/계(9)→갑(0)
const OH_HO_DUN = [2, 4, 6, 8, 0, 2, 4, 6, 8, 0];

// 절기 시작일 (대략, ±1일 오차)
const SOLAR_TERMS = [
  { name: "입춘", monthDay: "2/4" },   // 인월
  { name: "경칩", monthDay: "3/6" },   // 묘월
  { name: "청명", monthDay: "4/5" },   // 진월
  { name: "입하", monthDay: "5/5" },   // 사월
  { name: "망종", monthDay: "6/6" },   // 오월
  { name: "소서", monthDay: "7/7" },   // 미월
  { name: "입추", monthDay: "8/8" },   // 신월
  { name: "백로", monthDay: "9/8" },   // 유월
  { name: "한로", monthDay: "10/8" },  // 술월
  { name: "입동", monthDay: "11/7" },  // 해월
  { name: "대설", monthDay: "12/7" },  // 자월
  { name: "소한", monthDay: "1/6" },   // 축월 (다음 양력년)
];

interface MonthlyPillar {
  saju_month: number;          // 1=인월 ~ 12=축월
  pillar_ko: string;           // 한글 간지 (예: "계사")
  pillar_hj: string;           // 한자 간지 (예: "癸巳")
  stem_ko: string;             // 한글 천간
  stem_hj: string;             // 한자 천간
  stem_element: string;        // 천간 오행
  branch_ko: string;           // 한글 지지
  branch_hj: string;           // 한자 지지
  branch_element: string;      // 지지 오행
  solar_term: string;          // 절기 이름
  solar_term_date: string;     // 절기 시작일 (M/D 양력 근사)
}

interface MonthlyPillarsResult {
  saju_year: number;
  year_stem_ko: string;
  year_stem_hj: string;
  first_month_pillar: string;  // 인월 간지 (예: "庚寅")
  pillars: MonthlyPillar[];    // 12개월 전체
  note: string;
}

/**
 * 12개월 월주 계산
 * @param sajuYear 사주년 (입춘 후 기준, 예: 2026)
 */
export function calculateMonthlyPillars(sajuYear: number): MonthlyPillarsResult {
  if (!Number.isInteger(sajuYear) || sajuYear < 1900 || sajuYear > 2100) {
    return {
      saju_year: sajuYear,
      year_stem_ko: "",
      year_stem_hj: "",
      first_month_pillar: "",
      pillars: [],
      note: `잘못된 년도: ${sajuYear} (1900~2100 범위만 지원)`,
    };
  }

  const yearStemIdx = ((sajuYear - 4) % 10 + 10) % 10;
  const firstStemIdx = OH_HO_DUN[yearStemIdx];

  const pillars: MonthlyPillar[] = [];
  for (let i = 0; i < 12; i++) {
    const stemIdx = (firstStemIdx + i) % 10;
    const term = SOLAR_TERMS[i];
    pillars.push({
      saju_month: i + 1,
      pillar_ko: STEMS_KO[stemIdx] + BRANCHES_KO[i],
      pillar_hj: STEMS_HJ[stemIdx] + BRANCHES_HJ[i],
      stem_ko: STEMS_KO[stemIdx],
      stem_hj: STEMS_HJ[stemIdx],
      stem_element: STEM_ELEMENTS[stemIdx],
      branch_ko: BRANCHES_KO[i],
      branch_hj: BRANCHES_HJ[i],
      branch_element: BRANCH_ELEMENTS[i],
      solar_term: term.name,
      solar_term_date: term.monthDay,
    });
  }

  return {
    saju_year: sajuYear,
    year_stem_ko: STEMS_KO[yearStemIdx],
    year_stem_hj: STEMS_HJ[yearStemIdx],
    first_month_pillar: pillars[0].pillar_hj,
    pillars,
    note: "절기 시작일은 ±1일 오차 가능. 정밀 계산 필요 시 만세력 참조.",
  };
}
