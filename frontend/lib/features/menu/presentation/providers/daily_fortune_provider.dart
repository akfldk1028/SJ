import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/data/queries.dart';
import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/common/korea_date_utils.dart';
import '../../../../core/supabase/generated/ai_summaries.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'daily_fortune_provider.g.dart';

/// 안전한 int 파싱 (num, String 모두 지원)
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// 오늘의 운세 데이터 모델
class DailyFortuneData {
  final int overallScore;
  final String overallMessage;
  final String overallMessageShort;  // 짧은 버전 (오늘의 한마디)
  final String date;
  final Map<String, CategoryScore> categories;
  final LuckyInfo lucky;
  final IdiomInfo idiom;  // 오늘의 사자성어
  final String caution;
  final String affirmation;

  const DailyFortuneData({
    required this.overallScore,
    required this.overallMessage,
    this.overallMessageShort = '',
    required this.date,
    required this.categories,
    required this.lucky,
    this.idiom = IdiomInfo.empty,
    required this.caution,
    required this.affirmation,
  });

  /// AI 응답 JSON에서 파싱
  factory DailyFortuneData.fromJson(Map<String, dynamic> json) {
    // categories 파싱
    final categoriesJson = json['categories'] as Map<String, dynamic>? ?? {};
    final categories = <String, CategoryScore>{};

    categoriesJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        categories[key] = CategoryScore(
          score: _safeInt(value['score']),
          message: value['message'] as String? ?? '',
          tip: value['tip'] as String? ?? '',
        );
      }
    });

    // lucky 파싱
    final luckyJson = json['lucky'] as Map<String, dynamic>? ?? {};
    final lucky = LuckyInfo(
      time: luckyJson['time'] as String? ?? '',
      color: luckyJson['color'] as String? ?? '',
      number: _safeInt(luckyJson['number']),
      direction: luckyJson['direction'] as String? ?? '',
    );

    // idiom 파싱 (오늘의 사자성어)
    final idiomJson = json['idiom'] as Map<String, dynamic>? ?? {};
    final idiom = IdiomInfo(
      chinese: idiomJson['chinese'] as String? ?? '',
      korean: idiomJson['korean'] as String? ?? '',
      meaning: idiomJson['meaning'] as String? ?? '',
      message: idiomJson['message'] as String? ?? '',
    );

    return DailyFortuneData(
      overallScore: _safeInt(json['overall_score']),
      overallMessage: json['overall_message'] as String? ?? '',
      overallMessageShort: json['overall_message_short'] as String? ?? '',
      date: json['date'] as String? ?? '',
      categories: categories,
      lucky: lucky,
      idiom: idiom,
      caution: json['caution'] as String? ?? '',
      affirmation: json['affirmation'] as String? ?? '',
    );
  }

  /// 카테고리 점수 가져오기
  int getCategoryScore(String category) {
    return categories[category]?.score ?? 0;
  }

  /// 카테고리 메시지 가져오기
  String getCategoryMessage(String category) {
    return categories[category]?.message ?? '';
  }

  /// 카테고리 팁 가져오기
  String getCategoryTip(String category) {
    return categories[category]?.tip ?? '';
  }
}

/// 카테고리별 점수
class CategoryScore {
  final int score;
  final String message;
  final String tip;

  const CategoryScore({
    required this.score,
    required this.message,
    required this.tip,
  });
}

/// 행운 정보
class LuckyInfo {
  final String time;
  final String color;
  final int number;
  final String direction;

  const LuckyInfo({
    required this.time,
    required this.color,
    required this.number,
    required this.direction,
  });
}

/// 오늘의 사자성어 정보
class IdiomInfo {
  final String chinese;   // 한자 (예: 磨斧爲針)
  final String korean;    // 한글 (예: 마부위침)
  final String meaning;   // 뜻풀이 (예: 도끼를 갈아 바늘을 만든다)
  final String message;   // 오늘에 맞는 메시지 (2-3문장)

  const IdiomInfo({
    required this.chinese,
    required this.korean,
    required this.meaning,
    required this.message,
  });

  /// 빈 사자성어 정보
  static const empty = IdiomInfo(
    chinese: '',
    korean: '',
    meaning: '',
    message: '',
  );

  /// 유효한지 확인
  bool get isValid => korean.isNotEmpty && chinese.isNotEmpty;
}

/// 오늘의 운세 Provider
///
/// activeProfile의 오늘 운세를 DB에서 조회
/// 캐시가 없으면 AI 분석을 자동 트리거
///
/// Phase 60: 탭 이동 시 중복 분석 방지
/// - keepAlive로 Provider 상태 유지
/// - 프로필+날짜 기반 분석 완료 플래그 (static Set)
/// - 한국 시간 기준 하루 1회만 분석
@riverpod
class DailyFortune extends _$DailyFortune {
  /// Phase 60: 오늘 이미 분석을 시도한 프로필 ID (한국 날짜 기준)
  /// key: "profileId_yyyy-MM-dd"
  static final Set<String> _analyzedToday = {};

  /// 현재 분석 중인 프로필 ID
  static final Set<String> _currentlyAnalyzing = {};

  /// Phase 60 v3: FortuneCoordinator 완료 대기 폴링 중인 프로필 ID
  /// 중복 폴링 방지 (build() 재호출 시 폴링이 누적되는 문제 해결)
  static final Set<String> _pollingForCompletion = {};

  /// Phase 60 v4: 분석 실패 재시도 횟수 (최대 2회)
  /// key: "profileId_yyyy-MM-dd", value: 시도 횟수
  static final Map<String, int> _retryCount = {};

  /// 분석 완료 플래그 키 생성
  static String _getAnalyzedKey(String profileId, DateTime date) {
    return '${profileId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Phase 60 v2: 이전 날짜 항목 정리 (메모리 누수 방지)
  /// 오늘 날짜가 아닌 키는 제거
  static void _cleanupOldEntries(DateTime today) {
    final todaySuffix = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final oldCount = _analyzedToday.length;
    _analyzedToday.removeWhere((key) => !key.endsWith(todaySuffix));
    _retryCount.removeWhere((key, _) => !key.endsWith(todaySuffix)); // Phase 60 v4
    final removed = oldCount - _analyzedToday.length;
    if (removed > 0) {
      print('[DailyFortune] 🧹 이전 날짜 항목 정리: $removed개 제거');
    }
  }

  /// v7.5: 프로필 수정 시 분석 플래그 초기화 (외부 호출용)
  ///
  /// 프로필이 수정되면 기존 AI 캐시가 삭제되므로,
  /// _analyzedToday 플래그도 초기화해야 새 분석이 실행됨.
  ///
  /// [profileId] 초기화할 프로필 ID
  static void resetAnalyzedFlagForProfile(String profileId) {
    final today = KoreaDateUtils.today;
    final analyzedKey = _getAnalyzedKey(profileId, today);

    final hadFlag = _analyzedToday.contains(analyzedKey);
    _analyzedToday.remove(analyzedKey);
    _currentlyAnalyzing.remove(profileId);
    _pollingForCompletion.remove(profileId);
    _retryCount.remove(analyzedKey);

    if (hadFlag) {
      print('[DailyFortune] 🔄 v7.5 프로필 수정 - 분석 플래그 초기화 (key=$analyzedKey)');
    }
  }

  @override
  Future<DailyFortuneData?> build() async {
    // Phase 60: keepAlive로 탭 이동 시에도 Provider 상태 유지
    ref.keepAlive();

    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    // 🔧 한국 시간 기준으로 조회해야 캐시 히트됨 (저장도 한국 시간 기준)
    final today = KoreaDateUtils.today;
    final analyzedKey = _getAnalyzedKey(activeProfile.id, today);

    // Phase 60 v2: 날짜 변경 시 이전 날짜 항목 정리 (메모리 누수 방지)
    _cleanupOldEntries(today);

    // ═══════════════════════════════════════════════════════════════════════════
    // Phase 60 v3: 빠른 반환 조건
    // ═══════════════════════════════════════════════════════════════════════════

    // 1. 현재 이 Provider가 직접 분석을 시작한 상태면 대기
    if (_currentlyAnalyzing.contains(activeProfile.id)) {
      print('[DailyFortune] ⏳ 분석 중 - 대기 (profileId=${activeProfile.id})');
      return null;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Phase 60 v3: DB 캐시 확인 (FortuneCoordinator 상태보다 먼저!)
    // 🔴 핵심 수정: DB에 데이터가 있으면 FortuneCoordinator가 다른 분석을
    //    진행 중이더라도 즉시 반환. 이전에는 isAnalyzing 체크가 먼저여서
    //    monthly/yearly 분석 중(60-120초) 동안 daily 데이터를 무시했음.
    // ═══════════════════════════════════════════════════════════════════════════

    final result = await aiQueries.getDailyFortune(activeProfile.id, today);

    // 캐시가 있으면 바로 반환
    if (result.isSuccess && result.data != null) {
      final aiSummary = result.data!;
      final content = aiSummary.content;
      if (content != null) {
        // Phase 60: 캐시 히트 시 분석 완료로 마킹
        _analyzedToday.add(analyzedKey);
        _currentlyAnalyzing.remove(activeProfile.id);

        final fortune = DailyFortuneData.fromJson(content as Map<String, dynamic>);
        print('[DailyFortune] idiom 파싱 결과: korean="${fortune.idiom.korean}", chinese="${fortune.idiom.chinese}", isValid=${fortune.idiom.isValid}');

        // idiom이 없어도 기존 데이터 그대로 사용
        // - prompt_version 필터가 이미 구버전 캐시를 걸러냄
        // - 재분석해도 DailyService가 캐시 히트하여 동일 데이터 반환 → 무한루프 위험
        if (!fortune.idiom.isValid) {
          print('[DailyFortune] ⚠️ idiom 없음 - 기존 데이터 그대로 사용');
        }

        print('[DailyFortune] ✅ 캐시 히트 - 오늘의 운세 로드 (분석 스킵)');
        return fortune;
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Phase 60 v3: 캐시 미스 → FortuneCoordinator 상태 확인 → 분석 트리거
    // ═══════════════════════════════════════════════════════════════════════════

    // 3. FortuneCoordinator에서 분석 중이면 폴링 시작 후 null 반환
    //    (DB 캐시 miss인 경우에만 도달 = daily가 아직 DB에 없는 것)
    if (FortuneCoordinator.isAnalyzing(activeProfile.id)) {
      print('[DailyFortune] ⏳ FortuneCoordinator에서 분석 중 - 폴링 시작 (daily 아직 미완료)');
      _analyzedToday.add(analyzedKey);  // 중복 시도 방지
      _waitForCoordinatorCompletion(activeProfile.id);
      return null;
    }

    // 4. 오늘 이미 분석 시도했으면 스킵 (중복 방지)
    if (_analyzedToday.contains(analyzedKey)) {
      print('[DailyFortune] ⏭️ 오늘 이미 분석 시도함 - 스킵 (key=$analyzedKey)');
      return null;
    }

    // 5. 캐시가 없으면 AI 분석 트리거
    print('[DailyFortune] 캐시 없음 - AI 분석 시작');
    await _triggerAnalysisIfNeeded(activeProfile.id, today);

    // 분석 완료 후 다시 조회 (null 반환하면 UI에서 "분석 중" 표시)
    return null;
  }

  /// AI 분석 트리거 (중복 호출 방지)
  ///
  /// v7.3: analyzeFortuneOnly → analyzeDailyOnly로 변경
  /// 홈 화면에서 일운 캐시 미스 시 Daily만 단독 분석 (Gemini Flash ~3초).
  /// 기존 analyzeFortuneOnly는 4개(daily+monthly+yearly) 전부 돌려서 ~2분 소요.
  /// monthly/yearly는 프로필 저장 시 또는 해당 화면 진입 시 개별 분석.
  ///
  /// Phase 60: 한국 시간 기준 하루 1회만 분석
  /// - _analyzedToday: 오늘 이미 분석 시도한 프로필 (날짜별)
  /// - _currentlyAnalyzing: 현재 분석 중인 프로필
  Future<void> _triggerAnalysisIfNeeded(String profileId, DateTime today) async {
    final analyzedKey = _getAnalyzedKey(profileId, today);

    // Phase 60: 오늘 이미 분석 시도했으면 스킵
    if (_analyzedToday.contains(analyzedKey)) {
      print('[DailyFortune] ⏭️ 오늘 이미 분석 시도함 - 스킵 (key=$analyzedKey)');
      return;
    }

    // Phase 60: 현재 분석 중이면 스킵
    if (_currentlyAnalyzing.contains(profileId)) {
      print('[DailyFortune] 이미 분석 중 - 스킵');
      return;
    }

    // v6.1 전역 중복 체크 (FortuneCoordinator에서 이미 분석 중인지)
    if (FortuneCoordinator.isAnalyzing(profileId)) {
      print('[DailyFortune] ⏭️ FortuneCoordinator에서 이미 분석 중 - 완료 대기');
      // Phase 60: 분석 완료로 마킹 (중복 시도 방지)
      _analyzedToday.add(analyzedKey);
      // FortuneCoordinator가 완료될 때까지 폴링하여 UI 갱신
      _waitForCoordinatorCompletion(profileId);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[DailyFortune] 사용자 없음 - 분석 스킵');
      return;
    }

    // Phase 60: 분석 시작 마킹
    _currentlyAnalyzing.add(profileId);
    _analyzedToday.add(analyzedKey);
    print('[DailyFortune] 🚀 v7.3 Daily만 분석 시작 (Gemini Flash ~3초)');
    print('[DailyFortune] Phase 60: analyzedKey=$analyzedKey 등록');

    // v7.3: Daily만 단독 분석 (Gemini Flash ~3초)
    // - 기존 analyzeFortuneOnly는 4개(daily+monthly+yearly) 전부 돌려서 ~2분 소요
    // - monthly/yearly는 프로필 저장 시 또는 해당 화면 진입 시 개별 분석
    fortuneCoordinator.analyzeDailyOnly(
      userId: user.id,
      profileId: profileId,
    ).then((result) {
      _currentlyAnalyzing.remove(profileId);

      // Phase 60 v4: 성공 시 즉시 갱신, 실패 시 제한된 재시도 (최대 2회)
      if (result.success) {
        print('[DailyFortune] ✅ Daily 분석 성공 - UI 갱신');
        _retryCount.remove(analyzedKey);
        ref.invalidateSelf();
      } else {
        final errorMsg = result.errorMessage ?? 'unknown';

        // v7.6: "이미 분석 중" 에러는 진짜 실패가 아님
        // FortuneCoordinator가 '진행 중' 메시지를 반환한 경우
        // → _analyzedToday 가드 유지 (제거하지 않음!)
        // → 폴링으로 완료 대기
        if (errorMsg.contains('진행 중')) {
          print('[DailyFortune] ⏳ v7.6 이미 분석 진행 중 감지 - 폴링 전환 (재시도 안 함): $errorMsg');
          _waitForCoordinatorCompletion(profileId);
          return;
        }

        // 진짜 실패만 재시도
        final retries = _retryCount[analyzedKey] ?? 0;
        if (retries < 2) {
          _retryCount[analyzedKey] = retries + 1;
          _analyzedToday.remove(analyzedKey); // 재시도 허용
          print('[DailyFortune] ⚠️ Daily 분석 실패 (재시도 ${retries + 1}/2): $errorMsg');
          // 3초 후 재시도 (Gemini 응답 불안정 대응)
          Future.delayed(const Duration(seconds: 3), () {
            ref.invalidateSelf();
          });
        } else {
          print('[DailyFortune] ❌ Daily 분석 최종 실패 (2회 재시도 소진): $errorMsg');
        }
      }
    }).catchError((e) {
      print('[DailyFortune] ❌ Daily 분석 오류: $e');
      _currentlyAnalyzing.remove(profileId);

      // v7.6: catchError에서도 "진행 중" 에러 체크
      final errorStr = e.toString();
      if (errorStr.contains('진행 중')) {
        print('[DailyFortune] ⏳ v7.6 오류 내 진행 중 감지 - 폴링 전환');
        _waitForCoordinatorCompletion(profileId);
        return;
      }

      final retries = _retryCount[analyzedKey] ?? 0;
      if (retries < 2) {
        _retryCount[analyzedKey] = retries + 1;
        _analyzedToday.remove(analyzedKey);
        print('[DailyFortune] 🔄 오류 후 재시도 예정 (${retries + 1}/2)');
        Future.delayed(const Duration(seconds: 3), () {
          ref.invalidateSelf();
        });
      }
    });
  }

  /// Daily Fortune DB 데이터가 생길 때까지 폴링 후 provider 갱신
  /// FortuneCoordinator 전체 완료를 기다리지 않고, daily만 완료되면 즉시 UI 갱신
  ///
  /// Phase 60 v3: _pollingForCompletion Set으로 중복 폴링 방지
  /// 이전에는 build() 재호출마다 새 폴링이 생성되어 누적 → 무한 루프의 원인
  void _waitForCoordinatorCompletion(String profileId) {
    // Phase 60 v3: 이미 이 프로필에 대해 폴링 중이면 스킵
    if (_pollingForCompletion.contains(profileId)) {
      print('[DailyFortune] 🔁 이미 폴링 중 - 스킵 (profileId=$profileId)');
      return;
    }
    _pollingForCompletion.add(profileId);

    final today = KoreaDateUtils.today;
    int attempts = 0;
    const maxAttempts = 60; // 3초 × 60 = 3분

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      attempts++;

      // DB에서 직접 daily fortune 확인
      final result = await aiQueries.getDailyFortune(profileId, today);
      if (result.isSuccess && result.data != null && result.data!.content != null) {
        print('[DailyFortune] ✅ Daily Fortune DB 데이터 감지 ($attempts회) - UI 갱신');
        _pollingForCompletion.remove(profileId);
        ref.invalidateSelf();
        return false; // stop polling
      }

      if (attempts >= maxAttempts) {
        print('[DailyFortune] ⚠️ 폴링 타임아웃 ($maxAttempts회)');
        _pollingForCompletion.remove(profileId);
        return false; // stop polling
      }
      return true; // continue polling
    });
  }

  /// 운세 새로고침 (캐시 무효화)
  ///
  /// Phase 60: 수동 새로고침 시 오늘 분석 플래그 리셋
  /// - 사용자가 명시적으로 새로고침 요청 시에만 재분석 허용
  Future<void> refresh() async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile != null) {
      final today = KoreaDateUtils.today;
      final analyzedKey = _getAnalyzedKey(activeProfile.id, today);
      _analyzedToday.remove(analyzedKey);
      _currentlyAnalyzing.remove(activeProfile.id);
      _pollingForCompletion.remove(activeProfile.id);  // Phase 60 v3: 폴링 플래그도 리셋
      _retryCount.remove(analyzedKey);  // Phase 60 v4: 재시도 횟수도 리셋
      print('[DailyFortune] 🔄 수동 새로고침 - 플래그 리셋 (key=$analyzedKey)');
    }
    ref.invalidateSelf();
  }
}

/// 특정 날짜의 운세 Provider
@riverpod
Future<DailyFortuneData?> dailyFortuneForDate(Ref ref, DateTime date) async {
  final activeProfile = await ref.watch(activeProfileProvider.future);
  if (activeProfile == null) return null;

  final result = await aiQueries.getDailyFortune(activeProfile.id, date);

  if (result.isFailure || result.data == null) {
    return null;
  }

  final aiSummary = result.data!;
  final content = aiSummary.content;

  if (content == null) return null;

  return DailyFortuneData.fromJson(content as Map<String, dynamic>);
}

/// 프로필의 일운이 있는 날짜 목록 Provider (캘린더 마커용)
///
/// ## 용도
/// 캘린더에서 운세가 저장된 날에 마커(점)를 표시하기 위해
/// 해당 프로필의 모든 daily_fortune 날짜를 조회합니다.
///
/// ## 사용 예시
/// ```dart
/// final datesAsync = ref.watch(dailyFortuneDatesProvider);
/// datesAsync.when(
///   data: (dates) => dates.contains(day) ? ['fortune'] : [],
///   ...
/// );
/// ```
@riverpod
Future<List<DateTime>> dailyFortuneDates(Ref ref) async {
  final activeProfile = await ref.watch(activeProfileProvider.future);
  if (activeProfile == null) return [];

  final result = await aiQueries.getDailyFortuneDates(activeProfile.id);
  return result.data ?? [];
}
