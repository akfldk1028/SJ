/// 십이지신 페르소나 모듈
///
/// 60갑자 기반 AI 동물 캐릭터 시스템
/// - 12개 동물 페르소나 (기본 성격)
/// - 5색 오행 모디파이어 (천간 기반 성격 보정)
/// - 60갑자 조합 = "푸른 말", "흰 호랑이" 등
///
/// ## 사용법
/// ```dart
/// import 'package:sadam/AI/jina/personas/zodiac/zodiac.dart';
///
/// // 생년으로 정체성 조회
/// final identity = ZodiacPersonaMatcher.getIdentity(1990);
/// print(identity.fullName);  // "흰 말"
/// print(identity.ganji);     // "경오"
///
/// // 올해의 동물
/// final year = ZodiacPersonaMatcher.currentYearIdentity;
/// print(year.fullName);  // "붉은 말" (2026)
///
/// // 동물 페르소나 가져오기
/// final persona = PersonaSelector.getByBirthYear(1990);
/// ```
library;

// 핵심 모듈
export 'zodiac_persona_matcher.dart';
export 'zodiac_identity.dart';
export 'zodiac_resolver.dart';

// 12동물 페르소나
export 'zodiac_rat.dart';
export 'zodiac_ox.dart';
export 'zodiac_tiger.dart';
export 'zodiac_rabbit.dart';
export 'zodiac_dragon.dart';
export 'zodiac_snake.dart';
export 'zodiac_horse.dart';
export 'zodiac_sheep.dart';
export 'zodiac_monkey.dart';
export 'zodiac_rooster.dart';
export 'zodiac_dog.dart';
export 'zodiac_pig.dart';
