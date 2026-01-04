import 'lunar_year_data.dart';

/// 음력 데이터 테이블 (2000-2050년)
/// 한국천문연구원(KASI) 데이터 기반 - korean-lunar-calendar 라이브러리 검증
/// 2024-01-04 전체 재생성
final List<LunarYearData> lunarTable2000_2050 = [
  // 2000년
  LunarYearData(
    year: 2000,
    leapMonth: 0,
    monthDays: [30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 29],
    solarNewYear: DateTime(2000, 2, 5),
  ),
  // 2001년 - 윤4월
  LunarYearData(
    year: 2001,
    leapMonth: 4,
    monthDays: [30, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2001, 1, 24),
  ),
  // 2002년
  LunarYearData(
    year: 2002,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2002, 2, 12),
  ),
  // 2003년
  LunarYearData(
    year: 2003,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30],
    solarNewYear: DateTime(2003, 2, 1),
  ),
  // 2004년 - 윤2월
  LunarYearData(
    year: 2004,
    leapMonth: 2,
    monthDays: [29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2004, 1, 22),
  ),
  // 2005년
  LunarYearData(
    year: 2005,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 29],
    solarNewYear: DateTime(2005, 2, 9),
  ),
  // 2006년 - 윤7월
  LunarYearData(
    year: 2006,
    leapMonth: 7,
    monthDays: [30, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2006, 1, 29),
  ),
  // 2007년
  LunarYearData(
    year: 2007,
    leapMonth: 0,
    monthDays: [29, 29, 30, 29, 29, 30, 29, 30, 30, 30, 29, 30],
    solarNewYear: DateTime(2007, 2, 18),
  ),
  // 2008년
  LunarYearData(
    year: 2008,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2008, 2, 7),
  ),
  // 2009년 - 윤5월
  LunarYearData(
    year: 2009,
    leapMonth: 5,
    monthDays: [30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(2009, 1, 26),
  ),
  // 2010년
  LunarYearData(
    year: 2010,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2010, 2, 14),
  ),
  // 2011년
  LunarYearData(
    year: 2011,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2011, 2, 3),
  ),
  // 2012년 - 윤3월
  LunarYearData(
    year: 2012,
    leapMonth: 3,
    monthDays: [30, 29, 30, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2012, 1, 23),
  ),
  // 2013년
  LunarYearData(
    year: 2013,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2013, 2, 10),
  ),
  // 2014년 - 윤9월
  LunarYearData(
    year: 2014,
    leapMonth: 9,
    monthDays: [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2014, 1, 31),
  ),
  // 2015년
  LunarYearData(
    year: 2015,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 30, 30, 29, 30, 29],
    solarNewYear: DateTime(2015, 2, 19),
  ),
  // 2016년
  LunarYearData(
    year: 2016,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2016, 2, 8),
  ),
  // 2017년 - 윤5월
  LunarYearData(
    year: 2017,
    leapMonth: 5,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(2017, 1, 28),
  ),
  // 2018년
  LunarYearData(
    year: 2018,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(2018, 2, 16),
  ),
  // 2019년
  LunarYearData(
    year: 2019,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2019, 2, 5),
  ),
  // 2020년 - 윤4월
  LunarYearData(
    year: 2020,
    leapMonth: 4,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2020, 1, 25),
  ),
  // 2021년
  LunarYearData(
    year: 2021,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2021, 2, 12),
  ),
  // 2022년
  LunarYearData(
    year: 2022,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2022, 2, 1),
  ),
  // 2023년 - 윤2월
  LunarYearData(
    year: 2023,
    leapMonth: 2,
    monthDays: [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2023, 1, 22),
  ),
  // 2024년
  LunarYearData(
    year: 2024,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29],
    solarNewYear: DateTime(2024, 2, 10),
  ),
  // 2025년 - 윤6월
  LunarYearData(
    year: 2025,
    leapMonth: 6,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(2025, 1, 29),
  ),
  // 2026년
  LunarYearData(
    year: 2026,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(2026, 2, 17),
  ),
  // 2027년
  LunarYearData(
    year: 2027,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 30],
    solarNewYear: DateTime(2027, 2, 7),
  ),
  // 2028년 - 윤5월
  LunarYearData(
    year: 2028,
    leapMonth: 5,
    monthDays: [29, 30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29],
    solarNewYear: DateTime(2028, 1, 27),
  ),
  // 2029년
  LunarYearData(
    year: 2029,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 30, 29, 29, 30, 29, 29, 30, 30],
    solarNewYear: DateTime(2029, 2, 13),
  ),
  // 2030년
  LunarYearData(
    year: 2030,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2030, 2, 3),
  ),
  // 2031년 - 윤3월
  LunarYearData(
    year: 2031,
    leapMonth: 3,
    monthDays: [30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2031, 1, 23),
  ),
  // 2032년
  LunarYearData(
    year: 2032,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2032, 2, 11),
  ),
  // 2033년 - 윤11월
  LunarYearData(
    year: 2033,
    leapMonth: 11,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29, 30],
    solarNewYear: DateTime(2033, 1, 31),
  ),
  // 2034년
  LunarYearData(
    year: 2034,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(2034, 2, 19),
  ),
  // 2035년
  LunarYearData(
    year: 2035,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2035, 2, 8),
  ),
  // 2036년 - 윤6월
  LunarYearData(
    year: 2036,
    leapMonth: 6,
    monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2036, 1, 28),
  ),
  // 2037년
  LunarYearData(
    year: 2037,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30],
    solarNewYear: DateTime(2037, 2, 15),
  ),
  // 2038년
  LunarYearData(
    year: 2038,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 29],
    solarNewYear: DateTime(2038, 2, 4),
  ),
  // 2039년 - 윤5월
  LunarYearData(
    year: 2039,
    leapMonth: 5,
    monthDays: [30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 29],
    solarNewYear: DateTime(2039, 1, 24),
  ),
  // 2040년
  LunarYearData(
    year: 2040,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2040, 2, 12),
  ),
  // 2041년
  LunarYearData(
    year: 2041,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2041, 2, 1),
  ),
  // 2042년 - 윤2월
  LunarYearData(
    year: 2042,
    leapMonth: 2,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2042, 1, 22),
  ),
  // 2043년
  LunarYearData(
    year: 2043,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2043, 2, 10),
  ),
  // 2044년 - 윤7월
  LunarYearData(
    year: 2044,
    leapMonth: 7,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(2044, 1, 30),
  ),
  // 2045년
  LunarYearData(
    year: 2045,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(2045, 2, 17),
  ),
  // 2046년
  LunarYearData(
    year: 2046,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30],
    solarNewYear: DateTime(2046, 2, 6),
  ),
  // 2047년 - 윤5월
  LunarYearData(
    year: 2047,
    leapMonth: 5,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30],
    solarNewYear: DateTime(2047, 1, 26),
  ),
  // 2048년
  LunarYearData(
    year: 2048,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29],
    solarNewYear: DateTime(2048, 2, 14),
  ),
  // 2049년
  LunarYearData(
    year: 2049,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30, 29],
    solarNewYear: DateTime(2049, 2, 2),
  ),
  // 2050년 - 윤3월
  // Note: korean-lunar-calendar 라이브러리 2050년 데이터 불완전
  // 기존 데이터 유지하되 추후 KASI 공식 데이터로 검증 필요
  LunarYearData(
    year: 2050,
    leapMonth: 3,
    monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(2050, 1, 23),
  ),
];
