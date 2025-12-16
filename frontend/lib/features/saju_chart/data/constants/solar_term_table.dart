/// 24절기 시각 테이블
/// 한국천문연구원 데이터 기반 (2020-2030년)
/// 데이터 출처: https://holidays.dist.be (공공데이터포털 기반)
/// 2027-2030년: 천문학적 근사식 계산값 (오차 ±30분 이내)
library;

/// 절기 시각 데이터 구조
class SolarTermData {
  final DateTime dateTime;
  final String name;

  const SolarTermData(this.dateTime, this.name);
}

/// 연도별 절기 시각 테이블
/// 실제 사용 시 한국천문연구원 API 또는 정밀 계산 라이브러리 사용 권장
final Map<int, Map<String, SolarTermData>> solarTermTable = {
  // ========== 2020년 (한국천문연구원 데이터) ==========
  2020: {
    'sohan': SolarTermData(DateTime(2020, 1, 6, 6, 30), '소한'),
    'daehan': SolarTermData(DateTime(2020, 1, 20, 23, 55), '대한'),
    'ipchun': SolarTermData(DateTime(2020, 2, 4, 18, 3), '입춘'),
    'usoo': SolarTermData(DateTime(2020, 2, 19, 13, 57), '우수'),
    'gyeongchip': SolarTermData(DateTime(2020, 3, 5, 11, 57), '경칩'),
    'chunbun': SolarTermData(DateTime(2020, 3, 20, 3, 20), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2020, 4, 4, 16, 38), '청명'),
    'gogu': SolarTermData(DateTime(2020, 4, 19, 23, 45), '곡우'),
    'ipha': SolarTermData(DateTime(2020, 5, 5, 9, 51), '입하'),
    'soman': SolarTermData(DateTime(2020, 5, 20, 22, 49), '소만'),
    'mangjong': SolarTermData(DateTime(2020, 6, 5, 13, 58), '망종'),
    'haji': SolarTermData(DateTime(2020, 6, 21, 6, 44), '하지'),
    'soseo': SolarTermData(DateTime(2020, 7, 7, 0, 14), '소서'),
    'daeseo': SolarTermData(DateTime(2020, 7, 22, 17, 37), '대서'),
    'ipchu': SolarTermData(DateTime(2020, 8, 7, 10, 6), '입추'),
    'cheoseo': SolarTermData(DateTime(2020, 8, 23, 0, 45), '처서'),
    'baekro': SolarTermData(DateTime(2020, 9, 7, 13, 8), '백로'),
    'chubeun': SolarTermData(DateTime(2020, 9, 22, 22, 31), '추분'),
    'hanro': SolarTermData(DateTime(2020, 10, 8, 4, 55), '한로'),
    'sanggang': SolarTermData(DateTime(2020, 10, 23, 8, 0), '상강'),
    'ipdong': SolarTermData(DateTime(2020, 11, 7, 8, 14), '입동'),
    'soseol': SolarTermData(DateTime(2020, 11, 22, 5, 40), '소설'),
    'daeseol': SolarTermData(DateTime(2020, 12, 7, 1, 9), '대설'),
    'dongji': SolarTermData(DateTime(2020, 12, 21, 19, 2), '동지'),
  },
  // ========== 2021년 (한국천문연구원 데이터) ==========
  2021: {
    'sohan': SolarTermData(DateTime(2021, 1, 5, 12, 23), '소한'),
    'daehan': SolarTermData(DateTime(2021, 1, 20, 5, 40), '대한'),
    'ipchun': SolarTermData(DateTime(2021, 2, 3, 23, 59), '입춘'),
    'usoo': SolarTermData(DateTime(2021, 2, 18, 19, 44), '우수'),
    'gyeongchip': SolarTermData(DateTime(2021, 3, 5, 17, 54), '경칩'),
    'chunbun': SolarTermData(DateTime(2021, 3, 20, 18, 37), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2021, 4, 4, 22, 35), '청명'),
    'gogu': SolarTermData(DateTime(2021, 4, 20, 5, 33), '곡우'),
    'ipha': SolarTermData(DateTime(2021, 5, 5, 15, 47), '입하'),
    'soman': SolarTermData(DateTime(2021, 5, 21, 4, 37), '소만'),
    'mangjong': SolarTermData(DateTime(2021, 6, 5, 19, 52), '망종'),
    'haji': SolarTermData(DateTime(2021, 6, 21, 12, 32), '하지'),
    'soseo': SolarTermData(DateTime(2021, 7, 7, 6, 5), '소서'),
    'daeseo': SolarTermData(DateTime(2021, 7, 22, 23, 26), '대서'),
    'ipchu': SolarTermData(DateTime(2021, 8, 7, 15, 54), '입추'),
    'cheoseo': SolarTermData(DateTime(2021, 8, 23, 6, 35), '처서'),
    'baekro': SolarTermData(DateTime(2021, 9, 7, 18, 53), '백로'),
    'chubeun': SolarTermData(DateTime(2021, 9, 23, 4, 21), '추분'),
    'hanro': SolarTermData(DateTime(2021, 10, 8, 10, 39), '한로'),
    'sanggang': SolarTermData(DateTime(2021, 10, 23, 13, 51), '상강'),
    'ipdong': SolarTermData(DateTime(2021, 11, 7, 13, 59), '입동'),
    'soseol': SolarTermData(DateTime(2021, 11, 22, 11, 34), '소설'),
    'daeseol': SolarTermData(DateTime(2021, 12, 7, 6, 57), '대설'),
    'dongji': SolarTermData(DateTime(2021, 12, 22, 0, 59), '동지'),
  },
  // ========== 2022년 (한국천문연구원 데이터) ==========
  2022: {
    'sohan': SolarTermData(DateTime(2022, 1, 5, 18, 14), '소한'),
    'daehan': SolarTermData(DateTime(2022, 1, 20, 11, 39), '대한'),
    'ipchun': SolarTermData(DateTime(2022, 2, 4, 5, 51), '입춘'),
    'usoo': SolarTermData(DateTime(2022, 2, 19, 1, 43), '우수'),
    'gyeongchip': SolarTermData(DateTime(2022, 3, 5, 23, 44), '경칩'),
    'chunbun': SolarTermData(DateTime(2022, 3, 21, 0, 33), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2022, 4, 5, 4, 20), '청명'),
    'gogu': SolarTermData(DateTime(2022, 4, 20, 11, 24), '곡우'),
    'ipha': SolarTermData(DateTime(2022, 5, 5, 21, 26), '입하'),
    'soman': SolarTermData(DateTime(2022, 5, 21, 10, 23), '소만'),
    'mangjong': SolarTermData(DateTime(2022, 6, 6, 1, 26), '망종'),
    'haji': SolarTermData(DateTime(2022, 6, 21, 18, 14), '하지'),
    'soseo': SolarTermData(DateTime(2022, 7, 7, 11, 38), '소서'),
    'daeseo': SolarTermData(DateTime(2022, 7, 23, 5, 7), '대서'),
    'ipchu': SolarTermData(DateTime(2022, 8, 7, 21, 29), '입추'),
    'cheoseo': SolarTermData(DateTime(2022, 8, 23, 12, 16), '처서'),
    'baekro': SolarTermData(DateTime(2022, 9, 8, 0, 32), '백로'),
    'chubeun': SolarTermData(DateTime(2022, 9, 23, 10, 4), '추분'),
    'hanro': SolarTermData(DateTime(2022, 10, 8, 16, 22), '한로'),
    'sanggang': SolarTermData(DateTime(2022, 10, 23, 19, 36), '상강'),
    'ipdong': SolarTermData(DateTime(2022, 11, 7, 19, 45), '입동'),
    'soseol': SolarTermData(DateTime(2022, 11, 22, 17, 20), '소설'),
    'daeseol': SolarTermData(DateTime(2022, 12, 7, 12, 46), '대설'),
    'dongji': SolarTermData(DateTime(2022, 12, 22, 6, 48), '동지'),
  },
  // ========== 2023년 (한국천문연구원 데이터) ==========
  2023: {
    'sohan': SolarTermData(DateTime(2023, 1, 6, 0, 5), '소한'),
    'daehan': SolarTermData(DateTime(2023, 1, 20, 17, 30), '대한'),
    'ipchun': SolarTermData(DateTime(2023, 2, 4, 11, 43), '입춘'),
    'usoo': SolarTermData(DateTime(2023, 2, 19, 7, 34), '우수'),
    'gyeongchip': SolarTermData(DateTime(2023, 3, 6, 5, 36), '경칩'),
    'chunbun': SolarTermData(DateTime(2023, 3, 21, 6, 24), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2023, 4, 5, 10, 13), '청명'),
    'gogu': SolarTermData(DateTime(2023, 4, 20, 17, 14), '곡우'),
    'ipha': SolarTermData(DateTime(2023, 5, 6, 3, 19), '입하'),
    'soman': SolarTermData(DateTime(2023, 5, 21, 16, 9), '소만'),
    'mangjong': SolarTermData(DateTime(2023, 6, 6, 7, 18), '망종'),
    'haji': SolarTermData(DateTime(2023, 6, 21, 23, 58), '하지'),
    'soseo': SolarTermData(DateTime(2023, 7, 7, 17, 31), '소서'),
    'daeseo': SolarTermData(DateTime(2023, 7, 23, 10, 50), '대서'),
    'ipchu': SolarTermData(DateTime(2023, 8, 8, 3, 23), '입추'),
    'cheoseo': SolarTermData(DateTime(2023, 8, 23, 18, 1), '처서'),
    'baekro': SolarTermData(DateTime(2023, 9, 8, 6, 27), '백로'),
    'chubeun': SolarTermData(DateTime(2023, 9, 23, 15, 50), '추분'),
    'hanro': SolarTermData(DateTime(2023, 10, 8, 22, 16), '한로'),
    'sanggang': SolarTermData(DateTime(2023, 10, 24, 1, 21), '상강'),
    'ipdong': SolarTermData(DateTime(2023, 11, 8, 1, 36), '입동'),
    'soseol': SolarTermData(DateTime(2023, 11, 22, 23, 3), '소설'),
    'daeseol': SolarTermData(DateTime(2023, 12, 7, 18, 33), '대설'),
    'dongji': SolarTermData(DateTime(2023, 12, 22, 12, 27), '동지'),
  },
  // ========== 2024년 (한국천문연구원 데이터) ==========
  2024: {
    'sohan': SolarTermData(DateTime(2024, 1, 6, 5, 49), '소한'),
    'daehan': SolarTermData(DateTime(2024, 1, 20, 23, 7), '대한'),
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
  // ========== 2025년 (한국천문연구원 데이터) ==========
  2025: {
    'sohan': SolarTermData(DateTime(2025, 1, 5, 11, 33), '소한'),
    'daehan': SolarTermData(DateTime(2025, 1, 20, 4, 59), '대한'),
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
  // ========== 2026년 (한국천문연구원 데이터) ==========
  2026: {
    'sohan': SolarTermData(DateTime(2026, 1, 5, 17, 23), '소한'),
    'daehan': SolarTermData(DateTime(2026, 1, 20, 10, 45), '대한'),
    'ipchun': SolarTermData(DateTime(2026, 2, 4, 5, 2), '입춘'),
    'usoo': SolarTermData(DateTime(2026, 2, 19, 0, 52), '우수'),
    'gyeongchip': SolarTermData(DateTime(2026, 3, 5, 22, 59), '경칩'),
    'chunbun': SolarTermData(DateTime(2026, 3, 20, 23, 46), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2026, 4, 5, 3, 40), '청명'),
    'gogu': SolarTermData(DateTime(2026, 4, 20, 10, 39), '곡우'),
    'ipha': SolarTermData(DateTime(2026, 5, 5, 20, 49), '입하'),
    'soman': SolarTermData(DateTime(2026, 5, 21, 9, 37), '소만'),
    'mangjong': SolarTermData(DateTime(2026, 6, 6, 0, 48), '망종'),
    'haji': SolarTermData(DateTime(2026, 6, 21, 17, 25), '하지'),
    'soseo': SolarTermData(DateTime(2026, 7, 7, 10, 57), '소서'),
    'daeseo': SolarTermData(DateTime(2026, 7, 23, 4, 13), '대서'),
    'ipchu': SolarTermData(DateTime(2026, 8, 7, 20, 43), '입추'),
    'cheoseo': SolarTermData(DateTime(2026, 8, 23, 11, 19), '처서'),
    'baekro': SolarTermData(DateTime(2026, 9, 7, 23, 41), '백로'),
    'chubeun': SolarTermData(DateTime(2026, 9, 23, 9, 5), '추분'),
    'hanro': SolarTermData(DateTime(2026, 10, 8, 15, 29), '한로'),
    'sanggang': SolarTermData(DateTime(2026, 10, 23, 18, 38), '상강'),
    'ipdong': SolarTermData(DateTime(2026, 11, 7, 18, 52), '입동'),
    'soseol': SolarTermData(DateTime(2026, 11, 22, 16, 23), '소설'),
    'daeseol': SolarTermData(DateTime(2026, 12, 7, 11, 53), '대설'),
    'dongji': SolarTermData(DateTime(2026, 12, 22, 5, 50), '동지'),
  },
  // ========== 2027년 (천문학적 근사 계산값) ==========
  2027: {
    'sohan': SolarTermData(DateTime(2027, 1, 5, 23, 10), '소한'),
    'daehan': SolarTermData(DateTime(2027, 1, 20, 16, 30), '대한'),
    'ipchun': SolarTermData(DateTime(2027, 2, 4, 10, 46), '입춘'),
    'usoo': SolarTermData(DateTime(2027, 2, 19, 6, 33), '우수'),
    'gyeongchip': SolarTermData(DateTime(2027, 3, 6, 4, 39), '경칩'),
    'chunbun': SolarTermData(DateTime(2027, 3, 21, 5, 24), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2027, 4, 5, 9, 17), '청명'),
    'gogu': SolarTermData(DateTime(2027, 4, 20, 16, 17), '곡우'),
    'ipha': SolarTermData(DateTime(2027, 5, 6, 2, 25), '입하'),
    'soman': SolarTermData(DateTime(2027, 5, 21, 15, 18), '소만'),
    'mangjong': SolarTermData(DateTime(2027, 6, 6, 6, 26), '망종'),
    'haji': SolarTermData(DateTime(2027, 6, 21, 23, 11), '하지'),
    'soseo': SolarTermData(DateTime(2027, 7, 7, 16, 37), '소서'),
    'daeseo': SolarTermData(DateTime(2027, 7, 23, 9, 54), '대서'),
    'ipchu': SolarTermData(DateTime(2027, 8, 8, 2, 27), '입추'),
    'cheoseo': SolarTermData(DateTime(2027, 8, 23, 17, 14), '처서'),
    'baekro': SolarTermData(DateTime(2027, 9, 8, 5, 28), '백로'),
    'chubeun': SolarTermData(DateTime(2027, 9, 23, 14, 55), '추분'),
    'hanro': SolarTermData(DateTime(2027, 10, 8, 21, 16), '한로'),
    'sanggang': SolarTermData(DateTime(2027, 10, 24, 0, 32), '상강'),
    'ipdong': SolarTermData(DateTime(2027, 11, 8, 0, 38), '입동'),
    'soseol': SolarTermData(DateTime(2027, 11, 22, 22, 15), '소설'),
    'daeseol': SolarTermData(DateTime(2027, 12, 7, 17, 37), '대설'),
    'dongji': SolarTermData(DateTime(2027, 12, 22, 11, 42), '동지'),
  },
  // ========== 2028년 (천문학적 근사 계산값) ==========
  2028: {
    'sohan': SolarTermData(DateTime(2028, 1, 6, 4, 55), '소한'),
    'daehan': SolarTermData(DateTime(2028, 1, 20, 22, 22), '대한'),
    'ipchun': SolarTermData(DateTime(2028, 2, 4, 16, 34), '입춘'),
    'usoo': SolarTermData(DateTime(2028, 2, 19, 12, 25), '우수'),
    'gyeongchip': SolarTermData(DateTime(2028, 3, 5, 10, 24), '경칩'),
    'chunbun': SolarTermData(DateTime(2028, 3, 20, 11, 17), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2028, 4, 4, 15, 3), '청명'),
    'gogu': SolarTermData(DateTime(2028, 4, 19, 22, 9), '곡우'),
    'ipha': SolarTermData(DateTime(2028, 5, 5, 8, 12), '입하'),
    'soman': SolarTermData(DateTime(2028, 5, 20, 21, 9), '소만'),
    'mangjong': SolarTermData(DateTime(2028, 6, 5, 12, 16), '망종'),
    'haji': SolarTermData(DateTime(2028, 6, 21, 5, 2), '하지'),
    'soseo': SolarTermData(DateTime(2028, 7, 6, 22, 30), '소서'),
    'daeseo': SolarTermData(DateTime(2028, 7, 22, 15, 46), '대서'),
    'ipchu': SolarTermData(DateTime(2028, 8, 7, 8, 21), '입추'),
    'cheoseo': SolarTermData(DateTime(2028, 8, 22, 23, 1), '처서'),
    'baekro': SolarTermData(DateTime(2028, 9, 7, 11, 22), '백로'),
    'chubeun': SolarTermData(DateTime(2028, 9, 22, 20, 45), '추분'),
    'hanro': SolarTermData(DateTime(2028, 10, 8, 3, 8), '한로'),
    'sanggang': SolarTermData(DateTime(2028, 10, 23, 6, 14), '상강'),
    'ipdong': SolarTermData(DateTime(2028, 11, 7, 6, 27), '입동'),
    'soseol': SolarTermData(DateTime(2028, 11, 22, 3, 54), '소설'),
    'daeseol': SolarTermData(DateTime(2028, 12, 6, 23, 25), '대설'),
    'dongji': SolarTermData(DateTime(2028, 12, 21, 17, 20), '동지'),
  },
  // ========== 2029년 (천문학적 근사 계산값) ==========
  2029: {
    'sohan': SolarTermData(DateTime(2029, 1, 5, 10, 42), '소한'),
    'daehan': SolarTermData(DateTime(2029, 1, 20, 4, 0), '대한'),
    'ipchun': SolarTermData(DateTime(2029, 2, 3, 22, 20), '입춘'),
    'usoo': SolarTermData(DateTime(2029, 2, 18, 18, 7), '우수'),
    'gyeongchip': SolarTermData(DateTime(2029, 3, 5, 16, 17), '경칩'),
    'chunbun': SolarTermData(DateTime(2029, 3, 20, 17, 1), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2029, 4, 4, 20, 52), '청명'),
    'gogu': SolarTermData(DateTime(2029, 4, 20, 3, 55), '곡우'),
    'ipha': SolarTermData(DateTime(2029, 5, 5, 14, 8), '입하'),
    'soman': SolarTermData(DateTime(2029, 5, 21, 2, 59), '소만'),
    'mangjong': SolarTermData(DateTime(2029, 6, 5, 18, 12), '망종'),
    'haji': SolarTermData(DateTime(2029, 6, 21, 10, 48), '하지'),
    'soseo': SolarTermData(DateTime(2029, 7, 7, 4, 22), '소서'),
    'daeseo': SolarTermData(DateTime(2029, 7, 22, 21, 42), '대서'),
    'ipchu': SolarTermData(DateTime(2029, 8, 7, 14, 12), '입추'),
    'cheoseo': SolarTermData(DateTime(2029, 8, 23, 4, 52), '처서'),
    'baekro': SolarTermData(DateTime(2029, 9, 7, 17, 12), '백로'),
    'chubeun': SolarTermData(DateTime(2029, 9, 23, 2, 38), '추분'),
    'hanro': SolarTermData(DateTime(2029, 10, 8, 9, 0), '한로'),
    'sanggang': SolarTermData(DateTime(2029, 10, 23, 12, 8), '상강'),
    'ipdong': SolarTermData(DateTime(2029, 11, 7, 12, 17), '입동'),
    'soseol': SolarTermData(DateTime(2029, 11, 22, 9, 48), '소설'),
    'daeseol': SolarTermData(DateTime(2029, 12, 7, 5, 13), '대설'),
    'dongji': SolarTermData(DateTime(2029, 12, 21, 23, 14), '동지'),
  },
  // ========== 2030년 (천문학적 근사 계산값) ==========
  2030: {
    'sohan': SolarTermData(DateTime(2030, 1, 5, 16, 32), '소한'),
    'daehan': SolarTermData(DateTime(2030, 1, 20, 9, 55), '대한'),
    'ipchun': SolarTermData(DateTime(2030, 2, 4, 4, 8), '입춘'),
    'usoo': SolarTermData(DateTime(2030, 2, 19, 0, 0), '우수'),
    'gyeongchip': SolarTermData(DateTime(2030, 3, 5, 22, 7), '경칩'),
    'chunbun': SolarTermData(DateTime(2030, 3, 20, 22, 51), '춘분'),
    'cheongmyeong': SolarTermData(DateTime(2030, 4, 5, 2, 40), '청명'),
    'gogu': SolarTermData(DateTime(2030, 4, 20, 9, 44), '곡우'),
    'ipha': SolarTermData(DateTime(2030, 5, 5, 19, 56), '입하'),
    'soman': SolarTermData(DateTime(2030, 5, 21, 8, 41), '소만'),
    'mangjong': SolarTermData(DateTime(2030, 6, 5, 23, 59), '망종'),
    'haji': SolarTermData(DateTime(2030, 6, 21, 16, 31), '하지'),
    'soseo': SolarTermData(DateTime(2030, 7, 7, 10, 10), '소서'),
    'daeseo': SolarTermData(DateTime(2030, 7, 23, 3, 24), '대서'),
    'ipchu': SolarTermData(DateTime(2030, 8, 7, 20, 3), '입추'),
    'cheoseo': SolarTermData(DateTime(2030, 8, 23, 10, 36), '처서'),
    'baekro': SolarTermData(DateTime(2030, 9, 7, 23, 2), '백로'),
    'chubeun': SolarTermData(DateTime(2030, 9, 23, 8, 27), '추분'),
    'hanro': SolarTermData(DateTime(2030, 10, 8, 14, 54), '한로'),
    'sanggang': SolarTermData(DateTime(2030, 10, 23, 18, 0), '상강'),
    'ipdong': SolarTermData(DateTime(2030, 11, 7, 18, 9), '입동'),
    'soseol': SolarTermData(DateTime(2030, 11, 22, 15, 36), '소설'),
    'daeseol': SolarTermData(DateTime(2030, 12, 7, 11, 8), '대설'),
    'dongji': SolarTermData(DateTime(2030, 12, 22, 5, 0), '동지'),
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
