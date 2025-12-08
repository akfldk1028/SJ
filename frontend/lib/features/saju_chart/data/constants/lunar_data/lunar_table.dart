/// 음력 데이터 테이블 통합 모듈
/// 1900-2100년 데이터를 통합 제공
library;

export 'lunar_year_data.dart';
export 'lunar_table_1900_1949.dart';
export 'lunar_table_1950_1999.dart';
export 'lunar_table_2000_2050.dart';
export 'lunar_table_2051_2100.dart';

import 'lunar_year_data.dart';
import 'lunar_table_1900_1949.dart';
import 'lunar_table_1950_1999.dart';
import 'lunar_table_2000_2050.dart';
import 'lunar_table_2051_2100.dart';

/// 전체 음력 데이터 테이블 (1900-2100년)
/// 연도를 키로 빠른 조회 가능
final Map<int, LunarYearData> lunarDataMap = {
  for (final data in lunarTable1900_1949) data.year: data,
  for (final data in lunarTable1950_1999) data.year: data,
  for (final data in lunarTable2000_2050) data.year: data,
  for (final data in lunarTable2051_2100) data.year: data,
};

/// 지원 연도 범위
const int lunarMinYear = 1900;
const int lunarMaxYear = 2100;

/// 연도별 음력 데이터 조회
LunarYearData? getLunarYearData(int year) {
  return lunarDataMap[year];
}

/// 지원 범위 내 연도인지 확인
bool isYearSupported(int year) {
  return year >= lunarMinYear && year <= lunarMaxYear;
}
