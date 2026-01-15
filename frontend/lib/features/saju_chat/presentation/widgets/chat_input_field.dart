import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'send_button.dart';

/// 멘션 패턴 정규식 (@카테고리/이름)
final _mentionPattern = RegExp(r'@[^\s/]+/[^\s]+');

/// 채팅 입력 필드 위젯 - 동양풍 다크 테마
/// 멘션(@카테고리/이름) 색상 하이라이트 지원
class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;
  final String? hintText;

  /// 외부에서 텍스트 제어를 위한 컨트롤러 (선택적)
  final TextEditingController? controller;

  /// 멘션 하이라이트 색상 (기본: 파란색)
  final Color? mentionColor;

  const ChatInputField({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.hintText,
    this.controller,
    this.mentionColor,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  TextEditingController? _internalController;
  bool _hasText = false;
  bool _hasMention = false;

  /// 외부 또는 내부 컨트롤러 반환
  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    // 초기 텍스트 상태 확인
    _hasText = _controller.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(ChatInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 컨트롤러가 변경되면 리스너 재연결
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      _internalController?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
      _hasText = _controller.text.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // 내부 컨트롤러만 dispose (외부 컨트롤러는 외부에서 관리)
    _internalController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    final hasMention = _mentionPattern.hasMatch(_controller.text);
    if (hasText != _hasText || hasMention != _hasMention) {
      setState(() {
        _hasText = hasText;
        _hasMention = hasMention;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  /// 멘션 하이라이트를 적용한 TextSpan 리스트 생성
  List<InlineSpan> _buildStyledTextSpans(String text, AppTheme theme) {
    final spans = <InlineSpan>[];
    final matches = _mentionPattern.allMatches(text);

    if (matches.isEmpty) {
      // 멘션이 없으면 전체 텍스트를 일반 스타일로
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 15,
        ),
      ));
      return spans;
    }

    int lastEnd = 0;
    final mentionColor = widget.mentionColor ?? const Color(0xFF00D4FF);

    for (final match in matches) {
      // 멘션 이전의 일반 텍스트
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 15,
          ),
        ));
      }

      // 멘션 텍스트 (하이라이트)
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: mentionColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ));

      lastEnd = match.end;
    }

    // 마지막 멘션 이후의 텍스트
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 15,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.isDark ? null : theme.cardColor,
                  gradient: theme.isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1A24),
                            const Color(0xFF14141C),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(theme.isDark ? 0.15 : 0.12),
                  ),
                  boxShadow: theme.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Stack(
                  children: [
                    // 실제 입력 필드 (멘션 있으면 텍스트 투명) - 먼저 렌더링 (아래)
                    TextField(
                      controller: _controller,
                      enabled: widget.enabled,
                      style: TextStyle(
                        color: _hasMention ? Colors.transparent : theme.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? '메시지를 입력하세요...',
                        hintStyle: TextStyle(
                          color: theme.textMuted,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      maxLines: null,
                    ),
                    // 멘션 하이라이트용 오버레이 텍스트 - 나중 렌더링 (위)
                    if (_hasMention)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: _buildStyledTextSpans(
                                  _controller.text,
                                  theme,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SendButton(
              enabled: widget.enabled,
              hasText: _hasText,
              onPressed: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}
