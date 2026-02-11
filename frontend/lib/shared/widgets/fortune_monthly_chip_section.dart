import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../ad/ad_config.dart';
import '../../ad/ad_service.dart';
import '../../purchase/providers/purchase_provider.dart';

/// 카테고리별 운세 데이터
class CategoryData {
  final String title;
  final int score;
  final String reading;

  const CategoryData({
    required this.title,
    required this.score,
    required this.reading,
  });
}

/// v5.0: 월별 하이라이트 데이터 (career/business/wealth/love)
class MonthHighlightData {
  final int score;
  final String summary;

  const MonthHighlightData({
    required this.score,
    required this.summary,
  });
}

/// v5.0: 월별 사자성어 데이터
class MonthIdiomData {
  final String phrase;
  final String meaning;

  const MonthIdiomData({
    required this.phrase,
    required this.meaning,
  });
}

/// v5.3: 월별 행운 데이터
class MonthLuckyData {
  final String color;
  final int number;

  const MonthLuckyData({
    required this.color,
    required this.number,
  });

  bool get hasContent => color.isNotEmpty || number > 0;
}

/// 월별 데이터 인터페이스 (v5.0: highlights, idiom 포함)
class MonthData {
  final String keyword;
  final int score;
  final String reading;
  final String tip;
  /// v5.0: 7개 카테고리 상세 데이터 (광고 해금 후 로드)
  final Map<String, CategoryData>? categories;
  /// v5.0: 4개 하이라이트 (career/business/wealth/love) - 광고 해금 전에도 표시
  final Map<String, MonthHighlightData>? highlights;
  /// v5.0: 사자성어 정보 - 광고 해금 전에도 표시
  final MonthIdiomData? idiom;
  /// v5.3: 행운 요소 (색상, 숫자)
  final MonthLuckyData? lucky;
  /// 상세 데이터 로딩 중 플래그
  final bool isLoading;

  const MonthData({
    this.keyword = '',
    this.score = 0,
    this.reading = '',
    this.tip = '',
    this.categories,
    this.highlights,
    this.idiom,
    this.lucky,
    this.isLoading = false,
  });

  /// 카테고리 데이터가 있는지 확인
  bool get hasCategories => categories != null && categories!.isNotEmpty;

  /// v5.0: 하이라이트 데이터가 있는지 확인
  bool get hasHighlights => highlights != null && highlights!.isNotEmpty;

  /// v5.0: 사자성어 데이터가 있는지 확인
  bool get hasIdiom => idiom != null && idiom!.phrase.isNotEmpty;

  /// v5.3: 행운 데이터가 있는지 확인
  bool get hasLucky => lucky != null && lucky!.hasContent;

  /// 로딩 중 상태로 복사
  MonthData copyWithLoading(bool loading) {
    return MonthData(
      keyword: keyword,
      score: score,
      reading: reading,
      tip: tip,
      categories: categories,
      highlights: highlights,
      idiom: idiom,
      lucky: lucky,
      isLoading: loading,
    );
  }

  /// 카테고리 데이터 추가
  MonthData copyWithCategories(Map<String, CategoryData> newCategories) {
    return MonthData(
      keyword: keyword,
      score: score,
      reading: reading,
      tip: tip,
      categories: newCategories,
      highlights: highlights,
      idiom: idiom,
      lucky: lucky,
      isLoading: false,
    );
  }
}

/// 월별 운세 칩 섹션 (월별 운세용)
///
/// - 12개월이 칩으로 표시되고 탭하면 펼쳐짐
/// - 잠긴 월은 광고를 봐야 해제
/// - 현재 달(currentMonth)은 처음부터 잠금 해제 상태
/// - v5.0: 광고 해금 시 상세 운세 API 호출 콜백 지원
class FortuneMonthlyChipSection extends ConsumerStatefulWidget {
  /// 운세 타입 (monthly_fortune)
  final String fortuneType;

  /// 월별 데이터 맵 (key: month1, month2 등)
  final Map<String, MonthData> months;

  /// 섹션 제목
  final String? title;

  /// 현재 달 (1-12). 이 달은 처음부터 잠금 해제됨
  final int? currentMonth;

  /// v5.0: 월 해금 시 호출되는 콜백 (상세 운세 API 호출용)
  /// monthNumber: 해금된 월 (1-12)
  /// 반환값: 상세 운세 데이터 (categories 포함)
  final Future<MonthData?> Function(int monthNumber)? onMonthUnlocked;

  const FortuneMonthlyChipSection({
    super.key,
    required this.fortuneType,
    required this.months,
    this.title,
    this.currentMonth,
    this.onMonthUnlocked,
  });

  @override
  ConsumerState<FortuneMonthlyChipSection> createState() =>
      _FortuneMonthlyChipSectionState();
}

class _FortuneMonthlyChipSectionState extends ConsumerState<FortuneMonthlyChipSection> {
  /// 현재 펼쳐진 월
  String? _expandedMonth;

  /// 광고 로딩 중 플래그
  bool _isLoadingAd = false;

  /// [Static] 세션 기반 잠금해제 상태 - 앱 종료 전까지 유지!
  /// fortuneType별로 구분
  static final Map<String, Set<String>> _sessionUnlockedMonths = {};

  /// [Static] 세션 기반 상세 데이터 캐시 - 앱 종료 전까지 유지!
  /// fortuneType -> monthKey -> MonthData (with categories)
  static final Map<String, Map<String, MonthData>> _sessionDetailedMonths = {};

  /// 현재 fortuneType의 해금된 월 Set (현재 달 포함)
  Set<String> get _unlockedMonths {
    final unlocked = _sessionUnlockedMonths[widget.fortuneType] ?? {};
    // 현재 달은 항상 해금
    if (widget.currentMonth != null) {
      return {...unlocked, 'month${widget.currentMonth}'};
    }
    return unlocked;
  }

  /// 현재 월의 데이터 가져오기 (캐시된 상세 데이터 우선)
  MonthData? _getMonthData(String monthKey) {
    // 1. 캐시된 상세 데이터가 있으면 사용
    final cached = _sessionDetailedMonths[widget.fortuneType]?[monthKey];
    if (cached != null && cached.hasCategories) {
      return cached;
    }
    // 2. 없으면 기본 데이터 사용
    return widget.months[monthKey];
  }

  @override
  void initState() {
    super.initState();
    // static 변수 초기화 (fortuneType별로)
    _sessionUnlockedMonths[widget.fortuneType] ??= {};
    _sessionDetailedMonths[widget.fortuneType] ??= {};
  }

  /// 월 잠금 해제 및 상세 데이터 로드
  Future<void> _unlockMonthAndFetchDetails(String monthKey) async {
    final monthNum = int.tryParse(monthKey.replaceAll('month', '')) ?? 0;

    // 1. 잠금 해제
    _sessionUnlockedMonths[widget.fortuneType] ??= {};
    _sessionUnlockedMonths[widget.fortuneType]!.add(monthKey);

    // 2. 상세 데이터 로드 (콜백이 있으면)
    if (widget.onMonthUnlocked != null && monthNum > 0) {
      debugPrint('[MonthlyChip] 🚀 상세 운세 API 호출 시작: $monthNum월');

      // 로딩 상태 저장
      _sessionDetailedMonths[widget.fortuneType] ??= {};
      _sessionDetailedMonths[widget.fortuneType]![monthKey] =
          (widget.months[monthKey] ?? const MonthData()).copyWithLoading(true);

      if (mounted) setState(() {});

      try {
        final detailedData = await widget.onMonthUnlocked!(monthNum);
        if (detailedData != null) {
          debugPrint('[MonthlyChip] ✅ 상세 운세 로드 완료: ${detailedData.categories?.length ?? 0}개 카테고리');
          _sessionDetailedMonths[widget.fortuneType]![monthKey] = detailedData;
        } else {
          debugPrint('[MonthlyChip] ⚠️ 상세 운세 데이터 없음');
          // 로딩 해제
          _sessionDetailedMonths[widget.fortuneType]![monthKey] =
              (widget.months[monthKey] ?? const MonthData()).copyWithLoading(false);
        }
      } catch (e) {
        debugPrint('[MonthlyChip] ❌ 상세 운세 로드 실패: $e');
        // 로딩 해제
        _sessionDetailedMonths[widget.fortuneType]![monthKey] =
            (widget.months[monthKey] ?? const MonthData()).copyWithLoading(false);
      }
    }

    if (mounted) {
      setState(() {}); // UI 갱신
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          widget.title ?? '월별 운세',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // 안내 텍스트
        Text(
          '탭하여 각 달의 운세를 확인하세요',
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // 월별 칩들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.months.entries.map((entry) {
            final key = entry.key;
            final isUnlocked = _unlockedMonths.contains(key);
            final isExpanded = _expandedMonth == key;
            final monthNum = key.replaceAll('month', '');

            return _buildMonthChip(
              theme: theme,
              monthKey: key,
              monthName: '$monthNum월',
              isUnlocked: isUnlocked,
              isExpanded: isExpanded,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 펼쳐진 월 내용
        if (_expandedMonth != null) ...[
          _buildExpandedContent(theme, _expandedMonth!),
        ],
      ],
    );
  }

  Widget _buildMonthChip({
    required AppThemeExtension theme,
    required String monthKey,
    required String monthName,
    required bool isUnlocked,
    required bool isExpanded,
  }) {
    return GestureDetector(
      onTap: () => _onChipTap(monthKey, isUnlocked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isExpanded
              ? theme.primaryColor.withValues(alpha: 0.15)
              : isUnlocked
                  ? theme.cardColor
                  : theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? theme.primaryColor
                : isUnlocked
                    ? theme.textMuted.withValues(alpha: 0.3)
                    : theme.textMuted.withValues(alpha: 0.2),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 잠금 아이콘 (잠긴 경우)
            if (!isUnlocked) ...[
              Icon(
                Icons.lock_outline,
                size: 14,
                color: theme.textSecondary,
              ),
              const SizedBox(width: 4),
            ],

            // 월 이름
            Text(
              monthName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                color: isUnlocked ? theme.textPrimary : theme.textSecondary,
              ),
            ),

            // 펼침 아이콘
            if (isUnlocked) ...[
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: theme.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(AppThemeExtension theme, String monthKey) {
    final month = _getMonthData(monthKey);
    debugPrint('[MonthlyChip] _buildExpandedContent: monthKey=$monthKey');
    debugPrint('[MonthlyChip] month data: keyword=${month?.keyword}, score=${month?.score}, hasCategories=${month?.hasCategories}, isLoading=${month?.isLoading}');
    if (month == null) return const SizedBox.shrink();

    final monthNum = monthKey.replaceAll('month', '');

    // 로딩 중이면 로딩 표시
    if (month.isLoading) {
      return _buildLoadingContent(theme, monthNum);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '$monthNum월 운세',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              if (month.score > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(month.score).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${month.score}점',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(month.score),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // 닫기 버튼
              GestureDetector(
                onTap: () => setState(() => _expandedMonth = null),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 키워드
          if (month.keyword.isNotEmpty) ...[
            Text(
              '키워드: ${month.keyword}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 풀이 (총운)
          if (month.reading.isNotEmpty) ...[
            Text(
              month.reading,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // v5.0: 사자성어 - 가장 먼저 표시
          if (month.hasIdiom) ...[
            _buildIdiomCard(theme, month.idiom!),
            const SizedBox(height: 16),
          ],

          // v5.0: 하이라이트 (career/business/wealth/love) - 광고 해금 전에도 표시
          if (month.hasHighlights) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              '분야별 요약',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...month.highlights!.entries.map((entry) {
              return _buildHighlightCard(theme, entry.key, entry.value);
            }),
          ],

          // v5.0: 카테고리별 운세 (상세 데이터가 있을 때 - API 호출 후)
          if (month.hasCategories) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              '분야별 상세 운세',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...month.categories!.entries.map((entry) {
              return _buildCategoryCard(theme, entry.key, entry.value);
            }),
          ],

          // v5.3: 행운 요소
          if (month.hasLucky) ...[
            const SizedBox(height: 12),
            _buildLuckyCard(theme, month.lucky!),
          ],

          // 팁
          if (month.tip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      month.tip,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 로딩 중 UI
  Widget _buildLoadingContent(AppThemeExtension theme, String monthNum) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$monthNum월 운세',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _expandedMonth = null),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '$monthNum월 운세를 분석하고 있습니다...',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 카테고리 카드 빌드
  Widget _buildCategoryCard(AppThemeExtension theme, String categoryKey, CategoryData category) {
    final categoryName = _getCategoryName(categoryKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                categoryName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (category.score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getScoreColor(category.score).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${category.score}점',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(category.score),
                    ),
                  ),
                ),
            ],
          ),
          if (category.reading.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              category.reading,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryName(String key) {
    const names = {
      'career': '직업운',
      'work': '직장운',  // DB 키와 일치
      'business': '사업운',
      'wealth': '재물운',
      'love': '애정운',
      'marriage': '결혼운',
      'study': '학업운',
      'health': '건강운',
    };
    return names[key] ?? key;
  }

  /// v5.3: 하이라이트 카드 아이콘 가져오기 (7개 카테고리)
  IconData _getHighlightIcon(String key) {
    const icons = {
      'career': Icons.work_outline,
      'business': Icons.business_center_outlined,
      'wealth': Icons.account_balance_wallet_outlined,
      'love': Icons.favorite_outline,
      'marriage': Icons.home_outlined,
      'health': Icons.monitor_heart_outlined,
      'study': Icons.school_outlined,
    };
    return icons[key] ?? Icons.star_outline;
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  /// v5.0: 하이라이트 카드 빌드
  Widget _buildHighlightCard(AppThemeExtension theme, String key, MonthHighlightData highlight) {
    final categoryName = _getCategoryName(key);
    final icon = _getHighlightIcon(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (highlight.score > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getScoreColor(highlight.score).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${highlight.score}점',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getScoreColor(highlight.score),
                          ),
                        ),
                      ),
                  ],
                ),
                if (highlight.summary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    highlight.summary,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// v5.0: 사자성어 카드 빌드
  Widget _buildIdiomCard(AppThemeExtension theme, MonthIdiomData idiom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.12),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, size: 20, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '이달의 사자성어',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            idiom.phrase,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            idiom.meaning,
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// v5.3: 행운 카드 빌드
  Widget _buildLuckyCard(AppThemeExtension theme, MonthLuckyData lucky) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: Colors.purple.shade300),
          const SizedBox(width: 10),
          Text(
            '행운',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          if (lucky.color.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lucky.color,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.purple.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (lucky.number > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${lucky.number}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.purple.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onChipTap(String monthKey, bool isUnlocked) async {
    if (isUnlocked) {
      // 이미 해제된 월 - 토글
      setState(() {
        if (_expandedMonth == monthKey) {
          _expandedMonth = null;
        } else {
          _expandedMonth = monthKey;
        }
      });
    } else {
      // 잠긴 월 - 광고 보여주기
      await _showRewardedAdAndUnlock(monthKey);
    }
  }

  Future<void> _showRewardedAdAndUnlock(String monthKey) async {
    if (_isLoadingAd) return;

    final monthNum = monthKey.replaceAll('month', '');
    final monthName = '$monthNum월';

    // 프리미엄 유저는 광고 없이 바로 해제
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;
    if (isPremium) {
      await _unlockMonthAndFetchDetails(monthKey);
      if (mounted) {
        setState(() {
          _expandedMonth = monthKey;
        });
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$monthName 운세가 해제되었습니다!'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    setState(() => _isLoadingAd = true);

    // 웹에서는 광고 스킵하고 바로 해제 (테스트용)
    if (kIsWeb) {
      await _unlockMonthAndFetchDetails(monthKey);
      if (mounted) {
        setState(() {
          _expandedMonth = monthKey;
          _isLoadingAd = false;
        });
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$monthName 운세가 해제되었습니다! (웹 테스트)'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    // 광고 킬스위치 OFF → 바로 점검 중 다이얼로그
    if (!adEnabled) {
      setState(() => _isLoadingAd = false);
      _showAdNotReadyDialog(monthName);
      return;
    }

    // 광고가 로드되어 있는지 확인
    if (!AdService.instance.isRewardedLoaded) {
      await AdService.instance.loadRewardedAd(
        onLoaded: () async {
          final shown = await AdService.instance.showRewardedAd(
            onRewarded: (amount, type) async {
              await _unlockMonthAndFetchDetails(monthKey);

              if (mounted) {
                setState(() {
                  _expandedMonth = monthKey;
                  _isLoadingAd = false;
                });

                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$monthName 운세를 분석합니다...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (_) {
                  // ScaffoldMessenger not available (ad activity context)
                }
              }
            },
          );

          if (!shown && mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(monthName);
          }
        },
        onFailed: (error) {
          if (mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(monthName);
          }
        },
      );
    } else {
      debugPrint('[MonthlyChip] Rewarded ad already loaded, showing...');
      final shown = await AdService.instance.showRewardedAd(
        onRewarded: (amount, type) async {
          debugPrint('[MonthlyChip] onRewarded called! amount=$amount, type=$type, monthKey=$monthKey');
          await _unlockMonthAndFetchDetails(monthKey);

          if (mounted) {
            debugPrint('[MonthlyChip] Setting expandedMonth=$monthKey');
            setState(() {
              _expandedMonth = monthKey;
              _isLoadingAd = false;
            });

            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$monthName 운세를 분석합니다...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            } catch (_) {
              // ScaffoldMessenger not available (ad activity context)
            }
          }
        },
      );
      debugPrint('[MonthlyChip] showRewardedAd returned: shown=$shown');

      if (!shown && mounted) {
        setState(() => _isLoadingAd = false);
        _showAdNotReadyDialog(monthName);
      }
    }
  }

  void _showAdNotReadyDialog(String monthName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(adEnabled ? '광고 준비 중' : '광고 서비스 점검 중'),
        content: Text(
          adEnabled
              ? '$monthName 운세를 보려면 광고를 시청해야 합니다.\n잠시 후 다시 시도해주세요.'
              : '$monthName 운세를 보려면 광고 시청이 필요하지만,\n현재 광고 서비스 점검 중입니다.\n프리미엄 구독으로 바로 이용할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
