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

const JIJANGGAN: { [ji: string]: JijangganEntry } = {
  '자': { ji: '자', hanja: '子', bongi: '癸(계수)', junggi: '', yeogi: '', bongi_oheng: '수(水)' },
  '축': { ji: '축', hanja: '丑', bongi: '己(기토)', junggi: '癸(계수)', yeogi: '辛(신금)', bongi_oheng: '토(土)' },
  '인': { ji: '인', hanja: '寅', bongi: '甲(갑목)', junggi: '丙(병화)', yeogi: '戊(무토)', bongi_oheng: '목(木)' },
  '묘': { ji: '묘', hanja: '卯', bongi: '乙(을목)', junggi: '', yeogi: '', bongi_oheng: '목(木)' },
  '진': { ji: '진', hanja: '辰', bongi: '戊(무토)', junggi: '乙(을목)', yeogi: '癸(계수)', bongi_oheng: '토(土)' },
  '사': { ji: '사', hanja: '巳', bongi: '丙(병화)', junggi: '戊(무토)', yeogi: '庚(경금)', bongi_oheng: '화(火)' },
  '오': { ji: '오', hanja: '午', bongi: '丁(정화)', junggi: '己(기토)', yeogi: '', bongi_oheng: '화(火)' },
  '미': { ji: '미', hanja: '未', bongi: '己(기토)', junggi: '丁(정화)', yeogi: '乙(을목)', bongi_oheng: '토(土)' },
  '신': { ji: '신', hanja: '申', bongi: '庚(경금)', junggi: '壬(임수)', yeogi: '戊(무토)', bongi_oheng: '금(金)' },
  '유': { ji: '유', hanja: '酉', bongi: '辛(신금)', junggi: '', yeogi: '', bongi_oheng: '금(金)' },
  '술': { ji: '술', hanja: '戌', bongi: '戊(무토)', junggi: '辛(신금)', yeogi: '丁(정화)', bongi_oheng: '토(土)' },
  '해': { ji: '해', hanja: '亥', bongi: '壬(임수)', junggi: '甲(갑목)', yeogi: '', bongi_oheng: '수(水)' },
};

export function lookupJijanggan(ji: string): JijangganEntry | { error: string; hint: string } {
  const entry = JIJANGGAN[ji];
  if (!entry) {
    return { error: `알 수 없는 지지: ${ji}`, hint: '자/축/인/묘/진/사/오/미/신/유/술/해 중 선택' };
  }
  return entry;
}
