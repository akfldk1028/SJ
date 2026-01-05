import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/saju_chat/domain/entities/chat_message.dart';

/// 채팅 버블 - 동양풍 다크 테마
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // AI 아바타 표시
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Text(
                    '🌙',
                    style: TextStyle(
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: theme.primaryColor.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '만톡 AI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 메시지 버블
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // 다크 테마: 골드 (유저) / 틸 포인트 다크 (AI)
              // 라이트 테마: 따뜻한 테라코타 (유저) / 쿨그레이 (AI)
              gradient: isUser
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: theme.isDark
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
                      colors: theme.isDark
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
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: theme.isDark
                          ? const Color(0xFF4ECDC4).withOpacity(0.15)
                          : const Color(0xFFE0E0E0),
                    ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? (theme.isDark
                          ? const Color(0xFFD4A54A).withOpacity(0.3)
                          : const Color(0xFFC27256).withOpacity(0.25))
                      : Colors.black.withOpacity(theme.isDark ? 0.2 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : theme.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
