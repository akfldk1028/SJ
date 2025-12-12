/// RuleEngine 신살 테스트
///
/// Phase 10-B: 신살 JSON 분리 테스트
/// - JSON 파싱 테스트
/// - RuleEngine 매칭 테스트
/// - 기존 로직과 비교 테스트

import 'dart:convert';
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
  group('RuleCondition 파싱 테스트', () {
    test('SimpleCondition - eq 연산자', () {
      final json = {
        'field': 'dayGan',
        'op': 'eq',
        'value': '갑',
      };

      final condition = RuleCondition.fromJson(json);
      expect(condition, isA<SimpleCondition>());

      final simple = condition as SimpleCondition;
      expect(simple.field, ConditionField.dayGan);
      expect(simple.op, ConditionOp.eq);
      expect(simple.value, '갑');
    });

    test('SimpleCondition - in 연산자', () {
      final json = {
        'field': 'jiAny',
        'op': 'in',
        'value': ['축', '미'],
      };

      final condition = RuleCondition.fromJson(json);
      expect(condition, isA<SimpleCondition>());

      final simple = condition as SimpleCondition;
      expect(simple.field, ConditionField.jiAny);
      expect(simple.op, ConditionOp.contains);
      expect(simple.value, ['축', '미']);
    });

    test('CompositeCondition - and 연산자', () {
      final json = {
        'op': 'and',
        'conditions': [
          {'field': 'dayGan', 'op': 'in', 'value': ['갑', '무', '경']},
          {'field': 'jiAny', 'op': 'in', 'value': ['축', '미']},
        ],
      };

      final condition = RuleCondition.fromJson(json);
      expect(condition, isA<CompositeCondition>());

      final composite = condition as CompositeCondition;
      expect(composite.op, ConditionOp.and);
      expect(composite.conditions.length, 2);
    });

    test('CompositeCondition - or 연산자 (중첩)', () {
      final json = {
        'op': 'or',
        'conditions': [
          {
            'op': 'and',
            'conditions': [
              {'field': 'dayGan', 'op': 'in', 'value': ['갑', '무', '경']},
              {'field': 'jiAny', 'op': 'in', 'value': ['축', '미']},
            ],
          },
          {
            'op': 'and',
            'conditions': [
              {'field': 'dayGan', 'op': 'in', 'value': ['을', '기']},
              {'field': 'jiAny', 'op': 'in', 'value': ['자', '신']},
            ],
          },
        ],
      };

      final condition = RuleCondition.fromJson(json);
      expect(condition, isA<CompositeCondition>());

      final composite = condition as CompositeCondition;
      expect(composite.op, ConditionOp.or);
      expect(composite.conditions.length, 2);
      expect(composite.conditions[0], isA<CompositeCondition>());
    });
  });

  group('RuleModel 파싱 테스트', () {
    test('천을귀인 룰 파싱', () {
      final json = {
        'id': 'cheon_eul_gwin',
        'name': '천을귀인',
        'hanja': '天乙貴人',
        'type': 'sinsal',
        'category': '특수신살',
        'fortuneType': '길',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'dayGan', 'op': 'in', 'value': ['갑', '무', '경']},
            {'field': 'jiAny', 'op': 'in', 'value': ['축', '미']},
          ],
        },
        'reasonTemplate': '일간 {dayGan}에서 {matchedJi}가 천을귀인',
        'description': '귀인의 도움을 받는 길성입니다.',
        'priority': 100,
        'enabled': true,
      };

      final rule = RuleModel.fromJson(json);

      expect(rule.id, 'cheon_eul_gwin');
      expect(rule.name, '천을귀인');
      expect(rule.hanja, '天乙貴人');
      expect(rule.type, RuleType.sinsal);
      expect(rule.category, '특수신살');
      expect(rule.fortuneType, FortuneType.gil);
      expect(rule.priority, 100);
      expect(rule.enabled, true);
    });

    test('RuleModel JSON 왕복', () {
      final originalJson = {
        'id': 'test_rule',
        'name': '테스트 룰',
        'hanja': '測試',
        'type': 'sinsal',
        'category': '테스트',
        'fortuneType': '흉',
        'when': {
          'field': 'dayGan',
          'op': 'eq',
          'value': '갑',
        },
        'reasonTemplate': '일간 {dayGan}가 테스트',
        'description': '테스트용 룰입니다.',
        'priority': 50,
        'enabled': true,
      };

      final rule = RuleModel.fromJson(originalJson);
      final backToJson = rule.toJson();

      expect(backToJson['id'], originalJson['id']);
      expect(backToJson['name'], originalJson['name']);
      expect(backToJson['type'], 'sinsal');
      expect(backToJson['fortuneType'], '흉');
    });
  });

  group('RuleSetParseResult 파싱 테스트', () {
    test('전체 룰셋 파싱', () {
      final jsonString = '''
{
  "schemaVersion": "1.0.0",
  "ruleType": "sinsal",
  "version": "2024.12.12",
  "description": "테스트 룰셋",
  "rules": [
    {
      "id": "rule_1",
      "name": "룰1",
      "type": "sinsal",
      "category": "테스트",
      "fortuneType": "길",
      "when": { "field": "dayGan", "op": "eq", "value": "갑" },
      "reasonTemplate": "테스트"
    },
    {
      "id": "rule_2",
      "name": "룰2",
      "type": "sinsal",
      "category": "테스트",
      "fortuneType": "흉",
      "when": { "field": "dayGan", "op": "eq", "value": "을" },
      "reasonTemplate": "테스트"
    }
  ]
}
''';

      final result = RuleParser.parseFromString(jsonString);

      expect(result.meta.schemaVersion, '1.0.0');
      expect(result.meta.ruleType, RuleType.sinsal);
      expect(result.meta.version, '2024.12.12');
      expect(result.rules.length, 2);
      expect(result.isSuccess, true);
    });
  });

  group('RuleEngine 매칭 테스트', () {
    late SajuChart testChart;
    late SajuContext testContext;

    setUp(() {
      // 1990년 2월 15일 서울 09:30 - 경오년 무인월 신해일 임진시
      // 일간: 신(辛) - 양인살 지지: 술
      testChart = SajuChart(
        yearPillar: Pillar(gan: '경', ji: '오'),
        monthPillar: Pillar(gan: '무', ji: '인'),
        dayPillar: Pillar(gan: '신', ji: '해'),
        hourPillar: Pillar(gan: '임', ji: '진'),
        birthDateTime: DateTime(1990, 2, 15, 9, 30),
        correctedDateTime: DateTime(1990, 2, 15, 9, 0), // 진태양시 보정
        birthCity: '서울',
        isLunarCalendar: false,
      );
      testContext = SajuContext.fromChart(testChart);
    });

    test('천을귀인 매칭 - 신(辛) 일간, 인/오 지지', () {
      // 신(辛) 일간의 천을귀인 지지: 인, 오
      // 테스트 사주: 오(년지), 인(월지) → 천을귀인 매칭되어야 함

      final rule = RuleModel.fromJson({
        'id': 'cheon_eul_gwin',
        'name': '천을귀인',
        'type': 'sinsal',
        'category': '특수신살',
        'fortuneType': '길',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'dayGan', 'op': 'eq', 'value': '신'},
            {'field': 'jiAny', 'op': 'in', 'value': ['인', '오']},
          ],
        },
        'reasonTemplate': '일간 {dayGan}에서 천을귀인',
        'priority': 100,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, testContext);

      expect(result, isNotNull);
      expect(result!.rule.name, '천을귀인');
      // 오(년지)와 인(월지)이 매칭됨
    });

    test('괴강살 매칭 - 일주 경진/경술/임진/임술', () {
      // 신해일은 괴강이 아님
      final rule = RuleModel.fromJson({
        'id': 'goe_gang_sal',
        'name': '괴강살',
        'type': 'sinsal',
        'category': '특수신살',
        'fortuneType': '중',
        'when': {
          'op': 'or',
          'conditions': [
            {'field': 'dayPillar', 'op': 'eq', 'value': '경진'},
            {'field': 'dayPillar', 'op': 'eq', 'value': '경술'},
            {'field': 'dayPillar', 'op': 'eq', 'value': '임진'},
            {'field': 'dayPillar', 'op': 'eq', 'value': '임술'},
          ],
        },
        'reasonTemplate': '일주 {dayPillar}가 괴강살',
        'priority': 85,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, testContext);

      expect(result, isNull); // 신해일은 괴강이 아님
    });

    test('괴강살 매칭 - 임진일', () {
      // 임진일 테스트 차트
      final goeGangChart = SajuChart(
        yearPillar: Pillar(gan: '경', ji: '오'),
        monthPillar: Pillar(gan: '무', ji: '인'),
        dayPillar: Pillar(gan: '임', ji: '진'),
        hourPillar: Pillar(gan: '임', ji: '자'),
        birthDateTime: DateTime(1990, 1, 1),
        correctedDateTime: DateTime(1990, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final goeGangContext = SajuContext.fromChart(goeGangChart);

      final rule = RuleModel.fromJson({
        'id': 'goe_gang_sal',
        'name': '괴강살',
        'type': 'sinsal',
        'category': '특수신살',
        'fortuneType': '중',
        'when': {
          'op': 'or',
          'conditions': [
            {'field': 'dayPillar', 'op': 'eq', 'value': '경진'},
            {'field': 'dayPillar', 'op': 'eq', 'value': '경술'},
            {'field': 'dayPillar', 'op': 'eq', 'value': '임진'},
            {'field': 'dayPillar', 'op': 'eq', 'value': '임술'},
          ],
        },
        'reasonTemplate': '일주 {dayPillar}가 괴강살',
        'priority': 85,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, goeGangContext);

      expect(result, isNotNull);
      expect(result!.rule.name, '괴강살');
    });

    test('양인살 매칭 - 신(辛) 일간, 술 지지', () {
      // 신(辛) 일간의 양인살 지지: 술
      final rule = RuleModel.fromJson({
        'id': 'yang_in_sal',
        'name': '양인살',
        'type': 'sinsal',
        'category': '특수신살',
        'fortuneType': '흉',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'dayGan', 'op': 'eq', 'value': '신'},
            {'field': 'jiAny', 'op': 'eq', 'value': '술'},
          ],
        },
        'reasonTemplate': '일간 {dayGan}에서 양인살',
        'priority': 90,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, testContext);

      expect(result, isNull); // 테스트 사주에 술(戌)이 없음
    });

    test('matchAll - 여러 룰 동시 매칭', () {
      final rules = [
        RuleModel.fromJson({
          'id': 'cheon_eul_gwin',
          'name': '천을귀인',
          'type': 'sinsal',
          'category': '특수신살',
          'fortuneType': '길',
          'when': {
            'op': 'and',
            'conditions': [
              {'field': 'dayGan', 'op': 'eq', 'value': '신'},
              {'field': 'jiAny', 'op': 'in', 'value': ['인', '오']},
            ],
          },
          'reasonTemplate': '천을귀인',
          'priority': 100,
        }),
        RuleModel.fromJson({
          'id': 'non_match_rule',
          'name': '매칭 안되는 룰',
          'type': 'sinsal',
          'category': '테스트',
          'fortuneType': '흉',
          'when': {
            'field': 'dayGan',
            'op': 'eq',
            'value': '갑',
          },
          'reasonTemplate': '테스트',
          'priority': 50,
        }),
      ];

      final compiled = CompiledRules(
        meta: RuleSetMeta(
          schemaVersion: '1.0.0',
          ruleType: RuleType.sinsal,
          version: '1.0.0',
          ruleCount: rules.length,
        ),
        rules: rules,
        compiledAt: DateTime.now(),
      );

      final engine = RuleEngine();
      final results = engine.matchAll(compiled, testContext);

      expect(results.length, 1);
      expect(results[0].rule.name, '천을귀인');
    });
  });

  group('12신살 룰 테스트', () {
    test('역마살 - 인오술 년지, 인 지지', () {
      // 인오술(화국) 년지에서 역마살은 인에 위치
      final testChart = SajuChart(
        yearPillar: Pillar(gan: '갑', ji: '오'), // 오(午) - 인오술 화국
        monthPillar: Pillar(gan: '병', ji: '인'), // 인(寅) - 역마살 위치
        dayPillar: Pillar(gan: '무', ji: '진'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final testContext = SajuContext.fromChart(testChart);

      final rule = RuleModel.fromJson({
        'id': 'twelve_sinsal_yeokma',
        'name': '역마살',
        'type': 'sinsal',
        'category': '12신살',
        'fortuneType': '중',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'yearJi', 'op': 'in', 'value': ['인', '오', '술']},
            {'field': 'jiAny', 'op': 'in', 'value': ['인']}, // jiAny는 리스트이므로 'in' 사용
          ],
        },
        'reasonTemplate': '년지 {yearJi} 기준 역마살',
        'priority': 55,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, testContext);

      expect(result, isNotNull);
      expect(result!.rule.name, '역마살');
    });

    test('도화살 - 사유축 년지, 자 지지', () {
      // 사유축(금국) 년지에서 도화살은 자에 위치
      final testChart = SajuChart(
        yearPillar: Pillar(gan: '신', ji: '유'), // 유(酉) - 사유축 금국
        monthPillar: Pillar(gan: '경', ji: '자'), // 자(子) - 도화살 위치
        dayPillar: Pillar(gan: '임', ji: '오'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final testContext = SajuContext.fromChart(testChart);

      final rule = RuleModel.fromJson({
        'id': 'twelve_sinsal_yeonsal',
        'name': '도화살',
        'type': 'sinsal',
        'category': '12신살',
        'fortuneType': '중',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'yearJi', 'op': 'in', 'value': ['사', '유', '축']},
            {'field': 'jiAny', 'op': 'in', 'value': ['자']}, // jiAny는 리스트이므로 'in' 사용
          ],
        },
        'reasonTemplate': '년지 {yearJi} 기준 도화살',
        'priority': 55,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, testContext);

      expect(result, isNotNull);
      expect(result!.rule.name, '도화살');
    });

    test('장성살 - 해묘미 년지, 유 지지', () {
      // 해묘미(목국) 년지에서 장성살은 유에 위치
      final testChart = SajuChart(
        yearPillar: Pillar(gan: '을', ji: '묘'), // 묘(卯) - 해묘미 목국
        monthPillar: Pillar(gan: '기', ji: '유'), // 유(酉) - 장성살 위치
        dayPillar: Pillar(gan: '신', ji: '사'),
        hourPillar: null,
        birthDateTime: DateTime(2000, 1, 1),
        correctedDateTime: DateTime(2000, 1, 1),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final testContext = SajuContext.fromChart(testChart);

      final rule = RuleModel.fromJson({
        'id': 'twelve_sinsal_jangsung',
        'name': '장성살',
        'type': 'sinsal',
        'category': '12신살',
        'fortuneType': '길',
        'when': {
          'op': 'and',
          'conditions': [
            {'field': 'yearJi', 'op': 'in', 'value': ['해', '묘', '미']},
            {'field': 'jiAny', 'op': 'in', 'value': ['유']}, // jiAny는 리스트이므로 'in' 사용
          ],
        },
        'reasonTemplate': '년지 {yearJi} 기준 장성살',
        'priority': 60,
      });

      final engine = RuleEngine();
      final result = engine.match(rule, testContext);

      expect(result, isNotNull);
      expect(result!.rule.name, '장성살');
    });
  });

  group('SajuContext 테스트', () {
    test('기본 필드 접근', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '경', ji: '오'),
        monthPillar: Pillar(gan: '무', ji: '인'),
        dayPillar: Pillar(gan: '신', ji: '해'),
        hourPillar: Pillar(gan: '임', ji: '진'),
        birthDateTime: DateTime(1990, 2, 15, 9, 30),
        correctedDateTime: DateTime(1990, 2, 15, 9, 0),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      expect(context.yearGan, '경');
      expect(context.yearJi, '오');
      expect(context.dayGan, '신');
      expect(context.dayJi, '해');
      expect(context.dayPillar, '신해');
      expect(context.allJi, ['오', '인', '해', '진']);
      expect(context.allGan, ['경', '무', '신', '임']);
    });

    test('getFieldValue 동작', () {
      final chart = SajuChart(
        yearPillar: Pillar(gan: '경', ji: '오'),
        monthPillar: Pillar(gan: '무', ji: '인'),
        dayPillar: Pillar(gan: '신', ji: '해'),
        hourPillar: null,
        birthDateTime: DateTime(1990, 2, 15),
        correctedDateTime: DateTime(1990, 2, 15),
        birthCity: '서울',
        isLunarCalendar: false,
      );
      final context = SajuContext.fromChart(chart);

      expect(context.getFieldValue(ConditionField.dayGan), '신');
      expect(context.getFieldValue(ConditionField.jiAny), ['오', '인', '해']);
      expect(context.getFieldValue(ConditionField.dayPillar), '신해');
      expect(context.getFieldValue(ConditionField.hourJi), isNull);
    });
  });

  group('FortuneType 파싱 테스트', () {
    test('한글 길흉 파싱', () {
      expect(FortuneType.fromString('길'), FortuneType.gil);
      expect(FortuneType.fromString('흉'), FortuneType.hyung);
      expect(FortuneType.fromString('중'), FortuneType.jung);
      expect(FortuneType.fromString('길흉혼합'), FortuneType.jung);
    });

    test('영문 길흉 파싱', () {
      expect(FortuneType.fromString('gil'), FortuneType.gil);
      expect(FortuneType.fromString('hyung'), FortuneType.hyung);
      expect(FortuneType.fromString('jung'), FortuneType.jung);
    });
  });
}
