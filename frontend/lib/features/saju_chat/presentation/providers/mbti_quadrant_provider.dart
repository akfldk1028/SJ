import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/ai_persona.dart';

part 'mbti_quadrant_provider.g.dart';

/// Hive Box 이름
const String _mbtiBoxName = 'mbti_settings';
const String _mbtiKey = 'current_quadrant';

/// MBTI 분면 상태 Provider
///
/// 캐릭터와 별도로 MBTI 성향을 관리
/// 4x4 조합: 4개 캐릭터 × 4개 MBTI 분면 = 16 조합
///
/// ## 사용 예시
/// ```dart
/// final quadrant = ref.watch(mbtiQuadrantNotifierProvider);
/// ref.read(mbtiQuadrantNotifierProvider.notifier).setQuadrant(MbtiQuadrant.NT);
/// ```
@riverpod
class MbtiQuadrantNotifier extends _$MbtiQuadrantNotifier {
  Box<String>? _box;

  @override
  MbtiQuadrant build() {
    _initBox();
    return _loadFromHive();
  }

  /// Hive Box 초기화
  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_mbtiBoxName)) {
      _box = await Hive.openBox<String>(_mbtiBoxName);
    } else {
      _box = Hive.box<String>(_mbtiBoxName);
    }
  }

  /// Hive에서 저장된 분면 로드
  MbtiQuadrant _loadFromHive() {
    try {
      if (Hive.isBoxOpen(_mbtiBoxName)) {
        final box = Hive.box<String>(_mbtiBoxName);
        final value = box.get(_mbtiKey);
        return _fromString(value);
      }
    } catch (e) {
      // 에러 시 기본값 반환
    }
    return MbtiQuadrant.NF;
  }

  /// 문자열에서 MbtiQuadrant로 변환
  MbtiQuadrant _fromString(String? value) {
    switch (value) {
      case 'NF':
        return MbtiQuadrant.NF;
      case 'NT':
        return MbtiQuadrant.NT;
      case 'SF':
        return MbtiQuadrant.SF;
      case 'ST':
        return MbtiQuadrant.ST;
      default:
        return MbtiQuadrant.NF;
    }
  }

  /// 분면 변경
  Future<void> setQuadrant(MbtiQuadrant quadrant) async {
    state = quadrant;

    // Hive에 저장
    try {
      if (_box == null || !_box!.isOpen) {
        await _initBox();
      }
      await _box?.put(_mbtiKey, quadrant.name);
    } catch (e) {
      // 저장 실패해도 state는 변경됨
    }
  }
}

/// 현재 MBTI 분면 Provider (read-only)
@riverpod
MbtiQuadrant currentMbtiQuadrant(CurrentMbtiQuadrantRef ref) {
  return ref.watch(mbtiQuadrantNotifierProvider);
}

/// MBTI 분면별 modifier 프롬프트
///
/// 기본 캐릭터 성격에 이 modifier를 추가하여 성향 조절
extension MbtiQuadrantModifier on MbtiQuadrant {
  /// AI 프롬프트용 modifier
  String get promptModifier {
    switch (this) {
      case MbtiQuadrant.NF:
        return '''
[성향 modifier: 감성형 (NF)]
- 따뜻하고 공감적인 톤으로 대화
- 상대방의 감정을 먼저 읽고 위로
- 직관적이고 영감 있는 해석 제공
- "느껴지는", "마음이", "감동" 등의 표현 사용
''';
      case MbtiQuadrant.NT:
        return '''
[성향 modifier: 분석형 (NT)]
- 논리적이고 체계적인 분석 제공
- 원인과 결과를 명확히 설명
- 객관적 데이터와 근거 중시
- "분석하면", "논리적으로", "체계적으로" 등의 표현 사용
''';
      case MbtiQuadrant.SF:
        return '''
[성향 modifier: 친근형 (SF)]
- 유쾌하고 친근한 말투
- 일상적이고 실용적인 조언
- 현실적인 예시와 비유 사용
- "솔직히", "편하게", "재미있게" 등의 표현 사용
''';
      case MbtiQuadrant.ST:
        return '''
[성향 modifier: 현실형 (ST)]
- 직설적이고 핵심만 전달
- 구체적이고 실행 가능한 조언
- 사실과 경험 기반 해석
- "현실적으로", "실제로", "구체적으로" 등의 표현 사용
''';
    }
  }
}
