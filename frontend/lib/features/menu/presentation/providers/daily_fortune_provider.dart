import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/query_result.dart';
import '../../../../AI/data/queries.dart';
import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/common/korea_date_utils.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/supabase/generated/ai_summaries.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'daily_analysis_step_provider.dart';

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
  final String overallMessageShort;
  final String date;
  final Map<String, CategoryScore> categories;
  final LuckyInfo lucky;
  final IdiomInfo idiom;
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

    final luckyJson = json['lucky'] as Map<String, dynamic>? ?? {};
    final lucky = LuckyInfo(
      time: luckyJson['time'] as String? ?? '',
      color: luckyJson['color'] as String? ?? '',
      number: _safeInt(luckyJson['number']),
      direction: luckyJson['direction'] as String? ?? '',
    );

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

  int getCategoryScore(String category) {
    return categories[category]?.score ?? 0;
  }

  String getCategoryMessage(String category) {
    return categories[category]?.message ?? '';
  }

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
  final String chinese;
  final String korean;
  final String meaning;
  final String message;

  const IdiomInfo({
    required this.chinese,
    required this.korean,
    required this.meaning,
    required this.message,
  });

  static const empty = IdiomInfo(
    chinese: '',
    korean: '',
    meaning: '',
    message: '',
  );

  bool get isValid => korean.isNotEmpty && chinese.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════════════════════════════════════

/// 오늘의 운세 Provider
///
/// 로직:
///   1. 활성 프로필로 DB 조회
///   2. 캐시 히트 → 반환
///   3. 캐시 미스 → AI 분석 트리거 (fire-and-forget) → 완료 시 자동 갱신
///
/// 갱신 시점:
///   - 프로필 변경 → profile_provider가 ref.invalidate(dailyFortuneProvider)
///   - 날짜 변경 → app.dart가 ref.invalidate(dailyFortuneProvider)
///   - 수동 → 사용자 탭 → refresh()
///
/// 중복 분석 방지: FortuneCoordinator가 전담 (_analyzingProfiles, _analyzingDaily)
@riverpod
class DailyFortune extends _$DailyFortune {
  static const String _hiveCacheBoxName = 'daily_fortune_cache';

  /// 프로필별 캐시 키 (프로필 전환 시 다른 운세 표시 방지)
  static String _cacheKey(String profileId) => 'fortune_$profileId';
  static String _cacheDateKey(String profileId) => 'fortune_date_$profileId';

  /// 오프라인 재시도 횟수 (static: invalidateSelf 후에도 유지되어야 함)
  static int _offlineRetryCount = 0;
  static const int _maxOfflineRetries = 10;

  @override
  Future<DailyFortuneData?> build() async {
    ref.keepAlive();

    // dispose 가드 (모든 비동기 콜백에서 사용)
    var isDisposed = false;
    ref.onDispose(() => isDisposed = true);

    // 1. 프로필
    final profile = await ref.read(activeProfileProvider.future);
    if (profile == null) return null;

    final today = KoreaDateUtils.today;
    final todayKey = KoreaDateUtils.currentDateKey;
    final profileId = profile.id;

    // 2. Hive 로컬 캐시 먼저 확인 (즉시 반환 → 0ms)
    final hiveCached = _loadFromHive(profileId, todayKey);
    if (hiveCached != null) {
      // Hive 캐시 히트 → 즉시 표시 + 백그라운드 Supabase 갱신
      _refreshInBackground(profileId, today, todayKey, isDisposed);
      _offlineRetryCount = 0;
      return hiveCached;
    }

    // 3. Supabase DB 조회
    final result = await aiQueries.getDailyFortune(profileId, today);

    // 4. DB 캐시 히트 → 반환 + Hive에 저장
    if ((result.isSuccess || result.isOffline) &&
        result.data != null &&
        result.data!.content.isNotEmpty) {
      _offlineRetryCount = 0;
      final data = DailyFortuneData.fromJson(result.data!.content);
      _saveToHive(profileId, todayKey, result.data!.content);
      return data;
    }

    // 5. 오프라인 상태면 재시도 (최대 10회)
    if (result.isOffline || !SupabaseService.isConnected) {
      if (_offlineRetryCount >= _maxOfflineRetries) {
        print('[DailyFortune] 오프라인 재시도 초과 ($_offlineRetryCount/$_maxOfflineRetries)');
        _offlineRetryCount = 0;
        return null;
      }
      _offlineRetryCount++;
      print('[DailyFortune] 오프라인 - 3초 후 재시도 ($_offlineRetryCount/$_maxOfflineRetries)');
      Future.delayed(const Duration(seconds: 3), () {
        if (!isDisposed) ref.invalidateSelf();
      });
      return null;
    }

    // 6. 캐시 미스 → 분석 트리거
    _triggerAnalysis(profileId);
    return null;
  }

  /// Hive에서 프로필+날짜 매칭 캐시 로드 (동기, 즉시)
  DailyFortuneData? _loadFromHive(String profileId, String todayKey) {
    try {
      if (!Hive.isBoxOpen(_hiveCacheBoxName)) return null;
      final box = Hive.box<String>(_hiveCacheBoxName);
      final cachedDate = box.get(_cacheDateKey(profileId));
      if (cachedDate != todayKey) return null;
      final jsonStr = box.get(_cacheKey(profileId));
      if (jsonStr == null) return null;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      print('[DailyFortune] Hive 캐시 히트 (profile=$profileId, date=$todayKey)');
      return DailyFortuneData.fromJson(json);
    } catch (e) {
      print('[DailyFortune] Hive 캐시 읽기 실패: $e');
      return null;
    }
  }

  /// Hive에 프로필별 일일 운세 캐시 저장
  void _saveToHive(String profileId, String todayKey, Map<String, dynamic> content) {
    try {
      if (!Hive.isBoxOpen(_hiveCacheBoxName)) return;
      final box = Hive.box<String>(_hiveCacheBoxName);
      box.put(_cacheDateKey(profileId), todayKey);
      box.put(_cacheKey(profileId), jsonEncode(content));
    } catch (e) {
      print('[DailyFortune] Hive 캐시 저장 실패: $e');
    }
  }

  /// 백그라운드 Supabase 갱신 (데이터 변경 시 UI도 업데이트)
  void _refreshInBackground(String profileId, DateTime today, String todayKey, bool isDisposed) {
    if (!SupabaseService.isConnected) return;
    aiQueries.getDailyFortune(profileId, today).then((result) {
      if (result.isSuccess && result.data != null && result.data!.content.isNotEmpty) {
        final newContent = result.data!.content;
        _saveToHive(profileId, todayKey, newContent);
        // 데이터 변경 시 UI 업데이트
        if (!isDisposed) {
          final newData = DailyFortuneData.fromJson(newContent);
          final current = state.valueOrNull;
          if (current == null || current.overallScore != newData.overallScore) {
            state = AsyncData(newData);
          }
        }
      }
    }).catchError((e) {
      // 백그라운드 갱신 실패는 무시 (Hive 캐시가 이미 표시됨)
    });
  }

  /// AI 분석 트리거 (fire-and-forget)
  ///
  /// FortuneCoordinator가 중복 분석 방지 담당:
  /// - _analyzingProfiles: analyzeFortuneOnly() 실행 중 (profile_provider)
  /// - _analyzingDaily: analyzeDailyOnly() 실행 중
  void _triggerAnalysis(String profileId) {
    // dispose 가드 (비동기 콜백에서 dead ref 접근 방지)
    var isDisposed = false;
    ref.onDispose(() => isDisposed = true);

    // profile_provider에서 이미 분석 중이면 5초 후 재시도
    if (FortuneCoordinator.isAnalyzing(profileId)) {
      ref.read(dailyAnalysisStepProvider.notifier).state = DailyAnalysisStep.callingApi;
      Future.delayed(const Duration(seconds: 5), () {
        if (!isDisposed) ref.invalidateSelf();
      });
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // DailyService step 콜백 연결 (dispose 가드 포함)
    ref.read(dailyAnalysisStepProvider.notifier).state = DailyAnalysisStep.checkingCache;
    fortuneCoordinator.dailyServiceStepCallback = (step) {
      if (isDisposed) return;
      final mapped = switch (step) {
        1 => DailyAnalysisStep.checkingCache,
        2 => DailyAnalysisStep.callingApi,
        3 => DailyAnalysisStep.saving,
        4 => DailyAnalysisStep.completed,
        _ => DailyAnalysisStep.idle,
      };
      ref.read(dailyAnalysisStepProvider.notifier).state = mapped;
    };

    fortuneCoordinator.analyzeDailyOnly(
      userId: user.id,
      profileId: profileId,
    ).then((result) {
      if (isDisposed) return;
      ref.read(dailyAnalysisStepProvider.notifier).state =
          result.success ? DailyAnalysisStep.completed : DailyAnalysisStep.error;
      if (result.success) {
        ref.invalidateSelf();
      }
    }).catchError((e) {
      print('[DailyFortune] 분석 오류: $e');
      if (!isDisposed) {
        ref.read(dailyAnalysisStepProvider.notifier).state = DailyAnalysisStep.error;
      }
    });
  }

  /// 수동 새로고침 (탭하면 재시도)
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// 프로필 변경 시 호출 (profile_provider 호환)
  /// FortuneCoordinator.resetAnalyzingFlagForProfile()이 실제 리셋 처리
  static void resetAnalyzedFlagForProfile(String profileId) {
    // 별도 static 상태 없으므로 no-op
  }
}

/// 특정 날짜의 운세 Provider (캘린더용)
@riverpod
Future<DailyFortuneData?> dailyFortuneForDate(Ref ref, DateTime date) async {
  final activeProfile = await ref.read(activeProfileProvider.future);
  if (activeProfile == null) return null;

  final result = await aiQueries.getDailyFortune(activeProfile.id, date);
  if (result.isFailure || result.data == null) return null;

  final content = result.data!.content;
  if (content.isEmpty) return null;

  return DailyFortuneData.fromJson(content);
}

/// 프로필의 일운이 있는 날짜 목록 Provider (캘린더 마커용)
@riverpod
Future<List<DateTime>> dailyFortuneDates(Ref ref) async {
  final activeProfile = await ref.read(activeProfileProvider.future);
  if (activeProfile == null) return [];

  final result = await aiQueries.getDailyFortuneDates(activeProfile.id);
  return result.data ?? [];
}
