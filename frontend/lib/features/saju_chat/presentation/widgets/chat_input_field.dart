import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const ChatInputField({
    super.key,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(
          top: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ShadInput(
              controller: _controller,
              placeholder: const Text('사주에 대해 궁금한 점을 물어보세요...'),
              enabled: !widget.isLoading,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          ShadButton.icon(
            icon: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: widget.isLoading ? null : _handleSend,
          ),
        ],
      ),
    );
  }
}
