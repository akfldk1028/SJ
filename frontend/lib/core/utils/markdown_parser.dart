import 'package:flutter/material.dart';

/// 경량 마크다운 파서 — AI 사주 응답 최적화
///
/// 블록 레벨:
/// - `**카테고리:**` 또는 `* 카테고리:` → 섹션 헤더 (이모지 자동 + 굵은 글씨 + 상단 간격)
/// - `* ` `- ` 불릿 → • 들여쓰기
/// - 중첩 불릿 → ◦ 추가 들여쓰기
/// - `---` `***` → Divider
/// - 숫자 리스트 `1. ` → 번호 유지 + 들여쓰기
/// - 빈 줄 → 단락 간격
///
/// 인라인:
/// - **볼드** → FontWeight.bold
/// - *이탤릭* → FontStyle.italic
class MarkdownParser {
  // 핵심 카테고리만 이모지 (과하지 않게)
  static const _categoryEmoji = {
    '재물': '💰', '재운': '💰', '금전': '💰',
    '건강': '🏥',
    '사랑': '💕', '연애': '💕',
    '직업': '💼', '업무': '💼',
    '총운': '✨', '종합': '✨', '전체': '✨',
    '주의': '⚠️',
  };

  /// TextSpan 반환 (스트리밍 중 — Text.rich 호환)
  static TextSpan parse(String text, TextStyle baseStyle) {
    final cleaned = _preprocessToPlainText(text);
    return _parseInline(cleaned, baseStyle);
  }

  /// Widget 반환 (완성된 메시지 — 블록 레벨 가독성 최적)
  static Widget parseToWidget(String text, TextStyle baseStyle, {bool selectable = false}) {
    final blocks = _parseBlocks(text);
    if (blocks.length == 1 && blocks[0].type == _BlockType.paragraph) {
      final span = _parseInline(blocks[0].content, baseStyle);
      return selectable ? SelectableText.rich(span) : Text.rich(span);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) => _buildBlock(b, baseStyle, selectable)).toList(),
    );
  }

  // ═══════════════════════════════════════════════════
  // 블록 파싱
  // ═══════════════════════════════════════════════════

  static List<_Block> _parseBlocks(String text) {
    final lines = text.split('\n');
    final blocks = <_Block>[];
    final buf = StringBuffer();

    void flush() {
      if (buf.isNotEmpty) {
        blocks.add(_Block(_BlockType.paragraph, buf.toString().trimRight()));
        buf.clear();
      }
    }

    for (final line in lines) {
      final trimmed = line.trimLeft();

      // 빈 줄
      if (trimmed.isEmpty) {
        flush();
        continue;
      }

      // --- 또는 ***  → 구분선
      if (RegExp(r'^-{3,}$|^\*{3,}$').hasMatch(trimmed)) {
        flush();
        blocks.add(_Block(_BlockType.divider, ''));
        continue;
      }

      // # 헤더 (##, ### 포함) → 섹션 헤더
      final hashMatch = RegExp(r'^#{1,3}\s+(.+)$').firstMatch(trimmed);
      if (hashMatch != null) {
        flush();
        blocks.add(_Block(_BlockType.sectionHeader, hashMatch.group(1)!.trim()));
        continue;
      }

      // 섹션 헤더 감지: "**카테고리:**" 또는 "* 카테고리:" 형태
      final headerMatch1 = RegExp(r'^\*\*(.+?)[:：]\*\*\s*$').firstMatch(trimmed);
      final headerMatch2 = RegExp(r'^(?:\*(?!\*)|-)\s+(.+?)[:：]\s*$').firstMatch(trimmed);
      if (headerMatch1 != null) {
        flush();
        blocks.add(_Block(_BlockType.sectionHeader, headerMatch1.group(1)!.trim()));
        continue;
      }
      if (headerMatch2 != null) {
        flush();
        blocks.add(_Block(_BlockType.sectionHeader, headerMatch2.group(1)!.trim()));
        continue;
      }

      // 불릿: * 또는 - (** 볼드 제외)
      final bulletMatch = RegExp(r'^(\s*)(?:\*(?!\*)|-)\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        flush();
        final indent = bulletMatch.group(1)!.length;
        final content = bulletMatch.group(2)!;
        blocks.add(_Block(
          indent >= 3 ? _BlockType.subBullet : _BlockType.bullet,
          content,
        ));
        continue;
      }

      // 숫자 리스트: "1. ", "2. " 등
      final numMatch = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        flush();
        blocks.add(_Block(_BlockType.numbered, '${numMatch.group(1)}. ${numMatch.group(2)}'));
        continue;
      }

      // 일반 텍스트 → 단락 누적
      if (buf.isNotEmpty) buf.write('\n');
      buf.write(line);
    }

    flush();
    return blocks;
  }

  // ═══════════════════════════════════════════════════
  // 블록 → Widget
  // ═══════════════════════════════════════════════════

  static Widget _buildBlock(_Block block, TextStyle baseStyle, bool selectable) {
    switch (block.type) {
      case _BlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, thickness: 0.5, color: baseStyle.color?.withOpacity(0.15)),
        );

      case _BlockType.sectionHeader:
        // ** 제거 (볼드 마크다운이 섞여 들어올 수 있음)
        final cleanHeader = block.content.replaceAll('**', '').trim();
        final emoji = _findEmoji(cleanHeader);
        final headerStyle = baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: (baseStyle.fontSize ?? 14) + 1,
        );
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 2),
          child: Text(
            emoji != null ? '$emoji $cleanHeader' : cleanHeader,
            style: headerStyle,
          ),
        );

      case _BlockType.bullet:
        return Padding(
          padding: const EdgeInsets.only(top: 4, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('•  ', style: baseStyle.copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(child: _inlineWidget(block.content, baseStyle, selectable)),
            ],
          ),
        );

      case _BlockType.subBullet:
        return Padding(
          padding: const EdgeInsets.only(top: 3, left: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('◦  ', style: baseStyle.copyWith(color: baseStyle.color?.withOpacity(0.5))),
              ),
              Expanded(child: _inlineWidget(block.content, baseStyle, selectable)),
            ],
          ),
        );

      case _BlockType.numbered:
        final numEnd = block.content.indexOf('. ');
        final num = block.content.substring(0, numEnd + 1);
        final content = block.content.substring(numEnd + 2);
        return Padding(
          padding: const EdgeInsets.only(top: 4, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text('$num ', style: baseStyle.copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(child: _inlineWidget(content, baseStyle, selectable)),
            ],
          ),
        );

      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _inlineWidget(block.content, baseStyle, selectable),
        );
    }
  }

  static String? _findEmoji(String text) {
    for (final entry in _categoryEmoji.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static Widget _inlineWidget(String text, TextStyle baseStyle, bool selectable) {
    final span = _parseInline(text, baseStyle);
    return selectable ? SelectableText.rich(span) : Text.rich(span);
  }

  // ═══════════════════════════════════════════════════
  // 인라인 파싱 (볼드, 이탤릭)
  // ═══════════════════════════════════════════════════

  static TextSpan _parseInline(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(text: match.group(1), style: baseStyle.copyWith(fontWeight: FontWeight.bold)));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(text: match.group(2), style: baseStyle.copyWith(fontStyle: FontStyle.italic)));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return spans.isEmpty ? TextSpan(text: text, style: baseStyle) : TextSpan(children: spans);
  }

  // ═══════════════════════════════════════════════════
  // 스트리밍용 전처리 (TextSpan parse() 에서 사용)
  // ═══════════════════════════════════════════════════

  static String _preprocessToPlainText(String text) {
    final lines = text.split('\n');
    final result = <String>[];

    for (final line in lines) {
      final trimmed = line.trimLeft();

      if (RegExp(r'^-{3,}$|^\*{3,}$').hasMatch(trimmed)) {
        result.add('');
        continue;
      }

      // # 헤더 → # 제거
      final hashMatch = RegExp(r'^#{1,3}\s+(.+)$').firstMatch(trimmed);
      if (hashMatch != null) {
        result.add(hashMatch.group(1)!);
        continue;
      }

      final bulletMatch = RegExp(r'^(\s*)(?:\*(?!\*)|-)\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        final indent = bulletMatch.group(1)!;
        final content = bulletMatch.group(2)!;
        result.add(indent.length >= 3 ? '  ◦ $content' : '• $content');
        continue;
      }

      result.add(line);
    }

    return result.join('\n');
  }
}

enum _BlockType { paragraph, bullet, subBullet, numbered, divider, sectionHeader }

class _Block {
  final _BlockType type;
  final String content;
  _Block(this.type, this.content);
}
