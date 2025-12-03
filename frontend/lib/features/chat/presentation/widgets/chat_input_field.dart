import 'package:shadcn_flutter/shadcn_flutter.dart';

/// 채팅 입력 필드 위젯 (Shadcn UI)
class ChatInputField extends StatefulWidget {
  const ChatInputField({
    super.key,
    required this.onSend,
    this.isLoading = false,
  });

  final ValueChanged<String> onSend;
  final bool isLoading;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
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
    if (text.isEmpty || widget.isLoading) return;

    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 텍스트 입력
            Expanded(
              child: TextField(
                controller: _controller,
                placeholder: const Text('사주에 대해 물어보세요...'),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const Gap(8),

            // 전송 버튼
            _hasText && !widget.isLoading
                ? PrimaryButton(
                    size: ButtonSize.small,
                    onPressed: _handleSend,
                    child: const Icon(RadixIcons.paperPlane, size: 16),
                  )
                : SecondaryButton(
                    size: ButtonSize.small,
                    onPressed: null,
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(size: 16),
                          )
                        : Icon(
                            RadixIcons.paperPlane,
                            size: 16,
                            color: theme.colorScheme.mutedForeground,
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
