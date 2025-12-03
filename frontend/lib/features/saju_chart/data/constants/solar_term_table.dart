/// 24절기 시각 테이블
/// 한국천문연구원 데이터 기반 (2020-2030년)

/// 절기 시각 데이터 구조
class SolarTermData {
  final DateTime dateTime;
  final String name;

  const SolarTermData(this.dateTime, this.name);
}

/// 연도별 절기 시각 테이블
/// 실제 사용 시 한국천문연구원 API 또는 정밀 계산 라이브러리 사용 권장
const Map<int, Map<String, SolarTermData>> solarTermTable = {
  2024: {
    'ipchun': SolarTermData(DateTime(2024, 2, 4, 17, 26), '입춘'),
    'usoo': SolarTermData(DateTime(2024, 2, 19, 12, 12), '우수'),
    'gyeongchip': SolarTermData(DateTime(2024, 3, 5, 10, 22), '경칩'),
    'chunbun': SolarTermData(DateTime(2024, 3, 20, 12, 6), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2024, 4, 4, 16, 19), '청명'),
    'gogu': SolarTermData(DateTime(2024, 4, 19, 21, 59), '곡우'),
    'ipha': SolarTermData(DateTime(2024, 5, 5, 9, 9), '입하'),
    'soman': SolarTermData(DateTime(2024, 5, 20, 20, 59), '소만'),
    'mangjong': SolarTermData(DateTime(2024, 6, 5, 13, 9), '망종'),
    'haji': SolarTermData(DateTime(2024, 6, 21, 5, 50), '하지'),
    'soseo': SolarTermData(DateTime(2024, 7, 6, 23, 19), '소서'),
    'daeseo': SolarTermData(DateTime(2024, 7, 22, 16, 43), '대서'),
    'ipchu': SolarTermData(DateTime(2024, 8, 7, 9, 8), '입추'),
    'cheoseo': SolarTermData(DateTime(2024, 8, 22, 23, 54), '처서'),
    'baekro': SolarTermData(DateTime(2024, 9, 7, 11, 10), '백로'),
    'chubeun': SolarTermData(DateTime(2024, 9, 22, 13, 43), '추분'),
    'hanro': SolarTermData(DateTime(2024, 10, 8, 3, 0), '한로'),
    'sanggang': SolarTermData(DateTime(2024, 10, 23, 7, 14), '상강'),
    'ipdong': SolarTermData(DateTime(2024, 11, 7, 1, 19), '입동'),
    'soseol': SolarTermData(DateTime(2024, 11, 22, 3, 55), '소설'),
    'daeseol': SolarTermData(DateTime(2024, 12, 7, 0, 16), '대설'),
    'dongji': SolarTermData(DateTime(2024, 12, 21, 18, 20), '동지'),
  },
  2025: {
    'ipchun': SolarTermData(DateTime(2025, 2, 3, 23, 9), '입춘'),
    'usoo': SolarTermData(DateTime(2025, 2, 18, 17, 59), '우수'),
    'gyeongchip': SolarTermData(DateTime(2025, 3, 5, 16, 6), '경칩'),
    'chunbun': SolarTermData(DateTime(2025, 3, 20, 17, 1), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2025, 4, 4, 21, 47), '청명'),
    'gogu': SolarTermData(DateTime(2025, 4, 20, 3, 55), '곡우'),
    'ipha': SolarTermData(DateTime(2025, 5, 5, 14, 55), '입하'),
    'soman': SolarTermData(DateTime(2025, 5, 21, 2, 54), '소만'),
    'mangjong': SolarTermData(DateTime(2025, 6, 5, 18, 56), '망종'),
    'haji': SolarTermData(DateTime(2025, 6, 21, 11, 42), '하지'),
    'soseo': SolarTermData(DateTime(2025, 7, 7, 5, 5), '소서'),
    'daeseo': SolarTermData(DateTime(2025, 7, 22, 22, 29), '대서'),
    'ipchu': SolarTermData(DateTime(2025, 8, 7, 14, 52), '입추'),
    'cheoseo': SolarTermData(DateTime(2025, 8, 23, 5, 33), '처서'),
    'baekro': SolarTermData(DateTime(2025, 9, 7, 16, 50), '백로'),
    'chubeun': SolarTermData(DateTime(2025, 9, 22, 19, 19), '추분'),
    'hanro': SolarTermData(DateTime(2025, 10, 8, 8, 48), '한로'),
    'sanggang': SolarTermData(DateTime(2025, 10, 23, 13, 14), '상강'),
    'ipdong': SolarTermData(DateTime(2025, 11, 7, 7, 19), '입동'),
    'soseol': SolarTermData(DateTime(2025, 11, 22, 9, 55), '소설'),
    'daeseol': SolarTermData(DateTime(2025, 12, 7, 6, 4), '대설'),
    'dongji': SolarTermData(DateTime(2025, 12, 22, 0, 2), '동지'),
  },
};

/// 절기 순서 (월주 계산용)
/// 각 절기는 2개씩 한 달을 담당
const List<String> solarTermOrder = [
  'ipchun',      // 입춘 (1월 시작)
  'usoo',        // 우수
  'gyeongchip',  // 경칩 (2월 시작)
  'chunbun',     // 춘분
  'cheongmyeong', // 청명 (3월 시작)
  'gogu',        // 곡우
  'ipha',        // 입하 (4월 시작)
  'soman',       // 소만
  'mangjong',    // 망종 (5월 시작)
  'haji',        // 하지
  'soseo',       // 소서 (6월 시작)
  'daeseo',      // 대서
  'ipchu',       // 입추 (7월 시작)
  'cheoseo',     // 처서
  'baekro',      // 백로 (8월 시작)
  'chubeun',     // 추분
  'hanro',       // 한로 (9월 시작)
  'sanggang',    // 상강
  'ipdong',      // 입동 (10월 시작)
  'soseol',      // 소설
  'daeseol',     // 대설 (11월 시작)
  'dongji',      // 동지
  'sohan',       // 소한 (12월 시작) - 다음 년도 데이터
  'daehan',      // 대한
];

/// 절기 → 월주 매핑
/// 입춘부터 인월(1월) 시작
const Map<String, int> solarTermToMonthIndex = {
  'ipchun': 0,      // 인월 (1월)
  'usoo': 0,
  'gyeongchip': 1,  // 묘월 (2월)
  'chunbun': 1,
  'cheongmyeong': 2, // 진월 (3월)
  'gogu': 2,
  'ipha': 3,        // 사월 (4월)
  'soman': 3,
  'mangjong': 4,    // 오월 (5월)
  'haji': 4,
  'soseo': 5,       // 미월 (6월)
  'daeseo': 5,
  'ipchu': 6,       // 신월 (7월)
  'cheoseo': 6,
  'baekro': 7,      // 유월 (8월)
  'chubeun': 7,
  'hanro': 8,       // 술월 (9월)
  'sanggang': 8,
  'ipdong': 9,      // 해월 (10월)
  'soseol': 9,
  'daeseol': 10,    // 자월 (11월)
  'dongji': 10,
  'sohan': 11,      // 축월 (12월)
  'daehan': 11,
};
