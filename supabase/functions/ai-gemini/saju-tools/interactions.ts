/**
 * 지지(地支) 간 관계 룩업 테이블
 * 충/원진/해/육합/삼합/방합/형/파 판별
 */

// 충(冲) — 6쌍
const CHUNG: { [k: string]: string } = {
  '자': '오', '오': '자',
  '축': '미', '미': '축',
  '인': '신', '신': '인',
  '묘': '유', '유': '묘',
  '진': '술', '술': '진',
  '사': '해', '해': '사',
};

// 원진(怨嗔) — 6쌍
const WONJIN: { [k: string]: string } = {
  '자': '미', '미': '자',
  '축': '오', '오': '축',
  '인': '유', '유': '인',
  '묘': '신', '신': '묘',
  '진': '해', '해': '진',
  '사': '술', '술': '사',
};

// 해(害/六害) — 6쌍 (원진과 다름!)
const HAE: { [k: string]: string } = {
  '자': '미', '미': '자',
  '축': '오', '오': '축',
  '인': '사', '사': '인',
  '묘': '진', '진': '묘',
  '신': '해', '해': '신',
  '유': '술', '술': '유',
};

// 육합(六合) — 6쌍 + 합화 결과
const YUKHAP: { [k: string]: { pair: string; result: string } } = {
  '자': { pair: '축', result: '토' },
  '축': { pair: '자', result: '토' },
  '인': { pair: '해', result: '목' },
  '해': { pair: '인', result: '목' },
  '묘': { pair: '술', result: '화' },
  '술': { pair: '묘', result: '화' },
  '진': { pair: '유', result: '금' },
  '유': { pair: '진', result: '금' },
  '사': { pair: '신', result: '수' },
  '신': { pair: '사', result: '수' },
  '오': { pair: '미', result: '토' },
  '미': { pair: '오', result: '토' },
};

// 삼합(三合) — 4조
const SAMHAP: Array<{ members: string[]; result: string }> = [
  { members: ['신', '자', '진'], result: '수국(水局)' },
  { members: ['인', '오', '술'], result: '화국(火局)' },
  { members: ['사', '유', '축'], result: '금국(金局)' },
  { members: ['해', '묘', '미'], result: '목국(木局)' },
];

// 방합(方合) — 4조
const BANGHAP: Array<{ members: string[]; result: string }> = [
  { members: ['인', '묘', '진'], result: '동방 목(木)' },
  { members: ['사', '오', '미'], result: '남방 화(火)' },
  { members: ['신', '유', '술'], result: '서방 금(金)' },
  { members: ['해', '자', '축'], result: '북방 수(水)' },
];

// 형(刑) — 삼형살 + 자형
const HYUNG: Array<{ members: string[]; name: string }> = [
  { members: ['인', '사', '신'], name: '무은지형(無恩之刑)' },
  { members: ['축', '술', '미'], name: '무례지형(無禮之刑)' },
  { members: ['자', '묘'], name: '무예지형(無禮之刑)' },
  { members: ['진', '진'], name: '자형(自刑)' },
  { members: ['오', '오'], name: '자형(自刑)' },
  { members: ['유', '유'], name: '자형(自刑)' },
  { members: ['해', '해'], name: '자형(自刑)' },
];

// 파(破) — 6쌍
const PA: { [k: string]: string } = {
  '자': '유', '유': '자',
  '축': '진', '진': '축',
  '인': '해', '해': '인',
  '묘': '오', '오': '묘',
  '사': '신', '신': '사',
  '술': '미', '미': '술',
};

export function verifyInteraction(ji1: string, ji2: string): { [k: string]: unknown } {
  const results: { [k: string]: unknown } = {
    ji1,
    ji2,
    relations: [] as string[],
  };
  const relations: string[] = [];

  // 충
  if (CHUNG[ji1] === ji2) {
    relations.push(`${ji1}${ji2}충(冲): 부딪힘/변화/돌파`);
  }

  // 원진
  if (WONJIN[ji1] === ji2) {
    relations.push(`${ji1}${ji2}원진(怨嗔): 미워하면서 끌리는 복잡한 관계`);
  }

  // 해
  if (HAE[ji1] === ji2) {
    relations.push(`${ji1}${ji2}해(害): 은근히 갈아먹는 관계`);
  }

  // 육합
  if (YUKHAP[ji1]?.pair === ji2) {
    relations.push(`${ji1}${ji2}육합(六合): 합화 → ${YUKHAP[ji1].result}`);
  }

  // 삼합 (2개만으로는 반합)
  for (const s of SAMHAP) {
    if (s.members.includes(ji1) && s.members.includes(ji2)) {
      const missing = s.members.find(m => m !== ji1 && m !== ji2);
      relations.push(`${ji1}${ji2} 반합(半合): ${s.result}의 일부. 나머지 ${missing}이 오면 삼합 완성`);
    }
  }

  // 방합 (2개만으로는 부분 방합)
  for (const b of BANGHAP) {
    if (b.members.includes(ji1) && b.members.includes(ji2)) {
      const missing = b.members.find(m => m !== ji1 && m !== ji2);
      relations.push(`${ji1}${ji2}: ${b.result} 방합(方合) 구성원. 나머지 ${missing} 필요`);
    }
  }

  // 형
  for (const h of HYUNG) {
    if (h.members.length === 2 && h.members.includes(ji1) && h.members.includes(ji2)) {
      relations.push(`${ji1}${ji2}형(刑): ${h.name}`);
    }
  }

  // 파
  if (PA[ji1] === ji2) {
    relations.push(`${ji1}${ji2}파(破): 깨뜨림/와해`);
  }

  if (relations.length === 0) {
    relations.push(`${ji1}과 ${ji2} 사이에 특별한 합충형해파원진 관계 없음`);
  }

  results.relations = relations;
  return results;
}
