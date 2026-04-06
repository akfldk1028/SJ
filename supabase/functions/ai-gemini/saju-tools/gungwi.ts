/**
 * 궁위(宮位) — 사주 4주(柱)의 의미
 */

const GUNGWI: Record<string, Record<string, string>> = {
  year: {
    name: '년주(年柱) — 조상궁/사회궁',
    period: '유년기 (1~15세)',
    represents: '조부모, 가문, 사회적 배경, 유년기 환경',
    gan_meaning: '년간: 조상의 외적 성향, 사회적 인연',
    ji_meaning: '년지: 조상의 내적 성향, 유년기 환경',
  },
  month: {
    name: '월주(月柱) — 부모궁/형제궁',
    period: '청년기 (16~30세)',
    represents: '부모, 형제, 사회활동, 직업환경, 격국의 근거',
    gan_meaning: '월간: 부모의 외적 성향, 사회적 역할',
    ji_meaning: '월지: 부모의 내적 성향, 격국 판단의 핵심 (월령)',
  },
  day_gan: {
    name: '일간(日干) — 나 자신',
    period: '중년기 (31~45세)',
    represents: '나의 본질, 성격, 정체성. 모든 십성 계산의 기준점',
    note: '⚠️ 일간은 "배우자궁"이 아님! 일간 = 나, 일지 = 배우자궁',
  },
  day_ji: {
    name: '일지(日支) — 배우자궁',
    period: '중년기 (31~45세)',
    represents: '배우자, 결혼생활, 가정. 배우자의 성격과 인연',
    note: '일지에 앉은 십성이 배우자의 성격을 보여줌. 일지의 충/합이 결혼운에 영향',
  },
  hour: {
    name: '시주(時柱) — 자녀궁/말년궁',
    period: '말년 (46세~)',
    represents: '자녀, 후배, 제자, 노후, 말년 운세',
    gan_meaning: '시간: 자녀의 외적 성향, 말년 사회활동',
    ji_meaning: '시지: 자녀의 내적 성향, 노후 환경',
  },
};

export function getGungwi(pillar: string): Record<string, string> {
  const info = GUNGWI[pillar];
  if (!info) {
    return {
      error: `알 수 없는 주(柱): ${pillar}. year/month/day_gan/day_ji/hour 중 선택`,
      summary: '년주=조상궁, 월주=부모궁, 일간=나, 일지=배우자궁, 시주=자녀궁',
    };
  }
  return info;
}
