import '../../../../core/services/supabase_service.dart';
import '../../../../features/profile/domain/entities/saju_profile.dart';
import 'zodiac_identity.dart';
import 'zodiac_resolver.dart';

/// 60갑자 수호동물 이미지 URL 서비스
///
/// Supabase Storage `zodiac-animals` 버킷에서 이미지 로드.
/// 오프라인 시 로컬 에셋 fallback.
///
/// ## 파일명 규칙
/// `zodiac_{element}_{animal}.webp`
/// - element: wood, fire, earth, metal, water (천간 오행)
/// - animal: rat, ox, tiger, rabbit, dragon, snake, horse, sheep, monkey, rooster, dog, pig
///
/// ## 버킷 구조
/// ```
/// zodiac-animals/
/// ├── zodiac_fire_horse.webp     (128px, 채팅 아바타)
/// └── large/
///     └── zodiac_fire_horse.webp (512px, 온보딩)
/// ```
class ZodiacImageService {
  ZodiacImageService._();

  static const _bucket = 'zodiac-animals';

  /// Supabase Storage base URL
  static String get _bucketUrl {
    final base = SupabaseService.supabaseUrl;
    if (base == null) return '';
    return '$base/storage/v1/object/public/$_bucket';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // URL 빌더
  // ═══════════════════════════════════════════════════════════════════════════

  /// ZodiacIdentity → 이미지 URL
  ///
  /// [large] true면 온보딩용 큰 이미지 (512px), false면 아바타용 (128px)
  static String? getImageUrl(ZodiacIdentity identity, {bool large = false}) {
    if (_bucketUrl.isEmpty) return null;
    final name = _buildFilename(identity);
    final prefix = large ? 'large/' : '';
    return '$_bucketUrl/$prefix$name';
  }

  /// SajuProfile로 일주 기반 이미지 URL (정확한 매칭)
  ///
  /// 음력/진태양시/자시 보정 모두 적용.
  static String? getImageUrlByProfile(
    SajuProfile profile, {
    String? localeCode,
    bool large = false,
  }) {
    final identity =
        ZodiacResolver.fromProfile(profile, localeCode: localeCode);
    return getImageUrl(identity, large: large);
  }

  /// 생년으로 바로 이미지 URL
  ///
  /// ⚠️ DEPRECATED — 띠(년주) 기반. 음력/진태양시 보정 안 됨.
  /// `getImageUrlByProfile(profile)` 사용 (일주 기반).
  @Deprecated('Use getImageUrlByProfile(profile) — accurate Day Pillar')
  static String? getImageUrlByYear(int birthYear, {bool large = false}) {
    // ignore: deprecated_member_use_from_same_package
    return getImageUrl(ZodiacIdentity.fromBirthYear(birthYear), large: large);
  }

  /// persona ID + element로 이미지 URL (persona selector용)
  ///
  /// [personaId] 'zodiac_horse' 등
  /// [elementKey] 'fire' 등 (null이면 동물 고유 오행 사용)
  static String? getImageUrlByPersonaId(String personaId, {String? elementKey, bool large = false}) {
    if (_bucketUrl.isEmpty) return null;
    final animal = personaId.replaceFirst('zodiac_', '');
    final element = elementKey ?? _defaultElement(personaId);
    final prefix = large ? 'large/' : '';
    return '$_bucketUrl/${prefix}zodiac_${element}_$animal.webp';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 로컬 에셋 fallback
  // ═══════════════════════════════════════════════════════════════════════════

  /// 로컬 에셋 경로 (오프라인 fallback)
  static String getLocalAsset(ZodiacIdentity identity) {
    return 'assets/images/zodiac/${_buildFilename(identity)}';
  }

  static String getLocalAssetByPersonaId(String personaId, {String? elementKey}) {
    final animal = personaId.replaceFirst('zodiac_', '');
    final element = elementKey ?? _defaultElement(personaId);
    return 'assets/images/zodiac/zodiac_${element}_$animal.webp';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 내부 헬퍼
  // ═══════════════════════════════════════════════════════════════════════════

  static String _buildFilename(ZodiacIdentity identity) {
    final element = identity.elementNameEn.toLowerCase();
    final animal = identity.animalPersonaId.replaceFirst('zodiac_', '');
    return 'zodiac_${element}_$animal.webp';
  }

  /// persona ID → 동물 고유 오행 (지지 기준)
  static String _defaultElement(String personaId) {
    const map = {
      'zodiac_rat': 'water',
      'zodiac_ox': 'earth',
      'zodiac_tiger': 'wood',
      'zodiac_rabbit': 'wood',
      'zodiac_dragon': 'earth',
      'zodiac_snake': 'fire',
      'zodiac_horse': 'fire',
      'zodiac_sheep': 'earth',
      'zodiac_monkey': 'metal',
      'zodiac_rooster': 'metal',
      'zodiac_dog': 'earth',
      'zodiac_pig': 'water',
    };
    return map[personaId] ?? 'earth';
  }
}
