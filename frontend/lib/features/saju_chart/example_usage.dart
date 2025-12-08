/// 사주 계산 사용 예제
/// 실제 사용 시 이 파일을 참고하여 구현
library;

import 'saju_chart.dart';

/// 사주 계산 예제
void exampleSajuCalculation() {
  // 서비스 초기화
  final sajuService = SajuCalculationService();

  // 예제: 1990년 5월 15일 오후 3시 30분, 서울 출생
  final birthDateTime = DateTime(1990, 5, 15, 15, 30);

  // 사주 계산
  final sajuChart = sajuService.calculate(
    birthDateTime: birthDateTime,
    birthCity: '서울',
    isLunarCalendar: false, // 양력
    jasiMode: JasiMode.yaJasi, // 야자시 모드 (전통)
    birthTimeUnknown: false, // 출생시간 있음
  );

  // 결과 출력
  print('=== 사주팔자 ===');
  print('사주: ${sajuChart.fullSaju}');
  print('한자: ${sajuChart.fullSajuHanja}');
  print('일간 (나): ${sajuChart.dayMaster}');
  print('');
  print('연주: ${sajuChart.yearPillar.fullName} (${sajuChart.yearPillar.hanja})');
  print('월주: ${sajuChart.monthPillar.fullName} (${sajuChart.monthPillar.hanja})');
  print('일주: ${sajuChart.dayPillar.fullName} (${sajuChart.dayPillar.hanja})');
  if (sajuChart.hourPillar != null) {
    print('시주: ${sajuChart.hourPillar!.fullName} (${sajuChart.hourPillar!.hanja})');
  }
  print('');
  print('=== 보정 정보 ===');
  print('입력 시각: ${sajuChart.birthDateTime}');
  print('보정 시각: ${sajuChart.correctedDateTime}');
  print('출생지: ${sajuChart.birthCity}');
}

/// 출생시간 모를 때 예제
void exampleUnknownBirthTime() {
  final sajuService = SajuCalculationService();

  final birthDateTime = DateTime(1985, 3, 20, 12, 0); // 시간은 무시됨

  final sajuChart = sajuService.calculate(
    birthDateTime: birthDateTime,
    birthCity: '부산',
    isLunarCalendar: false,
    birthTimeUnknown: true, // 출생시간 모름
  );

  print('=== 출생시간 모르는 사주 ===');
  print('사주: ${sajuChart.fullSaju}');
  print('시주 없음: ${sajuChart.hasUnknownBirthTime}');
}

/// 음력 사주 계산 예제
void exampleLunarCalendar() {
  final sajuService = SajuCalculationService();

  // 음력 1988년 4월 15일
  final lunarBirthDate = DateTime(1988, 4, 15, 10, 0);

  final sajuChart = sajuService.calculate(
    birthDateTime: lunarBirthDate,
    birthCity: '대전',
    isLunarCalendar: true, // 음력
    isLeapMonth: false, // 윤달 아님
  );

  print('=== 음력 사주 ===');
  print('사주: ${sajuChart.fullSaju}');
}

/// 자시 처리 예제
void exampleJasiHandling() {
  final sajuService = SajuCalculationService();

  // 23:30 출생 (야자시 vs 조자시 차이)
  final birthDateTime = DateTime(1995, 1, 1, 23, 30);

  // 야자시 모드
  final yaJasiChart = sajuService.calculate(
    birthDateTime: birthDateTime,
    birthCity: '서울',
    isLunarCalendar: false,
    jasiMode: JasiMode.yaJasi,
  );

  // 조자시 모드
  final joJasiChart = sajuService.calculate(
    birthDateTime: birthDateTime,
    birthCity: '서울',
    isLunarCalendar: false,
    jasiMode: JasiMode.joJasi,
  );

  print('=== 자시 처리 비교 ===');
  print('야자시: ${yaJasiChart.dayPillar.fullName}');
  print('조자시: ${joJasiChart.dayPillar.fullName}');
}

/// JSON 직렬화 예제
void exampleJsonSerialization() {
  final sajuService = SajuCalculationService();

  final birthDateTime = DateTime(2000, 12, 25, 14, 30);
  final sajuChart = sajuService.calculate(
    birthDateTime: birthDateTime,
    birthCity: '인천',
    isLunarCalendar: false,
  );

  // SajuChart를 JSON으로
  final json = sajuChart.toJson();
  print('JSON: $json');

  // JSON에서 SajuChart로
  final restored = SajuChart.fromJson(json);
  print('복원된 사주: ${restored.fullSaju}');
}
