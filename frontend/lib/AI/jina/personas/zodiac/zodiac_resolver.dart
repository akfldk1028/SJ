import '../../../../features/profile/domain/entities/saju_profile.dart';
import '../../../../features/saju_chart/domain/services/saju_calculation_service.dart';
import '../../../../features/saju_chart/domain/services/true_solar_time_service.dart';
import 'zodiac_identity.dart';

/// SajuProfile → ZodiacIdentity 변환 헬퍼
///
/// 음력/진태양시/DST/자시 모두 보정해서 정확한 일주(Day Pillar) 갑자로
/// ZodiacIdentity 생성. 온보딩과 동일한 경로.
///
/// `ZodiacIdentity.fromBirthDate`는 양력만 받고 음력 보정이 없어
/// 음력 입력 사용자의 일주가 어긋나는 버그가 있었음. 모든 화면은 이 헬퍼 사용 권장.
class ZodiacResolver {
  ZodiacResolver._();

  static final SajuCalculationService _saju = SajuCalculationService();

  /// SajuProfile로부터 일주 기반 ZodiacIdentity 생성
  ///
  /// [profile] 활성 프로필 (음력/양력, 진태양시 도시, 자시 처리 등 포함)
  /// [localeCode] 도시 정보가 비어있을 때 사용할 기본 도시 결정용 (현재 locale)
  static ZodiacIdentity fromProfile(
    SajuProfile profile, {
    String? localeCode,
  }) {
    final fallbackCity = TrueSolarTimeService.defaultCityForLocale(
      localeCode ?? 'ko',
    );
    final city = profile.birthCity.isNotEmpty ? profile.birthCity : fallbackCity;

    final chart = _saju.calculate(
      birthDateTime: profile.birthDate,
      birthCity: city,
      isLunarCalendar: profile.isLunar,
      isLeapMonth: profile.isLeapMonth,
      birthTimeUnknown: profile.birthTimeUnknown,
    );

    return ZodiacIdentity.fromGanji(
      chart.dayPillar.gan,
      chart.dayPillar.ji,
    );
  }

  /// BuildContext가 있을 때 (locale 자동 추출)
  static ZodiacIdentity fromProfileWithContext(
    SajuProfile profile,
    String localeCode,
  ) {
    return fromProfile(profile, localeCode: localeCode);
  }
}
