import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/data/query_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profile/domain/entities/saju_profile.dart';

import '../../../../AI/data/queries.dart';
import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/common/korea_date_utils.dart';
import '../../../../core/supabase/generated/ai_summaries.dart';
import '../../../../core/services/error_logging_service.dart';
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

  /// 자정 자동 갱신 Timer (static으로 중복 방지)
  static Timer? _midnightTimer;

  /// v8: DB 쿼리 타임아웃 시 재시도 카운터 (최대 3회)
  static int _queryRetryCount = 0;
  static const int _maxQueryRetries = 3;

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

  /// 다음 자정(KST)에 provider를 자동 갱신하는 Timer 설정
  /// 앱이 활성 상태에서 자정을 넘기는 경우 대응
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = KoreaDateUtils.nowKorea();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now) + const Duration(seconds: 2);
    print('[DailyFortune] ⏰ 자정 Timer 설정: ${duration.inMinutes}분 후 갱신');
    _midnightTimer = Timer(duration, () {
      print('[DailyFortune] 🌙 자정 도달 - provider 갱신');
      _midnightTimer = null;
      ref.invalidateSelf();
    });
  }

  /// v8: DB 쿼리 타임아웃/오류 시 자동 재시도 (5초 후, 최대 3회)
  void _scheduleRetry() {
    if (_queryRetryCount >= _maxQueryRetries) {
      print('[DailyFortune] ❌ 재시도 한도 초과 ($_maxQueryRetries회) - 포기');
      _queryRetryCount = 0;
      return;
    }
    _queryRetryCount++;
    print('[DailyFortune] 🔄 $_queryRetryCount/$_maxQueryRetries 재시도 예약 (5초 후)');
    Future.delayed(const Duration(seconds: 5), () {
      ref.invalidateSelf();
    });
  }

  @override
  Future<DailyFortuneData?> build() async {
    // Phase 60: keepAlive로 탭 이동 시에도 Provider 상태 유지
    ref.keepAlive();

    // 자정 Timer: 앱 활성 상태에서 날짜 넘어가면 자동 갱신
    _scheduleMidnightRefresh();

    // v9: 전체 build()를 try-catch로 감싸 예외 누수 방지
    // 어떤 예외든 build()가 반드시 완료되어야 UI가 loading에서 벗어남
    try {
      return await _buildInternal();
    } catch (e, st) {
      print('[DailyFortune] ❌ build() 예외 누수 방지: $e');
      ErrorLoggingService.logError(
        operation: 'daily_fortune_build',
        errorMessage: 'build() uncaught exception: $e',
        errorType: 'uncaught',
        sourceFile: 'daily_fortune_provider.dart',
        stackTrace: st.toString(),
      );
      // 5초 후 재시도
      Future.delayed(const Duration(seconds: 5), () {
        ref.invalidateSelf();
      });
      return null;
    }
  }

  /// build() 내부 로직 (v9: 외부 try-catch에서 호출)
  Future<DailyFortuneData?> _buildInternal() async {
    // v10: ref.read 사용 (ref.watch 대신)
    // ref.watch는 activeProfileProvider가 변경될 때마다 build()를 취소+재시작시킴
    // → 앱 시작 시 프로필 동기화/리빌드가 반복되면 build()가 영원히 완료 안 됨 (무한로딩)
    // 프로필 변경 시에는 profile_provider.dart에서 이미 ref.invalidate(dailyFortuneProvider) 호출함
    SajuProfile? activeProfile;
    try {
      activeProfile = await ref.read(activeProfileProvider.future)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      print('[DailyFortune] ⚠️ activeProfileProvider 타임아웃 (10초)');
      ErrorLoggingService.logError(
        operation: 'daily_fortune_load',
        errorMessage: 'activeProfileProvider timeout (10s)',
        errorType: 'timeout',
        sourceFile: 'daily_fortune_provider.dart',
        extraData: {'retry': _queryRetryCount},
      );
      _scheduleRetry();
      return null;
    } catch (e, st) {
      print('[DailyFortune] ❌ activeProfileProvider 오류: $e');
      ErrorLoggingService.logError(
        operation: 'daily_fortune_load',
        errorMessage: 'activeProfileProvider error: $e',
        errorType: 'profile_error',
        sourceFile: 'daily_fortune_provider.dart',
        stackTrace: st.toString(),
      );
      _scheduleRetry();
      return null;
    }
    if (activeProfile == null) return null;

    // 🔧 한국 시간 기준으로 조회해야 캐시 히트됨 (저장도 한국 시간 기준)
    final today = KoreaDateUtils.today;
    final analyzedKey = _getAnalyzedKey(activeProfile.id, today);

    // Phase 60 v2: 날짜 변경 시 이전 날짜 항목 정리 (메모리 누수 방지)
    _cleanupOldEntries(today);

    // ═══════════════════════════════════════════════════════════════════════════
    // v11: DB 캐시를 항상 먼저 조회 (flag 체크보다 우선)
    // DB에 데이터가 있으면 어떤 상태든 즉시 반환
    // ═══════════════════════════════════════════════════════════════════════════

    QueryResult<AiSummaries?> result;
    try {
      result = await aiQueries.getDailyFortune(activeProfile.id, today, locale: activeProfile.locale)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      print('[DailyFortune] ⚠️ DB 쿼리 타임아웃 (8초) - 재시도 예약');
      ErrorLoggingService.logError(
        operation: 'daily_fortune_db_query',
        errorMessage: 'getDailyFortune timeout (8s) - profileId=${activeProfile.id}',
        errorType: 'timeout',
        sourceFile: 'daily_fortune_provider.dart',
        extraData: {'profileId': activeProfile.id, 'retry': _queryRetryCount},
      );
      _scheduleRetry();
      return null;
    } catch (e, st) {
      print('[DailyFortune] ❌ DB 쿼리 오류: $e - 재시도 예약');
      ErrorLoggingService.logError(
        operation: 'daily_fortune_db_query',
        errorMessage: 'getDailyFortune error: $e',
        errorType: 'query_error',
        sourceFile: 'daily_fortune_provider.dart',
        stackTrace: st.toString(),
        extraData: {'profileId': activeProfile.id, 'retry': _queryRetryCount},
      );
      _scheduleRetry();
      return null;
    }

    // DB에 데이터 있으면 즉시 반환 (flag 무시)
    if ((result.isSuccess || result.isOffline) && result.data != null) {
      final aiSummary = result.data!;
      final content = aiSummary.content;
      if (content.isNotEmpty) {
        _analyzedToday.add(analyzedKey);
        _currentlyAnalyzing.remove(activeProfile.id);
        _queryRetryCount = 0;

        final fortune = DailyFortuneData.fromJson(content);
        print('[DailyFortune] ✅ 캐시 히트 - 오늘의 운세 로드');
        return fortune;
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 캐시 미스: 분석 중이면 대기, 아니면 분석 시작
    // ═══════════════════════════════════════════════════════════════════════════

    // 현재 분석 중이면 대기
    if (_currentlyAnalyzing.contains(activeProfile.id)) {
      print('[DailyFortune] ⏳ 분석 중 - 대기 (profileId=${activeProfile.id})');
      return null;
    }

    // FortuneCoordinator에서 분석 중이면 폴링
    if (FortuneCoordinator.isAnalyzing(activeProfile.id)) {
      print('[DailyFortune] ⏳ FortuneCoordinator 분석 중 - 폴링 시작');
      _analyzedToday.add(analyzedKey);
      _waitForCoordinatorCompletion(activeProfile.id, activeProfile.locale);
      return null;
    }

    // 오늘 이미 분석 시도했으면 스킵
    if (_analyzedToday.contains(analyzedKey)) {
      print('[DailyFortune] ⏭️ 오늘 이미 분석 시도함 - 스킵');
      return null;
    }

    // 캐시 없음 → 분석 트리거
    print('[DailyFortune] 캐시 없음 - AI 분석 시작');
    await _triggerAnalysisIfNeeded(activeProfile.id, today, activeProfile.locale);
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
  Future<void> _triggerAnalysisIfNeeded(String profileId, DateTime today, [String locale = 'ko']) async {
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
      locale: locale,
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
          ErrorLoggingService.logError(
            operation: 'daily_fortune_analysis',
            errorMessage: 'Daily 분석 최종 실패 (2회 재시도 소진): $errorMsg',
            errorType: 'analysis_failed',
            sourceFile: 'daily_fortune_provider.dart',
            extraData: {'profileId': profileId, 'analyzedKey': analyzedKey},
          );
        }
      }
    }).catchError((e, st) {
      print('[DailyFortune] ❌ Daily 분석 오류: $e');
      _currentlyAnalyzing.remove(profileId);
      ErrorLoggingService.logError(
        operation: 'daily_fortune_analysis',
        errorMessage: 'Daily 분석 오류: $e',
        sourceFile: 'daily_fortune_provider.dart',
        stackTrace: st.toString(),
        extraData: {'profileId': profileId},
      );

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
  void _waitForCoordinatorCompletion(String profileId, [String locale = 'ko']) {
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
      final result = await aiQueries.getDailyFortune(profileId, today, locale: locale);
      if (result.isSuccess && result.data != null && result.data!.content.isNotEmpty) {
        print('[DailyFortune] ✅ Daily Fortune DB 데이터 감지 ($attempts회) - UI 갱신');
        _pollingForCompletion.remove(profileId);
        ref.invalidateSelf();
        return false; // stop polling
      }

      if (attempts >= maxAttempts) {
        print('[DailyFortune] ⚠️ 폴링 타임아웃 ($maxAttempts회)');
        _pollingForCompletion.remove(profileId);
        ErrorLoggingService.logError(
          operation: 'daily_fortune_polling',
          errorMessage: '폴링 타임아웃 (${maxAttempts * 3}초) - DB 데이터 없음',
          errorType: 'timeout',
          sourceFile: 'daily_fortune_provider.dart',
          extraData: {'profileId': profileId, 'attempts': maxAttempts},
        );
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

/// 특정 날짜의 운세 Provider (캘린더용)
/// ref.read 사용: activeProfileProvider 변경 시 캘린더가 불필요하게 리빌드되지 않도록
@riverpod
Future<DailyFortuneData?> dailyFortuneForDate(Ref ref, DateTime date) async {
  final activeProfile = await ref.read(activeProfileProvider.future);
  if (activeProfile == null) return null;

  final result = await aiQueries.getDailyFortune(activeProfile.id, date, locale: activeProfile.locale);
  if (result.isFailure || result.data == null) return null;

  final content = result.data!.content;
  if (content.isEmpty) return null;

  return DailyFortuneData.fromJson(content);
}

/// 프로필의 일운이 있는 날짜 목록 Provider (캘린더 마커용)
/// ref.read 사용: activeProfileProvider 변경 시 불필요한 리빌드 방지
@riverpod
Future<List<DateTime>> dailyFortuneDates(Ref ref) async {
  final activeProfile = await ref.read(activeProfileProvider.future);
  if (activeProfile == null) return [];

  final result = await aiQueries.getDailyFortuneDates(activeProfile.id, locale: activeProfile.locale);
  return result.data ?? [];
}
