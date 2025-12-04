import 'lunar_year_data.dart';

/// 음력 데이터 테이블 (1950-1999년)
/// 한국천문연구원 데이터 기반
const List<LunarYearData> lunarTable1950_1999 = [
  // 1950년
  LunarYearData(
    year: 1950,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1950, 2, 17),
  ),
  // 1951년
  LunarYearData(
    year: 1951,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(1951, 2, 6),
  ),
  // 1952년 - 윤5월
  LunarYearData(
    year: 1952,
    leapMonth: 5,
    monthDays: [30, 29, 30, 29, 29, 30, 30, 29, 30, 30, 29, 30, 29],
    solarNewYear: DateTime(1952, 1, 27),
  ),
  // 1953년
  LunarYearData(
    year: 1953,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(1953, 2, 14),
  ),
  // 1954년
  LunarYearData(
    year: 1954,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(1954, 2, 3),
  ),
  // 1955년 - 윤3월
  LunarYearData(
    year: 1955,
    leapMonth: 3,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(1955, 1, 24),
  ),
  // 1956년
  LunarYearData(
    year: 1956,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1956, 2, 12),
  ),
  // 1957년 - 윤8월
  LunarYearData(
    year: 1957,
    leapMonth: 8,
    monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1957, 1, 31),
  ),
  // 1958년
  LunarYearData(
    year: 1958,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(1958, 2, 18),
  ),
  // 1959년
  LunarYearData(
    year: 1959,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1959, 2, 8),
  ),
  // 1960년 - 윤6월
  LunarYearData(
    year: 1960,
    leapMonth: 6,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(1960, 1, 28),
  ),
  // 1961년
  LunarYearData(
    year: 1961,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(1961, 2, 15),
  ),
  // 1962년
  LunarYearData(
    year: 1962,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 30, 29],
    solarNewYear: DateTime(1962, 2, 5),
  ),
  // 1963년 - 윤4월
  LunarYearData(
    year: 1963,
    leapMonth: 4,
    monthDays: [30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1963, 1, 25),
  ),
  // 1964년
  LunarYearData(
    year: 1964,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29],
    solarNewYear: DateTime(1964, 2, 13),
  ),
  // 1965년
  LunarYearData(
    year: 1965,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(1965, 2, 2),
  ),
  // 1966년 - 윤3월
  LunarYearData(
    year: 1966,
    leapMonth: 3,
    monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30, 29],
    solarNewYear: DateTime(1966, 1, 21),
  ),
  // 1967년
  LunarYearData(
    year: 1967,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(1967, 2, 9),
  ),
  // 1968년 - 윤7월
  LunarYearData(
    year: 1968,
    leapMonth: 7,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(1968, 1, 30),
  ),
  // 1969년
  LunarYearData(
    year: 1969,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(1969, 2, 17),
  ),
  // 1970년
  LunarYearData(
    year: 1970,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(1970, 2, 6),
  ),
  // 1971년 - 윤5월
  LunarYearData(
    year: 1971,
    leapMonth: 5,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(1971, 1, 27),
  ),
  // 1972년
  LunarYearData(
    year: 1972,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(1972, 2, 15),
  ),
  // 1973년
  LunarYearData(
    year: 1973,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30],
    solarNewYear: DateTime(1973, 2, 3),
  ),
  // 1974년 - 윤4월
  LunarYearData(
    year: 1974,
    leapMonth: 4,
    monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 30],
    solarNewYear: DateTime(1974, 1, 23),
  ),
  // 1975년
  LunarYearData(
    year: 1975,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29],
    solarNewYear: DateTime(1975, 2, 11),
  ),
  // 1976년 - 윤8월
  LunarYearData(
    year: 1976,
    leapMonth: 8,
    monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 30, 29, 29],
    solarNewYear: DateTime(1976, 1, 31),
  ),
  // 1977년
  LunarYearData(
    year: 1977,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29],
    solarNewYear: DateTime(1977, 2, 18),
  ),
  // 1978년
  LunarYearData(
    year: 1978,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(1978, 2, 7),
  ),
  // 1979년 - 윤6월
  LunarYearData(
    year: 1979,
    leapMonth: 6,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(1979, 1, 28),
  ),
  // 1980년
  LunarYearData(
    year: 1980,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(1980, 2, 16),
  ),
  // 1981년
  LunarYearData(
    year: 1981,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1981, 2, 5),
  ),
  // 1982년 - 윤4월
  LunarYearData(
    year: 1982,
    leapMonth: 4,
    monthDays: [30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 29, 30, 30],
    solarNewYear: DateTime(1982, 1, 25),
  ),
  // 1983년
  LunarYearData(
    year: 1983,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(1983, 2, 13),
  ),
  // 1984년 - 윤10월
  LunarYearData(
    year: 1984,
    leapMonth: 10,
    monthDays: [30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(1984, 2, 2),
  ),
  // 1985년
  LunarYearData(
    year: 1985,
    leapMonth: 0,
    monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(1985, 2, 20),
  ),
  // 1986년
  LunarYearData(
    year: 1986,
    leapMonth: 0,
    monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29],
    solarNewYear: DateTime(1986, 2, 9),
  ),
  // 1987년 - 윤6월
  LunarYearData(
    year: 1987,
    leapMonth: 6,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30],
    solarNewYear: DateTime(1987, 1, 29),
  ),
  // 1988년
  LunarYearData(
    year: 1988,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1988, 2, 17),
  ),
  // 1989년
  LunarYearData(
    year: 1989,
    leapMonth: 0,
    monthDays: [30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(1989, 2, 6),
  ),
  // 1990년 - 윤5월
  LunarYearData(
    year: 1990,
    leapMonth: 5,
    monthDays: [30, 30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30],
    solarNewYear: DateTime(1990, 1, 27),
  ),
  // 1991년
  LunarYearData(
    year: 1991,
    leapMonth: 0,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1991, 2, 15),
  ),
  // 1992년
  LunarYearData(
    year: 1992,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29],
    solarNewYear: DateTime(1992, 2, 4),
  ),
  // 1993년 - 윤3월
  LunarYearData(
    year: 1993,
    leapMonth: 3,
    monthDays: [30, 29, 30, 29, 29, 30, 30, 29, 30, 30, 29, 30, 29],
    solarNewYear: DateTime(1993, 1, 23),
  ),
  // 1994년
  LunarYearData(
    year: 1994,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30],
    solarNewYear: DateTime(1994, 2, 10),
  ),
  // 1995년 - 윤8월
  LunarYearData(
    year: 1995,
    leapMonth: 8,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30],
    solarNewYear: DateTime(1995, 1, 31),
  ),
  // 1996년
  LunarYearData(
    year: 1996,
    leapMonth: 0,
    monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30],
    solarNewYear: DateTime(1996, 2, 19),
  ),
  // 1997년
  LunarYearData(
    year: 1997,
    leapMonth: 0,
    monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1997, 2, 7),
  ),
  // 1998년 - 윤5월
  LunarYearData(
    year: 1998,
    leapMonth: 5,
    monthDays: [30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30],
    solarNewYear: DateTime(1998, 1, 28),
  ),
  // 1999년
  LunarYearData(
    year: 1999,
    leapMonth: 0,
    monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 29, 30, 29],
    solarNewYear: DateTime(1999, 2, 16),
  ),
];
