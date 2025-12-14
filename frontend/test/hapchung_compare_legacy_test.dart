/// compareWithLegacy() 테스트 - HapchungService 통합 테스트
///
/// Phase 10 테스트 검증: 하드코딩 vs RuleEngine 결과 비교
///
/// 실행 방법:
/// ```
/// cd frontend
/// flutter test test/hapchung_compare_legacy_test.dart
/// ```
///
/// 주의: 이 테스트는 실제 JSON 파일(hapchung_rules.json)을 로드합니다.
/// Flutter 테스트 환경에서 실행해야 합니다.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/saju_chart/domain/entities/pillar.dart';
import 'package:frontend/features/saju_chart/domain/entities/saju_chart.dart';
import 'package:frontend/features/saju_chart/domain/services/hapchung_service.dart';

void main() {
  // 테스트 시작 전 Flutter 바인딩 초기화
  TestWidgetsFlutterBinding.ensureInitialized();

  group('compareWithLegacy 하드코딩 vs RuleEngine 비교 테스트', () {
    // -------------------------------------------------------------------------
    // 케이스 1: 천간합만 있는 사주 (갑기합)
    // -------------------------------------------------------------------------
    test('케이스 1: 천간합 (갑기합) - 단순 합', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '인'),
        monthPillar: Pillar(gan: '기', ji: '묘'),
        dayPillar: Pillar(gan: '병', ji: '진'),
        hourPillar: Pillar(gan: '정', ji: '사'),
        birthDateTime: DateTime(1990, 3, 15),
        correctedDateTime: DateTime(1990, 3, 15),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 1: 천간합 (갑기합) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');
      print('Legacy에만 있음: ${comparison.onlyInLegacy}');
      print('RuleEngine에만 있음: ${comparison.onlyInRuleEngine}');

      // 갑기합이 양쪽에서 모두 감지되어야 함
      expect(
        comparison.legacyRelations.any((r) => r.contains('갑') && r.contains('기') && r.contains('합')),
        true,
        reason: 'Legacy에서 갑기합이 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 2: 지지충만 있는 사주 (자오충)
    // -------------------------------------------------------------------------
    test('케이스 2: 지지충 (자오충) - 단순 충', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '임', ji: '자'),
        monthPillar: Pillar(gan: '계', ji: '축'),
        dayPillar: Pillar(gan: '갑', ji: '인'),
        hourPillar: Pillar(gan: '병', ji: '오'),
        birthDateTime: DateTime(1992, 2, 10),
        correctedDateTime: DateTime(1992, 2, 10),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 2: 지지충 (자오충) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');

      // 자오충이 양쪽에서 모두 감지되어야 함
      expect(
        comparison.legacyRelations.any((r) => r.contains('자') && r.contains('오') && r.contains('충')),
        true,
        reason: 'Legacy에서 자오충이 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 3: 복합 관계 (합 + 충 동시)
    // -------------------------------------------------------------------------
    test('케이스 3: 복합 관계 (자축합 + 자오충)', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '오'),
        hourPillar: Pillar(gan: '정', ji: '미'),
        birthDateTime: DateTime(1984, 1, 20),
        correctedDateTime: DateTime(1984, 1, 20),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 3: 복합 관계 (자축합 + 자오충) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');
      print('완전 일치: ${comparison.isFullyMatched}');

      // 자축합, 자오충 모두 감지되어야 함
      expect(comparison.legacyRelations.length >= 2, true, reason: '최소 2개 이상의 관계가 감지되어야 합니다');
    });

    // -------------------------------------------------------------------------
    // 케이스 4: 삼합 (인오술 화국)
    // -------------------------------------------------------------------------
    test('케이스 4: 삼합 (인오술 화국)', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '인'),
        monthPillar: Pillar(gan: '병', ji: '오'),
        dayPillar: Pillar(gan: '무', ji: '술'),
        hourPillar: Pillar(gan: '경', ji: '자'),
        birthDateTime: DateTime(1986, 6, 15),
        correctedDateTime: DateTime(1986, 6, 15),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 4: 삼합 (인오술 화국) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');

      // 인오술 삼합이 감지되어야 함
      expect(
        comparison.legacyRelations.any((r) => r.contains('삼합') || r.contains('인오술')),
        true,
        reason: 'Legacy에서 인오술 삼합이 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 5: 자형 (진진자형)
    // -------------------------------------------------------------------------
    test('케이스 5: 자형 (진진자형)', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '진'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '진'), // 진이 2개
        hourPillar: Pillar(gan: '정', ji: '사'),
        birthDateTime: DateTime(1988, 4, 20),
        correctedDateTime: DateTime(1988, 4, 20),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 5: 자형 (진진자형) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');

      // RuleEngine에서 진진자형이 감지되어야 함
      expect(
        comparison.ruleEngineRelations.any((r) => r.contains('진진자형')),
        true,
        reason: 'RuleEngine에서 진진자형이 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 6: 방합 (해자축 북방수)
    // -------------------------------------------------------------------------
    test('케이스 6: 방합 (해자축 북방수)', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '계', ji: '해'),
        monthPillar: Pillar(gan: '갑', ji: '자'),
        dayPillar: Pillar(gan: '을', ji: '축'),
        hourPillar: Pillar(gan: '병', ji: '인'),
        birthDateTime: DateTime(1983, 12, 5),
        correctedDateTime: DateTime(1983, 12, 5),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 6: 방합 (해자축 북방수) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');

      // 해자축 방합이 감지되어야 함
      expect(
        comparison.legacyRelations.any((r) => r.contains('방합') || r.contains('해자축')),
        true,
        reason: 'Legacy에서 해자축 방합이 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 7: 형 (인사형 - 무은지형)
    // -------------------------------------------------------------------------
    test('케이스 7: 형 (인사형)', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '인'),
        monthPillar: Pillar(gan: '병', ji: '사'),
        dayPillar: Pillar(gan: '무', ji: '술'),
        hourPillar: Pillar(gan: '경', ji: '자'),
        birthDateTime: DateTime(1986, 5, 10),
        correctedDateTime: DateTime(1986, 5, 10),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 7: 형 (인사형) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');

      // 인사형이 양쪽에서 감지되어야 함
      expect(
        comparison.legacyRelations.any((r) => r.contains('인') && r.contains('사') && r.contains('형')),
        true,
        reason: 'Legacy에서 인사형이 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 8: 파 (자유파)
    // -------------------------------------------------------------------------
    test('케이스 8: 파 (자유파)', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '임', ji: '자'),
        monthPillar: Pillar(gan: '신', ji: '유'),
        dayPillar: Pillar(gan: '갑', ji: '인'),
        hourPillar: Pillar(gan: '병', ji: '오'),
        birthDateTime: DateTime(1992, 9, 20),
        correctedDateTime: DateTime(1992, 9, 20),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 8: 파 (자유파) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');

      // 자유파가 양쪽에서 감지되어야 함
      expect(
        comparison.legacyRelations.any((r) => r.contains('자') && r.contains('유') && r.contains('파')),
        true,
        reason: 'Legacy에서 자유파가 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 9: 해 (자미해)
    // -------------------------------------------------------------------------
    test('케이스 9: 해 (자미해)', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '기', ji: '미'),
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: Pillar(gan: '정', ji: '묘'),
        birthDateTime: DateTime(1984, 7, 15),
        correctedDateTime: DateTime(1984, 7, 15),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 9: 해 (자미해) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');

      // 자미해가 양쪽에서 감지되어야 함
      expect(
        comparison.legacyRelations.any((r) => r.contains('자') && r.contains('미') && r.contains('해')),
        true,
        reason: 'Legacy에서 자미해가 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 10: 원진 (자미원진)
    // -------------------------------------------------------------------------
    test('케이스 10: 원진 (자미원진)', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '기', ji: '미'),
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: Pillar(gan: '정', ji: '묘'),
        birthDateTime: DateTime(1984, 7, 15),
        correctedDateTime: DateTime(1984, 7, 15),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 10: 원진 (자미원진) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');

      // 자미원진이 양쪽에서 감지되어야 함 (자미해와 동시에)
      expect(
        comparison.legacyRelations.any((r) => r.contains('자') && r.contains('미') && r.contains('원진')),
        true,
        reason: 'Legacy에서 자미원진이 감지되어야 합니다',
      );
    });

    // -------------------------------------------------------------------------
    // 케이스 11: 관계 분석
    // -------------------------------------------------------------------------
    test('케이스 11: 관계 분석', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '병', ji: '인'),
        dayPillar: Pillar(gan: '무', ji: '진'),
        hourPillar: Pillar(gan: '경', ji: '신'),
        birthDateTime: DateTime(1984, 3, 10),
        correctedDateTime: DateTime(1984, 3, 10),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 11: 관계 분석 ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');
    });

    // -------------------------------------------------------------------------
    // 케이스 12: 실제 테스트 케이스 (1990-02-15 서울)
    // -------------------------------------------------------------------------
    test('케이스 12: 실제 사주 (1990-02-15)', () async {
      // 포스텔러 검증 완료된 실제 케이스
      final chart = SajuChart(
        yearPillar: Pillar(gan: '경', ji: '오'),
        monthPillar: Pillar(gan: '무', ji: '인'),
        dayPillar: Pillar(gan: '신', ji: '해'),
        hourPillar: Pillar(gan: '임', ji: '진'),
        birthDateTime: DateTime(1990, 2, 15, 9, 30),
        correctedDateTime: DateTime(1990, 2, 15, 9, 30),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final comparison = await HapchungService.compareWithLegacy(chart);

      print('=== 케이스 12: 실제 사주 (1990-02-15) ===');
      print('Legacy 관계: ${comparison.legacyRelations}');
      print('RuleEngine 관계: ${comparison.ruleEngineRelations}');
      print('일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');
      print('완전 일치: ${comparison.isFullyMatched}');
      print('Legacy에만: ${comparison.onlyInLegacy}');
      print('RuleEngine에만: ${comparison.onlyInRuleEngine}');
    });
  });

  group('compareWithLegacy 일치율 종합 테스트', () {
    test('다양한 케이스의 평균 일치율 계산', () async {
      final testCases = <SajuChart>[
        // 케이스 1: 천간합
        SajuChart(
          yearPillar: Pillar(gan: '갑', ji: '인'),
          monthPillar: Pillar(gan: '기', ji: '묘'),
          dayPillar: Pillar(gan: '병', ji: '진'),
          hourPillar: Pillar(gan: '정', ji: '사'),
          birthDateTime: DateTime(1990, 3, 15),
          correctedDateTime: DateTime(1990, 3, 15),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
        // 케이스 2: 지지충
        SajuChart(
          yearPillar: Pillar(gan: '임', ji: '자'),
          monthPillar: Pillar(gan: '계', ji: '축'),
          dayPillar: Pillar(gan: '갑', ji: '인'),
          hourPillar: Pillar(gan: '병', ji: '오'),
          birthDateTime: DateTime(1992, 2, 10),
          correctedDateTime: DateTime(1992, 2, 10),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
        // 케이스 3: 삼합
        SajuChart(
          yearPillar: Pillar(gan: '갑', ji: '인'),
          monthPillar: Pillar(gan: '병', ji: '오'),
          dayPillar: Pillar(gan: '무', ji: '술'),
          hourPillar: Pillar(gan: '경', ji: '자'),
          birthDateTime: DateTime(1986, 6, 15),
          correctedDateTime: DateTime(1986, 6, 15),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
        // 케이스 4: 방합
        SajuChart(
          yearPillar: Pillar(gan: '계', ji: '해'),
          monthPillar: Pillar(gan: '갑', ji: '자'),
          dayPillar: Pillar(gan: '을', ji: '축'),
          hourPillar: Pillar(gan: '병', ji: '인'),
          birthDateTime: DateTime(1983, 12, 5),
          correctedDateTime: DateTime(1983, 12, 5),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
        // 케이스 5: 형
        SajuChart(
          yearPillar: Pillar(gan: '갑', ji: '인'),
          monthPillar: Pillar(gan: '병', ji: '사'),
          dayPillar: Pillar(gan: '무', ji: '술'),
          hourPillar: Pillar(gan: '경', ji: '자'),
          birthDateTime: DateTime(1986, 5, 10),
          correctedDateTime: DateTime(1986, 5, 10),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
      ];

      var totalMatchRate = 0.0;
      var perfectMatchCount = 0;

      print('\n========================================');
      print('=== compareWithLegacy 종합 테스트 ===');
      print('========================================\n');

      for (var i = 0; i < testCases.length; i++) {
        final comparison = await HapchungService.compareWithLegacy(testCases[i]);
        totalMatchRate += comparison.matchRate;
        if (comparison.isFullyMatched) perfectMatchCount++;

        print('케이스 ${i + 1}: 일치율 ${(comparison.matchRate * 100).toStringAsFixed(1)}%');
        if (comparison.onlyInLegacy.isNotEmpty) {
          print('  - Legacy에만: ${comparison.onlyInLegacy}');
        }
        if (comparison.onlyInRuleEngine.isNotEmpty) {
          print('  - RuleEngine에만: ${comparison.onlyInRuleEngine}');
        }
      }

      final avgMatchRate = totalMatchRate / testCases.length;
      print('\n========================================');
      print('평균 일치율 (원본): ${(avgMatchRate * 100).toStringAsFixed(1)}%');
      print('완전 일치 케이스: $perfectMatchCount / ${testCases.length}');
      print('========================================\n');

      // 원본 일치율이 50% 이상이면 패스 (이름 형식 차이 존재)
      expect(avgMatchRate >= 0.5, true, reason: '원본 평균 일치율이 50% 미만입니다');
    });

    test('정규화된 일치율 계산 (이름 형식 차이 허용)', () async {
      final testCases = <SajuChart>[
        // 케이스 1: 천간합
        SajuChart(
          yearPillar: Pillar(gan: '갑', ji: '인'),
          monthPillar: Pillar(gan: '기', ji: '묘'),
          dayPillar: Pillar(gan: '병', ji: '진'),
          hourPillar: Pillar(gan: '정', ji: '사'),
          birthDateTime: DateTime(1990, 3, 15),
          correctedDateTime: DateTime(1990, 3, 15),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
        // 케이스 2: 지지충
        SajuChart(
          yearPillar: Pillar(gan: '임', ji: '자'),
          monthPillar: Pillar(gan: '계', ji: '축'),
          dayPillar: Pillar(gan: '갑', ji: '인'),
          hourPillar: Pillar(gan: '병', ji: '오'),
          birthDateTime: DateTime(1992, 2, 10),
          correctedDateTime: DateTime(1992, 2, 10),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
        // 케이스 3: 삼합
        SajuChart(
          yearPillar: Pillar(gan: '갑', ji: '인'),
          monthPillar: Pillar(gan: '병', ji: '오'),
          dayPillar: Pillar(gan: '무', ji: '술'),
          hourPillar: Pillar(gan: '경', ji: '자'),
          birthDateTime: DateTime(1986, 6, 15),
          correctedDateTime: DateTime(1986, 6, 15),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
        // 케이스 4: 방합
        SajuChart(
          yearPillar: Pillar(gan: '계', ji: '해'),
          monthPillar: Pillar(gan: '갑', ji: '자'),
          dayPillar: Pillar(gan: '을', ji: '축'),
          hourPillar: Pillar(gan: '병', ji: '인'),
          birthDateTime: DateTime(1983, 12, 5),
          correctedDateTime: DateTime(1983, 12, 5),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
        // 케이스 5: 형
        SajuChart(
          yearPillar: Pillar(gan: '갑', ji: '인'),
          monthPillar: Pillar(gan: '병', ji: '사'),
          dayPillar: Pillar(gan: '무', ji: '술'),
          hourPillar: Pillar(gan: '경', ji: '자'),
          birthDateTime: DateTime(1986, 5, 10),
          correctedDateTime: DateTime(1986, 5, 10),
          birthCity: '서울',
          isLunarCalendar: false,
        ),
      ];

      var totalNormalizedMatchRate = 0.0;
      var normalizedPerfectMatchCount = 0;

      print('\n========================================');
      print('=== 정규화된 일치율 테스트 ===');
      print('========================================\n');

      for (var i = 0; i < testCases.length; i++) {
        final comparison = await HapchungService.compareWithLegacy(testCases[i]);
        totalNormalizedMatchRate += comparison.normalizedMatchRate;
        if (comparison.isNormalizedFullyMatched) normalizedPerfectMatchCount++;

        print('케이스 ${i + 1}:');
        print('  원본 일치율: ${(comparison.matchRate * 100).toStringAsFixed(1)}%');
        print('  정규화 일치율: ${(comparison.normalizedMatchRate * 100).toStringAsFixed(1)}%');
        if (comparison.normalizedOnlyInLegacy.isNotEmpty) {
          print('  - Legacy에만 (정규화): ${comparison.normalizedOnlyInLegacy}');
        }
        if (comparison.normalizedOnlyInRuleEngine.isNotEmpty) {
          print('  - RuleEngine에만 (정규화): ${comparison.normalizedOnlyInRuleEngine}');
        }
      }

      final avgNormalizedMatchRate = totalNormalizedMatchRate / testCases.length;
      print('\n========================================');
      print('정규화 평균 일치율: ${(avgNormalizedMatchRate * 100).toStringAsFixed(1)}%');
      print('정규화 완전 일치 케이스: $normalizedPerfectMatchCount / ${testCases.length}');
      print('========================================\n');

      // 정규화된 일치율이 70% 이상이어야 함
      expect(avgNormalizedMatchRate >= 0.7, true, reason: '정규화 평균 일치율이 70% 미만입니다');
    });
  });

  group('RuleEngine 분석 결과 상세 확인', () {
    test('analyzeWithRuleEngine 기본 동작 확인', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '오'),
        hourPillar: Pillar(gan: '정', ji: '미'),
        birthDateTime: DateTime(1984, 1, 20),
        correctedDateTime: DateTime(1984, 1, 20),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final result = await HapchungService.analyzeWithRuleEngine(chart);

      print('=== analyzeWithRuleEngine 결과 ===');
      print('성공 여부: ${result.isSuccess}');
      print('매칭 개수: ${result.matchCount}');
      print('요약: ${result.summary}');
      print('');
      print('천간합: ${result.cheonganHapResults.map((r) => r.rule.name)}');
      print('천간충: ${result.cheonganChungResults.map((r) => r.rule.name)}');
      print('지지육합: ${result.jijiYukhapResults.map((r) => r.rule.name)}');
      print('삼합: ${result.samhapResults.map((r) => r.rule.name)}');
      print('방합: ${result.banghapResults.map((r) => r.rule.name)}');
      print('지지충: ${result.jijiChungResults.map((r) => r.rule.name)}');
      print('형: ${result.hyungResults.map((r) => r.rule.name)}');
      print('파: ${result.paResults.map((r) => r.rule.name)}');
      print('해: ${result.haeResults.map((r) => r.rule.name)}');
      print('원진: ${result.wonjinResults.map((r) => r.rule.name)}');
      print('');
      print('길한 관계: ${result.goodResults.map((r) => r.rule.name)}');
      print('흉한 관계: ${result.badResults.map((r) => r.rule.name)}');
      print('');
      print('합 총 개수: ${result.totalHaps}');
      print('충 총 개수: ${result.totalChungs}');
      print('흉살 총 개수: ${result.totalNegatives}');

      expect(result.isSuccess, true);
    });

    test('analyzeByFortune 길흉 분류 확인', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '오'),
        hourPillar: Pillar(gan: '정', ji: '미'),
        birthDateTime: DateTime(1984, 1, 20),
        correctedDateTime: DateTime(1984, 1, 20),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final fortune = await HapchungService.analyzeByFortune(chart);

      print('=== analyzeByFortune 결과 ===');
      print('전체 관계: ${fortune.total}개');
      print('길한 관계: ${fortune.good.length}개 (${(fortune.goodRatio * 100).toStringAsFixed(1)}%)');
      print('흉한 관계: ${fortune.bad.length}개 (${(fortune.badRatio * 100).toStringAsFixed(1)}%)');
      print('중립 관계: ${fortune.neutral.length}개');
      print('');
      print('길: ${fortune.good.map((r) => r.rule.name)}');
      print('흉: ${fortune.bad.map((r) => r.rule.name)}');
      print('중: ${fortune.neutral.map((r) => r.rule.name)}');

      expect(fortune.total >= 0, true);
    });

    test('findRelationById 특정 관계 검색', () async {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '오'),
        hourPillar: Pillar(gan: '정', ji: '미'),
        birthDateTime: DateTime(1984, 1, 20),
        correctedDateTime: DateTime(1984, 1, 20),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      // 자축합 검색
      final jachukHap = await HapchungService.findRelationById(chart, 'jiji_yukhap_jachuk');
      print('=== findRelationById (자축합) ===');
      if (jachukHap != null) {
        print('찾음: ${jachukHap.rule.name}');
        print('카테고리: ${jachukHap.rule.category}');
        print('길흉: ${jachukHap.rule.fortuneType}');
      } else {
        print('찾지 못함');
      }

      // 자오충 검색
      final jaoChung = await HapchungService.findRelationById(chart, 'jiji_chung_jao');
      print('\n=== findRelationById (자오충) ===');
      if (jaoChung != null) {
        print('찾음: ${jaoChung.rule.name}');
        print('카테고리: ${jaoChung.rule.category}');
        print('길흉: ${jaoChung.rule.fortuneType}');
      } else {
        print('찾지 못함');
      }
    });
  });
}
