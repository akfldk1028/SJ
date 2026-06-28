/**
 * 천간합(天干合) 5쌍 룩업
 */

const CHEONGAN_HAP: { [k: string]: { pair: string; result: string } } = {
  '갑': { pair: '기', result: '토(土)' },
  '기': { pair: '갑', result: '토(土)' },
  '을': { pair: '경', result: '금(金)' },
  '경': { pair: '을', result: '금(金)' },
  '병': { pair: '신', result: '수(水)' },
  '신': { pair: '병', result: '수(水)' },
  '정': { pair: '임', result: '목(木)' },
  '임': { pair: '정', result: '목(木)' },
  '무': { pair: '계', result: '화(火)' },
  '계': { pair: '무', result: '화(火)' },
};

export function verifyCheonganHap(gan1: string, gan2: string): { [k: string]: unknown } {
  const hap = CHEONGAN_HAP[gan1];
  if (hap && hap.pair === gan2) {
    return {
      gan1,
      gan2,
      is_hap: true,
      result: `${gan1}${gan2}합 → ${hap.result}`,
      note: '합화 여부는 주변 오행과 월령에 따라 다름. 합이 무조건 좋은 것은 아님 — 용신 방향이면 좋은 합, 기신 방향이면 나쁜 합.',
    };
  }
  return {
    gan1,
    gan2,
    is_hap: false,
    result: `${gan1}과 ${gan2}는 천간합이 아님`,
    all_pairs: '갑기합토, 을경합금, 병신합수, 정임합목, 무계합화',
  };
}
