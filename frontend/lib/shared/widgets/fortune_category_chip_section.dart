import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../ad/ad_service.dart';

/// 공통 카테고리 데이터 인터페이스
class CategoryData {
  final String title;
  final int score;
  final String reading;
  final String? summary;
  final List<int>? bestMonths;
  final List<int>? cautionMonths;
  final String? actionTip;
  final List<String>? focusAreas;

  const CategoryData({
    required this.title,
    required this.score,
    required this.reading,
    this.summary,
    this.bestMonths,
    this.cautionMonths,
    this.actionTip,
    this.focusAreas,
  });
}

/// 분야별 운세 카테고리 칩 섹션 (공통)
///
/// - 카테고리가 칩으로 표시되고 탭하면 펼쳐짐
/// - 잠긴 카테고리는 광고를 봐야 해제
/// - fortuneType으로 운세 종류 구분
class FortuneCategoryChipSection extends StatefulWidget {
  /// 운세 타입 (lifetime, yearly_2025, yearly_2026, monthly)
  final String fortuneType;

  /// 카테고리 데이터 맵 (key: career, wealth 등)
  final Map<String, CategoryData> categories;

  /// 섹션 제목
  final String? title;

  /// 상세 내용 표시 여부
  final bool showDetailedContent;

  const FortuneCategoryChipSection({
    super.key,
    required this.fortuneType,
    required this.categories,
    this.title,
    this.showDetailedContent = true,
  });

  @override
  State<FortuneCategoryChipSection> createState() =>
      _FortuneCategoryChipSectionState();
}

class _FortuneCategoryChipSectionState
    extends State<FortuneCategoryChipSection> {
  /// 현재 펼쳐진 카테고리
  String? _expandedCategory;

  /// 광고 로딩 중 플래그
  bool _isLoadingAd = false;

  /// Hive box for local storage
  Box<bool>? _box;
  Set<String> _unlockedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadUnlockedCategories();
  }

  Future<void> _loadUnlockedCategories() async {
    _box = await Hive.openBox<bool>('unlocked_fortune_categories');

    final unlocked = <String>{};
    for (final key in _box!.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('${widget.fortuneType}_') && _box!.get(key) == true) {
        unlocked.add(keyStr.substring(widget.fortuneType.length + 1));
      }
    }

    if (mounted) {
      setState(() => _unlockedCategories = unlocked);
    }
  }

  Future<void> _unlockCategory(String category) async {
    final box = _box ?? await Hive.openBox<bool>('unlocked_fortune_categories');
    await box.put('${widget.fortuneType}_$category', true);

    if (mounted) {
      setState(() {
        _unlockedCategories = {..._unlockedCategories, category};
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
          widget.title ?? '분야별 운세',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // 안내 텍스트
        Text(
          '탭하여 상세 운세를 확인하세요',
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // 카테고리 칩들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.entries.map((entry) {
            final key = entry.key;
            final cat = entry.value;
            final isUnlocked = _unlockedCategories.contains(key);
            final isExpanded = _expandedCategory == key;
            final categoryName = _getCategoryName(key);

            return _buildCategoryChip(
              theme: theme,
              categoryKey: key,
              categoryName: categoryName,
              score: cat.score,
              isUnlocked: isUnlocked,
              isExpanded: isExpanded,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 펼쳐진 카테고리 내용
        if (_expandedCategory != null && widget.showDetailedContent) ...[
          _buildExpandedContent(theme, _expandedCategory!),
        ],
      ],
    );
  }

  Widget _buildCategoryChip({
    required AppThemeExtension theme,
    required String categoryKey,
    required String categoryName,
    required int score,
    required bool isUnlocked,
    required bool isExpanded,
  }) {
    return GestureDetector(
      onTap: () => _onChipTap(categoryKey, isUnlocked),
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

            // 카테고리 이름
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                color: isUnlocked ? theme.textPrimary : theme.textSecondary,
              ),
            ),

            // 점수 (해제된 경우)
            if (isUnlocked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score점',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(score),
                  ),
                ),
              ),
            ],

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

  Widget _buildExpandedContent(AppThemeExtension theme, String categoryKey) {
    final cat = widget.categories[categoryKey];
    if (cat == null) return const SizedBox.shrink();

    final categoryName = _getCategoryName(categoryKey);

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
                categoryName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(cat.score).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${cat.score}점',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(cat.score),
                  ),
                ),
              ),
              const Spacer(),
              // 닫기 버튼
              GestureDetector(
                onTap: () => setState(() => _expandedCategory = null),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary (있으면)
          if (cat.summary != null && cat.summary!.isNotEmpty) ...[
            Text(
              cat.summary!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 내용
          if (cat.reading.isNotEmpty)
            Text(
              cat.reading,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.8,
              ),
            ),

          // 좋은 달 / 주의할 달
          if (cat.bestMonths != null && cat.bestMonths!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '좋은 달: ${cat.bestMonths!.map((m) => '${m}월').join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
                height: 1.6,
              ),
            ),
          ],
          if (cat.cautionMonths != null && cat.cautionMonths!.isNotEmpty)
            Text(
              '주의할 달: ${cat.cautionMonths!.map((m) => '${m}월').join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                height: 1.6,
              ),
            ),

          // 실천 팁
          if (cat.actionTip != null && cat.actionTip!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, '실천 팁', cat.actionTip!),
          ],

          // 집중 영역
          if (cat.focusAreas != null && cat.focusAreas!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '집중 영역:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ...cat.focusAreas!.map((area) => _buildListItem(theme, area)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection(AppThemeExtension theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: theme.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(AppThemeExtension theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
              height: 1.6,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onChipTap(String categoryKey, bool isUnlocked) async {
    if (isUnlocked) {
      // 이미 해제된 카테고리 - 토글
      setState(() {
        if (_expandedCategory == categoryKey) {
          _expandedCategory = null;
        } else {
          _expandedCategory = categoryKey;
        }
      });
    } else {
      // 잠긴 카테고리 - 광고 보여주기
      await _showRewardedAdAndUnlock(categoryKey);
    }
  }

  Future<void> _showRewardedAdAndUnlock(String categoryKey) async {
    if (_isLoadingAd) return;

    setState(() => _isLoadingAd = true);

    final categoryName = _getCategoryName(categoryKey);

    // 웹에서는 광고 스킵하고 바로 해제 (테스트용)
    if (kIsWeb) {
      await _unlockCategory(categoryKey);
      if (mounted) {
        setState(() {
          _expandedCategory = categoryKey;
          _isLoadingAd = false;
        });
        // SnackBar 표시 (에러 방지)
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

    // 광고가 로드되어 있는지 확인
    if (!AdService.instance.isRewardedLoaded) {
      // 광고 로드 시도
      await AdService.instance.loadRewardedAd(
        onLoaded: () async {
          // 광고 로드 완료 후 표시
          final shown = await AdService.instance.showRewardedAd(
            onRewarded: (amount, type) async {
              // 보상 지급 - 카테고리 잠금 해제
              await _unlockCategory(categoryKey);

              if (mounted) {
                setState(() {
                  _expandedCategory = categoryKey;
                  _isLoadingAd = false;
                });

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
      // 광고가 이미 로드됨 - 바로 표시
      final shown = await AdService.instance.showRewardedAd(
        onRewarded: (amount, type) async {
          await _unlockCategory(categoryKey);

          if (mounted) {
            setState(() {
              _expandedCategory = categoryKey;
              _isLoadingAd = false;
            });

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
      'overall': '총운',
      'family': '가정운',
      'social': '대인운',
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
