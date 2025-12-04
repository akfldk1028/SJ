import 'package:flutter/material.dart';

import 'send_button.dart';

/// 채팅 입력 필드 위젯
///
/// 위젯 트리 최적화:
/// - 단일 책임 (입력 처리만)
/// - 상태는 콜백으로 전달
class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;
  final String? hintText;

  const ChatInputField({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? '메시지를 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
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
