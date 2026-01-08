import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/entities/saju_chart.dart';
import 'package:frontend/features/saju_chart/domain/entities/pillar.dart';
import 'package:frontend/features/saju_chart/domain/services/twelve_sinsal_service.dart';
import 'package:frontend/features/saju_chart/data/constants/twelve_sinsal.dart';

void main() {
  group('12신살 년지/일지 기준 비교 테스트', () {
    test('박재현 사주 - 년지 기준 vs 일지 기준 비교', () {
      // 정축년 신해월 을해일 경진시
      // 년지=축 (사유축 삼합), 일지=해 (해묘미 삼합)
      final birthDateTime = DateTime(1997, 11, 29, 8, 3);
      final chart = SajuChart(
        yearPillar: const Pillar(gan: '정', ji: '축'),
        monthPillar: const Pillar(gan: '신', ji: '해'),
        dayPillar: const Pillar(gan: '을', ji: '해'),
        hourPillar: const Pillar(gan: '경', ji: '진'),
        birthDateTime: birthDateTime,
        correctedDateTime: birthDateTime,
        birthCity: '부산',
        isLunarCalendar: false,
      );

      // 년지(축) 기준 분석 - 포스텔러 방식
      final yearBasisResult =
          TwelveSinsalService.analyzeFromChart(chart, useYearJi: true);

      // 일지(해) 기준 분석 - 현대 명리학 방식
      final dayBasisResult =
          TwelveSinsalService.analyzeFromChart(chart, useYearJi: false);

      print('\n=======================================');
      print('[12신살 기준 비교 - 박재현]');
      print('사주: 정축년 신해월 을해일 경진시');
      print('년지=축 (사유축 삼합), 일지=해 (해묘미 삼합)');
      print('---------------------------------------');
      print('년지(축) 기준 결과 (포스텔러 방식):');
      print('  시지(진): ${yearBasisResult.hourResult?.sinsal.korean}');
      print('  일지(해): ${yearBasisResult.dayResult.sinsal.korean}');
      print('  월지(해): ${yearBasisResult.monthResult.sinsal.korean}');
      print('  년지(축): ${yearBasisResult.yearResult.sinsal.korean}');
      print('---------------------------------------');
      print('일지(해) 기준 결과 (현대 명리학):');
      print('  시지(진): ${dayBasisResult.hourResult?.sinsal.korean}');
      print('  일지(해): ${dayBasisResult.dayResult.sinsal.korean}');
      print('  월지(해): ${dayBasisResult.monthResult.sinsal.korean}');
      print('  년지(축): ${dayBasisResult.yearResult.sinsal.korean}');
      print('---------------------------------------');
      print('포스텔러 표시: 시=천살, 일=역마, 월=역마, 년=월살(?)');
      print('=======================================\n');

      // 년지(축) 기준 - 사유축 삼합에서 겁살 시작=인(2)
      // 진(4)=천살, 해(11)=역마, 축(1)=화개
      expect(yearBasisResult.hourResult?.sinsal, TwelveSinsal.cheonsal,
          reason: '년지 기준: 진=천살');
      expect(yearBasisResult.dayResult.sinsal, TwelveSinsal.yeokma,
          reason: '년지 기준: 해=역마');
      expect(yearBasisResult.monthResult.sinsal, TwelveSinsal.yeokma,
          reason: '년지 기준: 해=역마');
      expect(yearBasisResult.yearResult.sinsal, TwelveSinsal.hwagae,
          reason: '년지 기준: 축=화개');

      // 일지(해) 기준 - 해묘미 삼합에서 겁살 시작=신(8)
      // 진(4)=반안, 해(11)=지살, 축(1)=월살
      expect(dayBasisResult.hourResult?.sinsal, TwelveSinsal.banan,
          reason: '일지 기준: 진=반안');
      expect(dayBasisResult.dayResult.sinsal, TwelveSinsal.jisal,
          reason: '일지 기준: 해=지살');
      expect(dayBasisResult.monthResult.sinsal, TwelveSinsal.jisal,
          reason: '일지 기준: 해=지살');
      expect(dayBasisResult.yearResult.sinsal, TwelveSinsal.wolsal,
          reason: '일지 기준: 축=월살');
    });

    test('삼합별 12신살 배치 검증', () {
      print('\n=======================================');
      print('[삼합별 12신살 배치]');
      print('---------------------------------------');

      // 사유축 삼합 (금국) - 기준: 축
      final chukMap = buildSinsalMap('축');
      print('사유축(금국) 축 기준:');
      print('  인=겁살, 묘=재살, 진=천살, 사=지살');
      print('  오=연살, 미=월살, 신=망신, 유=장성');
      print('  술=반안, 해=역마, 자=육해, 축=화개');

      expect(chukMap['인'], TwelveSinsal.geopsal);
      expect(chukMap['묘'], TwelveSinsal.jaesal);
      expect(chukMap['진'], TwelveSinsal.cheonsal);
      expect(chukMap['사'], TwelveSinsal.jisal);
      expect(chukMap['오'], TwelveSinsal.yeonsal);
      expect(chukMap['미'], TwelveSinsal.wolsal);
      expect(chukMap['신'], TwelveSinsal.mangshin);
      expect(chukMap['유'], TwelveSinsal.jangsung);
      expect(chukMap['술'], TwelveSinsal.banan);
      expect(chukMap['해'], TwelveSinsal.yeokma);
      expect(chukMap['자'], TwelveSinsal.yukhae);
      expect(chukMap['축'], TwelveSinsal.hwagae);

      // 해묘미 삼합 (목국) - 기준: 해
      final haeMap = buildSinsalMap('해');
      print('\n해묘미(목국) 해 기준:');
      print('  신=겁살, 유=재살, 술=천살, 해=지살');
      print('  자=연살, 축=월살, 인=망신, 묘=장성');
      print('  진=반안, 사=역마, 오=육해, 미=화개');

      expect(haeMap['신'], TwelveSinsal.geopsal);
      expect(haeMap['유'], TwelveSinsal.jaesal);
      expect(haeMap['술'], TwelveSinsal.cheonsal);
      expect(haeMap['해'], TwelveSinsal.jisal);
      expect(haeMap['자'], TwelveSinsal.yeonsal);
      expect(haeMap['축'], TwelveSinsal.wolsal);
      expect(haeMap['인'], TwelveSinsal.mangshin);
      expect(haeMap['묘'], TwelveSinsal.jangsung);
      expect(haeMap['진'], TwelveSinsal.banan);
      expect(haeMap['사'], TwelveSinsal.yeokma);
      expect(haeMap['오'], TwelveSinsal.yukhae);
      expect(haeMap['미'], TwelveSinsal.hwagae);

      print('=======================================\n');
    });

    test('DualBasis 분석 테스트', () {
      // 정축년 신해월 을해일 경진시
      final birthDateTime = DateTime(1997, 11, 29, 8, 3);
      final chart = SajuChart(
        yearPillar: const Pillar(gan: '정', ji: '축'),
        monthPillar: const Pillar(gan: '신', ji: '해'),
        dayPillar: const Pillar(gan: '을', ji: '해'),
        hourPillar: const Pillar(gan: '경', ji: '진'),
        birthDateTime: birthDateTime,
        correctedDateTime: birthDateTime,
        birthCity: '부산',
        isLunarCalendar: false,
      );

      final dualResult = TwelveSinsalService.analyzeWithDualBasis(chart);

      print('\n=======================================');
      print('[년지+일지 병행 기준 분석 - 박재현]');
      print('---------------------------------------');
      print('도화살 있는 주: ${dualResult.dohwasalSummary}');
      print('역마살 있는 주: ${dualResult.yeokmasalSummary}');
      print('화개살 있는 주: ${dualResult.hwagaesalSummary}');
      print('---------------------------------------');
      print('년지 기준: ${dualResult.yearBasisResult.summary}');
      print('일지 기준: ${dualResult.dayBasisResult.summary}');
      print('=======================================\n');

      // 역마살 확인 (년지 기준에서 해=역마)
      expect(dualResult.hasYeokmasal, true);
      expect(dualResult.yeokmasalPillars.contains('월지'), true);
      expect(dualResult.yeokmasalPillars.contains('일지'), true);
    });
  });
}
