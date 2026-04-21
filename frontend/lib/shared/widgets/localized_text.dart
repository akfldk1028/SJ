import 'package:flutter/material.dart';

/// 다국어 텍스트 오버플로우 처리 위젯
///
/// 언어마다 텍스트 길이가 달라지는 문제를 일관되게 처리.
/// overflow/maxLines 기본값을 한 곳에서 관리.
///
/// 사용법:
/// ```dart
/// LocalizedText('saju_chat.rename'.tr())
/// LocalizedText('some.key'.tr(), maxLines: 2)
/// LocalizedText('some.key'.tr(), style: TextStyle(fontSize: 16))
/// ```
class LocalizedText extends StatelessWidget {
  const LocalizedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = true,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
