import '../../../../AI/fortune/common/locale_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/monthly/monthly_queries.dart';
import '../../../../AI/fortune/common/korea_date_utils.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'monthly_fortune_provider.g.dart';

/// 안전한 int 파싱 (num, String 모두 지원)
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// 월별 운세 데이터 모델 (v5.0: 12개월 확장)
///
/// ## v5.0 변경사항 (2026-01-24)
/// - 각 월별 데이터에 highlights (career/wealth/love) 추가
/// - 각 월별 데이터에 lucky (color/number) 추가
/// - reading 확장: 3-4문장 → 6-8문장
class MonthlyFortuneData {
  final int year;
  final int month;
  final String monthGanji;
  final OverviewSection overview;
  final Map<String, CategorySection> categories;
  final LuckySection lucky;
  final String closingMessage;
  /// v5.0: 12개월 확장 데이터 (highlights, lucky 포함)
  final Map<String, MonthSummary> months;

  const MonthlyFortuneData({
    required this.year,
    required this.month,
    required this.monthGanji,
    required this.overview,
    required this.categories,
    required this.lucky,
    required this.closingMessage,
    required this.months,
  });

  /// AI 응답 JSON에서 파싱 (v5.0: 12개월 확장 구조)
  factory MonthlyFortuneData.fromJson(Map<String, dynamic> json) {
    print('[MonthlyFortuneData] 🔍 fromJson 시작');
    print('[MonthlyFortuneData] json.keys=${json.keys.toList()}');

    // v5.0: current 섹션에서 현재 월 데이터 파싱
    final currentJson = json['current'] as Map<String, dynamic>? ?? json;
    print('[MonthlyFortuneData] currentJson.keys=${currentJson.keys.toList()}');
    final overviewJson = currentJson['overview'] as Map<String, dynamic>? ?? json['overview'] as Map<String, dynamic>? ?? {};

    final overview = OverviewSection(
      score: _safeInt(overviewJson['score']),
      keyword: overviewJson['keyword'] as String? ?? '',
      // v4.0: opening, monthEnergy 등이 reading으로 통합됨
      opening: overviewJson['reading'] as String? ?? overviewJson['opening'] as String? ?? '',
      monthEnergy: overviewJson['monthEnergy'] as String? ?? '',
      hapchungEffect: overviewJson['hapchungEffect'] as String? ?? '',
      conclusion: overviewJson['conclusion'] as String? ?? '',
    );

    // v4.0: categories가 current.categories 안에 있거나 루트에 있음
    final categoriesJson = currentJson['categories'] as Map<String, dynamic>? ?? {};
    final categories = <String, CategorySection>{};
    for (final key in ['career', 'business', 'wealth', 'love', 'marriage', 'study', 'health']) {
      // v4.0 구조 또는 기존 구조 모두 지원
      final catJson = categoriesJson[key] as Map<String, dynamic>? ?? json[key] as Map<String, dynamic>? ?? {};
      categories[key] = CategorySection(
        score: _safeInt(catJson['score']),
        title: catJson['title'] as String? ?? '',
        reading: catJson['reading'] as String? ?? '',
      );
    }

    // v5.2: lucky가 current.categories.lucky 안에 있거나 current.lucky에 있음
    final luckyJson = categoriesJson['lucky'] as Map<String, dynamic>?
        ?? currentJson['lucky'] as Map<String, dynamic>?
        ?? json['lucky'] as Map<String, dynamic>?
        ?? {};
    final lucky = LuckySection(
      colors: _parseStringList(luckyJson['colors']),
      numbers: _parseIntList(luckyJson['numbers']),
      foods: _parseStringList(luckyJson['foods']),
      tip: luckyJson['tip'] as String? ?? '',
    );

    // v5.0: 12개월 확장 데이터 파싱 (highlights, lucky 포함)
    // v5.2: months는 current 안에 있음! (content.current.months.month1 구조)
    final monthsJson = currentJson['months'] as Map<String, dynamic>? ?? json['months'] as Map<String, dynamic>? ?? {};
    final months = <String, MonthSummary>{};
    print('[MonthlyFortuneData] 🔍 fromJson: monthsJson.keys=${monthsJson.keys.toList()}');
    for (int i = 1; i <= 12; i++) {
      final monthKey = 'month$i';
      final monthJson = monthsJson[monthKey] as Map<String, dynamic>?;
      if (monthJson != null) {
        final hasHighlights = monthJson['highlights'] != null;
        final hasLucky = monthJson['lucky'] != null;
        print('[MonthlyFortuneData] $monthKey 파싱: keyword=${monthJson['keyword']}, highlights=$hasHighlights, lucky=$hasLucky');
        months[monthKey] = MonthSummary.fromJson(monthJson);
      } else {
        print('[MonthlyFortuneData] $monthKey: monthJson이 null!');
      }
    }
    print('[MonthlyFortuneData] ✅ 파싱 완료: months.length=${months.length}');

    // closing 파싱 (v4.0: closingMessage가 루트에 있거나 closing.message에 있음)
    final closingMessage = json['closingMessage'] as String? ??
        (json['closing'] as Map<String, dynamic>?)?['message'] as String? ?? '';

    return MonthlyFortuneData(
      year: _safeInt(json['year'], KoreaDateUtils.currentYear),
      month: _safeInt(json['currentMonth'], _safeInt(json['month'], KoreaDateUtils.currentMonth)),
      monthGanji: currentJson['monthGanji'] as String? ?? json['monthGanji'] as String? ?? '',
      overview: overview,
      categories: categories,
      lucky: lucky,
      closingMessage: closingMessage,
      months: months,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is List) {
      return value.map((e) => _safeInt(e)).toList();
    }
    return [];
  }

  /// 카테고리 점수 가져오기
  int getCategoryScore(String category) {
    return categories[category]?.score ?? 0;
  }

  /// 월 이름 (한글)
  String get monthName => '$month월';
}

/// 개요 섹션
class OverviewSection {
  final int score;
  final String keyword;
  final String opening;
  final String monthEnergy;
  final String hapchungEffect;
  final String conclusion;

  const OverviewSection({
    required this.score,
    required this.keyword,
    required this.opening,
    required this.monthEnergy,
    required this.hapchungEffect,
    required this.conclusion,
  });
}

/// 카테고리별 운세 섹션
class CategorySection {
  final int score;
  final String title;
  final String reading;

  const CategorySection({
    required this.score,
    required this.title,
    required this.reading,
  });
}

/// 월별 요약 데이터 (v5.3: 12개월 확장 - highlights 7개, tip, lucky 추가)
class MonthSummary {
  final String keyword;
  final int score;
  final String reading;
  /// v5.0: 카테고리별 하이라이트 (v5.3: 7개 카테고리)
  final MonthHighlights? highlights;
  /// v5.0: 사자성어
  final MonthIdiom? idiom;
  /// v5.3: 핵심 조언
  final String tip;
  /// v5.3: 행운 요소
  final MonthLucky? lucky;

  const MonthSummary({
    required this.keyword,
    required this.score,
    required this.reading,
    this.highlights,
    this.idiom,
    this.tip = '',
    this.lucky,
  });

  /// JSON에서 파싱 (v5.3)
  factory MonthSummary.fromJson(Map<String, dynamic> json) {
    return MonthSummary(
      keyword: json['keyword'] as String? ?? '',
      score: _safeInt(json['score']),
      reading: json['reading'] as String? ?? '',
      highlights: json['highlights'] != null
          ? MonthHighlights.fromJson(json['highlights'] as Map<String, dynamic>)
          : null,
      idiom: json['idiom'] != null
          ? MonthIdiom.fromJson(json['idiom'] as Map<String, dynamic>)
          : null,
      tip: json['tip'] as String? ?? '',
      lucky: json['lucky'] != null
          ? MonthLucky.fromJson(json['lucky'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 카테고리 데이터가 있는지 (광고 해금 후 표시 여부)
  bool get hasCategories => highlights != null;
}

/// v5.3: 월별 카테고리 하이라이트 (7개: career, business, wealth, love, marriage, health, study)
class MonthHighlights {
  final MonthHighlightItem? career;
  final MonthHighlightItem? business;
  final MonthHighlightItem? wealth;
  final MonthHighlightItem? love;
  final MonthHighlightItem? marriage;
  final MonthHighlightItem? health;
  final MonthHighlightItem? study;

  const MonthHighlights({
    this.career,
    this.business,
    this.wealth,
    this.love,
    this.marriage,
    this.health,
    this.study,
  });

  factory MonthHighlights.fromJson(Map<String, dynamic> json) {
    MonthHighlightItem? _parse(String key) =>
        json[key] != null ? MonthHighlightItem.fromJson(json[key] as Map<String, dynamic>) : null;
    return MonthHighlights(
      career: _parse('career'),
      business: _parse('business'),
      wealth: _parse('wealth'),
      love: _parse('love'),
      marriage: _parse('marriage'),
      health: _parse('health'),
      study: _parse('study'),
    );
  }
}

/// v5.0: 카테고리별 하이라이트 아이템
class MonthHighlightItem {
  final int score;
  final String summary;

  const MonthHighlightItem({
    required this.score,
    required this.summary,
  });

  factory MonthHighlightItem.fromJson(Map<String, dynamic> json) {
    return MonthHighlightItem(
      score: _safeInt(json['score']),
      summary: json['summary'] as String? ?? '',
    );
  }
}

/// v5.0: 월별 사자성어
class MonthIdiom {
  final String phrase;
  final String meaning;

  const MonthIdiom({
    required this.phrase,
    required this.meaning,
  });

  factory MonthIdiom.fromJson(Map<String, dynamic> json) {
    return MonthIdiom(
      phrase: json['phrase'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
    );
  }
}

/// v5.3: 월별 행운 요소
class MonthLucky {
  final String color;
  final int number;

  const MonthLucky({
    required this.color,
    required this.number,
  });

  factory MonthLucky.fromJson(Map<String, dynamic> json) {
    return MonthLucky(
      color: json['color'] as String? ?? '',
      number: _safeInt(json['number']),
    );
  }
}

/// 행운 섹션
class LuckySection {
  final List<String> colors;
  final List<int> numbers;
  final List<String> foods;
  final String tip;

  const LuckySection({
    required this.colors,
    required this.numbers,
    required this.foods,
    required this.tip,
  });
}

/// 월별 운세 Provider
///
/// activeProfile의 이번 달 운세를 DB에서 조회
/// 캐시가 없으면 AI 분석을 자동 트리거하고 폴링으로 완료 감지
///
/// ## v8.0 변경 (2026-02-08)
/// - 폴링 타임아웃 시 ref.invalidateSelf()로 자동 재시도 (무한 로딩 수정)
/// - _isAnalyzing safety timeout (6분) 추가 (stuck 플래그 방지)
/// - 재시도 카운터 (최대 3회) 후 에러 throw
/// - FortuneCoordinator stuck flag 자동 정리
@riverpod
class MonthlyFortune extends _$MonthlyFortune {
  /// 분석 진행 중 플래그 (중복 호출 방지)
  static bool _isAnalyzing = false;

  /// 분석 시작 시각 (safety timeout용)
  static DateTime? _analyzeStartTime;

  /// 연속 재시도 횟수 (무한 루프 방지)
  static int _retryCount = 0;

  /// 최대 재시도 횟수
  static const int _maxRetries = 3;

  /// 오프라인 재시도 횟수 (무한 루프 방지)
  static int _offlineRetryCount = 0;
  static const int _maxOfflineRetries = 10;

  /// 분석 타임아웃 (6분 - OpenAI polling 4분 + 여유)
  static const Duration _analyzeTimeout = Duration(minutes: 6);

  /// 폴링 활성화 플래그
  bool _isPolling = false;

  @override
  Future<MonthlyFortuneData?> build() async {
    // Dispose 시 폴링 중단 (Future.delayed 체인 정리)
    ref.onDispose(() {
      _isPolling = false;
      _isStalePolling = false;
    });

    // v8.0 Safety: stuck _isAnalyzing 리셋 (타임아웃 초과 시)
    if (_isAnalyzing && _analyzeStartTime != null &&
        DateTime.now().difference(_analyzeStartTime!) > _analyzeTimeout) {
      print('[MonthlyFortune] ⚠️ _isAnalyzing 타임아웃 리셋 (${_analyzeTimeout.inMinutes}분 초과)');
      _isAnalyzing = false;
      _analyzeStartTime = null;
    }

    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) return null;

    // 오프라인 상태면 3초 후 자동 재시도 (최대 10회)
    if (!SupabaseService.isConnected) {
      if (_offlineRetryCount >= _maxOfflineRetries) {
        print('[MonthlyFortune] 오프라인 재시도 초과 ($_offlineRetryCount/$_maxOfflineRetries)');
        _offlineRetryCount = 0;
        return null;
      }
      _offlineRetryCount++;
      print('[MonthlyFortune] 오프라인 모드 - 3초 후 재시도 ($_offlineRetryCount/$_maxOfflineRetries)');
      Future.delayed(const Duration(seconds: 3), () {
        ref.invalidateSelf();
      });
      return null;
    }
    _offlineRetryCount = 0; // 온라인 복귀 시 리셋

    // v8.0 Safety: FortuneCoordinator stuck flag 리셋
    if (!_isAnalyzing && FortuneCoordinator.isAnalyzing(activeProfile.id)) {
      print('[MonthlyFortune] ⚠️ FortuneCoordinator stuck flag 리셋');
      FortuneCoordinator.resetAnalyzingFlag(activeProfile.id);
    }

    final locale = FortuneLocaleUtils.currentLocale;
    final queries = MonthlyQueries(Supabase.instance.client);
    final result = await queries.getCached(
      activeProfile.id,
      year: KoreaDateUtils.currentYear,
      month: KoreaDateUtils.currentMonth,
      includeStale: true,
      locale: locale,
    );

    // 캐시가 있으면 바로 반환
    if (result != null) {
      final content = result['content'];
      final isStale = result['_isStale'] == true;
      if (content is Map<String, dynamic>) {
        _retryCount = 0; // 성공 시 재시도 카운터 리셋
        if (isStale) {
          print('[MonthlyFortune] stale 캐시 - 기존 데이터 표시 + 백그라운드 재생성');
          _triggerAnalysisIfNeeded(activeProfile.id);
          _startStalePolling(activeProfile.id);
        } else {
          print('[MonthlyFortune] 캐시 히트 - 월운 로드');
        }
        _isPolling = false;
        return MonthlyFortuneData.fromJson(content);
      }
    }

    // v8.0: 최대 재시도 초과 → 에러 throw (UI에서 에러 화면 + 재시도 버튼)
    if (_retryCount >= _maxRetries) {
      print('[MonthlyFortune] ❌ 최대 재시도 초과 ($_retryCount/$_maxRetries)');
      _retryCount = 0; // 다음 수동 새로고침에서는 다시 시도 가능
      throw Exception('월별 운세 분석에 실패했습니다.\n잠시 후 다시 시도해주세요.');
    }

    // 캐시가 없으면 AI 분석 트리거
    print('[MonthlyFortune] 캐시 없음 - AI 분석 시작 (retry=$_retryCount)');
    await _triggerAnalysisIfNeeded(activeProfile.id);

    // 폴링 시작 (3초마다 DB 확인)
    _startPolling(activeProfile.id);

    // 분석 완료 후 다시 조회 (null 반환하면 UI에서 "분석 중" 표시)
    return null;
  }

  /// 폴링 시도 횟수
  int _pollAttempts = 0;

  /// 최대 폴링 횟수 (3초 × 100 = 5분)
  static const int _maxPollAttempts = 100;

  /// DB 폴링 시작 (AI 분석 완료 감지)
  void _startPolling(String profileId) {
    if (_isPolling) return;
    _isPolling = true;
    _pollAttempts = 0;

    print('[MonthlyFortune] 폴링 시작 - 3초마다 DB 확인 (최대 ${_maxPollAttempts}회)');
    _pollForData(profileId);
  }

  /// 주기적으로 DB 확인 (최대 _maxPollAttempts 회)
  Future<void> _pollForData(String profileId) async {
    if (!_isPolling) return;

    await Future.delayed(const Duration(seconds: 3));
    if (!_isPolling) return;

    _pollAttempts++;

    final queries = MonthlyQueries(Supabase.instance.client);
    final locale = FortuneLocaleUtils.currentLocale;
    final result = await queries.getCurrentMonth(profileId, locale: locale);

    if (result != null && result['content'] != null) {
      print('[MonthlyFortune] 폴링 성공 - 데이터 발견! UI 자동 갱신 (${_pollAttempts}회)');
      _isPolling = false;
      _isAnalyzing = false;
      _analyzeStartTime = null;
      _retryCount = 0; // 성공 시 리셋
      ref.invalidateSelf();
    } else if (_pollAttempts >= _maxPollAttempts) {
      // v8.0: 최대 횟수 초과 → 재시도 (invalidateSelf로 build() 재실행)
      // Future.wait().timeout(5분) 덕분에 FortuneCoordinator 락이 해제되어
      // 재시도 시 Edge Function dedup → 완료된 데이터 반환 → 정상 save 진행
      print('[MonthlyFortune] ⚠️ 폴링 타임아웃 (${_maxPollAttempts}회 초과) - 재시도 #${_retryCount + 1}');
      _isPolling = false;
      _isAnalyzing = false;
      _analyzeStartTime = null;
      _retryCount++;
      ref.invalidateSelf();
    } else {
      // 데이터 없으면 계속 폴링 (로그 10회마다)
      if (_pollAttempts % 10 == 0) {
        print('[MonthlyFortune] 폴링 중 - 데이터 아직 없음 ($_pollAttempts/$_maxPollAttempts)');
      }
      _pollForData(profileId);
    }
  }

  /// AI 분석 트리거 (v6.1: 전역 중복 방지!)
  ///
  /// ## v6.0 변경 (2026-01-20) ⭐
  /// - sajuAnalysisService.analyzeOnProfileSave() → fortuneCoordinator.analyzeFortuneOnly()
  /// - saju_base(140초) 대기 없이 Fortune만 즉시 분석!
  ///
  /// ## v6.1 변경 (2026-01-20) ⭐
  /// - FortuneCoordinator.isAnalyzing() 전역 중복 체크 추가
  /// - SajuAnalysisService와 Provider 간 중복 호출 방지
  Future<void> _triggerAnalysisIfNeeded(String profileId) async {
    // v6.1 전역 중복 체크 (FortuneCoordinator에서 이미 분석 중인지)
    if (FortuneCoordinator.isAnalyzing(profileId)) {
      print('[MonthlyFortune] ⏭️ FortuneCoordinator에서 이미 분석 중 - 스킵');
      return;
    }

    if (_isAnalyzing) {
      print('[MonthlyFortune] 이미 분석 중 - 스킵');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[MonthlyFortune] 사용자 없음 - 분석 스킵');
      return;
    }

    _isAnalyzing = true;
    _analyzeStartTime = DateTime.now();
    print('[MonthlyFortune] 🚀 v6.0 Fortune만 즉시 분석 시작! (saju_base 대기 없음)');

    // v6.0: Fortune만 직접 분석 (saju_base 대기 없음!)
    final locale = FortuneLocaleUtils.currentLocale;
    fortuneCoordinator.analyzeFortuneOnly(
      userId: user.id,
      profileId: profileId,
      locale: locale,
    ).then((result) {
      _isAnalyzing = false;
      _analyzeStartTime = null;
      print('[MonthlyFortune] ✅ Fortune 분석 완료');
      print('  - monthly: ${result.monthly != null ? "성공" : "실패"}');
      print('  - yearly2025: ${result.yearly2025 != null ? "성공" : "실패"}');
      print('  - yearly2026: ${result.yearly2026 != null ? "성공" : "실패"}');
      // 폴링이 데이터를 감지하고 UI를 갱신할 것임
    }).catchError((e) {
      _isAnalyzing = false;
      _analyzeStartTime = null;
      print('[MonthlyFortune] ❌ Fortune 분석 오류: $e');
    });
  }

  /// stale 데이터 폴링 (백그라운드 재생성 완료 감지)
  bool _isStalePolling = false;
  int _stalePollAttempts = 0;
  static const int _maxStalePollAttempts = 60;

  void _startStalePolling(String profileId) {
    if (_isStalePolling) return;
    _isStalePolling = true;
    _stalePollAttempts = 0;
    print('[MonthlyFortune] stale 폴링 시작 - 5초마다 fresh 데이터 확인');
    _pollForFreshData(profileId);
  }

  Future<void> _pollForFreshData(String profileId) async {
    if (!_isStalePolling) return;

    await Future.delayed(const Duration(seconds: 5));
    if (!_isStalePolling) return;

    _stalePollAttempts++;

    final locale = FortuneLocaleUtils.currentLocale;
    final queries = MonthlyQueries(Supabase.instance.client);
    final result = await queries.getCached(
      profileId,
      year: KoreaDateUtils.currentYear,
      month: KoreaDateUtils.currentMonth,
      locale: locale,
    );

    if (result != null && result['content'] != null) {
      print('[MonthlyFortune] fresh 데이터 발견! UI 자동 갱신 ($_stalePollAttempts회)');
      _isStalePolling = false;
      ref.invalidateSelf();
    } else if (_stalePollAttempts >= _maxStalePollAttempts) {
      print('[MonthlyFortune] stale 폴링 타임아웃 - 중지');
      _isStalePolling = false;
    } else {
      _pollForFreshData(profileId);
    }
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    _isPolling = false;
    _isStalePolling = false;
    _isAnalyzing = false;
    _analyzeStartTime = null;
    _retryCount = 0;
    ref.invalidateSelf();
  }
}
