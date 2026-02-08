import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'send_button.dart';

/// 멘션 패턴 정규식 (@카테고리/이름)
final _mentionPattern = RegExp(r'@[^\s/]+/[^\s]+');

/// 멘션 하이라이트를 지원하는 커스텀 TextEditingController
/// TextField 내부에서 직접 색상을 적용하여 오버레이 없이 자연스러운 하이라이트
class MentionTextEditingController extends TextEditingController {
  /// 멘션 하이라이트 색상 (기본: 하늘색)
  final Color mentionColor;

  MentionTextEditingController({
    String? text,
    this.mentionColor = const Color(0xFF00D4FF),
  }) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    final matches = _mentionPattern.allMatches(text);

    // context에서 직접 테마 색상 가져오기 (타이밍 문제 해결)
    final theme = context.appTheme;
    final normalColor = theme.textPrimary;

    if (matches.isEmpty) {
      // 멘션 없으면 일반 텍스트
      return TextSpan(
        text: text,
        style: style?.copyWith(color: normalColor),
      );
    }

    // 멘션 있으면 스타일 분리
    final children = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // 멘션 이전 텍스트
      if (match.start > lastEnd) {
        children.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style?.copyWith(color: normalColor),
        ));
      }

      // 멘션 텍스트 (하이라이트)
      children.add(TextSpan(
        text: match.group(0),
        style: style?.copyWith(
          color: mentionColor,
          fontWeight: FontWeight.w600,
        ),
      ));

      lastEnd = match.end;
    }

    // 마지막 멘션 이후 텍스트
    if (lastEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastEnd),
        style: style?.copyWith(color: normalColor),
      ));
    }

    return TextSpan(children: children, style: style);
  }
}

/// 채팅 입력 필드 위젯 - 동양풍 다크 테마
/// 멘션(@카테고리/이름) 색상 하이라이트 지원
class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;
  final String? hintText;

  /// 힌트 텍스트 색상 (null이면 기본 textMuted)
  final Color? hintColor;

  /// 외부에서 텍스트 제어를 위한 컨트롤러 (선택적)
  final TextEditingController? controller;

  /// 멘션 하이라이트 색상 (기본: 하늘색)
  final Color? mentionColor;

  const ChatInputField({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.hintText,
    this.hintColor,
    this.controller,
    this.mentionColor,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  MentionTextEditingController? _internalController;
  bool _hasText = false;

  /// 실제 사용할 컨트롤러
  TextEditingController get _controller {
    if (widget.controller != null) {
      return widget.controller!;
    }
    if (_internalController == null) {
      _internalController = MentionTextEditingController(
        mentionColor: widget.mentionColor ?? const Color(0xFF00D4FF),
      );
      _internalController!.addListener(_onTextChanged);
    }
    return _internalController!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!.addListener(_onTextChanged);
      _hasText = widget.controller!.text.trim().isNotEmpty;
    }
  }

  @override
  void didUpdateWidget(ChatInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);
      _hasText = _controller.text.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    _internalController?.removeListener(_onTextChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
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
            color: theme.primaryColor.withValues(alpha: 0.1),
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
                    color: theme.primaryColor.withValues(alpha: theme.isDark ? 0.15 : 0.12),
                  ),
                  boxShadow: theme.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? '메시지를 입력하세요...',
                    hintStyle: TextStyle(
                      color: widget.hintColor ?? theme.textMuted,
                      fontSize: 15,
                      fontWeight: widget.hintColor != null ? FontWeight.w600 : null,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  textInputAction: TextInputAction.newline, // 엔터 = 줄바꿈
                  keyboardType: TextInputType.multiline, // 멀티라인 키보드
                  maxLines: 5, // 최대 5줄까지 확장
                  minLines: 1, // 최소 1줄
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
