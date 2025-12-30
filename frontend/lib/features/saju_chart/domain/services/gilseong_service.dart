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

  /// 삼기귀인 결과 (사주 전체 천간 조합)
  final SamgiResult? samgiResult;

  /// 복성귀인 일주 여부
  final bool hasBokseongGwiinIlju;

  /// 복성귀인 천간 여부 (연간 기준 식신)
  final bool hasBokseongGwiinGan;

  /// 홍란살 여부 (년지 기준)
  final bool hasHongranSal;

  /// 천희살 여부 (년지 기준)
  final bool hasCheonheeSal;

  /// 낙정관살 일주 여부 (강력 작용)
  final bool hasNakjeongGwansalIlju;

  // === Phase 24 추가 필드 ===

  /// 효신살 일주 여부
  final bool hasHyosinsal;

  /// 고신살 여부 (남자)
  final bool hasGosinsal;

  /// 과숙살 여부 (여자)
  final bool hasGwasuksal;

  /// 천라지망 여부
  final bool hasCheollaJimang;

  /// 원진살 개수
  final int wonJinsalCount;

  const GilseongAnalysisResult({
    required this.yearResult,
    required this.monthResult,
    required this.dayResult,
    this.hourResult,
    required this.allUniqueSinsals,
    required this.hasGwiMunGwanSal,
    this.samgiResult,
    this.hasBokseongGwiinIlju = false,
    this.hasBokseongGwiinGan = false,
    this.hasHongranSal = false,
    this.hasCheonheeSal = false,
    this.hasNakjeongGwansalIlju = false,
    // Phase 24
    this.hasHyosinsal = false,
    this.hasGosinsal = false,
    this.hasGwasuksal = false,
    this.hasCheollaJimang = false,
    this.wonJinsalCount = 0,
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

    // === Phase 23: 사주 전체 신살 분석 ===

    // 삼기귀인 체크 (천간 조합)
    final samgiResult = checkSamgiGwiin(
      yearGan: chart.yearPillar.gan,
      monthGan: chart.monthPillar.gan,
      dayGan: dayGan,
      hourGan: chart.hourPillar?.gan,
    );
    if (samgiResult.hasSamgi) {
      allSinsals.add(SpecialSinsal.samgigwiin);
    }

    // 복성귀인 일주 체크
    final hasBokseongIlju = isBokseongGwiinIlju(dayGan, chart.dayPillar.ji);
    if (hasBokseongIlju) {
      allSinsals.add(SpecialSinsal.bokseongGwiin);
    }

    // 복성귀인 천간 체크 (연간 기준 식신)
    final yearGan = chart.yearPillar.gan;
    final hasBokseongGan = isBokseongGwiinGan(yearGan, chart.monthPillar.gan) ||
        isBokseongGwiinGan(yearGan, dayGan) ||
        (chart.hourPillar != null && isBokseongGwiinGan(yearGan, chart.hourPillar!.gan));
    if (hasBokseongGan && !hasBokseongIlju) {
      allSinsals.add(SpecialSinsal.bokseongGwiin);
    }

    // 홍란살 체크 (년지 기준, 다른 지지에서 확인)
    final yearJi = chart.yearPillar.ji;
    final hasHongran = isHongranSal(yearJi, chart.monthPillar.ji) ||
        isHongranSal(yearJi, chart.dayPillar.ji) ||
        (chart.hourPillar != null && isHongranSal(yearJi, chart.hourPillar!.ji));
    if (hasHongran) {
      allSinsals.add(SpecialSinsal.hongransal);
    }

    // 천희살 체크 (년지 기준, 다른 지지에서 확인)
    final hasCheonhee = isCheonheeSal(yearJi, chart.monthPillar.ji) ||
        isCheonheeSal(yearJi, chart.dayPillar.ji) ||
        (chart.hourPillar != null && isCheonheeSal(yearJi, chart.hourPillar!.ji));
    if (hasCheonhee) {
      allSinsals.add(SpecialSinsal.cheonheesal);
    }

    // 낙정관살 일주 체크 (강력 작용)
    final hasNakjeongIlju = isNakjeongGwansalIlju(dayGan, chart.dayPillar.ji);

    // === Phase 24: 추가 신살 분석 ===

    // 효신살 일주 체크
    final hasHyosinsalResult = isHyosinsal(dayGan, chart.dayPillar.ji);
    if (hasHyosinsalResult) {
      allSinsals.add(SpecialSinsal.hyosinsal);
    }

    // 고신살 체크 (년지 기준, 다른 지지에서 확인)
    final hasGosinsalResult = isGosinsal(yearJi, chart.monthPillar.ji) ||
        isGosinsal(yearJi, chart.dayPillar.ji) ||
        (chart.hourPillar != null && isGosinsal(yearJi, chart.hourPillar!.ji));
    if (hasGosinsalResult) {
      allSinsals.add(SpecialSinsal.gosinsal);
    }

    // 과숙살 체크 (년지 기준, 다른 지지에서 확인)
    final hasGwasuksalResult = isGwasuksal(yearJi, chart.monthPillar.ji) ||
        isGwasuksal(yearJi, chart.dayPillar.ji) ||
        (chart.hourPillar != null && isGwasuksal(yearJi, chart.hourPillar!.ji));
    if (hasGwasuksalResult) {
      allSinsals.add(SpecialSinsal.gwasuksal);
    }

    // 천라지망 체크 (진술 동시 존재)
    final hasCheollaJimangResult = hasCheollaJimang(allJis);
    if (hasCheollaJimangResult) {
      allSinsals.add(SpecialSinsal.cheollaJimang);
    }

    // 원진살 개수 체크
    final wonJinsalCountResult = countWonJinsal(allJis);
    if (wonJinsalCountResult > 0) {
      allSinsals.add(SpecialSinsal.wonJinsal);
    }

    return GilseongAnalysisResult(
      yearResult: yearResult,
      monthResult: monthResult,
      dayResult: dayResult,
      hourResult: hourResult,
      allUniqueSinsals: allSinsals.toList(),
      hasGwiMunGwanSal: hasGwiMunGwanSal,
      samgiResult: samgiResult,
      hasBokseongGwiinIlju: hasBokseongIlju,
      hasBokseongGwiinGan: hasBokseongGan,
      hasHongranSal: hasHongran,
      hasCheonheeSal: hasCheonhee,
      hasNakjeongGwansalIlju: hasNakjeongIlju,
      // Phase 24
      hasHyosinsal: hasHyosinsalResult,
      hasGosinsal: hasGosinsalResult,
      hasGwasuksal: hasGwasuksalResult,
      hasCheollaJimang: hasCheollaJimangResult,
      wonJinsalCount: wonJinsalCountResult,
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

    // === Phase 23 추가 신살 분석 ===

    // 12. 금여 (일간 기준)
    if (isGeumYeo(dayGan, ji)) {
      sinsals.add(SpecialSinsal.geumyeo);
    }

    // 13. 낙정관살 (일간 기준)
    if (isNakjeongGwansal(dayGan, ji)) {
      sinsals.add(SpecialSinsal.nakjeongGwansal);
    }

    // 14. 문곡귀인 (일간 기준)
    if (isMungokGwiin(dayGan, ji)) {
      sinsals.add(SpecialSinsal.mungokgwiin);
    }

    // 15. 태극귀인 (일간 기준)
    if (isTaegukGwiin(dayGan, ji)) {
      sinsals.add(SpecialSinsal.taegukgwiin);
    }

    // 16. 천의귀인 (월지 기준)
    if (isCheonuiGwiin(monthJi, ji)) {
      sinsals.add(SpecialSinsal.cheonuigwiin);
    }

    // 17. 천주귀인 (일간 기준)
    if (isCheonjuGwiin(dayGan, ji)) {
      sinsals.add(SpecialSinsal.cheonjugwiin);
    }

    // 18. 암록귀인 (일간 기준)
    if (isAmnokGwiin(dayGan, ji)) {
      sinsals.add(SpecialSinsal.amnokgwiin);
    }

    // === Phase 24 추가 신살 분석 ===

    // 19. 건록 (일간 기준)
    if (isGeonrok(dayGan, ji)) {
      sinsals.add(SpecialSinsal.geonrok);
    }

    // 20. 비인살 (일간 기준)
    if (isBiinsal(dayGan, ji)) {
      sinsals.add(SpecialSinsal.biinsal);
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

    // === Phase 23: 사주 전체 신살 분석 ===

    // 삼기귀인 체크 (천간 조합)
    final samgiResult = checkSamgiGwiin(
      yearGan: yearGan,
      monthGan: monthGan,
      dayGan: dayGan,
      hourGan: hourGan,
    );
    if (samgiResult.hasSamgi) {
      allSinsals.add(SpecialSinsal.samgigwiin);
    }

    // 복성귀인 일주 체크
    final hasBokseongIlju = isBokseongGwiinIlju(dayGan, dayJi);
    if (hasBokseongIlju) {
      allSinsals.add(SpecialSinsal.bokseongGwiin);
    }

    // 복성귀인 천간 체크 (연간 기준 식신)
    final hasBokseongGan = isBokseongGwiinGan(yearGan, monthGan) ||
        isBokseongGwiinGan(yearGan, dayGan) ||
        (hourGan != null && isBokseongGwiinGan(yearGan, hourGan));
    if (hasBokseongGan && !hasBokseongIlju) {
      allSinsals.add(SpecialSinsal.bokseongGwiin);
    }

    // 홍란살 체크 (년지 기준, 다른 지지에서 확인)
    final hasHongran = isHongranSal(yearJi, monthJi) ||
        isHongranSal(yearJi, dayJi) ||
        (hourJi != null && isHongranSal(yearJi, hourJi));
    if (hasHongran) {
      allSinsals.add(SpecialSinsal.hongransal);
    }

    // 천희살 체크 (년지 기준, 다른 지지에서 확인)
    final hasCheonhee = isCheonheeSal(yearJi, monthJi) ||
        isCheonheeSal(yearJi, dayJi) ||
        (hourJi != null && isCheonheeSal(yearJi, hourJi));
    if (hasCheonhee) {
      allSinsals.add(SpecialSinsal.cheonheesal);
    }

    // 낙정관살 일주 체크 (강력 작용)
    final hasNakjeongIlju = isNakjeongGwansalIlju(dayGan, dayJi);

    // === Phase 24: 추가 신살 분석 ===

    // 효신살 일주 체크
    final hasHyosinsalResult = isHyosinsal(dayGan, dayJi);
    if (hasHyosinsalResult) {
      allSinsals.add(SpecialSinsal.hyosinsal);
    }

    // 고신살 체크 (년지 기준, 다른 지지에서 확인)
    final hasGosinsalResult = isGosinsal(yearJi, monthJi) ||
        isGosinsal(yearJi, dayJi) ||
        (hourJi != null && isGosinsal(yearJi, hourJi));
    if (hasGosinsalResult) {
      allSinsals.add(SpecialSinsal.gosinsal);
    }

    // 과숙살 체크 (년지 기준, 다른 지지에서 확인)
    final hasGwasuksalResult = isGwasuksal(yearJi, monthJi) ||
        isGwasuksal(yearJi, dayJi) ||
        (hourJi != null && isGwasuksal(yearJi, hourJi));
    if (hasGwasuksalResult) {
      allSinsals.add(SpecialSinsal.gwasuksal);
    }

    // 천라지망 체크 (진술 동시 존재)
    final hasCheollaJimangResult = hasCheollaJimang(allJis);
    if (hasCheollaJimangResult) {
      allSinsals.add(SpecialSinsal.cheollaJimang);
    }

    // 원진살 개수 체크
    final wonJinsalCountResult = countWonJinsal(allJis);
    if (wonJinsalCountResult > 0) {
      allSinsals.add(SpecialSinsal.wonJinsal);
    }

    return GilseongAnalysisResult(
      yearResult: yearResult,
      monthResult: monthResult,
      dayResult: dayResult,
      hourResult: hourResult,
      allUniqueSinsals: allSinsals.toList(),
      hasGwiMunGwanSal: hasGwiMunGwanSal,
      samgiResult: samgiResult,
      hasBokseongGwiinIlju: hasBokseongIlju,
      hasBokseongGwiinGan: hasBokseongGan,
      hasHongranSal: hasHongran,
      hasCheonheeSal: hasCheonhee,
      hasNakjeongGwansalIlju: hasNakjeongIlju,
      // Phase 24
      hasHyosinsal: hasHyosinsalResult,
      hasGosinsal: hasGosinsalResult,
      hasGwasuksal: hasGwasuksalResult,
      hasCheollaJimang: hasCheollaJimangResult,
      wonJinsalCount: wonJinsalCountResult,
    );
  }
}
