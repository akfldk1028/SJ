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
/// ## 실측 데이터 (2026-02 기준, Supabase DB)
///
/// ### Gemini API 비용 (실측 2026-03)
/// - 평균 $0.47/1M 토큰 (Gemini 3 Flash Preview, input+output 혼합)
/// - 일일 유저당 평균 API 비용: $0.03
/// - 10,000 토큰 보상 시 API 원가: $0.0047
///
/// ### 유저 행동 (비프리미엄, daily_quota=20,000)
/// - 메시지당 평균 토큰: ~5,200 (assistant 응답 기준)
/// - 기본 쿼타 대화량: 20,000 / 5,200 = ~3.8회
/// - 광고 시청 유저 평균: 대화 19회/일, 광고 ~6번 클릭
/// - 기본 유저 평균: 대화 5회/일
///
/// ### AdMob 수익 (한국 시장)
/// - 네이티브 CPC: $0.05~$1.00 (평균 ~$0.25)
/// - 리워드 영상: eCPM $15~$30 (한국 iOS $29), 1회 $0.015~$0.030
/// - 인라인 배너: eCPM $0.50~$1.50
/// - 전면 광고: eCPM $5~$11 (한국 Android $11.23)
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
  /// 6 = 3번째 대화 후 광고 1회 (유저+AI = 2메시지 × 3 = 6)
  static const int inlineAdMessageInterval = 4;

  /// 인라인 광고 최대 개수 (세션당) 이건그냥 많은게좋음
  static const int inlineAdMaxCount = 9999;
  /// 인라인 광고 최소 메시지 수 (이보다 적으면 광고 안 보임)
  /// 6 = 3번째 대화 후부터 광고 시작
  static const int inlineAdMinMessages = 4;

  // ==================== 전면 광고 ====================

  /// 전면 광고 표시 간격 (메시지 수)
  static const int interstitialMessageInterval = 5;

  /// 하루 최대 전면 광고 횟수
  static const int interstitialDailyLimit = 15;

  /// 전면 광고 쿨다운 (초)
  static const int interstitialCooldownSeconds = 60;

  /// 새 세션 시작 시 전면 광고 표시 여부
  static const bool showInterstitialOnNewSession = true;

  /// 새 세션 전면 광고 하루 최대 횟수
  static const int newSessionInterstitialDailyLimit = 5;

  // ==================== 토큰 보상 설정 ====================
  // ★ 여기서 보상 토큰 값 조정 ★
  //
  // [실측] 메시지당 평균 ~5,200 토큰, 일일 쿼타 20,000
  // 기본 대화 ~3.8회 → 광고로 추가 대화 확보
  //
  // [수익성] 네이티브 CPC ~$0.25, API 비용 $0.006/10K토큰
  //   → 10,000 토큰 보상: 순이익 $0.244/클릭 (마진 97.6%)
  //
  // [유저 패턴] 광고 시청 유저: 평균 6번 클릭 → 대화 19회/일

  /// 토큰 소진 → 전면 광고 5초 후 충전할 토큰량
  /// 전면 광고 eCPM $11.23 (한국 Android) → 1회 $0.011 수익
  /// Gemini 실측 $0.47/1M tokens → 14K = $0.0066 비용
  /// 순이익: $0.005 (~6원/회), 대화 ~2-3회 추가
  static const int depletedRewardTokensVideo = 14000;

  /// 토큰 소진 → 광고 로드 실패 시 소량 fallback 토큰
  /// 유저가 완전히 막히지 않도록 최소 1회 대화 가능량 지급
  static const int depletedFallbackTokens = 5000;

  /// 토큰 소진 → 네이티브 광고 보상 토큰: 0 (정책 위반 방지)
  /// v3: 네이티브 클릭 → 토큰 보상 제거 (AdMob 인센티브화 클릭 정책 위반)
  static const int depletedRewardTokensNative = 0;

  /// 인터벌(대화 중) 네이티브 광고 클릭 시 보상 토큰: 0 (정책 위반 방지)
  /// v3: 네이티브 클릭 → 토큰 보상 제거 (AdMob 인센티브화 클릭 정책 위반)
  static const int intervalClickRewardTokens = 0;

  // ==================== AdFit 보상 설정 ====================
  // AdFit은 CPC 모델 → 클릭 = 수익 → 인센티브화 보상 정책 위반 아님
  // AdMob과 별도 보상 정책 적용

  /// AdFit 네이티브 클릭 보상 토큰 (CPC 모델이므로 보상 OK)
  static const int adfitNativeClickRewardTokens = 10000;

  /// AdFit 전면 광고 보상 토큰 (AdMob 전면과 동일)
  static const int adfitInterstitialRewardTokens = 14000;

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
