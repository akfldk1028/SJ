// 12신살 년지+일지 병행 기준 테스트 (Phase 36)
// 이여진 프로필: 임신(壬申) / 기유(己酉) / 정사(丁巳) / 계묘(癸卯)
// 명리학 표준 기반 검증

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/data/constants/twelve_sinsal.dart';
import 'package:frontend/features/saju_chart/domain/services/twelve_sinsal_service.dart';

void main() {
  group('12신살 명리학 표준 검증 (Phase 36)', () {
    // 이여진: 임신(壬申) / 기유(己酉) / 정사(丁巳) / 계묘(癸卯)
    const yearJi = '신'; // 申
    const monthJi = '유'; // 酉
    const dayGan = '정'; // 丁 (일간)
    const dayJi = '사';  // 巳
    const hourJi = '묘'; // 卯

    group('12신살 기준별 결과 (명리학 표준)', () {
      test('년지(신) 기준 - 신자진(수국)', () {
        // 신자진(수국): 사에서 겁살 시작
        // 사=겁, 오=재, 미=천, 신=지, 유=연, 술=월, 해=망, 자=장, 축=반, 인=역, 묘=육, 진=화
        final yearResult = TwelveSinsalService.analyze(
          yearJi: yearJi,
          monthJi: monthJi,
          dayGan: dayGan,
          dayJi: dayJi,
          hourJi: hourJi,
          useYearJi: true,
        );

        print('=== 년지(신) 기준 12신살 - 신자진(수국) ===');
        print('시지(묘): ${yearResult.hourResult?.sinsal.korean}');
        print('일지(사): ${yearResult.dayResult.sinsal.korean}');
        print('월지(유): ${yearResult.monthResult.sinsal.korean}');
        print('년지(신): ${yearResult.yearResult.sinsal.korean}');

        // 명리학 표준 기대값
        expect(yearResult.hourResult?.sinsal, TwelveSinsal.yukhae, reason: '시지(묘)=육해 (명리학 표준)');
        expect(yearResult.dayResult.sinsal, TwelveSinsal.geopsal, reason: '일지(사)=겁살');
        expect(yearResult.monthResult.sinsal, TwelveSinsal.yeonsal, reason: '월지(유)=연살(도화살)');
        expect(yearResult.yearResult.sinsal, TwelveSinsal.jisal, reason: '년지(신)=지살');
      });

      test('일지(사) 기준 - 사유축(금국)', () {
        // 사유축(금국): 인에서 겁살 시작
        // 인=겁, 묘=재, 진=천, 사=지, 오=연, 미=월, 신=망, 유=장, 술=반, 해=역, 자=육, 축=화
        final dayResult = TwelveSinsalService.analyze(
          yearJi: yearJi,
          monthJi: monthJi,
          dayGan: dayGan,
          dayJi: dayJi,
          hourJi: hourJi,
          useYearJi: false,
        );

        print('\n=== 일지(사) 기준 12신살 - 사유축(금국) ===');
        print('시지(묘): ${dayResult.hourResult?.sinsal.korean}');
        print('일지(사): ${dayResult.dayResult.sinsal.korean}');
        print('월지(유): ${dayResult.monthResult.sinsal.korean}');
        print('년지(신): ${dayResult.yearResult.sinsal.korean}');

        // 명리학 표준 기대값
        expect(dayResult.hourResult?.sinsal, TwelveSinsal.jaesal, reason: '시지(묘)=재살');
        expect(dayResult.dayResult.sinsal, TwelveSinsal.jisal, reason: '일지(사)=지살');
        expect(dayResult.monthResult.sinsal, TwelveSinsal.jangsung, reason: '월지(유)=장성');
        expect(dayResult.yearResult.sinsal, TwelveSinsal.mangshin, reason: '년지(신)=망신');
      });
    });

    group('도화살/역마살 병행 기준 테스트', () {
      test('도화살 기준 확인', () {
        // 년지(신) → 신자진(수국) → 도화=유
        // 일지(사) → 사유축(금국) → 도화=오
        final yearDohwa = getDohwaJi(yearJi);
        final dayDohwa = getDohwaJi(dayJi);
        
        print('\n=== 도화살 기준 ===');
        print('년지($yearJi) 기준 도화: $yearDohwa');
        print('일지($dayJi) 기준 도화: $dayDohwa');
        
        expect(yearDohwa, '유');
        expect(dayDohwa, '오');
      });

      test('월지(유) 도화살 - 년지 기준', () {
        // 월지(유)는 년지(신) 기준 도화
        final hasDohwa = hasDohwasal(yearJi, dayJi, monthJi);
        
        print('\n=== 월지(유) 도화살 ===');
        print('월지($monthJi) 도화살 여부 (병행): $hasDohwa');
        
        expect(hasDohwa, true, reason: '월지(유)는 년지(신) 기준 도화살');
      });

      test('역마살 기준 확인', () {
        // 년지(신) → 신자진(수국) → 역마=인
        // 일지(사) → 사유축(금국) → 역마=해
        final yearYeokma = getYeokmaJi(yearJi);
        final dayYeokma = getYeokmaJi(dayJi);
        
        print('\n=== 역마살 기준 ===');
        print('년지($yearJi) 기준 역마: $yearYeokma');
        print('일지($dayJi) 기준 역마: $dayYeokma');
        
        expect(yearYeokma, '인');
        expect(dayYeokma, '해');
      });

      test('사주에 역마살 없음 확인', () {
        // 이 사주에는 인, 해가 없으므로 역마살 없음
        print('\n=== 역마살 여부 ===');
        
        final pillars = [hourJi, dayJi, monthJi, yearJi];
        for (final ji in pillars) {
          final has = hasYeokmasal(yearJi, dayJi, ji);
          print('$ji: $has');
          expect(has, false);
        }
      });
    });

    group('DualBasisSinsalResult 통합 테스트', () {
      test('병행 기준 전체 분석', () {
        final result = TwelveSinsalService.analyzeWithDualBasisParams(
          yearJi: yearJi,
          monthJi: monthJi,
          dayGan: dayGan,
          dayJi: dayJi,
          hourJi: hourJi,
        );

        print('\n=== DualBasisSinsalResult ===');
        print(result.toString());
        
        // 월지(유)에 도화살
        expect(result.dohwasalPillars, contains('월지'));
        expect(result.hasDohwasal, true);
        
        // 역마살 없음
        expect(result.yeokmasalPillars, isEmpty);
        expect(result.hasYeokmasal, false);
      });
    });
  });

  group('삼합별 12신살 테이블 검증', () {
    test('인오술(화국) - 해에서 겁살 시작', () {
      final map = buildSinsalMap('인');
      
      print('\n=== 인오술(화국) 테이블 ===');
      expect(map['해'], TwelveSinsal.geopsal);
      expect(map['묘'], TwelveSinsal.yeonsal); // 도화
      expect(map['신'], TwelveSinsal.yeokma);  // 역마
      expect(map['술'], TwelveSinsal.hwagae);  // 화개
    });

    test('사유축(금국) - 인에서 겁살 시작', () {
      final map = buildSinsalMap('사');
      
      print('=== 사유축(금국) 테이블 ===');
      expect(map['인'], TwelveSinsal.geopsal);
      expect(map['오'], TwelveSinsal.yeonsal); // 도화
      expect(map['해'], TwelveSinsal.yeokma);  // 역마
      expect(map['축'], TwelveSinsal.hwagae);  // 화개
    });

    test('신자진(수국) - 사에서 겁살 시작', () {
      final map = buildSinsalMap('신');
      
      print('=== 신자진(수국) 테이블 ===');
      expect(map['사'], TwelveSinsal.geopsal);
      expect(map['유'], TwelveSinsal.yeonsal); // 도화
      expect(map['인'], TwelveSinsal.yeokma);  // 역마
      expect(map['진'], TwelveSinsal.hwagae);  // 화개
    });

    test('해묘미(목국) - 신에서 겁살 시작', () {
      final map = buildSinsalMap('해');
      
      print('=== 해묘미(목국) 테이블 ===');
      expect(map['신'], TwelveSinsal.geopsal);
      expect(map['자'], TwelveSinsal.yeonsal); // 도화
      expect(map['사'], TwelveSinsal.yeokma);  // 역마
      expect(map['미'], TwelveSinsal.hwagae);  // 화개
    });
  });
}
