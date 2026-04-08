/**
 * 대운(大運) 계산
 * 월주 + 년간 + 성별로 10개 대운 리스트 생성
 */

const CHEONGAN = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
const JIJI = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];
const YANG_GAN = new Set(['갑', '병', '무', '경', '임']);

interface DaeunResult {
  isForward: boolean;
  direction: string;
  reason: string;
  startAge: number;
  list: { order: number; gan: string; ji: string; pillar: string; startAge: number; endAge: number }[];
}

export function calculateDaeun(
  monthGan: string,
  monthJi: string,
  yearGan: string,
  gender: string,
  startAge?: number,
): DaeunResult {
  // 입력 검증
  const mGanIdx = CHEONGAN.indexOf(monthGan);
  const mJiIdx = JIJI.indexOf(monthJi);
  if (mGanIdx === -1) return { isForward: false, direction: '', reason: `알 수 없는 월간: ${monthGan}`, startAge: 0, list: [] };
  if (mJiIdx === -1) return { isForward: false, direction: '', reason: `알 수 없는 월지: ${monthJi}`, startAge: 0, list: [] };

  const yGanIdx = CHEONGAN.indexOf(yearGan);
  if (yGanIdx === -1) return { isForward: false, direction: '', reason: `알 수 없는 년간: ${yearGan}`, startAge: 0, list: [] };

  // 순행/역행 결정
  const isYangYear = YANG_GAN.has(yearGan);
  const isMale = gender === 'male';
  const isForward = (isMale && isYangYear) || (!isMale && !isYangYear);

  const direction = isForward ? '순행(順行)' : '역행(逆行)';
  const reason = `${yearGan}(${isYangYear ? '양' : '음'})년 ${isMale ? '남' : '여'}자 → ${direction}`;

  // 대운 시작 나이 (기본값 4세, 정확한 값은 절입일 계산 필요)
  const age = startAge ?? 4;

  // 대운 리스트 생성 (10개)
  const list = [];
  let ganIdx = mGanIdx;
  let jiIdx = mJiIdx;

  for (let i = 0; i < 10; i++) {
    if (isForward) {
      ganIdx = (ganIdx + 1) % 10;
      jiIdx = (jiIdx + 1) % 12;
    } else {
      ganIdx = (ganIdx - 1 + 10) % 10;
      jiIdx = (jiIdx - 1 + 12) % 12;
    }

    const gan = CHEONGAN[ganIdx];
    const ji = JIJI[jiIdx];
    const daeunStartAge = age + (i * 10);

    list.push({
      order: i + 1,
      gan,
      ji,
      pillar: `${gan}${ji}`,
      startAge: daeunStartAge,
      endAge: daeunStartAge + 9,
    });
  }

  return { isForward, direction, reason, startAge: age, list };
}
