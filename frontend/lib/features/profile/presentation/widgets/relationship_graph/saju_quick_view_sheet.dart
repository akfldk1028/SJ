import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/relationship_type.dart';
import '../../../../saju_chart/domain/entities/saju_chart.dart';
import '../../../../saju_chart/domain/entities/pillar.dart';
import '../../../../saju_chart/domain/services/saju_calculation_service.dart';
import '../../../../saju_chart/domain/services/jasi_service.dart';
import '../../../../saju_chart/data/constants/cheongan_jiji.dart';

/// 사주 빠른보기 바텀시트 (모던 UI)
class SajuQuickViewSheet extends ConsumerStatefulWidget {
  const SajuQuickViewSheet({
    super.key,
    required this.profile,
    this.onChatPressed,
    this.onDetailPressed,
    this.onCompatibilityPressed,
  });

  final SajuProfile profile;
  final VoidCallback? onChatPressed;
  final VoidCallback? onDetailPressed;
  final VoidCallback? onCompatibilityPressed;

  @override
  ConsumerState<SajuQuickViewSheet> createState() => _SajuQuickViewSheetState();
}

class _SajuQuickViewSheetState extends ConsumerState<SajuQuickViewSheet> {
  SajuChart? _sajuChart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculateSaju();
  }

  void _calculateSaju() {
    try {
      final service = SajuCalculationService();
      final profile = widget.profile;

      DateTime birthDateTime;
      if (profile.birthTimeUnknown || profile.birthTimeMinutes == null) {
        birthDateTime = DateTime(
          profile.birthDate.year,
          profile.birthDate.month,
          profile.birthDate.day,
          12, 0,
        );
      } else {
        final hours = profile.birthTimeMinutes! ~/ 60;
        final minutes = profile.birthTimeMinutes! % 60;
        birthDateTime = DateTime(
          profile.birthDate.year,
          profile.birthDate.month,
          profile.birthDate.day,
          hours,
          minutes,
        );
      }

      final chart = service.calculate(
        birthDateTime: birthDateTime,
        birthCity: profile.birthCity,
        isLunarCalendar: profile.isLunar,
        isLeapMonth: profile.isLeapMonth,
        birthTimeUnknown: profile.birthTimeUnknown,
        jasiMode: profile.useYaJasi ? JasiMode.yaJasi : JasiMode.joJasi,
      );

      setState(() {
        _sajuChart = chart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final profile = widget.profile;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: appTheme.isDark
            ? const Color(0xFF12121A)
            : Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: appTheme.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: appTheme.isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 프로필 헤더
                  _buildProfileHeader(context, profile),

                  const SizedBox(height: 20),

                  // 사주 정보
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('profile.sajuCalculationError'.tr(namedArgs: {'error': _error ?? ''})),
                    )
                  else if (_sajuChart != null)
                    _buildSajuDisplay(context, _sajuChart!),

                  const SizedBox(height: 24),

                  // 액션 버튼
                  _buildActionButtons(context),

                  // Safe area padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, SajuProfile profile) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final relationColor = _getRelationColor(profile.relationType);

    return Row(
      children: [
        // 아바타 - 더블 링 디자인
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [relationColor, relationColor.withValues(alpha: 0.6)],
            ),
            boxShadow: [
              BoxShadow(
                color: relationColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appTheme.isDark
                  ? const Color(0xFF12121A)
                  : Colors.grey[50],
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [relationColor, relationColor.withValues(alpha: 0.7)],
                ),
              ),
              child: Center(
                child: Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName.substring(0, 1)
                      : '?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // 이름 및 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    profile.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: appTheme.isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 관계 배지 - 글래스모피즘
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          relationColor.withValues(alpha: 0.2),
                          relationColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: relationColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      profile.relationType.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: relationColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    size: 13,
                    color: appTheme.isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${profile.birthDateFormatted} (${profile.calendarTypeLabel})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: appTheme.isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              if (!profile.birthTimeUnknown && profile.birthTimeFormatted != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 13,
                      color: appTheme.isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${profile.birthTimeFormatted} 출생',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: appTheme.isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSajuDisplay(BuildContext context, SajuChart chart) {
    final appTheme = context.appTheme;
    final isDark = appTheme.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey[200]!,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          // 4개 기둥 표시 (한자 + 한글 통합)
          Row(
            children: [
              _buildPillarColumn(
                context, '시주', chart.hourPillar, chart.hasUnknownBirthTime,
              ),
              const SizedBox(width: 6),
              _buildPillarColumn(
                context, '일주', chart.dayPillar, false, isDayMaster: true,
              ),
              const SizedBox(width: 6),
              _buildPillarColumn(context, '월주', chart.monthPillar, false),
              const SizedBox(width: 6),
              _buildPillarColumn(context, '년주', chart.yearPillar, false),
            ],
          ),

          const SizedBox(height: 14),

          // 일간 설명 - 미니멀 칩
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey[200]!,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getOhengColor(chart.dayPillar.ganOheng, isDark),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '일간(나)',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '·',
                    style: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ),
                Text(
                  '${chart.dayMaster} (${_getOhengText(chart.dayPillar.ganOheng)})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getOhengColor(chart.dayPillar.ganOheng, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarColumn(
    BuildContext context,
    String label,
    Pillar? pillar,
    bool isUnknown, {
    bool isDayMaster = false,
  }) {
    final appTheme = context.appTheme;
    final isDark = appTheme.isDark;

    if (isUnknown || pillar == null) {
      return Expanded(child: _buildUnknownPillar(context, label));
    }

    final ganHanja = cheonganHanja[pillar.gan] ?? '';
    final jiHanja = jijiHanja[pillar.ji] ?? '';
    final ganColor = _getOhengColor(pillar.ganOheng, isDark);
    final jiColor = _getOhengColor(pillar.jiOheng, isDark);
    const goldColor = Color(0xFFD4A54A);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: isDayMaster
            ? BoxDecoration(
                color: goldColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: goldColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 라벨
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: isDayMaster
                    ? goldColor
                    : (isDark ? Colors.grey[500] : Colors.grey[500]),
                fontWeight: isDayMaster ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // 천간 타일
            _buildElementTile(ganHanja, pillar.gan, ganColor, isDark),
            const SizedBox(height: 5),
            // 지지 타일
            _buildElementTile(jiHanja, pillar.ji, jiColor, isDark),
          ],
        ),
      ),
    );
  }

  /// 오행 타일 (한자 + 한글 라벨 통합)
  Widget _buildElementTile(String hanja, String hangul, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              hanja,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          hangul,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUnknownPillar(BuildContext context, String label) {
    final isDark = context.appTheme.isDark;
    final unknownColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey[200]!;
    final unknownTextColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        _buildUnknownTile(unknownColor, unknownTextColor),
        const SizedBox(height: 3),
        Text('?', style: TextStyle(fontSize: 10.5, color: unknownTextColor)),
        const SizedBox(height: 5),
        _buildUnknownTile(unknownColor, unknownTextColor),
        const SizedBox(height: 3),
        Text('?', style: TextStyle(fontSize: 10.5, color: unknownTextColor)),
      ],
    );
  }

  Widget _buildUnknownTile(Color bgColor, Color textColor) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI 사주 상담 (풀 너비, solid 골드)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.onChatPressed,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text('profile.aiSajuConsult'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4A54A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 사주 상세 + 궁합 보기
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: widget.onDetailPressed,
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: Text('profile.detailView'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: widget.onCompatibilityPressed,
                    icon: const Icon(Icons.favorite, size: 16),
                    label: Text('profile.compatibilityView'.tr()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRelationColor(RelationshipType type) {
    if (type == RelationshipType.me) return const Color(0xFFFF69B4);
    if (type == RelationshipType.family) return const Color(0xFFFF6B6B);
    if (type == RelationshipType.friend) return const Color(0xFF4ECDC4);
    if (type == RelationshipType.lover) return const Color(0xFFFF69B4);
    if (type == RelationshipType.work) return const Color(0xFF45B7D1);
    return const Color(0xFF95A5A6);
  }

  Color _getOhengColor(String oheng, bool isDark) {
    switch (oheng) {
      case '목':
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047);
      case '화':
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935);
      case '토':
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFFA726);
      case '금':
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107);
      case '수':
        return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1E88E5);
      default:
        return isDark ? Colors.grey[400]! : Colors.grey;
    }
  }

  String _getOhengText(String oheng) {
    switch (oheng) {
      case '목':
        return '목(木)';
      case '화':
        return '화(火)';
      case '토':
        return '토(土)';
      case '금':
        return '금(金)';
      case '수':
        return '수(水)';
      default:
        return oheng;
    }
  }
}

/// 사주 빠른보기 바텀시트 표시
void showSajuQuickView(
  BuildContext context, {
  required SajuProfile profile,
  VoidCallback? onChatPressed,
  VoidCallback? onDetailPressed,
  VoidCallback? onCompatibilityPressed,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SajuQuickViewSheet(
      profile: profile,
      onChatPressed: onChatPressed,
      onDetailPressed: onDetailPressed,
      onCompatibilityPressed: onCompatibilityPressed,
    ),
  );
}
