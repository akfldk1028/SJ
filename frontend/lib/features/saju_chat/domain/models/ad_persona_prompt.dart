/// 광고 페르소나 프롬프트
///
/// AI 페르소나가 자연스럽게 광고를 추천하기 위한 프롬프트 생성
/// 각 페르소나 스타일에 맞는 전환 문구 템플릿 제공
library;

import 'dart:math';

import '../models/ai_persona.dart';
import '../../data/models/conversational_ad_model.dart';

final _random = Random();

/// 광고 페르소나 프롬프트 생성기
///
/// 사용 예:
/// ```dart
/// final prompt = AdPersonaPrompt.getTransitionPrompt(
///   persona: currentPersona,
///   trigger: AdTriggerResult.tokenNearLimit,
/// );
/// ```
abstract class AdPersonaPrompt {
  AdPersonaPrompt._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 전환 프롬프트 생성
  // ═══════════════════════════════════════════════════════════════════════════

  /// 페르소나별 광고 전환 프롬프트 생성
  ///
  /// AI가 이 프롬프트를 기반으로 자연스러운 전환 문구를 생성
  static String getTransitionPrompt(AiPersona persona, AdTriggerResult trigger) {
    if (trigger == AdTriggerResult.none) return '';

    final personaStyle = _getPersonaStyle(persona);
    final basePrompt = _getBasePrompt(trigger);

    return '''
당신은 ${persona.displayName}입니다.
$basePrompt
$personaStyle

주의사항:
- 광고임을 직접적으로 언급하지 마세요
- 자연스러운 대화의 흐름을 유지하세요
- 사용자에게 도움이 되는 것처럼 제안하세요
- 2-3문장으로 짧게 작성하세요
''';
  }

  /// 트리거 유형별 기본 프롬프트
  static String _getBasePrompt(AdTriggerResult trigger) {
    return switch (trigger) {
      AdTriggerResult.tokenNearLimit => '''
대화가 길어져 잠시 쉬어가는 것을 자연스럽게 제안하세요.
사용자의 관심사와 연관된 추천을 해주는 것처럼 말하세요.
''',
      AdTriggerResult.tokenDepleted => '''
더 깊은 이야기를 나누려면 잠시 후원자 소개를 봐야 한다고 정중하게 안내하세요.
광고 시청 후 더 상세한 상담이 가능하다고 알려주세요.
''',
      AdTriggerResult.intervalAd => '''
대화 중 자연스럽게 관련 정보나 서비스를 추천하세요.
마치 친구에게 추천하듯 편안하게 말하세요.
''',
      AdTriggerResult.none => '',
    };
  }

  /// 페르소나별 말투 스타일
  static String _getPersonaStyle(AiPersona persona) {
    return switch (persona.name) {
      'doryeong' || 'dolyeong' => '''
조선시대 도령답게 고풍스럽고 정중하게 말하세요.
예시: "허허, 이야기가 깊어지니 잠시 숨을 고르는 것도 좋겠구려.
       말이 나온 김에, 요즘 제가 눈여겨보는 것이 있사온데..."
''',
      'seonyeo' || 'sunnyeo' => '''
선녀처럼 우아하고 신비롭게 말하세요.
예시: "후후, 사람의 인연이란 참 묘한 것이지요.
       혹시 더 깊은 인연을 원하신다면..."
''',
      'monk' || 'seunim' => '''
스님답게 담담하고 지혜롭게 말하세요.
예시: "아미타불, 마음의 여유를 갖는 것도 수행이오.
       잠시 눈을 돌려 이것을 살펴보시오."
''',
      'grandmother' || 'halmeoni' => '''
할머니처럼 따뜻하고 다정하게 말하세요.
예시: "아이고, 얘기가 길어졌구나. 잠깐 쉬어가자꾸나.
       그나저나 요즘 우리 손주가 좋아하는 게 있는디..."
''',
      _ => '''
친근하고 자연스럽게 말하세요.
예시: "참, 말이 나온 김에 추천해드리고 싶은 게 있어요.
       혹시 관심 있으시면 한번 보실래요?"
''',
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 전환 문구 템플릿 (AI 없이 사용)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 페르소나별 기본 전환 문구 (AI 생성 실패 시 폴백)
  static String getDefaultTransitionText(AiPersona persona, AdTriggerResult trigger) {
    final personaName = persona.name.toLowerCase();

    // 토큰 소진 (필수 광고)
    if (trigger == AdTriggerResult.tokenDepleted) {
      return switch (personaName) {
        'doryeong' || 'dolyeong' =>
          '허허, 대화가 깊어지니 저도 잠시 기력을 보충해야겠구려. '
          '아래 후원자님 소개를 보시면 이야기를 이어갈 수 있사옵니다.',
        'seonyeo' || 'sunnyeo' =>
          '후후, 인연의 끈이 깊어졌네요. '
          '잠시 후원자님 소개를 보시면 더 깊은 이야기를 나눌 수 있어요.',
        'monk' || 'seunim' =>
          '아미타불, 대화의 공덕이 쌓였습니다. '
          '아래 시주를 보시면 법문을 이어갈 수 있사옵니다.',
        'grandmother' || 'halmeoni' =>
          '아이고, 얘기가 길어졌구나. '
          '아래 거 한번 보면 계속 얘기할 수 있단다.',
        _ =>
          '대화가 즐거웠어요! '
          '아래 광고를 보시면 더 깊은 대화를 나눌 수 있어요.',
      };
    }

    // 토큰 경고 (선제적 광고)
    if (trigger == AdTriggerResult.tokenNearLimit) {
      return switch (personaName) {
        'doryeong' || 'dolyeong' =>
          '허허, 말이 나온 김에... 요즘 제가 눈여겨보는 것이 있사온데, '
          '혹시 관심이 있으시면 한번 보시겠소?',
        'seonyeo' || 'sunnyeo' =>
          '후후, 사람의 인연이란 참 묘한 것이지요. '
          '혹시 더 좋은 인연을 원하신다면...',
        'monk' || 'seunim' =>
          '아미타불, 마음의 여유를 갖는 것도 수행이오. '
          '잠시 이것을 살펴보시겠소?',
        'grandmother' || 'halmeoni' =>
          '아이고, 그나저나 요즘 좋은 거 있는디... '
          '한번 볼래?',
        _ =>
          '참, 추천해드리고 싶은 게 있어요. '
          '혹시 관심 있으시면 한번 보실래요?',
      };
    }

    // 인터벌 광고 - 랜덤 문구
    final variants = switch (personaName) {
      'doryeong' || 'dolyeong' => [
        '참, 잠시 후원자님 소개를 드리고 싶구려.',
        '허허, 말이 나온 김에 이것을 한번 보시게나.',
        '잠시 눈을 돌려보시오, 좋은 것이 있구려.',
        '이야기 중에 실례지만, 이것을 권해드리고 싶구려.',
        '참, 요즘 좋다고 소문난 것이 있사온데...',
      ],
      'seonyeo' || 'sunnyeo' => [
        '후후, 잠시 이것을 보여드릴게요.',
        '참, 좋은 인연이 있어서 소개해드릴게요.',
        '잠깐, 이것도 운명의 인연일지 몰라요.',
        '후후, 말 나온 김에 하나 보여드릴게요.',
        '혹시 이런 거 관심 있으세요?',
      ],
      'monk' || 'seunim' => [
        '아미타불, 잠시 시주님 소개를 드리겠습니다.',
        '잠시 마음의 여유를 갖고 이것을 살펴보시오.',
        '아미타불, 좋은 인연을 맺어드리겠습니다.',
        '잠깐 눈을 돌려 세상 구경도 하시오.',
        '이것도 하나의 인연이라 생각하시오.',
      ],
      'grandmother' || 'halmeoni' => [
        '아이고, 잠깐 이거 좀 봐봐.',
        '참, 요즘 이런 게 있더라고.',
        '잠깐만, 할미가 좋은 거 하나 보여줄게.',
        '어머, 이거 한번 봐봐. 괜찮은 거야.',
        '아이고, 쉬어가면서 이것도 좀 봐라.',
      ],
      _ => [
        '잠시 추천 드릴게요.',
        '참, 이것도 한번 보실래요?',
        '잠깐, 좋은 거 하나 보여드릴게요.',
        '말 나온 김에 추천해드리고 싶은 게 있어요.',
        '혹시 이런 거 관심 있으세요?',
      ],
    };
    return variants[_random.nextInt(variants.length)];
  }

  /// CTA(Call-to-Action) 문구
  static String getCtaText(AiPersona persona, AdTriggerResult trigger) {
    final personaName = persona.name.toLowerCase();

    if (trigger == AdTriggerResult.tokenDepleted) {
      return switch (personaName) {
        'doryeong' || 'dolyeong' =>
          '광고를 보시면 대화를 이어갈 수 있사옵니다.',
        'seonyeo' || 'sunnyeo' =>
          '잠시 보시면 더 깊은 인연 이야기를 나눌 수 있어요.',
        'monk' || 'seunim' =>
          '보시면 법문을 이어가겠습니다.',
        'grandmother' || 'halmeoni' =>
          '이거 보면 얘기 더 해줄게.',
        _ =>
          '광고 시청 후 대화를 계속할 수 있어요.',
      };
    }

    // 토큰 경고 (80%) - 보상형 광고 시청 유도
    if (trigger == AdTriggerResult.tokenNearLimit) {
      return switch (personaName) {
        'doryeong' || 'dolyeong' =>
          '광고를 보시면 AI와 더 대화할 수 있사옵니다!',
        'seonyeo' || 'sunnyeo' =>
          '잠시 광고를 보시면 저와 더 깊은 이야기를 나눌 수 있어요!',
        'monk' || 'seunim' =>
          '광고를 보시면 법문을 더 이어갈 수 있사옵니다.',
        'grandmother' || 'halmeoni' =>
          '이거 보면 얘기 더 해줄 수 있어!',
        _ =>
          '광고를 보면 AI와 더 대화할 수 있어요!',
      };
    }

    // 인터벌 광고 - 중간중간 광고 (랜덤 문구)
    if (trigger == AdTriggerResult.intervalAd) {
      final variants = switch (personaName) {
        'doryeong' || 'dolyeong' => [
          '광고를 누르시면 AI와 더 대화할 수 있사옵니다!',
          '이것을 눌러주시면 이야기를 더 이어갈 수 있구려.',
          '한번 살펴보시면 대화의 깊이가 더해지리다.',
          '누르시면 더 좋은 이야기를 들려드리겠소.',
        ],
        'seonyeo' || 'sunnyeo' => [
          '광고를 누르시면 저와 더 대화할 수 있어요!',
          '살짝 눌러보시면 더 깊은 이야기를 나눌 수 있어요.',
          '터치하시면 인연의 이야기가 계속돼요.',
          '눌러주시면 더 재미있는 얘기 해드릴게요!',
        ],
        'monk' || 'seunim' => [
          '광고를 누르시면 대화를 더 이어갈 수 있습니다.',
          '살펴보시면 법문을 계속 이어가겠습니다.',
          '한번 눌러보시오, 좋은 공덕이 되리다.',
          '터치하시면 이야기를 더 나눌 수 있사옵니다.',
        ],
        'grandmother' || 'halmeoni' => [
          '이거 누르면 얘기 더 할 수 있어!',
          '한번 눌러봐, 더 얘기해줄게!',
          '이거 터치하면 할미가 더 알려줄게.',
          '눌러봐, 재밌는 얘기가 더 있단다!',
        ],
        _ => [
          '광고를 누르면 AI와 더 대화할 수 있어요!',
          '터치하시면 대화를 더 이어갈 수 있어요!',
          '한번 눌러보시면 더 많은 이야기를 나눌 수 있어요.',
          '클릭하시면 대화가 계속돼요!',
        ],
      };
      return variants[_random.nextInt(variants.length)];
    }

    return '';
  }
}
