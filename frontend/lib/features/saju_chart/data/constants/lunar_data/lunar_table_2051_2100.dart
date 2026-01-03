import 'lunar_year_data.dart';

/// 음력 데이터 테이블 (2051-2100년)
/// 한국천문연구원 데이터 기반 (미래 예측치)
final List<LunarYearData> lunarTable2051_2100 = [
  // 2051년
  LunarYearData(
    year: 2051,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 29, 30, 29],
    solarNewYear: DateTime(2051, 2, 11),
  ),
  // 2052년 - 윤8월
  LunarYearData(
    year: 2052,
    leapMonth: 8,
    monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2052, 2, 1),
  ),
  // 2053년
  LunarYearData(
    year: 2053,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2053, 2, 19),
  ),
  // 2054년
  LunarYearData(
    year: 2054,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(2054, 2, 8),
  ),
  // 2055년 - 윤6월
  LunarYearData(
    year: 2055,
    leapMonth: 6,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2055, 1, 28),
  ),
  // 2056년
  LunarYearData(
    year: 2056,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29],
    solarNewYear: DateTime(2056, 2, 15),
  ),
  // 2057년
  LunarYearData(
    year: 2057,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2057, 2, 4),
  ),
  // 2058년 - 윤4월
  LunarYearData(
    year: 2058,
    leapMonth: 4,
    monthDays: [30, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 29, 30],
    solarNewYear: DateTime(2058, 1, 24),
  ),
  // 2059년
  LunarYearData(
    year: 2059,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2059, 2, 12),
  ),
  // 2060년
  LunarYearData(
    year: 2060,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2060, 2, 2),
  ),
  // 2061년 - 윤3월 - 한국 기준 (KASI)
  // 주의: 합삭이 1월 22일 0시 14분으로, 한국은 1월 22일, 중국은 1월 21일 설날
  LunarYearData(
    year: 2061,
    leapMonth: 3,
    monthDays: [30, 29, 30, 29, 29, 30, 30, 29, 30, 30, 29, 30, 29],
    solarNewYear: DateTime(2061, 1, 22),  // 수정: 1월 21일 → 1월 22일 (한국 기준)
  ),
  // 2062년
  LunarYearData(
    year: 2062,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2062, 2, 9),
  ),
  // 2063년 - 윤7월
  LunarYearData(
    year: 2063,
    leapMonth: 7,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2063, 1, 29),
  ),
  // 2064년
  LunarYearData(
    year: 2064,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(2064, 2, 17),
  ),
  // 2065년
  LunarYearData(
    year: 2065,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2065, 2, 5),
  ),
  // 2066년 - 윤5월
  LunarYearData(
    year: 2066,
    leapMonth: 5,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2066, 1, 26),
  ),
  // 2067년
  LunarYearData(
    year: 2067,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2067, 2, 14),
  ),
  // 2068년
  LunarYearData(
    year: 2068,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2068, 2, 3),
  ),
  // 2069년 - 윤4월
  LunarYearData(
    year: 2069,
    leapMonth: 4,
    monthDays: [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2069, 1, 23),
  ),
  // 2070년
  LunarYearData(
    year: 2070,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 30, 29, 30, 30, 29, 30, 29],
    solarNewYear: DateTime(2070, 2, 11),
  ),
  // 2071년 - 윤8월
  LunarYearData(
    year: 2071,
    leapMonth: 8,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29],
    solarNewYear: DateTime(2071, 1, 31),
  ),
  // 2072년
  LunarYearData(
    year: 2072,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(2072, 2, 19),
  ),
  // 2073년
  LunarYearData(
    year: 2073,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(2073, 2, 7),
  ),
  // 2074년 - 윤6월
  LunarYearData(
    year: 2074,
    leapMonth: 6,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(2074, 1, 27),
  ),
  // 2075년
  LunarYearData(
    year: 2075,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2075, 2, 15),
  ),
  // 2076년
  LunarYearData(
    year: 2076,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2076, 2, 5),
  ),
  // 2077년 - 윤4월
  LunarYearData(
    year: 2077,
    leapMonth: 4,
    monthDays: [30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2077, 1, 24),
  ),
  // 2078년
  LunarYearData(
    year: 2078,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2078, 2, 12),
  ),
  // 2079년
  LunarYearData(
    year: 2079,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(2079, 2, 2),
  ),
  // 2080년 - 윤3월
  LunarYearData(
    year: 2080,
    leapMonth: 3,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2080, 1, 22),
  ),
  // 2081년
  LunarYearData(
    year: 2081,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29],
    solarNewYear: DateTime(2081, 2, 9),
  ),
  // 2082년 - 윤7월
  LunarYearData(
    year: 2082,
    leapMonth: 7,
    monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2082, 1, 29),
  ),
  // 2083년
  LunarYearData(
    year: 2083,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2083, 2, 17),
  ),
  // 2084년
  LunarYearData(
    year: 2084,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2084, 2, 6),
  ),
  // 2085년 - 윤5월
  LunarYearData(
    year: 2085,
    leapMonth: 5,
    monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2085, 1, 26),
  ),
  // 2086년
  LunarYearData(
    year: 2086,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2086, 2, 14),
  ),
  // 2087년
  LunarYearData(
    year: 2087,
    leapMonth: 0,
    monthDays: [29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(2087, 2, 3),
  ),
  // 2088년 - 윤4월
  LunarYearData(
    year: 2088,
    leapMonth: 4,
    monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2088, 1, 24),
  ),
  // 2089년 - 한국 기준 (KASI)
  // 주의: 합삭이 2월 11일 0시 14분으로, 한국은 2월 11일, 중국은 2월 10일 설날
  LunarYearData(
    year: 2089,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29],
    solarNewYear: DateTime(2089, 2, 11),  // 수정: 2월 10일 → 2월 11일 (한국 기준)
  ),
  // 2090년 - 윤8월
  LunarYearData(
    year: 2090,
    leapMonth: 8,
    monthDays: [30, 30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(2090, 1, 30),
  ),
  // 2091년
  LunarYearData(
    year: 2091,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(2091, 2, 18),
  ),
  // 2092년 - 한국 기준 (KASI)
  // 주의: 합삭이 2월 8일 0시 2분으로, 한국은 2월 8일, 중국은 2월 7일 설날
  LunarYearData(
    year: 2092,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 30, 29, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2092, 2, 8),  // 수정: 2월 7일 → 2월 8일 (한국 기준)
  ),
  // 2093년 - 윤6월
  LunarYearData(
    year: 2093,
    leapMonth: 6,
    monthDays: [30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2093, 1, 27),
  ),
  // 2094년
  LunarYearData(
    year: 2094,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 30, 29],
    solarNewYear: DateTime(2094, 2, 14),
  ),
  // 2095년
  LunarYearData(
    year: 2095,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 29],
    solarNewYear: DateTime(2095, 2, 3),
  ),
  // 2096년 - 윤4월
  LunarYearData(
    year: 2096,
    leapMonth: 4,
    monthDays: [30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29],
    solarNewYear: DateTime(2096, 1, 24),
  ),
  // 2097년
  LunarYearData(
    year: 2097,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(2097, 2, 11),
  ),
  // 2098년
  LunarYearData(
    year: 2098,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(2098, 2, 1),
  ),
  // 2099년 - 윤2월
  LunarYearData(
    year: 2099,
    leapMonth: 2,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29, 30],
    solarNewYear: DateTime(2099, 1, 21),
  ),
  // 2100년
  LunarYearData(
    year: 2100,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(2100, 2, 9),
  ),
];
