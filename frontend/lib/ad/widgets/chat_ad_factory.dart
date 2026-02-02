/// Chat Ad Factory
/// 모듈형 채팅 내 광고 팩토리 패턴
library;

import 'package:flutter/material.dart';

import '../ad_strategy.dart';
import 'inline_ad_widget.dart';
import 'native_ad_widget.dart';

/// 채팅 광고 팩토리
///
/// 설정에 따라 적절한 광고 위젯 생성
/// 모듈형 설계로 광고 유형 쉽게 변경 가능
abstract class ChatAdFactory {
  ChatAdFactory._();

  /// 현재 설정된 광고 유형
  static ChatAdType get currentType => AdStrategy.chatAdType;

  /// 광고 위젯 생성
  ///
  /// [index]: 리스트 내 위치 (고유 키용)
  /// [type]: 광고 유형 (null이면 기본 설정 사용)
  static Widget create({
    required int index,
    ChatAdType? type,
  }) {
    final adType = type ?? currentType;

    return switch (adType) {
      ChatAdType.inlineBanner => InlineAdWidget(index: index),
      ChatAdType.nativeMedium => NativeAdWidget(index: index),
      ChatAdType.nativeCompact => CompactNativeAdWidget(index: index),
    };
  }

  /// 광고 유형별 예상 높이
  static double getEstimatedHeight(ChatAdType type) {
    return switch (type) {
      ChatAdType.inlineBanner => 60,
      ChatAdType.nativeMedium => 180,
      ChatAdType.nativeCompact => 80,
    };
  }

  /// 광고 유형별 설명
  static String getDescription(ChatAdType type) {
    return switch (type) {
      ChatAdType.inlineBanner => 'Inline Banner (\$1~3 eCPM)',
      ChatAdType.nativeMedium => 'Native Medium (\$3~15 eCPM)',
      ChatAdType.nativeCompact => 'Native Compact (\$2~8 eCPM)',
    };
  }
}

/// 채팅 광고 위젯 래퍼
///
/// Factory에서 생성된 광고를 감싸는 위젯
/// 공통 기능 (애니메이션, 여백 등) 제공
class ChatAdWidget extends StatelessWidget {
  final int index;
  final ChatAdType? type;

  const ChatAdWidget({
    super.key,
    required this.index,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ChatAdFactory.create(
            index: index,
            type: type,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 56, top: 4, bottom: 8),
          child: Text(
            '관심 있는 광고를 살펴보시면 대화가 더 많아져요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
