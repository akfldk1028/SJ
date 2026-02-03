import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../ad/ad_service.dart';
import '../../purchase/providers/purchase_provider.dart';
import '../../purchase/purchase_config.dart';

/// 주간 데이터 인터페이스
class WeeklyData {
  final String theme;
  final String focus;
  final String tip;

  const WeeklyData({
    required this.theme,
    required this.focus,
    required this.tip,
  });
}

/// 주간별 운세 칩 섹션 (월별 운세용)
///
/// - 주차가 칩으로 표시되고 탭하면 펼쳐짐
/// - 잠긴 주차는 광고를 봐야 해제
class FortuneWeeklyChipSection extends ConsumerStatefulWidget {
  /// 운세 타입 (monthly)
  final String fortuneType;

  /// 주간 데이터 맵 (key: week1, week2 등)
  final Map<String, WeeklyData> weeks;

  /// 섹션 제목
  final String? title;

  const FortuneWeeklyChipSection({
    super.key,
    required this.fortuneType,
    required this.weeks,
    this.title,
  });

  @override
  ConsumerState<FortuneWeeklyChipSection> createState() =>
      _FortuneWeeklyChipSectionState();
}

class _FortuneWeeklyChipSectionState extends ConsumerState<FortuneWeeklyChipSection> {
  /// 현재 펼쳐진 주차
  String? _expandedWeek;

  /// 광고 로딩 중 플래그
  bool _isLoadingAd = false;

  /// Hive box for local storage
  Box<bool>? _box;
  Set<String> _unlockedWeeks = {};

  @override
  void initState() {
    super.initState();
    _loadUnlockedWeeks();
  }

  Future<void> _loadUnlockedWeeks() async {
    _box = await Hive.openBox<bool>('unlocked_fortune_weeks');

    final unlocked = <String>{};
    for (final key in _box!.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('${widget.fortuneType}_') && _box!.get(key) == true) {
        unlocked.add(keyStr.substring(widget.fortuneType.length + 1));
      }
    }

    if (mounted) {
      setState(() => _unlockedWeeks = unlocked);
    }
  }

  Future<void> _unlockWeek(String week) async {
    final box = _box ?? await Hive.openBox<bool>('unlocked_fortune_weeks');
    await box.put('${widget.fortuneType}_$week', true);

    if (mounted) {
      setState(() {
        _unlockedWeeks = {..._unlockedWeeks, week};
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
          widget.title ?? '주간별 운세',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // 안내 텍스트
        Text(
          '탭하여 주간 운세를 확인하세요',
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // 주차 칩들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.weeks.entries.map((entry) {
            final key = entry.key;
            final isUnlocked = _unlockedWeeks.contains(key);
            final isExpanded = _expandedWeek == key;
            final weekNum = key.replaceAll('week', '');

            return _buildWeekChip(
              theme: theme,
              weekKey: key,
              weekName: '$weekNum주차',
              isUnlocked: isUnlocked,
              isExpanded: isExpanded,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 펼쳐진 주차 내용
        if (_expandedWeek != null) ...[
          _buildExpandedContent(theme, _expandedWeek!),
        ],
      ],
    );
  }

  Widget _buildWeekChip({
    required AppThemeExtension theme,
    required String weekKey,
    required String weekName,
    required bool isUnlocked,
    required bool isExpanded,
  }) {
    return GestureDetector(
      onTap: () => _onChipTap(weekKey, isUnlocked),
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

            // 주차 이름
            Text(
              weekName,
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

  Widget _buildExpandedContent(AppThemeExtension theme, String weekKey) {
    final week = widget.weeks[weekKey];
    if (week == null) return const SizedBox.shrink();

    final weekNum = weekKey.replaceAll('week', '');

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
                '$weekNum주차',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              // 닫기 버튼
              GestureDetector(
                onTap: () => setState(() => _expandedWeek = null),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 테마
          if (week.theme.isNotEmpty) ...[
            Text(
              '테마: ${week.theme}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 집중 포인트
          if (week.focus.isNotEmpty)
            Text(
              '집중 포인트: ${week.focus}',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),

          // 팁
          if (week.tip.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '팁: ${week.tip}',
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

  Future<void> _onChipTap(String weekKey, bool isUnlocked) async {
    if (isUnlocked) {
      // 이미 해제된 주차 - 토글
      setState(() {
        if (_expandedWeek == weekKey) {
          _expandedWeek = null;
        } else {
          _expandedWeek = weekKey;
        }
      });
    } else {
      // 잠긴 주차 - 광고 보여주기
      await _showRewardedAdAndUnlock(weekKey);
    }
  }

  Future<void> _showRewardedAdAndUnlock(String weekKey) async {
    if (_isLoadingAd) return;

    final weekNum = weekKey.replaceAll('week', '');
    final weekName = '$weekNum주차';

    // 프리미엄 유저는 광고 없이 바로 해제
    final purchaseState = ref.read(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) {
      await _unlockWeek(weekKey);
      if (mounted) {
        setState(() {
          _expandedWeek = weekKey;
        });
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$weekName 운세가 해제되었습니다!'),
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
      await _unlockWeek(weekKey);
      if (mounted) {
        setState(() {
          _expandedWeek = weekKey;
          _isLoadingAd = false;
        });
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$weekName 운세가 해제되었습니다! (웹 테스트)'),
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
              await _unlockWeek(weekKey);

              if (mounted) {
                setState(() {
                  _expandedWeek = weekKey;
                  _isLoadingAd = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$weekName 운세가 해제되었습니다!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          );

          if (!shown && mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(weekName);
          }
        },
        onFailed: (error) {
          if (mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(weekName);
          }
        },
      );
    } else {
      final shown = await AdService.instance.showRewardedAd(
        onRewarded: (amount, type) async {
          await _unlockWeek(weekKey);

          if (mounted) {
            setState(() {
              _expandedWeek = weekKey;
              _isLoadingAd = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$weekName 운세가 해제되었습니다!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );

      if (!shown && mounted) {
        setState(() => _isLoadingAd = false);
        _showAdNotReadyDialog(weekName);
      }
    }
  }

  void _showAdNotReadyDialog(String weekName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 준비 중'),
        content:
            Text('$weekName 운세를 보려면 광고를 시청해야 합니다.\n잠시 후 다시 시도해주세요.'),
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
