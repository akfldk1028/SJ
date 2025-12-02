/// 24절기 (二十四節氣)
enum SolarTerm {
  ipchun,      // 입춘 (立春)
  usoo,        // 우수 (雨水)
  gyeongchip,  // 경칩 (驚蟄)
  chunbun,     // 춘분 (春分)
  cheongmyeong, // 청명 (淸明)
  gogu,        // 곡우 (穀雨)
  ipha,        // 입하 (立夏)
  soman,       // 소만 (小滿)
  mangjong,    // 망종 (芒種)
  haji,        // 하지 (夏至)
  soseo,       // 소서 (小暑)
  daeseo,      // 대서 (大暑)
  ipchu,       // 입추 (立秋)
  cheoseo,     // 처서 (處暑)
  baekro,      // 백로 (白露)
  chubeun,     // 추분 (秋分)
  hanro,       // 한로 (寒露)
  sanggang,    // 상강 (霜降)
  ipdong,      // 입동 (立冬)
  soseol,      // 소설 (小雪)
  daeseol,     // 대설 (大雪)
  dongji,      // 동지 (冬至)
  sohan,       // 소한 (小寒)
  daehan,      // 대한 (大寒)
}

/// 절기 한글명
const Map<SolarTerm, String> solarTermKoreanName = {
  SolarTerm.ipchun: '입춘',
  SolarTerm.usoo: '우수',
  SolarTerm.gyeongchip: '경칩',
  SolarTerm.chunbun: '춘분',
  SolarTerm.cheongmyeong: '청명',
  SolarTerm.gogu: '곡우',
  SolarTerm.ipha: '입하',
  SolarTerm.soman: '소만',
  SolarTerm.mangjong: '망종',
  SolarTerm.haji: '하지',
  SolarTerm.soseo: '소서',
  SolarTerm.daeseo: '대서',
  SolarTerm.ipchu: '입추',
  SolarTerm.cheoseo: '처서',
  SolarTerm.baekro: '백로',
  SolarTerm.chubeun: '추분',
  SolarTerm.hanro: '한로',
  SolarTerm.sanggang: '상강',
  SolarTerm.ipdong: '입동',
  SolarTerm.soseol: '소설',
  SolarTerm.daeseol: '대설',
  SolarTerm.dongji: '동지',
  SolarTerm.sohan: '소한',
  SolarTerm.daehan: '대한',
};

/// 절기 한자명
const Map<SolarTerm, String> solarTermHanjaName = {
  SolarTerm.ipchun: '立春',
  SolarTerm.usoo: '雨水',
  SolarTerm.gyeongchip: '驚蟄',
  SolarTerm.chunbun: '春分',
  SolarTerm.cheongmyeong: '淸明',
  SolarTerm.gogu: '穀雨',
  SolarTerm.ipha: '立夏',
  SolarTerm.soman: '小滿',
  SolarTerm.mangjong: '芒種',
  SolarTerm.haji: '夏至',
  SolarTerm.soseo: '小暑',
  SolarTerm.daeseo: '大暑',
  SolarTerm.ipchu: '立秋',
  SolarTerm.cheoseo: '處暑',
  SolarTerm.baekro: '白露',
  SolarTerm.chubeun: '秋分',
  SolarTerm.hanro: '寒露',
  SolarTerm.sanggang: '霜降',
  SolarTerm.ipdong: '立冬',
  SolarTerm.soseol: '小雪',
  SolarTerm.daeseol: '大雪',
  SolarTerm.dongji: '冬至',
  SolarTerm.sohan: '小寒',
  SolarTerm.daehan: '大寒',
};
