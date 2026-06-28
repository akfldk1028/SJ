/**
 * 궁통보감(窮通寶鑑) 조후용신(調候用神) 120 조합 룩업
 * 일간(日干) × 월지(月支) = 10 × 12 = 120 조합
 *
 * 조후용신: 계절에 따라 일간이 필요로 하는 오행
 * - 억부용신(格局用神)과 별개로 보조적으로 참조
 * - 궁통보감 원전 + 난강망(欄江網) 기반
 */

interface JohuEntry {
  primary: string;    // 주 조후용신
  secondary: string;  // 보조 용신
  note: string;       // 해석 요점
}

// 甲木 (갑목)
const GAP: { [wolji: string]: JohuEntry } = {
  '인': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '초봄 한기 남음. 병화로 따뜻하게, 계수로 뿌리 보강' },
  '묘': { primary: '庚金(경금)', secondary: '丙火(병화)', note: '묘월 갑목 왕지. 경금으로 재단(조각)해야 귀. 병화 보조' },
  '진': { primary: '庚金(경금)', secondary: '壬水(임수)', note: '늦봄 토왕. 경금으로 다듬고 임수로 윤택' },
  '사': { primary: '癸水(계수)', secondary: '丁火(정화)', note: '초여름 화기 왕. 계수로 뿌리 보호, 정화 자연 조후' },
  '오': { primary: '癸水(계수)', secondary: '丁火(정화)', note: '한여름 극열. 반드시 계수 있어야 마르지 않음' },
  '미': { primary: '癸水(계수)', secondary: '庚金(경금)', note: '미월 토왕. 계수로 윤택, 경금 수원(水源)' },
  '신': { primary: '庚金(경금)', secondary: '丙火(병화)', note: '초가을 금왕. 경금 재단 + 병화 단련(鍛鍊)' },
  '유': { primary: '庚金(경금)', secondary: '丁火(정화)', note: '금왕절 경금으로 다듬고 정화로 단련' },
  '술': { primary: '庚金(경금)', secondary: '甲木(갑목)', note: '늦가을 토조. 경금 재단 + 갑목으로 토 제압' },
  '해': { primary: '庚金(경금)', secondary: '丁火(정화)', note: '초겨울 수왕. 경금 재단 필수, 정화로 온기' },
  '자': { primary: '丁火(정화)', secondary: '庚金(경금)', note: '한겨울 극한. 정화 먼저(온기), 경금 보조' },
  '축': { primary: '丁火(정화)', secondary: '庚金(경금)', note: '늦겨울 한토. 정화 온기 필수, 경금으로 형체' },
};

// 乙木 (을목)
const EUL: { [wolji: string]: JohuEntry } = {
  '인': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '초봄 을목은 연약. 병화로 따뜻하게 보호' },
  '묘': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '을목 왕지이나 여전히 한기. 병화 조후 필수' },
  '진': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '늦봄 토왕. 계수로 뿌리 보강, 병화 보조' },
  '사': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '초여름 화기 강. 계수로 마르지 않게' },
  '오': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '한여름 을목 시들 위험. 계수 생명수' },
  '미': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '미월 조토. 을목 뿌리 마름. 계수 필수' },
  '신': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '초가을 금극목. 병화로 금 제련, 계수 뿌리' },
  '유': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '금왕절 을목 상. 병화로 금 녹이기' },
  '술': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '늦가을 조토. 계수 윤택 + 병화 온기' },
  '해': { primary: '丙火(병화)', secondary: '戊土(무토)', note: '초겨울 수왕. 병화 온기 필수, 무토로 수 제어' },
  '자': { primary: '丙火(병화)', secondary: '戊土(무토)', note: '한겨울 을목 동결. 병화 필수, 무토 보조' },
  '축': { primary: '丙火(병화)', secondary: '戊土(무토)', note: '늦겨울 한토. 병화 온기가 생명줄' },
};

// 丙火 (병화)
const BYEONG: { [wolji: string]: JohuEntry } = {
  '인': { primary: '壬水(임수)', secondary: '庚金(경금)', note: '초봄 목생화로 불 커짐. 임수로 제어, 경금 수원' },
  '묘': { primary: '壬水(임수)', secondary: '己土(기토)', note: '봄 화기 상승. 임수 제어 필수' },
  '진': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '늦봄 토왕. 임수 조후 + 갑목으로 토 제압' },
  '사': { primary: '壬水(임수)', secondary: '庚金(경금)', note: '사월 건록. 병화 극강. 임수 반드시 필요' },
  '오': { primary: '壬水(임수)', secondary: '庚金(경금)', note: '한여름 병화 제왕. 임수 없으면 타버림' },
  '미': { primary: '壬水(임수)', secondary: '庚金(경금)', note: '미월 화토 조. 임수로 식히기' },
  '신': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '초가을 화 약해짐. 임수 약간 + 갑목 생화' },
  '유': { primary: '甲木(갑목)', secondary: '壬水(임수)', note: '금왕절 화 쇠. 갑목으로 불 살리기' },
  '술': { primary: '甲木(갑목)', secondary: '壬水(임수)', note: '늦가을 토조. 갑목 생화 + 임수 윤택' },
  '해': { primary: '甲木(갑목)', secondary: '戊土(무토)', note: '초겨울 수왕. 갑목으로 불 살리고 무토로 수 막기' },
  '자': { primary: '甲木(갑목)', secondary: '戊土(무토)', note: '한겨울 수극화. 갑목 필수(통관), 무토 수 제어' },
  '축': { primary: '甲木(갑목)', secondary: '壬水(임수)', note: '늦겨울 한토. 갑목 생화 필수' },
};

// 丁火 (정화)
const JEONG: { [wolji: string]: JohuEntry } = {
  '인': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '초봄 정화는 촛불. 갑목 연료 필수, 경금으로 갑목 재단' },
  '묘': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '봄 을목 왕. 갑목 연료 + 경금 다듬기' },
  '진': { primary: '甲木(갑목)', secondary: '壬水(임수)', note: '늦봄 토왕으로 화 설기. 갑목 생화 필수' },
  '사': { primary: '甲木(갑목)', secondary: '壬水(임수)', note: '사월 화왕. 갑목 연료 + 임수로 과열 방지' },
  '오': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '한여름 화왕. 임수 제어가 급선무' },
  '미': { primary: '甲木(갑목)', secondary: '壬水(임수)', note: '미월 토왕 설기. 갑목 연료 보충' },
  '신': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '초가을 금왕 극화. 갑목 생화 + 경금 재단' },
  '유': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '금왕절 정화 미약. 갑목 필수 연료' },
  '술': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '늦가을 토조. 갑목 생화 + 경금 보조' },
  '해': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '초겨울 수왕. 갑목이 통관 역할 (수생목생화)' },
  '자': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '한겨울 정화 꺼질 위기. 갑목 연료 급선무' },
  '축': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '늦겨울 한토. 갑목 없으면 불 꺼짐' },
};

// 戊土 (무토)
const MU: { [wolji: string]: JohuEntry } = {
  '인': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '초봄 토 한. 병화 온기 + 갑목으로 토 소통(疏通)' },
  '묘': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '봄 목왕극토. 병화 통관(목생화생토) 필수' },
  '진': { primary: '甲木(갑목)', secondary: '癸水(계수)', note: '진월 토왕. 갑목으로 소통, 계수로 윤택' },
  '사': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '초여름 화왕생토 과다. 임수로 제어' },
  '오': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '한여름 토 건조. 임수 윤택 필수' },
  '미': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '미월 토왕 건조. 계수 윤택 + 병화 생기' },
  '신': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '초가을 금설기. 병화 온기로 토 보강' },
  '유': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '금왕 토 설기. 병화로 보강, 계수 윤택' },
  '술': { primary: '甲木(갑목)', secondary: '癸水(계수)', note: '술월 토왕. 갑목 소통 필수' },
  '해': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '초겨울 수왕극토. 병화 온기 급선무' },
  '자': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '한겨울 토 냉. 병화 온기 필수' },
  '축': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '늦겨울 한토. 병화 따뜻하게 해야 생기' },
};

// 己土 (기토)
const GI: { [wolji: string]: JohuEntry } = {
  '인': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '초봄 기토 한습. 병화 온기 필수' },
  '묘': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '봄 목왕극토. 병화 통관 필수' },
  '진': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '진월 습토. 병화 건조 + 계수 윤택 균형' },
  '사': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '초여름 조토. 계수로 윤택하게' },
  '오': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '한여름 기토 건조. 계수 필수' },
  '미': { primary: '癸水(계수)', secondary: '丙火(병화)', note: '미월 토왕 건조. 계수 윤택 급선무' },
  '신': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '초가을 금설기. 병화 보강' },
  '유': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '금왕 설기. 병화로 온기' },
  '술': { primary: '丙火(병화)', secondary: '癸水(계수)', note: '술월 토왕. 병화 생기 + 계수 윤택' },
  '해': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '초겨울 수왕. 병화 온기 필수' },
  '자': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '한겨울 기토 냉습. 병화가 생명줄' },
  '축': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '늦겨울 한습토. 병화 온기 최우선' },
};

// 庚金 (경금)
const GYEONG: { [wolji: string]: JohuEntry } = {
  '인': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '초봄 금 한. 병화로 단련(鍛鍊)해야 성기(成器)' },
  '묘': { primary: '丁火(정화)', secondary: '甲木(갑목)', note: '봄 목왕. 정화로 정밀 단련, 갑목 연료' },
  '진': { primary: '甲木(갑목)', secondary: '丁火(정화)', note: '늦봄 토왕생금. 갑목 소통 + 정화 단련' },
  '사': { primary: '壬水(임수)', secondary: '戊土(무토)', note: '사월 화왕극금. 임수로 식히기' },
  '오': { primary: '壬水(임수)', secondary: '己土(기토)', note: '한여름 금 녹을 위험. 임수 필수 냉각' },
  '미': { primary: '壬水(임수)', secondary: '丙火(병화)', note: '미월 화토. 임수로 식히기 + 병화 적당히' },
  '신': { primary: '丁火(정화)', secondary: '甲木(갑목)', note: '신월 금왕. 정화로 정밀 단련 필수' },
  '유': { primary: '丁火(정화)', secondary: '甲木(갑목)', note: '금왕절. 정화+갑목으로 단련해야 보석' },
  '술': { primary: '甲木(갑목)', secondary: '壬水(임수)', note: '늦가을 토왕. 갑목 소통, 임수 윤택' },
  '해': { primary: '丁火(정화)', secondary: '甲木(갑목)', note: '초겨울 수왕. 정화 단련 + 갑목 연료' },
  '자': { primary: '丁火(정화)', secondary: '丙火(병화)', note: '한겨울 경금 극한. 정화 단련 + 병화 조후' },
  '축': { primary: '丁火(정화)', secondary: '丙火(병화)', note: '늦겨울 한금. 정화 단련 + 병화 온기' },
};

// 辛金 (신금)
const SIN: { [wolji: string]: JohuEntry } = {
  '인': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '초봄 신금(보석)은 세척 필요. 임수로 씻기' },
  '묘': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '봄 목왕. 임수로 세척 + 갑목 재성' },
  '진': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '늦봄 토왕매금. 임수로 드러내기' },
  '사': { primary: '壬水(임수)', secondary: '己土(기토)', note: '초여름 화극금. 임수 냉각 필수, 기토 보호' },
  '오': { primary: '壬水(임수)', secondary: '己土(기토)', note: '한여름 신금 용해 위험. 임수+기토 보호' },
  '미': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '미월 토왕매금. 임수 세척 + 갑목 소통' },
  '신': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '신월 금왕. 임수 설기(泄氣) + 갑목 재성' },
  '유': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '금왕절 신금 왕. 임수로 빛내기' },
  '술': { primary: '壬水(임수)', secondary: '甲木(갑목)', note: '늦가을 토매금. 임수 세척 필수' },
  '해': { primary: '丙火(병화)', secondary: '壬水(임수)', note: '초겨울 수다. 병화 온기 + 임수 약간' },
  '자': { primary: '丙火(병화)', secondary: '戊土(무토)', note: '한겨울 수왕. 병화 온기 필수, 무토 수 제어' },
  '축': { primary: '丙火(병화)', secondary: '壬水(임수)', note: '늦겨울 한금. 병화 온기 + 임수 세척' },
};

// 壬水 (임수)
const IM: { [wolji: string]: JohuEntry } = {
  '인': { primary: '戊土(무토)', secondary: '丙火(병화)', note: '초봄 수 아직 차. 무토 제방 + 병화 온기' },
  '묘': { primary: '戊土(무토)', secondary: '辛金(신금)', note: '봄 목왕 설기. 무토 제방, 신금 수원' },
  '진': { primary: '甲木(갑목)', secondary: '庚金(경금)', note: '진월 토왕극수. 갑목으로 토 제압' },
  '사': { primary: '壬水(임수)', secondary: '辛金(신금)', note: '초여름 화왕. 임수 비겁 도움 + 신금 수원' },
  '오': { primary: '辛金(신금)', secondary: '甲木(갑목)', note: '한여름 수 고갈. 신금 수원 필수' },
  '미': { primary: '辛金(신금)', secondary: '甲木(갑목)', note: '미월 토왕. 신금 수원 + 갑목 토 제압' },
  '신': { primary: '戊土(무토)', secondary: '丁火(정화)', note: '초가을 금생수 범람. 무토 제방 필수' },
  '유': { primary: '甲木(갑목)', secondary: '戊土(무토)', note: '금왕생수. 갑목 소통 + 무토 제방' },
  '술': { primary: '甲木(갑목)', secondary: '丙火(병화)', note: '늦가을 토극수. 갑목 소통 + 병화 온기' },
  '해': { primary: '戊土(무토)', secondary: '丙火(병화)', note: '해월 임수 건록. 무토 제방 필수' },
  '자': { primary: '戊土(무토)', secondary: '丙火(병화)', note: '한겨울 수 범람. 무토 제방 + 병화 온기' },
  '축': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '늦겨울 한수. 병화 온기 최우선' },
};

// 癸水 (계수)
const GYE: { [wolji: string]: JohuEntry } = {
  '인': { primary: '辛金(신금)', secondary: '丙火(병화)', note: '초봄 계수(이슬). 신금 수원 + 병화 온기' },
  '묘': { primary: '庚金(경금)', secondary: '辛金(신금)', note: '봄 목왕 설기. 경금/신금으로 수원 보충' },
  '진': { primary: '丙火(병화)', secondary: '辛金(신금)', note: '진월 토극수. 병화 통관 + 신금 수원' },
  '사': { primary: '辛金(신금)', secondary: '壬水(임수)', note: '초여름 화왕. 신금 수원 + 임수 비겁 도움' },
  '오': { primary: '庚金(경금)', secondary: '辛金(신금)', note: '한여름 계수 증발 위험. 금 수원 필수' },
  '미': { primary: '庚金(경금)', secondary: '辛金(신금)', note: '미월 토조극수. 금으로 수원 보충' },
  '신': { primary: '丁火(정화)', secondary: '甲木(갑목)', note: '초가을 금왕생수. 정화로 금 제련, 수 과다 방지' },
  '유': { primary: '丙火(병화)', secondary: '甲木(갑목)', note: '금왕생수 범람. 병화 온기 + 갑목 소통' },
  '술': { primary: '辛金(신금)', secondary: '丙火(병화)', note: '늦가을 토극수. 신금 수원 + 병화 온기' },
  '해': { primary: '戊土(무토)', secondary: '丙火(병화)', note: '초겨울 수왕. 무토 제방 + 병화 온기' },
  '자': { primary: '丙火(병화)', secondary: '戊土(무토)', note: '한겨울 계수 범람. 병화 온기 + 무토 제방' },
  '축': { primary: '丙火(병화)', secondary: '辛金(신금)', note: '늦겨울 한수. 병화 온기 최우선, 신금 수원' },
};

const JOHU_MAP: { [ilgan: string]: { [wolji: string]: JohuEntry } } = {
  '갑': GAP, '을': EUL, '병': BYEONG, '정': JEONG, '무': MU,
  '기': GI, '경': GYEONG, '신': SIN, '임': IM, '계': GYE,
};

export function lookupJohu(ilgan: string, wolji: string): JohuEntry | { error: string; hint: string } {
  const ilganMap = JOHU_MAP[ilgan];
  if (!ilganMap) {
    return { error: `알 수 없는 일간: ${ilgan}`, hint: '갑/을/병/정/무/기/경/신/임/계 중 선택' };
  }
  const entry = ilganMap[wolji];
  if (!entry) {
    return { error: `알 수 없는 월지: ${wolji}`, hint: '인/묘/진/사/오/미/신/유/술/해/자/축 중 선택' };
  }
  return { ...entry, ilgan, wolji, source: '궁통보감(窮通寶鑑)' };
}
