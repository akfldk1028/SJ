import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/gender.dart';
import '../../../domain/entities/relationship_type.dart';
import '../../../../saju_chart/domain/entities/saju_chart.dart';
import '../../../../saju_chart/domain/entities/pillar.dart';
import '../../../../saju_chart/domain/services/saju_calculation_service.dart';
import '../../../../saju_chart/domain/services/jasi_service.dart';
import '../../../../saju_chart/data/constants/cheongan_jiji.dart';

/// 사주 빠른보기 바텀시트
///
/// 노드 탭 시 프로필의 사주팔자 정보를 표시
class SajuQuickViewSheet extends ConsumerStatefulWidget {
  const SajuQuickViewSheet({
    super.key,
    required this.profile,
    this.onChatPressed,
    this.onDetailPressed,
  });

  final SajuProfile profile;
  final VoidCallback? onChatPressed;
  final VoidCallback? onDetailPressed;

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

      // birthTimeMinutes를 DateTime으로 변환
      DateTime birthDateTime;
      if (profile.birthTimeUnknown || profile.birthTimeMinutes == null) {
        birthDateTime = DateTime(
          profile.birthDate.year,
          profile.birthDate.month,
          profile.birthDate.day,
          12, 0, // 정오 기준
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
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final profile = widget.profile;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: appTheme.isDark
            ? const Color(0xFF1A1A24) // 다크 배경
            : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: appTheme.isDark
                      ? Colors.grey[600]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

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
                  child: Text('사주 계산 오류: $_error'),
                )
              else if (_sajuChart != null)
                _buildSajuDisplay(context, _sajuChart!),

              const SizedBox(height: 20),

              // 액션 버튼
              _buildActionButtons(context),

              // Safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
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
        // 아바타
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [relationColor, relationColor.withOpacity(0.7)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: relationColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName.substring(0, 1)
                  : '?',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
                      color: appTheme.isDark ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: relationColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      profile.relationType.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: relationColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.birthDateFormatted} (${profile.calendarTypeLabel})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: appTheme.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (!profile.birthTimeUnknown && profile.birthTimeFormatted != null)
                Text(
                  '${profile.birthTimeFormatted} 출생',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: appTheme.isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSajuDisplay(BuildContext context, SajuChart chart) {
    final appTheme = context.appTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme.isDark
            ? const Color(0xFF252530) // 다크 카드 배경
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appTheme.isDark
              ? const Color(0xFF3A3A4A)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // 사주팔자 한자 헤더
          Text(
            chart.fullSajuHanja,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: appTheme.isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chart.fullSaju,
            style: TextStyle(
              fontSize: 14,
              color: appTheme.isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 4,
            ),
          ),
          Divider(
            height: 24,
            color: appTheme.isDark ? const Color(0xFF3A3A4A) : null,
          ),

          // 4개 기둥 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPillarColumn(
                context,
                '시주',
                chart.hourPillar,
                chart.hasUnknownBirthTime,
              ),
              _buildPillarColumn(context, '일주', chart.dayPillar, false, isDayMaster: true),
              _buildPillarColumn(context, '월주', chart.monthPillar, false),
              _buildPillarColumn(context, '년주', chart.yearPillar, false),
            ],
          ),

          const SizedBox(height: 16),

          // 일간 설명
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: appTheme.isDark
                  ? const Color(0xFF1A1A24)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appTheme.isDark
                    ? const Color(0xFF3A3A4A)
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '일간(나): ',
                  style: TextStyle(
                    fontSize: 13,
                    color: appTheme.isDark ? Colors.grey[400] : Colors.black,
                  ),
                ),
                Text(
                  '${chart.dayMaster} (${_getOhengText(chart.dayPillar.ganOheng)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _getOhengColor(chart.dayPillar.ganOheng, appTheme.isDark),
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

    if (isUnknown || pillar == null) {
      return _buildUnknownPillar(context, label);
    }

    final ganHanja = cheonganHanja[pillar.gan] ?? '';
    final jiHanja = jijiHanja[pillar.ji] ?? '';
    final ganColor = _getOhengColor(pillar.ganOheng, appTheme.isDark);
    final jiColor = _getOhengColor(pillar.jiOheng, appTheme.isDark);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isDayMaster
          ? BoxDecoration(
              color: appTheme.isDark
                  ? const Color(0xFFD4A54A).withOpacity(0.15)
                  : Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appTheme.isDark
                    ? const Color(0xFFD4A54A)
                    : Colors.amber,
                width: 2,
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDayMaster
                  ? (appTheme.isDark ? const Color(0xFFD4A54A) : Colors.amber[800])
                  : (appTheme.isDark ? Colors.grey[400] : Colors.grey[600]),
              fontWeight: isDayMaster ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          // 천간 - 오행 색상 배경에 흰색 텍스트
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ganColor, ganColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: ganColor.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                ganHanja,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pillar.gan,
            style: TextStyle(
              fontSize: 11,
              color: appTheme.isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          // 지지 - 오행 색상 배경에 흰색 텍스트
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [jiColor, jiColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: jiColor.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                jiHanja,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pillar.ji,
            style: TextStyle(
              fontSize: 11,
              color: appTheme.isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownPillar(BuildContext context, String label) {
    final appTheme = context.appTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: appTheme.isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: appTheme.isDark
                ? const Color(0xFF3A3A4A)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: appTheme.isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '미상',
          style: TextStyle(
            fontSize: 11,
            color: appTheme.isDark ? Colors.grey[500] : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: appTheme.isDark
                ? const Color(0xFF3A3A4A)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: appTheme.isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '미상',
          style: TextStyle(
            fontSize: 11,
            color: appTheme.isDark ? Colors.grey[500] : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onChatPressed,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('사주 상담'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: widget.onDetailPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: const Text('상세보기'),
        ),
      ],
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
    // 다크 테마에서는 더 밝고 선명한 색상 사용
    switch (oheng) {
      case '목':
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047); // 초록
      case '화':
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935); // 빨강
      case '토':
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFFA726); // 주황
      case '금':
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107); // 금색
      case '수':
        return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1E88E5); // 파랑
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
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SajuQuickViewSheet(
      profile: profile,
      onChatPressed: onChatPressed,
      onDetailPressed: onDetailPressed,
    ),
  );
}
