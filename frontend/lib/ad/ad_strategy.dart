/// 광고 전략 설정
/// 사주 앱 비즈니스 맞춤 수익화 전략
library;

/// 채팅 내 광고 유형
enum ChatAdType {
  /// Inline Adaptive Banner (간단, $1~3 eCPM)
  inlineBanner,

  /// Native Ad Medium (채팅 버블 스타일, $3~15 eCPM)
  nativeMedium,

  /// Native Ad Compact (작은 크기, $2~8 eCPM)
  nativeCompact,
}

/// 광고 표시 전략
///
/// ## 수익화 포인트
///
/// ### 1. 배너 광고 (기본 수익)
/// - 위치: 메인 화면 하단 (BottomNavigationBar 위)
/// - 타이밍: 상시 노출
/// - eCPM: $0.5~2 (낮지만 impression 수 많음)
///
/// ### 2. 전면 광고 (중간 수익)
/// - 위치: 화면 전환 시
/// - 타이밍:
///   - 사주 분석 결과 보기 전
///   - 채팅 N개 메시지 후
///   - 새 채팅 세션 시작 시 (하루 3회 제한)
/// - eCPM: $2~10
///
/// ### 3. 보상형 광고 (높은 수익)
/// - 위치: 프리미엄 기능 해제
/// - 타이밍:
///   - 상세 사주 분석 보기
///   - 일일 무료 채팅 횟수 초과
///   - 궁합 분석 무료 체험
/// - eCPM: $10~50 (가장 높음)
abstract class AdStrategy {
  AdStrategy._();

  // ==================== 배너 광고 ====================

  /// 배너 광고 표시 화면
  static const List<String> bannerScreens = [
    '/home',
    '/saju/chat',
    '/relationship',
  ];

  // ==================== 채팅 내 광고 ====================

  /// 채팅 내 광고 유형 설정
  /// - inlineBanner: 간단한 배너 ($1~3 eCPM)
  /// - nativeMedium: 채팅 버블 스타일 ($3~15 eCPM) ★ 추천
  /// - nativeCompact: 컴팩트 네이티브 ($2~8 eCPM)
  static const ChatAdType chatAdType = ChatAdType.nativeMedium;

  /// 인라인 광고 표시 간격 (메시지 수)
  /// 10 = 5번 왕복 대화마다 광고 (유저+AI 메시지 합산)
  /// 첫 광고: 메시지 10개 이후 (minMessages=10), 이후 10개마다
  /// → 대화 흐름 유지 + 적절한 광고 빈도
  static const int inlineAdMessageInterval = 10;

  /// 인라인 광고 최대 개수 (대화 중 지속적으로 표시)
  static const int inlineAdMaxCount = 10;

  /// 인라인 광고 최소 메시지 수 (이보다 적으면 광고 안 보임)
  /// 10 = 5번 왕복 대화 후부터 광고 가능
  static const int inlineAdMinMessages = 10;

  // ==================== 전면 광고 ====================

  /// 전면 광고 표시 간격 (메시지 수)
  static const int interstitialMessageInterval = 5;

  /// 하루 최대 전면 광고 횟수 (9999 = 무제한)
  static const int interstitialDailyLimit = 9999;

  /// 전면 광고 쿨다운 (초) - 0 = 제한 없음
  static const int interstitialCooldownSeconds = 0;

  /// 새 세션 시작 시 전면 광고 표시 여부
  static const bool showInterstitialOnNewSession = true;

  /// 새 세션 전면 광고 하루 최대 횟수 (9999 = 무제한)
  static const int newSessionInterstitialDailyLimit = 9999;

  // ==================== 보상형 광고 ====================

  /// 일일 무료 채팅 횟수
  static const int dailyFreeChatLimit = 10;

  /// 보상형 광고로 추가되는 채팅 횟수
  static const int rewardedChatBonus = 5;

  /// 보상형 광고 쿨다운 (초)
  static const int rewardedCooldownSeconds = 30;

  // ==================== 프리미엄 기능 ====================

  /// 광고 없이 사용 가능한 프리미엄 기능 목록
  static const List<String> premiumFeatures = [
    'detailed_saju_analysis', // 상세 사주 분석
    'compatibility_analysis', // 궁합 분석
    'yearly_fortune', // 연간 운세
    'career_advice', // 직업/사업 조언
    'ad_free', // 광고 제거
  ];
}

/// 광고 표시 조건 체크 결과
class AdCheckResult {
  final bool shouldShow;
  final String? reason;

  const AdCheckResult({
    required this.shouldShow,
    this.reason,
  });

  const AdCheckResult.show() : shouldShow = true, reason = null;

  const AdCheckResult.skip(this.reason) : shouldShow = false;
}
