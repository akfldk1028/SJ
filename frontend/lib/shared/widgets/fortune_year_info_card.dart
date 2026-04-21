import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 년도별 특징 정보 카드
///
/// 간지(을사년, 병오년 등), 띠, 오행의 특성을 동양풍으로 표시
class FortuneYearInfoCard extends StatelessWidget {
  final int year;
  final String ganji; // 을사년, 병오년 등
  final String? customDescription; // 커스텀 설명 (AI 생성)

  const FortuneYearInfoCard({
    super.key,
    required this.year,
    required this.ganji,
    this.customDescription,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final yearInfo = _getYearInfo(year, ganji);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yearInfo.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: yearInfo.color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 연도 + 간지
          Row(
            children: [
              // 띠 아이콘/이모지
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: yearInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: yearInfo.color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    yearInfo.zodiacEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'year_info.yearTitle'.tr(namedArgs: {'year': '$year', 'ganji': ganji}),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      yearInfo.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: yearInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 구분선
          Container(
            height: 1,
            color: theme.textMuted.withValues(alpha: 0.1),
          ),

          const SizedBox(height: 16),

          // 오행 + 특성 정보
          Row(
            children: [
              Expanded(child: _buildInfoChip(theme, 'year_info.fiveElements'.tr(), 'year_info.${yearInfo.element}'.tr(), yearInfo.color)),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoChip(theme, 'year_info.zodiac'.tr(), 'year_info.${yearInfo.zodiac}'.tr(), yearInfo.color)),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoChip(theme, 'year_info.yinYang'.tr(), 'year_info.${yearInfo.yinYang}'.tr(), yearInfo.color)),
            ],
          ),

          const SizedBox(height: 16),

          // 년도 특성 설명
          Text(
            customDescription ?? yearInfo.description,
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
              height: 1.7,
            ),
          ),

          // 키워드 태그
          if (yearInfo.keywords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: yearInfo.keywords.map((keyword) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: yearInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '#$keyword',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: yearInfo.color,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(AppThemeExtension theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.textMuted.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 연도별 정보 생성
  _YearInfo _getYearInfo(int year, String ganji) {
    // 간지에서 천간과 지지 추출
    final heavenlyStem = ganji.isNotEmpty ? ganji[0] : '';
    final earthlyBranch = ganji.length > 1 ? ganji[1] : '';

    // 천간별 오행과 음양
    final stemInfo = _heavenlyStemInfo[heavenlyStem] ?? _StemInfo('wood', 'yang', const Color(0xFF2D8659));

    // 지지별 띠 정보
    final branchInfo = _earthlyBranchInfo[earthlyBranch] ?? _BranchInfo('dragon', '🐉', 'dragon');

    // 년도별 특수 명칭 및 설명
    final specialInfo = _getSpecialYearInfo(year, heavenlyStem, earthlyBranch);

    return _YearInfo(
      title: specialInfo.title,
      element: stemInfo.element,
      yinYang: stemInfo.yinYang,
      zodiac: branchInfo.zodiacName,
      zodiacEmoji: branchInfo.emoji,
      color: specialInfo.color ?? stemInfo.color,
      description: specialInfo.description,
      keywords: specialInfo.keywords,
    );
  }

  _SpecialYearInfo _getSpecialYearInfo(int year, String stem, String branch) {
    // 2025년 을사년 (청뱀의 해)
    if (year == 2025 && stem == '을' && branch == '사') {
      return _SpecialYearInfo(
        title: 'year_info.greenSnakeTitle'.tr(),
        description: 'year_info.greenSnakeDesc'.tr(),
        keywords: ['year_info.greenSnakeK1'.tr(), 'year_info.greenSnakeK2'.tr(), 'year_info.greenSnakeK3'.tr(), 'year_info.greenSnakeK4'.tr()],
        color: const Color(0xFF2D8659),
      );
    }

    // 2026년 병오년 (붉은말의 해)
    if (year == 2026 && stem == '병' && branch == '오') {
      return _SpecialYearInfo(
        title: 'year_info.redHorseTitle'.tr(),
        description: 'year_info.redHorseDesc'.tr(),
        keywords: ['year_info.redHorseK1'.tr(), 'year_info.redHorseK2'.tr(), 'year_info.redHorseK3'.tr(), 'year_info.redHorseK4'.tr()],
        color: const Color(0xFFB8420F),
      );
    }

    // 2024년 갑진년 (청룡의 해)
    if (year == 2024 && stem == '갑' && branch == '진') {
      return _SpecialYearInfo(
        title: 'year_info.greenDragonTitle'.tr(),
        description: 'year_info.greenDragonDesc'.tr(),
        keywords: ['year_info.greenDragonK1'.tr(), 'year_info.greenDragonK2'.tr(), 'year_info.greenDragonK3'.tr(), 'year_info.greenDragonK4'.tr()],
        color: const Color(0xFF2D8659),
      );
    }

    // 기본 정보
    final stemInfo = _heavenlyStemInfo[stem] ?? _StemInfo('wood', 'yang', const Color(0xFF2D8659));
    final branchInfo = _earthlyBranchInfo[branch] ?? _BranchInfo('dragon', '辰', 'dragon');

    return _SpecialYearInfo(
      title: 'year_info.yearOfTitle'.tr(namedArgs: {'element': 'year_info.${stemInfo.element}'.tr(), 'zodiac': 'year_info.${branchInfo.zodiacName}'.tr()}),
      description: 'year_info.yearOfDesc'.tr(namedArgs: {'element': 'year_info.${stemInfo.element}'.tr(), 'yinYang': 'year_info.${stemInfo.yinYang}'.tr(), 'zodiac': 'year_info.${branchInfo.zodiacName}'.tr()}),
      keywords: [],
      color: stemInfo.color,
    );
  }

  // 천간 정보 (오행 i18n 키, 음양 i18n 키, 색상)
  static final Map<String, _StemInfo> _heavenlyStemInfo = {
    '갑': _StemInfo('wood', 'yang', const Color(0xFF2D8659)),
    '을': _StemInfo('wood', 'yin', const Color(0xFF3D9970)),
    '병': _StemInfo('fire', 'yang', const Color(0xFFB8420F)),
    '정': _StemInfo('fire', 'yin', const Color(0xFFD4652F)),
    '무': _StemInfo('earth', 'yang', const Color(0xFFB8860B)),
    '기': _StemInfo('earth', 'yin', const Color(0xFFCDA64F)),
    '경': _StemInfo('metal', 'yang', const Color(0xFF6B7280)),
    '신': _StemInfo('metal', 'yin', const Color(0xFF9CA3AF)),
    '임': _StemInfo('water', 'yang', const Color(0xFF1E40AF)),
    '계': _StemInfo('water', 'yin', const Color(0xFF3B5998)),
  };

  // 지지 정보 (띠 i18n 키, 이모지, 짧은 이름)
  static final Map<String, _BranchInfo> _earthlyBranchInfo = {
    '자': _BranchInfo('rat', '🐀', 'rat'),
    '축': _BranchInfo('ox', '🐂', 'ox'),
    '인': _BranchInfo('tiger', '🐅', 'tiger'),
    '묘': _BranchInfo('rabbit', '🐇', 'rabbit'),
    '진': _BranchInfo('dragon', '🐉', 'dragon'),
    '사': _BranchInfo('snake', '🐍', 'snake'),
    '오': _BranchInfo('horse', '🐴', 'horse'),
    '미': _BranchInfo('goat', '🐏', 'goat'),
    '신': _BranchInfo('monkey', '🐒', 'monkey'),
    '유': _BranchInfo('rooster', '🐓', 'rooster'),
    '술': _BranchInfo('dog', '🐕', 'dog'),
    '해': _BranchInfo('pig', '🐖', 'pig'),
  };
}

class _StemInfo {
  final String element;
  final String yinYang;
  final Color color;

  const _StemInfo(this.element, this.yinYang, this.color);
}

class _BranchInfo {
  final String zodiacName;
  final String emoji;
  final String shortName;

  const _BranchInfo(this.zodiacName, this.emoji, this.shortName);
}

class _SpecialYearInfo {
  final String title;
  final String description;
  final List<String> keywords;
  final Color? color;

  const _SpecialYearInfo({
    required this.title,
    required this.description,
    required this.keywords,
    this.color,
  });
}

class _YearInfo {
  final String title;
  final String element;
  final String yinYang;
  final String zodiac;
  final String zodiacEmoji;
  final Color color;
  final String description;
  final List<String> keywords;

  const _YearInfo({
    required this.title,
    required this.element,
    required this.yinYang,
    required this.zodiac,
    required this.zodiacEmoji,
    required this.color,
    required this.description,
    required this.keywords,
  });
}
