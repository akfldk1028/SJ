import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../ad/ad_service.dart';
import '../../purchase/providers/purchase_provider.dart';
import '../../purchase/purchase_config.dart';
import 'fortune_category_chip_section.dart';

/// 월별 운세 + 카테고리 Step by Step 섹션
///
/// - 12개월 칩이 가로 스크롤로 표시
/// - 월 선택 시 해당 월의 분기 테마 + 카테고리가 순차적으로 표시
/// - 각 카테고리는 광고 시청 후 해금
class FortuneMonthlyStepSection extends ConsumerStatefulWidget {
  /// 운세 타입 (yearly_2025, yearly_2026)
  final String fortuneType;

  /// 섹션 제목
  final String? title;

  /// 분기별 데이터 (q1, q2, q3, q4)
  final Map<String, QuarterData> quarters;

  /// 카테고리 데이터
  final Map<String, CategoryData> categories;

  const FortuneMonthlyStepSection({
    super.key,
    required this.fortuneType,
    required this.quarters,
    required this.categories,
    this.title,
  });

  @override
  ConsumerState<FortuneMonthlyStepSection> createState() =>
      _FortuneMonthlyStepSectionState();
}

/// 분기별 데이터
class QuarterData {
  final String period;
  final String theme;
  final int score;
  final String reading;

  const QuarterData({
    required this.period,
    required this.theme,
    required this.score,
    required this.reading,
  });
}

class _FortuneMonthlyStepSectionState extends ConsumerState<FortuneMonthlyStepSection> {
  /// 현재 선택된 월 (1~12, null이면 미선택)
  int? _selectedMonth;

  /// 현재 step (0: 분기 요약, 1~7: 각 카테고리)
  int _currentStep = 0;

  /// 해금된 월 목록
  Set<int> _unlockedMonths = {};

  /// 해금된 step 목록
  Set<int> _unlockedSteps = {0}; // 0번(분기 요약)은 기본 해금

  /// 광고 로딩 중
  bool _isLoadingAd = false;

  /// Hive box
  Box<bool>? _box;

  @override
  void initState() {
    super.initState();
    _loadUnlockedData();
  }

  Future<void> _loadUnlockedData() async {
    _box = await Hive.openBox<bool>('unlocked_monthly_steps');

    // 해금된 월 로드
    final unlockedMonths = <int>{};
    for (int month = 1; month <= 12; month++) {
      final key = '${widget.fortuneType}_month$month';
      if (_box!.get(key) == true) {
        unlockedMonths.add(month);
      }
    }

    // 해금된 step 로드 (선택된 월이 있을 때)
    final unlockedSteps = <int>{0};
    if (_selectedMonth != null) {
      for (int i = 1; i <= 7; i++) {
        final key = '${widget.fortuneType}_month${_selectedMonth}_step$i';
        if (_box!.get(key) == true) {
          unlockedSteps.add(i);
        }
      }
    }

    if (mounted) {
      setState(() {
        _unlockedMonths = unlockedMonths;
        _unlockedSteps = unlockedSteps;
      });
    }
  }

  Future<void> _unlockMonth(int month) async {
    final box = _box ?? await Hive.openBox<bool>('unlocked_monthly_steps');
    final key = '${widget.fortuneType}_month$month';
    await box.put(key, true);

    if (mounted) {
      setState(() {
        _unlockedMonths = {..._unlockedMonths, month};
        _selectedMonth = month;
        _currentStep = 0;
        _unlockedSteps = {0}; // 월 변경 시 step 초기화
      });
      _loadStepsForMonth(month);
    }
  }

  Future<void> _loadStepsForMonth(int month) async {
    final box = _box ?? await Hive.openBox<bool>('unlocked_monthly_steps');
    final unlockedSteps = <int>{0};
    for (int i = 1; i <= 7; i++) {
      final key = '${widget.fortuneType}_month${month}_step$i';
      if (box.get(key) == true) {
        unlockedSteps.add(i);
      }
    }
    if (mounted) {
      setState(() => _unlockedSteps = unlockedSteps);
    }
  }

  Future<void> _unlockStep(int step) async {
    final box =
        _box ?? await Hive.openBox<bool>('unlocked_monthly_steps');
    final key = '${widget.fortuneType}_month${_selectedMonth}_step$step';
    await box.put(key, true);

    if (mounted) {
      setState(() {
        _unlockedSteps = {..._unlockedSteps, step};
        _currentStep = step;
      });
    }
  }

  /// 월 → 분기 매핑
  String _getQuarterKey(int month) {
    if (month <= 3) return 'q1';
    if (month <= 6) return 'q2';
    if (month <= 9) return 'q3';
    return 'q4';
  }

  /// 카테고리 키 목록
  List<String> get _categoryKeys =>
      ['career', 'business', 'wealth', 'love', 'marriage', 'study', 'health'];

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final quarter = _selectedMonth != null
        ? widget.quarters[_getQuarterKey(_selectedMonth!)]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          widget.title ?? '월별 상세 운세',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          '월을 선택하면 광고 시청 후 상세 운세를 확인할 수 있습니다',
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // 월별 칩 (가로 스크롤)
        _buildMonthChips(theme),
        const SizedBox(height: 24),

        // 선택된 월이 있고 해금된 경우에만 내용 표시
        if (_selectedMonth != null && _unlockedMonths.contains(_selectedMonth)) ...[
          // 분기 테마 (선택된 월의 분기)
          if (quarter != null) _buildQuarterSummary(theme, quarter),
          const SizedBox(height: 24),

          // Step by Step 카테고리
          _buildCategorySteps(theme),
        ] else if (_selectedMonth != null && !_unlockedMonths.contains(_selectedMonth)) ...[
          // 잠긴 상태 안내
          _buildLockedMonthMessage(theme),
        ] else ...[
          // 월 미선택 안내
          _buildSelectMonthMessage(theme),
        ],
      ],
    );
  }

  Widget _buildLockedMonthMessage(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: theme.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            '$_selectedMonth월 운세를 확인하려면\n광고를 시청해주세요',
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoadingAd ? null : () => _showNativeAdAndUnlockMonth(_selectedMonth!),
            icon: const Icon(Icons.play_circle_outline, size: 20),
            label: Text(_isLoadingAd ? '광고 로딩 중...' : '광고 보고 해금하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectMonthMessage(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month,
            size: 48,
            color: theme.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            '위에서 월을 선택하면\n해당 월의 상세 운세를 확인할 수 있습니다',
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChips(AppThemeExtension theme) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final isSelected = month == _selectedMonth;
          final isUnlocked = _unlockedMonths.contains(month);

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == 11 ? 0 : 0,
            ),
            child: GestureDetector(
              onTap: () => _onMonthTap(month, isUnlocked),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.15)
                      : isUnlocked
                          ? theme.cardColor
                          : theme.cardColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : isUnlocked
                            ? theme.textMuted.withValues(alpha: 0.3)
                            : theme.textMuted.withValues(alpha: 0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 잠금 아이콘 (잠긴 경우)
                    if (!isUnlocked) ...[
                      Icon(
                        Icons.lock_outline,
                        size: 12,
                        color: theme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '$month월',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? theme.primaryColor
                            : isUnlocked
                                ? theme.textPrimary
                                : theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onMonthTap(int month, bool isUnlocked) {
    if (isUnlocked) {
      // 이미 해금된 월 - 바로 선택
      setState(() {
        _selectedMonth = month;
        _currentStep = 0;
      });
      _loadStepsForMonth(month);
    } else {
      // 잠긴 월 - 선택만 하고 광고 안내 표시
      setState(() {
        _selectedMonth = month;
        _currentStep = 0;
      });
    }
  }

  /// 네이티브 광고 표시 후 월 해금
  Future<void> _showNativeAdAndUnlockMonth(int month) async {
    if (_isLoadingAd) return;

    // 프리미엄 유저는 광고 없이 바로 해제
    final purchaseState = ref.read(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) {
      await _unlockMonth(month);
      if (mounted) {
        setState(() => _isLoadingAd = false);
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$month월 운세가 해제되었습니다!'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    setState(() => _isLoadingAd = true);

    // 웹에서는 광고 스킵
    if (kIsWeb) {
      await _unlockMonth(month);
      if (mounted) {
        setState(() => _isLoadingAd = false);
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$month월 운세가 해제되었습니다! (웹 테스트)'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    // 네이티브 광고 대신 보상형 광고 사용 (네이티브 광고는 인라인 표시용)
    // 여기서는 보상형 광고로 대체
    if (!AdService.instance.isRewardedLoaded) {
      await AdService.instance.loadRewardedAd(
        onLoaded: () async {
          final shown = await AdService.instance.showRewardedAd(
            onRewarded: (amount, type) async {
              await _unlockMonth(month);
              if (mounted) {
                setState(() => _isLoadingAd = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$month월 운세가 해제되었습니다!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          );

          if (!shown && mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog('$month월');
          }
        },
        onFailed: (error) {
          if (mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog('$month월');
          }
        },
      );
    } else {
      final shown = await AdService.instance.showRewardedAd(
        onRewarded: (amount, type) async {
          await _unlockMonth(month);
          if (mounted) {
            setState(() => _isLoadingAd = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$month월 운세가 해제되었습니다!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );

      if (!shown && mounted) {
        setState(() => _isLoadingAd = false);
        _showAdNotReadyDialog('$month월');
      }
    }
  }

  Widget _buildQuarterSummary(AppThemeExtension theme, QuarterData quarter) {
    final month = _selectedMonth ?? 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$month월 운세 요약',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (quarter.score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(quarter.score).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${quarter.score}점',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(quarter.score),
                    ),
                  ),
                ),
            ],
          ),
          if (quarter.theme.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '테마: ${quarter.theme}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
            ),
          ],
          if (quarter.reading.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              quarter.reading,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySteps(AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '분야별 상세 운세',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Step Indicator
        _buildStepIndicator(theme),
        const SizedBox(height: 16),

        // 현재 Step 내용
        _buildCurrentStepContent(theme),
      ],
    );
  }

  Widget _buildStepIndicator(AppThemeExtension theme) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryKeys.length,
        itemBuilder: (context, index) {
          final step = index + 1;
          final categoryKey = _categoryKeys[index];
          final isUnlocked = _unlockedSteps.contains(step);
          final isCurrent = _currentStep == step;
          final categoryName = _getCategoryName(categoryKey);

          return GestureDetector(
            onTap: () => _onStepTap(step, isUnlocked),
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == _categoryKeys.length - 1 ? 0 : 4,
              ),
              child: Column(
                children: [
                  // Step 원
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? theme.primaryColor
                          : isUnlocked
                              ? theme.primaryColor.withValues(alpha: 0.3)
                              : theme.cardColor,
                      border: Border.all(
                        color: isCurrent
                            ? theme.primaryColor
                            : isUnlocked
                                ? theme.primaryColor.withValues(alpha: 0.5)
                                : theme.textMuted.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Text(
                              '$step',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCurrent
                                    ? Colors.white
                                    : theme.primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.lock,
                              size: 16,
                              color: theme.textSecondary,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 카테고리 이름
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrent
                          ? theme.primaryColor
                          : isUnlocked
                              ? theme.textSecondary
                              : theme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStepContent(AppThemeExtension theme) {
    if (_currentStep == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.textMuted.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.touch_app,
              size: 32,
              color: theme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              '위의 분야를 선택하면 상세 운세를 확인할 수 있습니다',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final categoryKey = _categoryKeys[_currentStep - 1];
    final category = widget.categories[categoryKey];
    if (category == null) {
      return const SizedBox.shrink();
    }

    final categoryName = _getCategoryName(categoryKey);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step $_currentStep',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedMonth ?? ""}월 $categoryName',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              if (category.score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(category.score).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${category.score}점',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(category.score),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary
          if (category.summary != null && category.summary!.isNotEmpty) ...[
            Text(
              category.summary!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Reading
          if (category.reading.isNotEmpty)
            Text(
              category.reading,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.8,
              ),
            ),

          // Best/Caution Months
          if (category.bestMonths != null && category.bestMonths!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '좋은 달: ${category.bestMonths!.map((m) => '$m월').join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
                height: 1.6,
              ),
            ),
          ],
          if (category.cautionMonths != null && category.cautionMonths!.isNotEmpty)
            Text(
              '주의할 달: ${category.cautionMonths!.map((m) => '$m월').join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                height: 1.6,
              ),
            ),

          // Action Tip
          if (category.actionTip != null && category.actionTip!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.actionTip!,
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

          // 다음 Step 버튼
          if (_currentStep < _categoryKeys.length) ...[
            const SizedBox(height: 20),
            _buildNextStepButton(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildNextStepButton(AppThemeExtension theme) {
    final nextStep = _currentStep + 1;
    final isNextUnlocked = _unlockedSteps.contains(nextStep);
    final nextCategoryName =
        nextStep <= _categoryKeys.length ? _getCategoryName(_categoryKeys[nextStep - 1]) : '';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoadingAd ? null : () => _onStepTap(nextStep, isNextUnlocked),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isNextUnlocked ? theme.primaryColor : theme.textSecondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isNextUnlocked) ...[
              const Icon(Icons.play_circle_outline, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              isNextUnlocked
                  ? '다음: $nextCategoryName'
                  : '광고 보고 $nextCategoryName 확인하기',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStepTap(int step, bool isUnlocked) async {
    if (step < 1 || step > _categoryKeys.length) return;

    if (isUnlocked) {
      setState(() => _currentStep = step);
    } else {
      await _showRewardedAdAndUnlock(step);
    }
  }

  Future<void> _showRewardedAdAndUnlock(int step) async {
    if (_isLoadingAd) return;

    final categoryName =
        step <= _categoryKeys.length ? _getCategoryName(_categoryKeys[step - 1]) : 'Step $step';

    // 프리미엄 유저는 광고 없이 바로 해제
    final purchaseState = ref.read(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) {
      await _unlockStep(step);
      if (mounted) {
        setState(() => _isLoadingAd = false);
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$categoryName 운세가 해제되었습니다!'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    setState(() => _isLoadingAd = true);

    // 웹에서는 광고 스킵
    if (kIsWeb) {
      await _unlockStep(step);
      if (mounted) {
        setState(() => _isLoadingAd = false);
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$categoryName 운세가 해제되었습니다! (웹 테스트)'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    // 광고 로드 및 표시
    if (!AdService.instance.isRewardedLoaded) {
      await AdService.instance.loadRewardedAd(
        onLoaded: () async {
          final shown = await AdService.instance.showRewardedAd(
            onRewarded: (amount, type) async {
              await _unlockStep(step);
              if (mounted) {
                setState(() => _isLoadingAd = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$categoryName 운세가 해제되었습니다!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          );

          if (!shown && mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(categoryName);
          }
        },
        onFailed: (error) {
          if (mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(categoryName);
          }
        },
      );
    } else {
      final shown = await AdService.instance.showRewardedAd(
        onRewarded: (amount, type) async {
          await _unlockStep(step);
          if (mounted) {
            setState(() => _isLoadingAd = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$categoryName 운세가 해제되었습니다!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );

      if (!shown && mounted) {
        setState(() => _isLoadingAd = false);
        _showAdNotReadyDialog(categoryName);
      }
    }
  }

  void _showAdNotReadyDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 준비 중'),
        content:
            Text('$categoryName 운세를 보려면 광고를 시청해야 합니다.\n잠시 후 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String key) {
    const names = {
      'career': '직업운',
      'business': '사업운',
      'wealth': '재물운',
      'love': '애정운',
      'marriage': '결혼운',
      'study': '학업운',
      'health': '건강운',
    };
    return names[key] ?? key;
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
