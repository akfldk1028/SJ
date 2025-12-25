/// 길성(吉星) 서비스
/// 각 기둥(시/일/월/년)별로 해당하는 특수 신살(길신/흉신) 목록을 수집
///
/// Phase 16-B: 포스텔러 스타일 "길성" 행 표시를 위한 서비스
library;

import '../../data/constants/twelve_sinsal.dart';
import '../entities/saju_chart.dart';

// ============================================================================
// 기둥별 길성 결과 모델
// ============================================================================

/// 단일 기둥의 길성 분석 결과
class PillarGilseongResult {
  /// 기둥 이름 (년주/월주/일주/시주)
  final String pillarName;

  /// 천간
  final String gan;

  /// 지지
  final String ji;

  /// 해당 기둥에서 발견된 특수 신살 목록
  final List<SpecialSinsal> sinsals;

  const PillarGilseongResult({
    required this.pillarName,
    required this.gan,
    required this.ji,
    required this.sinsals,
  });

  /// 길성만 필터링
  List<SpecialSinsal> get goodSinsals =>
      sinsals.where((s) => s.isGood).toList();

  /// 흉성만 필터링
  List<SpecialSinsal> get badSinsals =>
      sinsals.where((s) => s.isBad).toList();

  /// 혼합 신살만 필터링
  List<SpecialSinsal> get mixedSinsals =>
      sinsals.where((s) => s.fortuneType == SinsalFortuneType.mixed).toList();

  /// 신살이 있는지 여부
  bool get hasSinsals => sinsals.isNotEmpty;

  /// 길성이 있는지 여부
  bool get hasGoodSinsals => goodSinsals.isNotEmpty;

  /// 흉성이 있는지 여부
  bool get hasBadSinsals => badSinsals.isNotEmpty;
}

/// 사주 전체 길성 분석 결과
class GilseongAnalysisResult {
  /// 년주 길성 결과
  final PillarGilseongResult yearResult;

  /// 월주 길성 결과
  final PillarGilseongResult monthResult;

  /// 일주 길성 결과
  final PillarGilseongResult dayResult;

  /// 시주 길성 결과 (시간 모를 경우 null)
  final PillarGilseongResult? hourResult;

  /// 사주 전체에서 발견된 특수 신살 (중복 제거)
  final List<SpecialSinsal> allUniqueSinsals;

  /// 귀문관살 여부 (사주 전체에서 인신사해 2개 이상)
  final bool hasGwiMunGwanSal;

  const GilseongAnalysisResult({
    required this.yearResult,
    required this.monthResult,
    required this.dayResult,
    this.hourResult,
    required this.allUniqueSinsals,
    required this.hasGwiMunGwanSal,
  });

  /// 모든 기둥 결과 리스트
  List<PillarGilseongResult> get allResults => [
        yearResult,
        monthResult,
        dayResult,
        if (hourResult != null) hourResult!,
      ];

  /// 전체 길성 개수
  int get totalGoodCount =>
      allResults.fold(0, (sum, r) => sum + r.goodSinsals.length);

  /// 전체 흉성 개수
  int get totalBadCount =>
      allResults.fold(0, (sum, r) => sum + r.badSinsals.length);

  /// 전체 신살 개수 (중복 포함)
  int get totalSinsalCount =>
      allResults.fold(0, (sum, r) => sum + r.sinsals.length);

  /// 요약 문자열 (포스텔러 스타일)
  String get summary {
    final names = allUniqueSinsals.map((s) => s.korean).toList();
    if (names.isEmpty) return '특수 신살 없음';
    return names.join(', ');
  }
}

// ============================================================================
// 길성 서비스
// ============================================================================

/// 길성 서비스 - 기둥별 특수 신살 분석
class GilseongService {
  /// 사주 차트에서 길성 분석
  static GilseongAnalysisResult analyzeFromChart(SajuChart chart) {
    final dayGan = chart.dayPillar.gan;
    final monthJi = chart.monthPillar.ji;

    // 모든 지지 목록 (귀문관살 체크용)
    final allJis = [
      chart.yearPillar.ji,
      chart.monthPillar.ji,
      chart.dayPillar.ji,
      if (chart.hourPillar != null) chart.hourPillar!.ji,
    ];

    // 귀문관살 여부
    final hasGwiMunGwanSal = isGwiMunGwanSal(allJis);

    // 각 기둥 분석
    final yearResult = _analyzePillar(
      pillarName: '년주',
      gan: chart.yearPillar.gan,
      ji: chart.yearPillar.ji,
      dayGan: dayGan,
      monthJi: monthJi,
      allJis: allJis,
      hasGwiMunGwanSal: hasGwiMunGwanSal,
    );

    final monthResult = _analyzePillar(
      pillarName: '월주',
      gan: chart.monthPillar.gan,
      ji: chart.monthPillar.ji,
      dayGan: dayGan,
      monthJi: monthJi,
      allJis: allJis,
      hasGwiMunGwanSal: hasGwiMunGwanSal,
    );

    final dayResult = _analyzePillar(
      pillarName: '일주',
      gan: chart.dayPillar.gan,
      ji: chart.dayPillar.ji,
      dayGan: dayGan,
      monthJi: monthJi,
      allJis: allJis,
      hasGwiMunGwanSal: hasGwiMunGwanSal,
      isDayPillar: true,
    );

    PillarGilseongResult? hourResult;
    if (chart.hourPillar != null) {
      hourResult = _analyzePillar(
        pillarName: '시주',
        gan: chart.hourPillar!.gan,
        ji: chart.hourPillar!.ji,
        dayGan: dayGan,
        monthJi: monthJi,
        allJis: allJis,
        hasGwiMunGwanSal: hasGwiMunGwanSal,
      );
    }

    // 전체 고유 신살 수집
    final allSinsals = <SpecialSinsal>{};
    for (final result in [yearResult, monthResult, dayResult, if (hourResult != null) hourResult]) {
      allSinsals.addAll(result.sinsals);
    }

    return GilseongAnalysisResult(
      yearResult: yearResult,
      monthResult: monthResult,
      dayResult: dayResult,
      hourResult: hourResult,
      allUniqueSinsals: allSinsals.toList(),
      hasGwiMunGwanSal: hasGwiMunGwanSal,
    );
  }

  /// 개별 기둥 분석
  static PillarGilseongResult _analyzePillar({
    required String pillarName,
    required String gan,
    required String ji,
    required String dayGan,
    required String monthJi,
    required List<String> allJis,
    required bool hasGwiMunGwanSal,
    bool isDayPillar = false,
  }) {
    final sinsals = <SpecialSinsal>[];

    // 1. 천을귀인 (일간 기준)
    if (isCheonEulGwin(dayGan, ji)) {
      sinsals.add(SpecialSinsal.cheoneulgwin);
    }

    // 2. 양인살 (일간 기준)
    if (isYangIn(dayGan, ji)) {
      sinsals.add(SpecialSinsal.yangin);
    }

    // 3. 백호대살 (일주만)
    if (isDayPillar && isBaekHoDaeSal(gan, ji)) {
      sinsals.add(SpecialSinsal.baekhodaesal);
    }

    // 4. 현침살 (천간 또는 지지)
    if (isHyeonChimSal(gan, ji)) {
      sinsals.add(SpecialSinsal.hyeonchimsal);
    }

    // 5. 천덕귀인 (월지 기준)
    if (isCheonDeokGwiIn(monthJi, gan, ji)) {
      sinsals.add(SpecialSinsal.cheondeokgwiin);
    }

    // 6. 월덕귀인 (월지 기준, 천간만)
    if (isWolDeokGwiIn(monthJi, gan)) {
      sinsals.add(SpecialSinsal.woldeokgwiin);
    }

    // 7. 천문성 (지지)
    if (isCheonMunSeong(ji)) {
      sinsals.add(SpecialSinsal.cheonmunseong);
    }

    // 8. 황은대사 (월지 기준, 일지/시지)
    if (pillarName == '일주' || pillarName == '시주') {
      if (isHwangEunDaeSa(monthJi, ji)) {
        sinsals.add(SpecialSinsal.hwangeundaesa);
      }
    }

    // 9. 학당귀인 (일간 기준)
    if (isHakDangGwiIn(dayGan, ji)) {
      sinsals.add(SpecialSinsal.hakdanggwiin);
    }

    // 10. 괴강살 (일주만)
    if (isDayPillar && isGoeGang(gan, ji)) {
      sinsals.add(SpecialSinsal.goegang);
    }

    // 11. 귀문관살 (해당 지지가 인신사해이고, 전체적으로 2개 이상)
    if (hasGwiMunGwanSal && isGwiMunGwanSalJi(ji)) {
      sinsals.add(SpecialSinsal.gwimungwansal);
    }

    return PillarGilseongResult(
      pillarName: pillarName,
      gan: gan,
      ji: ji,
      sinsals: sinsals,
    );
  }

  /// 개별 파라미터로 길성 분석
  static GilseongAnalysisResult analyze({
    required String yearGan,
    required String yearJi,
    required String monthGan,
    required String monthJi,
    required String dayGan,
    required String dayJi,
    String? hourGan,
    String? hourJi,
  }) {
    // 모든 지지 목록
    final allJis = [
      yearJi,
      monthJi,
      dayJi,
      if (hourJi != null) hourJi,
    ];

    final hasGwiMunGwanSal = isGwiMunGwanSal(allJis);

    final yearResult = _analyzePillar(
      pillarName: '년주',
      gan: yearGan,
      ji: yearJi,
      dayGan: dayGan,
      monthJi: monthJi,
      allJis: allJis,
      hasGwiMunGwanSal: hasGwiMunGwanSal,
    );

    final monthResult = _analyzePillar(
      pillarName: '월주',
      gan: monthGan,
      ji: monthJi,
      dayGan: dayGan,
      monthJi: monthJi,
      allJis: allJis,
      hasGwiMunGwanSal: hasGwiMunGwanSal,
    );

    final dayResult = _analyzePillar(
      pillarName: '일주',
      gan: dayGan,
      ji: dayJi,
      dayGan: dayGan,
      monthJi: monthJi,
      allJis: allJis,
      hasGwiMunGwanSal: hasGwiMunGwanSal,
      isDayPillar: true,
    );

    PillarGilseongResult? hourResult;
    if (hourGan != null && hourJi != null) {
      hourResult = _analyzePillar(
        pillarName: '시주',
        gan: hourGan,
        ji: hourJi,
        dayGan: dayGan,
        monthJi: monthJi,
        allJis: allJis,
        hasGwiMunGwanSal: hasGwiMunGwanSal,
      );
    }

    // 전체 고유 신살 수집
    final allSinsals = <SpecialSinsal>{};
    for (final result in [yearResult, monthResult, dayResult, if (hourResult != null) hourResult]) {
      allSinsals.addAll(result.sinsals);
    }

    return GilseongAnalysisResult(
      yearResult: yearResult,
      monthResult: monthResult,
      dayResult: dayResult,
      hourResult: hourResult,
      allUniqueSinsals: allSinsals.toList(),
      hasGwiMunGwanSal: hasGwiMunGwanSal,
    );
  }
}
