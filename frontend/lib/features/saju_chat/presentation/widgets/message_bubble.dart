import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';

/// 채팅 메시지 버블 위젯
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 단일 책임 (메시지 표시만)
/// - 100줄 이하 유지
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && showAvatar) ...[
            _buildAvatar(theme, appTheme),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                // 그라데이션 적용: 다크/라이트 테마별 색상
                gradient: isUser
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: appTheme.isDark
                            ? [
                                const Color(0xFFE8C077), // 밝은 골드
                                const Color(0xFFD4A54A), // 진한 골드
                              ]
                            : [
                                const Color(0xFFD4846A), // 테라코타
                                const Color(0xFFC27256), // 진한 테라코타
                              ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: appTheme.isDark
                            ? [
                                const Color(0xFF2A3540), // 틸 다크
                                const Color(0xFF1E2830), // 딥 틸 다크
                              ]
                            : [
                                const Color(0xFFF8F9FA), // 밝은 그레이
                                const Color(0xFFF0F2F5), // 쿨 그레이
                              ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: appTheme.isDark
                            ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
                            : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? (appTheme.isDark
                            ? const Color(0xFFD4A54A).withValues(alpha: 0.3)
                            : const Color(0xFFC27256).withValues(alpha: 0.25))
                        : Colors.black.withValues(alpha: appTheme.isDark ? 0.2 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildMessageContent(theme, appTheme, isUser),
            ),
          ),
          if (isUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(theme, appTheme),
          ],
        ],
      ),
    );
  }

  /// 메시지 내용 빌드
  ///
  /// AI 메시지: 커스텀 볼드 파싱 + Gowun Dodum 폰트
  /// 사용자 메시지: Noto Sans KR (깔끔한 산세리프)
  Widget _buildMessageContent(ThemeData theme, AppThemeExtension appTheme, bool isUser) {
    // 사용자 메시지: Noto Sans KR (plain text)
    if (isUser) {
      final userStyle = AppFonts.userMessage(
        color: appTheme.isDark ? Colors.black : Colors.white,
      );
      return Text(message.content, style: userStyle);
    }

    // AI 메시지: 커스텀 볼드 파싱 (태그 제거 후)
    final aiStyle = AppFonts.aiMessage(
      color: appTheme.textPrimary,
    );

    return SelectableText.rich(
      _parseMarkdownBold(_cleanContent(message.content), aiStyle),
    );
  }

  /// [SUGGESTED_QUESTIONS] 태그 제거 (기존 저장된 메시지 호환)
  String _cleanContent(String content) {
    final tagStartIndex = content.indexOf('[SUGGESTED_QUESTIONS]');
    if (tagStartIndex != -1) {
      return content.substring(0, tagStartIndex).trim();
    }
    return content;
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

  Widget _buildAvatar(ThemeData theme, AppThemeExtension appTheme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: message.isUser
          ? appTheme.primaryColor.withValues(alpha: 0.2)
          : appTheme.cardColor,
      child: Icon(
        message.isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: message.isUser
            ? appTheme.primaryColor
            : appTheme.primaryColor,
      ),
    );
  }
}
