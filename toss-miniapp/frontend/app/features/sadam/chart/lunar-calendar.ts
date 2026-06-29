// Generated from Flutter lunar_data tables. Keep the structure aligned with
// frontend/lib/features/saju_chart/domain/services/lunar_solar_converter.dart.

export type LunarDateParts = {
  year: number;
  month: number;
  day: number;
};

type LunarYearData = {
  leapMonth: number;
  monthDays: number[];
  solarNewYear: LunarDateParts;
};

const LUNAR_MIN_YEAR = 1900;
const LUNAR_MAX_YEAR = 2100;

const lunarDataMap: Record<number, LunarYearData> = {
  1900: { leapMonth: 8, monthDays: [29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 1900, month: 1, day: 31 } },
  1901: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 1901, month: 2, day: 19 } },
  1902: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 1902, month: 2, day: 8 } },
  1903: { leapMonth: 5, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30], solarNewYear: { year: 1903, month: 1, day: 29 } },
  1904: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29], solarNewYear: { year: 1904, month: 2, day: 16 } },
  1905: { leapMonth: 0, monthDays: [30, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1905, month: 2, day: 4 } },
  1906: { leapMonth: 4, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1906, month: 1, day: 25 } },
  1907: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 1907, month: 2, day: 13 } },
  1908: { leapMonth: 0, monthDays: [30, 29, 29, 30, 30, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 1908, month: 2, day: 2 } },
  1909: { leapMonth: 2, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29, 30], solarNewYear: { year: 1909, month: 1, day: 22 } },
  1910: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 1910, month: 2, day: 10 } },
  1911: { leapMonth: 6, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1911, month: 1, day: 30 } },
  1912: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30], solarNewYear: { year: 1912, month: 2, day: 18 } },
  1913: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 1913, month: 2, day: 6 } },
  1914: { leapMonth: 5, monthDays: [30, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 29, 30], solarNewYear: { year: 1914, month: 1, day: 26 } },
  1915: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1915, month: 2, day: 14 } },
  1916: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 1916, month: 2, day: 4 } },
  1917: { leapMonth: 2, monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30, 29], solarNewYear: { year: 1917, month: 1, day: 23 } },
  1918: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29, 30], solarNewYear: { year: 1918, month: 2, day: 11 } },
  1919: { leapMonth: 7, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1919, month: 2, day: 1 } },
  1920: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1920, month: 2, day: 20 } },
  1921: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30], solarNewYear: { year: 1921, month: 2, day: 8 } },
  1922: { leapMonth: 5, monthDays: [30, 29, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30], solarNewYear: { year: 1922, month: 1, day: 28 } },
  1923: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 29, 30], solarNewYear: { year: 1923, month: 2, day: 16 } },
  1924: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29], solarNewYear: { year: 1924, month: 2, day: 5 } },
  1925: { leapMonth: 4, monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], solarNewYear: { year: 1925, month: 1, day: 24 } },
  1926: { leapMonth: 0, monthDays: [29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29], solarNewYear: { year: 1926, month: 2, day: 13 } },
  1927: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1927, month: 2, day: 2 } },
  1928: { leapMonth: 2, monthDays: [29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30, 30], solarNewYear: { year: 1928, month: 1, day: 23 } },
  1929: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 1929, month: 2, day: 10 } },
  1930: { leapMonth: 6, monthDays: [29, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 29], solarNewYear: { year: 1930, month: 1, day: 30 } },
  1931: { leapMonth: 0, monthDays: [30, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 1931, month: 2, day: 17 } },
  1932: { leapMonth: 0, monthDays: [30, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 1932, month: 2, day: 6 } },
  1933: { leapMonth: 5, monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29, 30], solarNewYear: { year: 1933, month: 1, day: 26 } },
  1934: { leapMonth: 0, monthDays: [29, 30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 30], solarNewYear: { year: 1934, month: 2, day: 14 } },
  1935: { leapMonth: 0, monthDays: [29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29], solarNewYear: { year: 1935, month: 2, day: 4 } },
  1936: { leapMonth: 3, monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 1936, month: 1, day: 24 } },
  1937: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 1937, month: 2, day: 11 } },
  1938: { leapMonth: 7, monthDays: [30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 1938, month: 1, day: 31 } },
  1939: { leapMonth: 0, monthDays: [30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1939, month: 2, day: 19 } },
  1940: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 1940, month: 2, day: 8 } },
  1941: { leapMonth: 6, monthDays: [30, 30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 1941, month: 1, day: 27 } },
  1942: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 29, 30], solarNewYear: { year: 1942, month: 2, day: 15 } },
  1943: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 1943, month: 2, day: 5 } },
  1944: { leapMonth: 4, monthDays: [29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1944, month: 1, day: 26 } },
  1945: { leapMonth: 0, monthDays: [29, 29, 30, 29, 29, 30, 29, 30, 30, 30, 29, 30], solarNewYear: { year: 1945, month: 2, day: 13 } },
  1946: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 1946, month: 2, day: 2 } },
  1947: { leapMonth: 2, monthDays: [30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30], solarNewYear: { year: 1947, month: 1, day: 22 } },
  1948: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1948, month: 2, day: 10 } },
  1949: { leapMonth: 7, monthDays: [30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1949, month: 1, day: 29 } },
  1950: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 1950, month: 2, day: 17 } },
  1951: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1951, month: 2, day: 6 } },
  1952: { leapMonth: 5, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1952, month: 1, day: 27 } },
  1953: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1953, month: 2, day: 14 } },
  1954: { leapMonth: 0, monthDays: [29, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1954, month: 2, day: 4 } },
  1955: { leapMonth: 3, monthDays: [30, 29, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 1955, month: 1, day: 24 } },
  1956: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30], solarNewYear: { year: 1956, month: 2, day: 12 } },
  1957: { leapMonth: 8, monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30], solarNewYear: { year: 1957, month: 1, day: 31 } },
  1958: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1958, month: 2, day: 19 } },
  1959: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 1959, month: 2, day: 8 } },
  1960: { leapMonth: 6, monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 1960, month: 1, day: 28 } },
  1961: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], solarNewYear: { year: 1961, month: 2, day: 15 } },
  1962: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29], solarNewYear: { year: 1962, month: 2, day: 5 } },
  1963: { leapMonth: 4, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 1963, month: 1, day: 25 } },
  1964: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 1964, month: 2, day: 13 } },
  1965: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 30], solarNewYear: { year: 1965, month: 2, day: 2 } },
  1966: { leapMonth: 3, monthDays: [29, 30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29], solarNewYear: { year: 1966, month: 1, day: 22 } },
  1967: { leapMonth: 0, monthDays: [30, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1967, month: 2, day: 9 } },
  1968: { leapMonth: 7, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 1968, month: 1, day: 30 } },
  1969: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 1969, month: 2, day: 17 } },
  1970: { leapMonth: 0, monthDays: [30, 29, 29, 30, 30, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 1970, month: 2, day: 6 } },
  1971: { leapMonth: 5, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29, 30], solarNewYear: { year: 1971, month: 1, day: 27 } },
  1972: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 1972, month: 2, day: 15 } },
  1973: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 30, 29], solarNewYear: { year: 1973, month: 2, day: 3 } },
  1974: { leapMonth: 4, monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30], solarNewYear: { year: 1974, month: 1, day: 23 } },
  1975: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 1975, month: 2, day: 11 } },
  1976: { leapMonth: 8, monthDays: [30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 29, 30], solarNewYear: { year: 1976, month: 1, day: 31 } },
  1977: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 29], solarNewYear: { year: 1977, month: 2, day: 18 } },
  1978: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 1978, month: 2, day: 7 } },
  1979: { leapMonth: 6, monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30, 29], solarNewYear: { year: 1979, month: 1, day: 28 } },
  1980: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1980, month: 2, day: 16 } },
  1981: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1981, month: 2, day: 5 } },
  1982: { leapMonth: 4, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1982, month: 1, day: 25 } },
  1983: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30], solarNewYear: { year: 1983, month: 2, day: 13 } },
  1984: { leapMonth: 10, monthDays: [30, 29, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30], solarNewYear: { year: 1984, month: 2, day: 2 } },
  1985: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 1985, month: 2, day: 20 } },
  1986: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29], solarNewYear: { year: 1986, month: 2, day: 9 } },
  1987: { leapMonth: 6, monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], solarNewYear: { year: 1987, month: 1, day: 29 } },
  1988: { leapMonth: 0, monthDays: [29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29], solarNewYear: { year: 1988, month: 2, day: 18 } },
  1989: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 1989, month: 2, day: 6 } },
  1990: { leapMonth: 5, monthDays: [29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30, 30], solarNewYear: { year: 1990, month: 1, day: 27 } },
  1991: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 1991, month: 2, day: 15 } },
  1992: { leapMonth: 0, monthDays: [29, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30], solarNewYear: { year: 1992, month: 2, day: 4 } },
  1993: { leapMonth: 3, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 1993, month: 1, day: 23 } },
  1994: { leapMonth: 0, monthDays: [30, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 1994, month: 2, day: 10 } },
  1995: { leapMonth: 8, monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29, 30], solarNewYear: { year: 1995, month: 1, day: 31 } },
  1996: { leapMonth: 0, monthDays: [29, 30, 29, 30, 30, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 1996, month: 2, day: 19 } },
  1997: { leapMonth: 0, monthDays: [29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29], solarNewYear: { year: 1997, month: 2, day: 8 } },
  1998: { leapMonth: 5, monthDays: [30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 1998, month: 1, day: 28 } },
  1999: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 1999, month: 2, day: 16 } },
  2000: { leapMonth: 0, monthDays: [30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 29], solarNewYear: { year: 2000, month: 2, day: 5 } },
  2001: { leapMonth: 4, monthDays: [30, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2001, month: 1, day: 24 } },
  2002: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 2002, month: 2, day: 12 } },
  2003: { leapMonth: 0, monthDays: [30, 30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 2003, month: 2, day: 1 } },
  2004: { leapMonth: 2, monthDays: [29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2004, month: 1, day: 22 } },
  2005: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 29], solarNewYear: { year: 2005, month: 2, day: 9 } },
  2006: { leapMonth: 7, monthDays: [30, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2006, month: 1, day: 29 } },
  2007: { leapMonth: 0, monthDays: [29, 29, 30, 29, 29, 30, 29, 30, 30, 30, 29, 30], solarNewYear: { year: 2007, month: 2, day: 18 } },
  2008: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 2008, month: 2, day: 7 } },
  2009: { leapMonth: 5, monthDays: [30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30], solarNewYear: { year: 2009, month: 1, day: 26 } },
  2010: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2010, month: 2, day: 14 } },
  2011: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 2011, month: 2, day: 3 } },
  2012: { leapMonth: 3, monthDays: [30, 29, 30, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 2012, month: 1, day: 23 } },
  2013: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2013, month: 2, day: 10 } },
  2014: { leapMonth: 9, monthDays: [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], solarNewYear: { year: 2014, month: 1, day: 31 } },
  2015: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 30, 30, 29, 30, 29], solarNewYear: { year: 2015, month: 2, day: 19 } },
  2016: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2016, month: 2, day: 8 } },
  2017: { leapMonth: 5, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 2017, month: 1, day: 28 } },
  2018: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30], solarNewYear: { year: 2018, month: 2, day: 16 } },
  2019: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2019, month: 2, day: 5 } },
  2020: { leapMonth: 4, monthDays: [30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2020, month: 1, day: 25 } },
  2021: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2021, month: 2, day: 12 } },
  2022: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2022, month: 2, day: 1 } },
  2023: { leapMonth: 2, monthDays: [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], solarNewYear: { year: 2023, month: 1, day: 22 } },
  2024: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29], solarNewYear: { year: 2024, month: 2, day: 10 } },
  2025: { leapMonth: 6, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 2025, month: 1, day: 29 } },
  2026: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 2026, month: 2, day: 17 } },
  2027: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 30], solarNewYear: { year: 2027, month: 2, day: 7 } },
  2028: { leapMonth: 5, monthDays: [29, 30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29], solarNewYear: { year: 2028, month: 1, day: 27 } },
  2029: { leapMonth: 0, monthDays: [30, 30, 29, 30, 30, 29, 29, 30, 29, 29, 30, 30], solarNewYear: { year: 2029, month: 2, day: 13 } },
  2030: { leapMonth: 0, monthDays: [29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2030, month: 2, day: 3 } },
  2031: { leapMonth: 3, monthDays: [30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2031, month: 1, day: 23 } },
  2032: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 2032, month: 2, day: 11 } },
  2033: { leapMonth: 11, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29, 30], solarNewYear: { year: 2033, month: 1, day: 31 } },
  2034: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 2034, month: 2, day: 19 } },
  2035: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30], solarNewYear: { year: 2035, month: 2, day: 8 } },
  2036: { leapMonth: 6, monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30], solarNewYear: { year: 2036, month: 1, day: 28 } },
  2037: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 2037, month: 2, day: 15 } },
  2038: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 29], solarNewYear: { year: 2038, month: 2, day: 4 } },
  2039: { leapMonth: 5, monthDays: [30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 29], solarNewYear: { year: 2039, month: 1, day: 24 } },
  2040: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2040, month: 2, day: 12 } },
  2041: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 2041, month: 2, day: 1 } },
  2042: { leapMonth: 2, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2042, month: 1, day: 22 } },
  2043: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2043, month: 2, day: 10 } },
  2044: { leapMonth: 7, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 2044, month: 1, day: 30 } },
  2045: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30], solarNewYear: { year: 2045, month: 2, day: 17 } },
  2046: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 2046, month: 2, day: 6 } },
  2047: { leapMonth: 5, monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30], solarNewYear: { year: 2047, month: 1, day: 26 } },
  2048: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29], solarNewYear: { year: 2048, month: 2, day: 14 } },
  2049: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30, 29], solarNewYear: { year: 2049, month: 2, day: 2 } },
  2050: { leapMonth: 3, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 30], solarNewYear: { year: 2050, month: 1, day: 23 } },
  2051: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 30, 29, 30, 29, 29, 30, 29], solarNewYear: { year: 2051, month: 2, day: 11 } },
  2052: { leapMonth: 8, monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2052, month: 2, day: 1 } },
  2053: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2053, month: 2, day: 19 } },
  2054: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 2054, month: 2, day: 8 } },
  2055: { leapMonth: 6, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 2055, month: 1, day: 28 } },
  2056: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29], solarNewYear: { year: 2056, month: 2, day: 15 } },
  2057: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2057, month: 2, day: 4 } },
  2058: { leapMonth: 4, monthDays: [30, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 29, 30], solarNewYear: { year: 2058, month: 1, day: 24 } },
  2059: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2059, month: 2, day: 12 } },
  2060: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2060, month: 2, day: 2 } },
  2061: { leapMonth: 3, monthDays: [30, 29, 30, 29, 29, 30, 30, 29, 30, 30, 29, 30, 29], solarNewYear: { year: 2061, month: 1, day: 22 } },
  2062: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2062, month: 2, day: 9 } },
  2063: { leapMonth: 7, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2063, month: 1, day: 29 } },
  2064: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30], solarNewYear: { year: 2064, month: 2, day: 17 } },
  2065: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2065, month: 2, day: 5 } },
  2066: { leapMonth: 5, monthDays: [30, 29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2066, month: 1, day: 26 } },
  2067: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29], solarNewYear: { year: 2067, month: 2, day: 14 } },
  2068: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2068, month: 2, day: 3 } },
  2069: { leapMonth: 4, monthDays: [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], solarNewYear: { year: 2069, month: 1, day: 23 } },
  2070: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 30, 29, 30, 30, 29, 30, 29], solarNewYear: { year: 2070, month: 2, day: 11 } },
  2071: { leapMonth: 8, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29], solarNewYear: { year: 2071, month: 1, day: 31 } },
  2072: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30], solarNewYear: { year: 2072, month: 2, day: 19 } },
  2073: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30], solarNewYear: { year: 2073, month: 2, day: 7 } },
  2074: { leapMonth: 6, monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30], solarNewYear: { year: 2074, month: 1, day: 27 } },
  2075: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2075, month: 2, day: 15 } },
  2076: { leapMonth: 0, monthDays: [29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2076, month: 2, day: 5 } },
  2077: { leapMonth: 4, monthDays: [30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2077, month: 1, day: 24 } },
  2078: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 2078, month: 2, day: 12 } },
  2079: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 2079, month: 2, day: 2 } },
  2080: { leapMonth: 3, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 2080, month: 1, day: 22 } },
  2081: { leapMonth: 0, monthDays: [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29], solarNewYear: { year: 2081, month: 2, day: 9 } },
  2082: { leapMonth: 7, monthDays: [30, 30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2082, month: 1, day: 29 } },
  2083: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2083, month: 2, day: 17 } },
  2084: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2084, month: 2, day: 6 } },
  2085: { leapMonth: 5, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2085, month: 1, day: 26 } },
  2086: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2086, month: 2, day: 14 } },
  2087: { leapMonth: 0, monthDays: [29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 2087, month: 2, day: 3 } },
  2088: { leapMonth: 4, monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 2088, month: 1, day: 24 } },
  2089: { leapMonth: 0, monthDays: [30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29], solarNewYear: { year: 2089, month: 2, day: 11 } },
  2090: { leapMonth: 8, monthDays: [30, 30, 29, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30], solarNewYear: { year: 2090, month: 1, day: 30 } },
  2091: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 29, 29, 30, 30, 29, 30, 30], solarNewYear: { year: 2091, month: 2, day: 18 } },
  2092: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 29, 29, 30, 30, 29, 30], solarNewYear: { year: 2092, month: 2, day: 8 } },
  2093: { leapMonth: 6, monthDays: [30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 30, 29, 30], solarNewYear: { year: 2093, month: 1, day: 27 } },
  2094: { leapMonth: 0, monthDays: [30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 30, 29], solarNewYear: { year: 2094, month: 2, day: 14 } },
  2095: { leapMonth: 0, monthDays: [30, 30, 29, 30, 29, 30, 29, 30, 29, 29, 30, 29], solarNewYear: { year: 2095, month: 2, day: 3 } },
  2096: { leapMonth: 4, monthDays: [30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29], solarNewYear: { year: 2096, month: 1, day: 24 } },
  2097: { leapMonth: 0, monthDays: [30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29], solarNewYear: { year: 2097, month: 2, day: 11 } },
  2098: { leapMonth: 0, monthDays: [29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30], solarNewYear: { year: 2098, month: 2, day: 1 } },
  2099: { leapMonth: 2, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29, 30], solarNewYear: { year: 2099, month: 1, day: 21 } },
  2100: { leapMonth: 0, monthDays: [29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 30, 29], solarNewYear: { year: 2100, month: 2, day: 9 } },
};

function getLunarYearData(year: number) {
  return lunarDataMap[year] ?? null;
}

export function isLunarYearSupported(year: number) {
  return year >= LUNAR_MIN_YEAR && year <= LUNAR_MAX_YEAR;
}

function getMonthIndex(month: number, isLeapMonth: boolean, yearLeapMonth: number) {
  if (yearLeapMonth === 0) return month - 1;
  if (month < yearLeapMonth) return month - 1;
  if (month === yearLeapMonth && !isLeapMonth) return month - 1;
  if (month === yearLeapMonth && isLeapMonth) return month;
  return month;
}

function addDays(parts: LunarDateParts, days: number): LunarDateParts {
  const date = new Date(parts.year, parts.month - 1, parts.day + days);
  return {
    year: date.getFullYear(),
    month: date.getMonth() + 1,
    day: date.getDate(),
  };
}

export function getLeapMonth(year: number) {
  return getLunarYearData(year)?.leapMonth ?? 0;
}

export function getLunarMonthDays(year: number, month: number, isLeapMonth = false) {
  const yearData = getLunarYearData(year);
  if (!yearData) return null;

  const monthIndex = getMonthIndex(month, isLeapMonth, yearData.leapMonth);
  return yearData.monthDays[monthIndex] ?? null;
}

export function lunarToSolar(
  lunarDate: LunarDateParts & { isLeapMonth?: boolean },
): LunarDateParts | null {
  if (!isLunarYearSupported(lunarDate.year)) return null;
  if (lunarDate.month < 1 || lunarDate.month > 12) return null;

  const yearData = getLunarYearData(lunarDate.year);
  if (!yearData) return null;

  const isLeapMonth = lunarDate.isLeapMonth ?? false;
  if (isLeapMonth && yearData.leapMonth !== lunarDate.month) return null;

  const targetMonthIndex = getMonthIndex(lunarDate.month, isLeapMonth, yearData.leapMonth);
  const monthDays = yearData.monthDays[targetMonthIndex];
  if (!monthDays || lunarDate.day < 1 || lunarDate.day > monthDays) return null;

  const totalDays = yearData.monthDays
    .slice(0, targetMonthIndex)
    .reduce((sum, days) => sum + days, 0) + lunarDate.day - 1;

  return addDays(yearData.solarNewYear, totalDays);
}
