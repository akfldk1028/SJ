import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  /// AI 메시지: Markdown 렌더링 + Gowun Dodum 폰트
  /// 사용자 메시지: Noto Sans KR (깔끔한 산세리프)
  Widget _buildMessageContent(ThemeData theme, AppThemeExtension appTheme, bool isUser) {
    // 사용자 메시지: Noto Sans KR (plain text)
    if (isUser) {
      final userStyle = AppFonts.userMessage(
        color: appTheme.isDark ? Colors.black : Colors.white,
      );
      return Text(message.content, style: userStyle);
    }

    // AI 메시지: Markdown 렌더링
    final aiStyle = AppFonts.aiMessage(
      color: appTheme.textPrimary,
    );

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: aiStyle,
        strong: aiStyle.copyWith(fontWeight: FontWeight.bold),
        em: aiStyle.copyWith(fontStyle: FontStyle.italic),
        code: aiStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: appTheme.backgroundColor,
        ),
        listBullet: aiStyle,
        a: aiStyle.copyWith(
          color: appTheme.primaryColor,
          decoration: TextDecoration.underline,
        ),
      ),
    );
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
