/**
 * 지장간(支藏干) 룩업 — 12지지의 본기/중기/여기
 * 본기가 가장 강하며, 격국·십성 판별의 핵심
 */

interface JijangganEntry {
  ji: string;
  hanja: string;
  bongi: string;      // 본기 (정기, 가장 강함)
  junggi: string;     // 중기
  yeogi: string;      // 여기 (가장 약함)
  bongi_oheng: string; // 본기 오행
}

// 표준 만세력 기준 (시간순: 절입 후 여기 → 중기 → 본기)
// 4정지지(자/묘/유)는 여기로 전월 본기를 표기 (한국 정통 명리)
// 4고지지(축/진/미/술)는 여기 9일 + 중기 3일 + 본기 18일
// 4생지지(인/사/신/해)는 여기 5~7일 + 중기 7~9일 + 본기 16일
// 오는 여기 10일 + 중기 9일 + 본기 11일
const JIJANGGAN: { [ji: string]: JijangganEntry } = {
  '자': { ji: '자', hanja: '子', yeogi: '壬(임수)', junggi: '',         bongi: '癸(계수)', bongi_oheng: '수(水)' },
  '축': { ji: '축', hanja: '丑', yeogi: '癸(계수)', junggi: '辛(신금)', bongi: '己(기토)', bongi_oheng: '토(土)' },
  '인': { ji: '인', hanja: '寅', yeogi: '戊(무토)', junggi: '丙(병화)', bongi: '甲(갑목)', bongi_oheng: '목(木)' },
  '묘': { ji: '묘', hanja: '卯', yeogi: '甲(갑목)', junggi: '',         bongi: '乙(을목)', bongi_oheng: '목(木)' },
  '진': { ji: '진', hanja: '辰', yeogi: '乙(을목)', junggi: '癸(계수)', bongi: '戊(무토)', bongi_oheng: '토(土)' },
  '사': { ji: '사', hanja: '巳', yeogi: '戊(무토)', junggi: '庚(경금)', bongi: '丙(병화)', bongi_oheng: '화(火)' },
  '오': { ji: '오', hanja: '午', yeogi: '丙(병화)', junggi: '己(기토)', bongi: '丁(정화)', bongi_oheng: '화(火)' },
  '미': { ji: '미', hanja: '未', yeogi: '丁(정화)', junggi: '乙(을목)', bongi: '己(기토)', bongi_oheng: '토(土)' },
  '신': { ji: '신', hanja: '申', yeogi: '戊(무토)', junggi: '壬(임수)', bongi: '庚(경금)', bongi_oheng: '금(金)' },
  '유': { ji: '유', hanja: '酉', yeogi: '庚(경금)', junggi: '',         bongi: '辛(신금)', bongi_oheng: '금(金)' },
  '술': { ji: '술', hanja: '戌', yeogi: '辛(신금)', junggi: '丁(정화)', bongi: '戊(무토)', bongi_oheng: '토(土)' },
  '해': { ji: '해', hanja: '亥', yeogi: '戊(무토)', junggi: '甲(갑목)', bongi: '壬(임수)', bongi_oheng: '수(水)' },
};

export function lookupJijanggan(ji: string): JijangganEntry | { error: string; hint: string } {
  const entry = JIJANGGAN[ji];
  if (!entry) {
    return { error: `알 수 없는 지지: ${ji}`, hint: '자/축/인/묘/진/사/오/미/신/유/술/해 중 선택' };
  }
  return entry;
}
