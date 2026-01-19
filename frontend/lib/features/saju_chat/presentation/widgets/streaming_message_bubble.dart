import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import 'typing_indicator.dart';

/// AI 스트리밍 응답 버블 위젯
///
/// 실시간으로 타이핑되는 AI 응답 표시
class StreamingMessageBubble extends StatelessWidget {
  final String content;

  const StreamingMessageBubble({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI 아바타
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: appTheme.isDark
                    ? [const Color(0xFF4A6572), const Color(0xFF344955)]
                    : [const Color(0xFF78909C), const Color(0xFF607D8B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: appTheme.isDark
                      ? [const Color(0xFF2A3540), const Color(0xFF1E2830)] // 틸 다크
                      : [const Color(0xFFF5F5F5), const Color(0xFFEBEBEB)], // 쿨 그레이
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: _buildMarkdownContent(appTheme),
                  ),
                  const SizedBox(width: 8),
                  const TypingIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 마크다운 콘텐츠 빌드 (커스텀 볼드 파싱)
  Widget _buildMarkdownContent(AppThemeExtension appTheme) {
    final aiStyle = AppFonts.aiMessage(
      color: appTheme.textPrimary,
    );

    return Text.rich(
      _parseMarkdownBold(content, aiStyle),
    );
  }

  /// **text** 패턴을 파싱해서 볼드체로 변환
  TextSpan _parseMarkdownBold(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // 매치 이전 텍스트 (일반)
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      // 매치된 텍스트 (볼드)
      spans.add(TextSpan(
        text: match.group(1), // ** 안의 텍스트
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      lastEnd = match.end;
    }

    // 마지막 남은 텍스트
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    // spans가 비어있으면 전체 텍스트 반환
    if (spans.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    return TextSpan(children: spans);
  }
}
