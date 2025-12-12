/// RuleEngine 합충형파해 테스트
///
/// Phase 10-C: 합충형파해 JSON 분리 테스트
/// - 천간합/충 룰 매칭 테스트
/// - 지지육합/삼합/방합/충/형/파/해 룰 매칭 테스트
/// - jiCount/ganCount 연산자 테스트 (자형 등)

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/saju_chart/domain/entities/rule.dart';
import 'package:frontend/features/saju_chart/domain/entities/rule_condition.dart';
import 'package:frontend/features/saju_chart/domain/entities/saju_context.dart';
import 'package:frontend/features/saju_chart/domain/entities/compiled_rules.dart';
import 'package:frontend/features/saju_chart/domain/entities/pillar.dart';
import 'package:frontend/features/saju_chart/domain/entities/saju_chart.dart';
import 'package:frontend/features/saju_chart/domain/services/rule_engine.dart';
import 'package:frontend/features/saju_chart/data/models/rule_models.dart';

void main() {
  group('ConditionOp 확장 테스트', () {
    test('gte 연산자 파싱', () {
      final json = {
        'field': 'jiCount',
        'op': 'gte',
        'value': {'진': 2},
      };

      final condition = RuleCondition.fromJson(json);
      expect(condition, isA<SimpleCondition>());

      final simple = condition as SimpleCondition;
      expect(simple.field, ConditionField.jiCount);
      expect(simple.op, ConditionOp.gte);
      expect(simple.value, {'진': 2});
    });

    test('lte 연산자 파싱', () {
      final json = {
        'field': 'ganCount',
        'op': 'lte',
        'value': {'갑': 1},
      };

      final condition = RuleCondition.fromJson(json);
      expect(condition, isA<SimpleCondition>());

      final simple = condition as SimpleCondition;
      expect(simple.field, ConditionField.ganCount);
      expect(simple.op, ConditionOp.lte);
    });
  });

  group('SajuContext jiCount/ganCount 테스트', () {
    test('jiCount - 중복 없는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: Pillar(gan: '정', ji: '묘'),
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final jiCount = context.jiCount;
      expect(jiCount['자'], 1);
      expect(jiCount['축'], 1);
      expect(jiCount['인'], 1);
      expect(jiCount['묘'], 1);
      expect(jiCount['진'], isNull); // 없는 지지
    });

    test('jiCount - 중복 있는 사주 (진진)', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '진'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '진'), // 진이 2개
        hourPillar: Pillar(gan: '정', ji: '묘'),
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final jiCount = context.jiCount;
      expect(jiCount['진'], 2); // 진이 2개
      expect(jiCount['축'], 1);
      expect(jiCount['묘'], 1);
    });

    test('ganCount - 중복 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '갑', ji: '축'), // 갑이 2개
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: Pillar(gan: '갑', ji: '묘'), // 갑이 3개
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final ganCount = context.ganCount;
      expect(ganCount['갑'], 3); // 갑이 3개
      expect(ganCount['병'], 1);
    });

    test('getFieldValue - jiCount/ganCount', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '진'),
        monthPillar: Pillar(gan: '을', ji: '진'),
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final jiCountValue = context.getFieldValue(ConditionField.jiCount);
      expect(jiCountValue, isA<Map<String, int>>());
      expect((jiCountValue as Map<String, int>)['진'], 2);

      final ganCountValue = context.getFieldValue(ConditionField.ganCount);
      expect(ganCountValue, isA<Map<String, int>>());
    });
  });

  group('천간합 룰 매칭 테스트', () {
    test('갑기합 - 갑과 기가 모두 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '기', ji: '축'), // 갑기합!
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'cheongan_hap_gap_gi',
        'name': '갑기합',
        'hanja': '甲己合',
        'type': 'hapchung',
        'category': '천간합',
        'fortuneType': '길',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'ganAny', 'op': 'in', 'value': ['갑']},
            {'field': 'ganAny', 'op': 'in', 'value': ['기']},
          ],
        },
        'reasonTemplate': '천간에 갑과 기가 있어 갑기합(토)을 이룹니다.',
        'priority': 80,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '갑기합');
    });

    test('을경합 - 을과 경이 없는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '기', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'cheongan_hap_eul_gyeong',
        'name': '을경합',
        'type': 'hapchung',
        'category': '천간합',
        'fortuneType': '길',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'ganAny', 'op': 'in', 'value': ['을']},
            {'field': 'ganAny', 'op': 'in', 'value': ['경']},
          ],
        },
        'reasonTemplate': '천간에 을과 경이 있어 을경합(금)을 이룹니다.',
        'priority': 80,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNull); // 을, 경이 없음
    });
  });

  group('천간충 룰 매칭 테스트', () {
    test('갑경충 - 갑과 경이 모두 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '경', ji: '오'), // 갑경충!
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'cheongan_chung_gap_gyeong',
        'name': '갑경충',
        'hanja': '甲庚沖',
        'type': 'hapchung',
        'category': '천간충',
        'fortuneType': '흉',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'ganAny', 'op': 'in', 'value': ['갑']},
            {'field': 'ganAny', 'op': 'in', 'value': ['경']},
          ],
        },
        'reasonTemplate': '천간에 갑과 경이 있어 갑경충이 발생합니다.',
        'priority': 75,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '갑경충');
    });
  });

  group('지지육합 룰 매칭 테스트', () {
    test('자축합 - 자와 축이 모두 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '을', ji: '축'), // 자축합!
        dayPillar: Pillar(gan: '병', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_yukhap_ja_chuk',
        'name': '자축합',
        'hanja': '子丑合',
        'type': 'hapchung',
        'category': '지지육합',
        'fortuneType': '길',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'jiAny', 'op': 'in', 'value': ['자']},
            {'field': 'jiAny', 'op': 'in', 'value': ['축']},
          ],
        },
        'reasonTemplate': '지지에 자와 축이 있어 자축합(토)을 이룹니다.',
        'priority': 70,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '자축합');
    });
  });

  group('지지삼합 룰 매칭 테스트', () {
    test('인오술 삼합 - 인, 오, 술이 모두 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '인'),
        monthPillar: Pillar(gan: '병', ji: '오'),
        dayPillar: Pillar(gan: '무', ji: '술'), // 인오술 삼합!
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_samhap_in_o_sul',
        'name': '인오술 삼합',
        'hanja': '寅午戌 三合',
        'type': 'hapchung',
        'category': '지지삼합',
        'fortuneType': '길',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'jiAny', 'op': 'in', 'value': ['인']},
            {'field': 'jiAny', 'op': 'in', 'value': ['오']},
            {'field': 'jiAny', 'op': 'in', 'value': ['술']},
          ],
        },
        'reasonTemplate': '지지에 인, 오, 술이 있어 삼합(화국)을 이룹니다.',
        'priority': 85,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '인오술 삼합');
    });

    test('해묘미 삼합 - 해, 묘만 있는 사주 (불완전)', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '해'),
        monthPillar: Pillar(gan: '을', ji: '묘'),
        dayPillar: Pillar(gan: '병', ji: '인'), // 미가 없음
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_samhap_hae_myo_mi',
        'name': '해묘미 삼합',
        'type': 'hapchung',
        'category': '지지삼합',
        'fortuneType': '길',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'jiAny', 'op': 'in', 'value': ['해']},
            {'field': 'jiAny', 'op': 'in', 'value': ['묘']},
            {'field': 'jiAny', 'op': 'in', 'value': ['미']},
          ],
        },
        'reasonTemplate': '지지에 해, 묘, 미가 있어 삼합(목국)을 이룹니다.',
        'priority': 85,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNull); // 미가 없어서 불완전
    });
  });

  group('지지충 룰 매칭 테스트', () {
    test('자오충 - 자와 오가 모두 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '병', ji: '오'), // 자오충!
        dayPillar: Pillar(gan: '무', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_chung_ja_o',
        'name': '자오충',
        'hanja': '子午沖',
        'type': 'hapchung',
        'category': '지지충',
        'fortuneType': '흉',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'jiAny', 'op': 'in', 'value': ['자']},
            {'field': 'jiAny', 'op': 'in', 'value': ['오']},
          ],
        },
        'reasonTemplate': '지지에 자와 오가 있어 자오충이 발생합니다.',
        'priority': 75,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '자오충');
    });
  });

  group('지지형 (자형 포함) 룰 매칭 테스트', () {
    test('진진자형 - 진이 2개 이상인 사주 (gte 연산자)', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '진'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '진'), // 진이 2개!
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_hyung_jin_jahyung',
        'name': '진진자형',
        'hanja': '辰辰自刑',
        'type': 'hapchung',
        'category': '지지형',
        'fortuneType': '흉',
        'when': {
          'field': 'jiCount',
          'op': 'gte',
          'value': {'진': 2},
        },
        'reasonTemplate': '지지에 진이 2개 이상 있어 진진자형이 발생합니다.',
        'priority': 70,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '진진자형');
      expect(result.matchedPositions, contains('년지'));
      expect(result.matchedPositions, contains('일지'));
    });

    test('오오자형 - 오가 3개인 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '병', ji: '오'),
        monthPillar: Pillar(gan: '정', ji: '오'),
        dayPillar: Pillar(gan: '무', ji: '오'), // 오가 3개!
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_hyung_o_jahyung',
        'name': '오오자형',
        'hanja': '午午自刑',
        'type': 'hapchung',
        'category': '지지형',
        'fortuneType': '흉',
        'when': {
          'field': 'jiCount',
          'op': 'gte',
          'value': {'오': 2},
        },
        'reasonTemplate': '지지에 오가 2개 이상 있어 오오자형이 발생합니다.',
        'priority': 70,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.bindings['count'], '3'); // 3개 매칭
    });

    test('자형 - 진이 1개만 있는 사주 (매칭 실패)', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '진'),
        monthPillar: Pillar(gan: '을', ji: '축'),
        dayPillar: Pillar(gan: '병', ji: '인'), // 진이 1개만
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_hyung_jin_jahyung',
        'name': '진진자형',
        'type': 'hapchung',
        'category': '지지형',
        'fortuneType': '흉',
        'when': {
          'field': 'jiCount',
          'op': 'gte',
          'value': {'진': 2},
        },
        'reasonTemplate': '진진자형',
        'priority': 70,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNull); // 진이 1개만 있어서 자형 아님
    });

    test('인사형 - 인과 사가 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '인'),
        monthPillar: Pillar(gan: '병', ji: '사'), // 인사형!
        dayPillar: Pillar(gan: '무', ji: '술'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_hyung_in_sa',
        'name': '인사형',
        'hanja': '寅巳刑',
        'type': 'hapchung',
        'category': '지지형',
        'fortuneType': '흉',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'jiAny', 'op': 'in', 'value': ['인']},
            {'field': 'jiAny', 'op': 'in', 'value': ['사']},
          ],
        },
        'reasonTemplate': '지지에 인과 사가 있어 인사형이 발생합니다.',
        'priority': 70,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '인사형');
    });
  });

  group('지지파 룰 매칭 테스트', () {
    test('자유파 - 자와 유가 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '신', ji: '유'), // 자유파!
        dayPillar: Pillar(gan: '임', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_pa_ja_yu',
        'name': '자유파',
        'hanja': '子酉破',
        'type': 'hapchung',
        'category': '지지파',
        'fortuneType': '흉',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'jiAny', 'op': 'in', 'value': ['자']},
            {'field': 'jiAny', 'op': 'in', 'value': ['유']},
          ],
        },
        'reasonTemplate': '지지에 자와 유가 있어 자유파가 발생합니다.',
        'priority': 60,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '자유파');
    });
  });

  group('지지해 룰 매칭 테스트', () {
    test('자미해 - 자와 미가 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '기', ji: '미'), // 자미해!
        dayPillar: Pillar(gan: '무', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'jiji_hae_ja_mi',
        'name': '자미해',
        'hanja': '子未害',
        'type': 'hapchung',
        'category': '지지해',
        'fortuneType': '흉',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'jiAny', 'op': 'in', 'value': ['자']},
            {'field': 'jiAny', 'op': 'in', 'value': ['미']},
          ],
        },
        'reasonTemplate': '지지에 자와 미가 있어 자미해가 발생합니다.',
        'priority': 55,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '자미해');
    });
  });

  group('원진 룰 매칭 테스트', () {
    test('자미원진 - 자와 미가 있는 사주', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '기', ji: '미'), // 자미원진!
        dayPillar: Pillar(gan: '무', ji: '인'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rule = RuleModel.fromJson({
        'id': 'wonjin_ja_mi',
        'name': '자미원진',
        'hanja': '子未怨嗔',
        'type': 'hapchung',
        'category': '원진',
        'fortuneType': '흉',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'jiAny', 'op': 'in', 'value': ['자']},
            {'field': 'jiAny', 'op': 'in', 'value': ['미']},
          ],
        },
        'reasonTemplate': '지지에 자와 미가 있어 자미원진이 발생합니다.',
        'priority': 50,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, context);

      expect(result, isNotNull);
      expect(result!.rule.name, '자미원진');
    });
  });

  group('RuleType hapchung 테스트', () {
    test('hapchung RuleType 파싱', () {
      final rule = RuleModel.fromJson({
        'id': 'test_hapchung',
        'name': '테스트 합충',
        'type': 'hapchung',
        'category': '천간합',
        'fortuneType': '길',
        'when': {'field': 'dayGan', 'op': 'eq', 'value': '갑'},
        'reasonTemplate': '테스트',
        'priority': 50,
      });

      expect(rule.type, RuleType.hapchung);
    });
  });

  group('복합 조건 매칭 테스트', () {
    test('여러 합충이 동시에 있는 사주', () {
      // 자축합 + 자오충이 동시에 있는 특수 케이스
      final chart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '자'),
        monthPillar: Pillar(gan: '을', ji: '축'), // 자축합
        dayPillar: Pillar(gan: '병', ji: '오'), // 자오충
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      final rules = [
        RuleModel.fromJson({
          'id': 'jiji_yukhap_ja_chuk',
          'name': '자축합',
          'type': 'hapchung',
          'category': '지지육합',
          'fortuneType': '길',
          'when': {
            'op': 'and',
            'conditions': [
              {'field': 'jiAny', 'op': 'in', 'value': ['자']},
              {'field': 'jiAny', 'op': 'in', 'value': ['축']},
            ],
          },
          'reasonTemplate': '자축합',
          'priority': 70,
        }),
        RuleModel.fromJson({
          'id': 'jiji_chung_ja_o',
          'name': '자오충',
          'type': 'hapchung',
          'category': '지지충',
          'fortuneType': '흉',
          'when': {
            'op': 'and',
            'conditions': [
              {'field': 'jiAny', 'op': 'in', 'value': ['자']},
              {'field': 'jiAny', 'op': 'in', 'value': ['오']},
            ],
          },
          'reasonTemplate': '자오충',
          'priority': 75,
        }),
      ];

      final compiled = CompiledRules(
        meta: RuleSetMeta(
          schemaVersion: '1.0.0',
          ruleType: RuleType.hapchung,
          version: '1.0.0',
          ruleCount: rules.length,
        ),
        rules: rules,
        compiledAt: DateTime.now(),
      );

      final engine = RuleEngine();
      final results = engine.matchAll(compiled, context);

      expect(results.length, 2); // 둘 다 매칭
      expect(results.map((r) => r.rule.name), contains('자축합'));
      expect(results.map((r) => r.rule.name), contains('자오충'));

      // 우선순위 정렬 확인 (자오충 75 > 자축합 70)
      expect(results[0].rule.name, '자오충');
      expect(results[1].rule.name, '자축합');
    });
  });
}
