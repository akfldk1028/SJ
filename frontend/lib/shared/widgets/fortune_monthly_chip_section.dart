import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../ad/ad_service.dart';

/// 월별 데이터 인터페이스
class MonthData {
  final String keyword;
  final int score;
  final String reading;
  final String tip;

  const MonthData({
    this.keyword = '',
    this.score = 0,
    this.reading = '',
    this.tip = '',
  });
}

/// 월별 운세 칩 섹션 (월별 운세용)
///
/// - 12개월이 칩으로 표시되고 탭하면 펼쳐짐
/// - 잠긴 월은 광고를 봐야 해제
/// - 현재 달(currentMonth)은 처음부터 잠금 해제 상태
class FortuneMonthlyChipSection extends StatefulWidget {
  /// 운세 타입 (monthly_fortune)
  final String fortuneType;

  /// 월별 데이터 맵 (key: month1, month2 등)
  final Map<String, MonthData> months;

  /// 섹션 제목
  final String? title;

  /// 현재 달 (1-12). 이 달은 처음부터 잠금 해제됨
  final int? currentMonth;

  const FortuneMonthlyChipSection({
    super.key,
    required this.fortuneType,
    required this.months,
    this.title,
    this.currentMonth,
  });

  @override
  State<FortuneMonthlyChipSection> createState() =>
      _FortuneMonthlyChipSectionState();
}

class _FortuneMonthlyChipSectionState extends State<FortuneMonthlyChipSection> {
  /// 현재 펼쳐진 월
  String? _expandedMonth;

  /// 광고 로딩 중 플래그
  bool _isLoadingAd = false;

  /// Hive box for local storage
  Box<bool>? _box;
  Set<String> _unlockedMonths = {};

  @override
  void initState() {
    super.initState();
    // 현재 달은 초기 상태에서도 바로 잠금 해제
    if (widget.currentMonth != null) {
      _unlockedMonths = {'month${widget.currentMonth}'};
    }
    _loadUnlockedMonths();
  }

  Future<void> _loadUnlockedMonths() async {
    _box = await Hive.openBox<bool>('unlocked_fortune_months');

    final unlocked = <String>{};

    // 현재 달은 처음부터 잠금 해제
    if (widget.currentMonth != null) {
      unlocked.add('month${widget.currentMonth}');
    }

    for (final key in _box!.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('${widget.fortuneType}_') && _box!.get(key) == true) {
        unlocked.add(keyStr.substring(widget.fortuneType.length + 1));
      }
    }

    if (mounted) {
      setState(() => _unlockedMonths = unlocked);
    }
  }

  Future<void> _unlockMonth(String month) async {
    final box = _box ?? await Hive.openBox<bool>('unlocked_fortune_months');
    await box.put('${widget.fortuneType}_$month', true);

    if (mounted) {
      setState(() {
        _unlockedMonths = {..._unlockedMonths, month};
      });
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
    final month = widget.months[monthKey];
    if (month == null) return const SizedBox.shrink();

    final monthNum = monthKey.replaceAll('month', '');

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

          // 풀이
          if (month.reading.isNotEmpty)
            Text(
              month.reading,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                height: 1.7,
              ),
            ),

          // 팁
          if (month.tip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '💡 ${month.tip}',
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

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
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

    setState(() => _isLoadingAd = true);

    final monthNum = monthKey.replaceAll('month', '');
    final monthName = '$monthNum월';

    // 웹에서는 광고 스킵하고 바로 해제 (테스트용)
    if (kIsWeb) {
      await _unlockMonth(monthKey);
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

    // 광고가 로드되어 있는지 확인
    if (!AdService.instance.isRewardedLoaded) {
      await AdService.instance.loadRewardedAd(
        onLoaded: () async {
          final shown = await AdService.instance.showRewardedAd(
            onRewarded: (amount, type) async {
              await _unlockMonth(monthKey);

              if (mounted) {
                setState(() {
                  _expandedMonth = monthKey;
                  _isLoadingAd = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$monthName 운세가 해제되었습니다!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
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
      final shown = await AdService.instance.showRewardedAd(
        onRewarded: (amount, type) async {
          await _unlockMonth(monthKey);

          if (mounted) {
            setState(() {
              _expandedMonth = monthKey;
              _isLoadingAd = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$monthName 운세가 해제되었습니다!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );

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
        title: const Text('광고 준비 중'),
        content:
            Text('$monthName 운세를 보려면 광고를 시청해야 합니다.\n잠시 후 다시 시도해주세요.'),
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
