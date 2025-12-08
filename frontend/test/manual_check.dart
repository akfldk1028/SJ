import 'package:frontend/features/saju_chart/domain/services/saju_calculation_service.dart';
import 'package:frontend/features/saju_chart/domain/services/jasi_service.dart'; // JasiMode defined here

void main() {
  final service = SajuCalculationService();

  final result = service.calculate(
    birthDateTime: DateTime(1990, 2, 15, 9, 30),
    birthCity: '서울',
    isLunarCalendar: false, // 양력
    isLeapMonth: false,
    jasiMode: JasiMode.yaJasi,
  );

  print('\n[Manual Verification]');
  print('Result:');
  print('Year: ${result.yearPillar.fullName}');
  print('Month: ${result.monthPillar.fullName}');
  print('Day: ${result.dayPillar.fullName}');
  print('Hour: ${result.hourPillar?.fullName}');
}
