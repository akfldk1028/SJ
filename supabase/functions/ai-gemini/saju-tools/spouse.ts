/**
 * 육친(六親) 배우자성 룩업
 * 남자 = 재성(내가 극하는 오행), 여자 = 관성(나를 극하는 오행)
 */

interface SpouseResult {
  ilgan: string;
  gender: string;
  rule: string;
  spouse_star_type: string;
  pyeonstar: string;
  jeongstar: string;
  explanation: string;
}

// 일간→오행 매핑
const GAN_OHENG: Record<string, { oheng: string; yinyang: string }> = {
  '갑': { oheng: '목', yinyang: '양' },
  '을': { oheng: '목', yinyang: '음' },
  '병': { oheng: '화', yinyang: '양' },
  '정': { oheng: '화', yinyang: '음' },
  '무': { oheng: '토', yinyang: '양' },
  '기': { oheng: '토', yinyang: '음' },
  '경': { oheng: '금', yinyang: '양' },
  '신': { oheng: '금', yinyang: '음' },
  '임': { oheng: '수', yinyang: '양' },
  '계': { oheng: '수', yinyang: '음' },
};

// 상극 관계 (내가 극하는 오행)
const克: Record<string, string> = {
  '목': '토', '토': '수', '수': '화', '화': '금', '금': '목',
};

// 나를 극하는 오행
const 被克: Record<string, string> = {
  '목': '금', '금': '화', '화': '수', '수': '토', '토': '목',
};

// 오행→천간 매핑
const OHENG_TO_GAN: Record<string, { yang: string; yin: string }> = {
  '목': { yang: '갑', yin: '을' },
  '화': { yang: '병', yin: '정' },
  '토': { yang: '무', yin: '기' },
  '금': { yang: '경', yin: '신' },
  '수': { yang: '임', yin: '계' },
};

export function getSpouseStar(ilgan: string, gender: string): SpouseResult {
  const ganInfo = GAN_OHENG[ilgan];
  if (!ganInfo) {
    return { ilgan, gender, rule: 'ERROR', spouse_star_type: '', pyeonstar: '', jeongstar: '', explanation: `알 수 없는 일간: ${ilgan}` };
  }

  const isMale = gender === 'male';

  if (isMale) {
    // 남자: 배우자 = 재성 = 내가 극하는 오행
    const spouseOheng = 克[ganInfo.oheng];
    const spouseGans = OHENG_TO_GAN[spouseOheng];
    // 편재 = 같은 음양, 정재 = 다른 음양
    const pyeon = ganInfo.yinyang === '양' ? spouseGans.yang : spouseGans.yin;
    const jeong = ganInfo.yinyang === '양' ? spouseGans.yin : spouseGans.yang;

    return {
      ilgan,
      gender: '남자',
      rule: '남자의 배우자 = 재성(財星) = 내가 극하는 오행',
      spouse_star_type: `${spouseOheng}(${spouseGans.yang}/${spouseGans.yin})`,
      pyeonstar: `편재: ${pyeon}`,
      jeongstar: `정재: ${jeong}`,
      explanation: `${ilgan}${ganInfo.oheng} 남자 → ${ganInfo.oheng}이 극하는 ${spouseOheng}이 배우자성. 편재=${pyeon}, 정재=${jeong}. ⚠️ 관성(${被克[ganInfo.oheng]})은 남자에게 직장/상사이지 배우자가 아님!`,
    };
  } else {
    // 여자: 배우자 = 관성 = 나를 극하는 오행
    const spouseOheng = 被克[ganInfo.oheng];
    const spouseGans = OHENG_TO_GAN[spouseOheng];
    const pyeon = ganInfo.yinyang === '양' ? spouseGans.yang : spouseGans.yin;
    const jeong = ganInfo.yinyang === '양' ? spouseGans.yin : spouseGans.yang;

    return {
      ilgan,
      gender: '여자',
      rule: '여자의 배우자 = 관성(官星) = 나를 극하는 오행',
      spouse_star_type: `${spouseOheng}(${spouseGans.yang}/${spouseGans.yin})`,
      pyeonstar: `편관: ${pyeon}`,
      jeongstar: `정관: ${jeong}`,
      explanation: `${ilgan}${ganInfo.oheng} 여자 → ${spouseOheng}이 ${ganInfo.oheng}을 극하므로 관성이 배우자. 편관=${pyeon}, 정관=${jeong}. ⚠️ 재성(${克[ganInfo.oheng]})은 여자에게 재물/아버지이지 배우자가 아님!`,
    };
  }
}
