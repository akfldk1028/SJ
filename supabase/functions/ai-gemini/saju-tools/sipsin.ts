/**
 * 십성(十星) 계산
 * 일간 기준 대상의 십성 판별
 */

const GAN_OHENG: { [k: string]: { oheng: string; yinyang: string } } = {
  '갑': { oheng: '목', yinyang: '양' }, '을': { oheng: '목', yinyang: '음' },
  '병': { oheng: '화', yinyang: '양' }, '정': { oheng: '화', yinyang: '음' },
  '무': { oheng: '토', yinyang: '양' }, '기': { oheng: '토', yinyang: '음' },
  '경': { oheng: '금', yinyang: '양' }, '신': { oheng: '금', yinyang: '음' },
  '임': { oheng: '수', yinyang: '양' }, '계': { oheng: '수', yinyang: '음' },
};

// 지지→오행/음양
// 지지→오행/음양: 정기(正氣=본기) 천간 기준 (십성 계산용)
// ⚠️ 지지 자체의 양/음이 아님! 정기 천간의 음양을 사용해야 십성이 정확함
const JI_OHENG: { [k: string]: { oheng: string; yinyang: string } } = {
  '자': { oheng: '수', yinyang: '음' }, // 정기=癸(계, 음수)
  '축': { oheng: '토', yinyang: '음' }, // 정기=己(기, 음토)
  '인': { oheng: '목', yinyang: '양' }, // 정기=甲(갑, 양목)
  '묘': { oheng: '목', yinyang: '음' }, // 정기=乙(을, 음목)
  '진': { oheng: '토', yinyang: '양' }, // 정기=戊(무, 양토)
  '사': { oheng: '화', yinyang: '양' }, // 정기=丙(병, 양화)
  '오': { oheng: '화', yinyang: '음' }, // 정기=丁(정, 음화)
  '미': { oheng: '토', yinyang: '음' }, // 정기=己(기, 음토)
  '신': { oheng: '금', yinyang: '양' }, // 정기=庚(경, 양금)
  '유': { oheng: '금', yinyang: '음' }, // 정기=辛(신, 음금)
  '술': { oheng: '토', yinyang: '양' }, // 정기=戊(무, 양토)
  '해': { oheng: '수', yinyang: '양' }, // 정기=壬(임, 양수)
};

const SANG_SAENG: { [k: string]: string } = { '목': '화', '화': '토', '토': '금', '금': '수', '수': '목' };
const SANG_GEUK: { [k: string]: string } = { '목': '토', '토': '수', '수': '화', '화': '금', '금': '목' };
const PI_SAENG: { [k: string]: string } = { '목': '수', '화': '목', '토': '화', '금': '토', '수': '금' };
const PI_GEUK: { [k: string]: string } = { '목': '금', '화': '수', '토': '목', '금': '화', '수': '토' };

export function getSipsin(ilgan: string, target: string): { [k: string]: string } {
  const me = GAN_OHENG[ilgan];
  const them = GAN_OHENG[target] || JI_OHENG[target];

  if (!me) return { error: `알 수 없는 일간: ${ilgan}` };
  if (!them) return { error: `알 수 없는 대상: ${target}` };

  const sameYY = me.yinyang === them.yinyang;

  let sipsin = '';
  let meaning = '';

  if (me.oheng === them.oheng) {
    sipsin = sameYY ? '비견(比肩)' : '겁재(劫財)';
    meaning = sameYY ? '나와 같은 기운, 경쟁자/형제' : '승부욕, 한번 꽂히면 밀어붙이는 기운';
  } else if (SANG_SAENG[me.oheng] === them.oheng) {
    sipsin = sameYY ? '식신(食神)' : '상관(傷官)';
    meaning = sameYY ? '표현력, 먹복, 창의력' : '직설적, 재능, 반항기';
  } else if (SANG_GEUK[me.oheng] === them.oheng) {
    sipsin = sameYY ? '편재(偏財)' : '정재(正財)';
    meaning = sameYY ? '유동적 재물, 사업, 투기' : '안정적 재물, 성실, 꾸준함';
  } else if (PI_GEUK[me.oheng] === them.oheng) {
    sipsin = sameYY ? '편관(偏官/七殺)' : '정관(正官)';
    meaning = sameYY ? '카리스마, 외부 압력, 추진력' : '책임감, 규율, 안정';
  } else if (PI_SAENG[me.oheng] === them.oheng) {
    sipsin = sameYY ? '편인(偏印)' : '정인(正印)';
    meaning = sameYY ? '독특한 사고, 직감, 편학' : '학문, 자격, 어머니';
  }

  return {
    ilgan,
    target,
    ilgan_oheng: `${me.oheng}(${me.yinyang})`,
    target_oheng: `${them.oheng}(${them.yinyang})`,
    sipsin,
    meaning,
  };
}
