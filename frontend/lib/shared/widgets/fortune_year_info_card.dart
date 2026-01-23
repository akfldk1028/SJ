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
                      '$year년 $ganji',
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
              _buildInfoChip(theme, '오행', yearInfo.element, yearInfo.color),
              const SizedBox(width: 10),
              _buildInfoChip(theme, '띠', yearInfo.zodiac, yearInfo.color),
              const SizedBox(width: 10),
              _buildInfoChip(theme, '음양', yearInfo.yinYang, yearInfo.color),
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
    final stemInfo = _heavenlyStemInfo[heavenlyStem] ?? _StemInfo('목', '양', const Color(0xFF2D8659));

    // 지지별 띠 정보
    final branchInfo = _earthlyBranchInfo[earthlyBranch] ?? _BranchInfo('용', '辰', '용띠');

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
        title: '청뱀의 해',
        description: '을사년은 목(木) 기운의 뱀띠 해입니다. 뱀의 지혜와 나무의 성장 에너지가 결합하여 내면의 성장과 통찰력이 강조됩니다. 조용하지만 깊은 변화의 한 해가 될 것입니다.',
        keywords: ['지혜', '성장', '내면탐구', '변화'],
        color: const Color(0xFF2D8659), // 청록색 (목)
      );
    }

    // 2026년 병오년 (붉은말의 해)
    if (year == 2026 && stem == '병' && branch == '오') {
      return _SpecialYearInfo(
        title: '붉은말의 해',
        description: '병오년은 화(火) 기운이 강한 말띠 해입니다. 말의 열정과 불의 에너지가 만나 활기차고 역동적인 기운이 넘칩니다. 새로운 도전과 적극적인 행동이 좋은 결과를 가져올 해입니다.',
        keywords: ['열정', '도전', '활력', '전진'],
        color: const Color(0xFFB8420F), // 붉은색 (화)
      );
    }

    // 2024년 갑진년 (청룡의 해)
    if (year == 2024 && stem == '갑' && branch == '진') {
      return _SpecialYearInfo(
        title: '청룡의 해',
        description: '갑진년은 목(木) 기운의 용띠 해입니다. 용의 기상과 푸른 나무의 생명력이 결합하여 큰 꿈과 비전을 펼치기 좋은 해입니다.',
        keywords: ['기상', '비전', '도약', '생명력'],
        color: const Color(0xFF2D8659),
      );
    }

    // 기본 정보
    final stemInfo = _heavenlyStemInfo[stem] ?? _StemInfo('목', '양', const Color(0xFF2D8659));
    final branchInfo = _earthlyBranchInfo[branch] ?? _BranchInfo('용', '辰', '용띠');

    return _SpecialYearInfo(
      title: '${stemInfo.element}${branchInfo.zodiacName}의 해',
      description: '${stemInfo.element}(${stemInfo.yinYang}) 기운과 ${branchInfo.zodiacName}띠의 특성이 조화를 이루는 해입니다.',
      keywords: [],
      color: stemInfo.color,
    );
  }

  // 천간 정보 (오행, 음양, 색상)
  static final Map<String, _StemInfo> _heavenlyStemInfo = {
    '갑': _StemInfo('목', '양', const Color(0xFF2D8659)), // 청색
    '을': _StemInfo('목', '음', const Color(0xFF3D9970)), // 청색
    '병': _StemInfo('화', '양', const Color(0xFFB8420F)), // 적색
    '정': _StemInfo('화', '음', const Color(0xFFD4652F)), // 적색
    '무': _StemInfo('토', '양', const Color(0xFFB8860B)), // 황색
    '기': _StemInfo('토', '음', const Color(0xFFCDA64F)), // 황색
    '경': _StemInfo('금', '양', const Color(0xFF6B7280)), // 백색/은색
    '신': _StemInfo('금', '음', const Color(0xFF9CA3AF)), // 백색/은색
    '임': _StemInfo('수', '양', const Color(0xFF1E40AF)), // 흑색/남색
    '계': _StemInfo('수', '음', const Color(0xFF3B5998)), // 흑색/남색
  };

  // 지지 정보 (띠, 한자, 이름)
  static final Map<String, _BranchInfo> _earthlyBranchInfo = {
    '자': _BranchInfo('쥐', '🐀', '쥐'),
    '축': _BranchInfo('소', '🐂', '소'),
    '인': _BranchInfo('호랑이', '🐅', '범'),
    '묘': _BranchInfo('토끼', '🐇', '토끼'),
    '진': _BranchInfo('용', '🐉', '용'),
    '사': _BranchInfo('뱀', '🐍', '뱀'),
    '오': _BranchInfo('말', '🐴', '말'),
    '미': _BranchInfo('양', '🐏', '양'),
    '신': _BranchInfo('원숭이', '🐒', '원숭이'),
    '유': _BranchInfo('닭', '🐓', '닭'),
    '술': _BranchInfo('개', '🐕', '개'),
    '해': _BranchInfo('돼지', '🐖', '돼지'),
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
