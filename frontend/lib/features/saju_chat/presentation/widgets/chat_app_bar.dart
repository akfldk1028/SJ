import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 채팅 화면 앱바
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 작은 위젯으로 분리
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClear;

  const ChatAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onClear,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? () => context.pop(),
      ),
      title: Text(title),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onClear,
          tooltip: 'saju_chat.resetChat'.tr(),
        ),
      ],
    );
  }
}
