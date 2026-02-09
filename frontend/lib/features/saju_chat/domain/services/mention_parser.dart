import 'package:flutter/foundation.dart';

import '../../../profile/data/models/profile_relation_model.dart';

/// 멘션 파싱 결과
class MentionParseResult {
  /// 파싱된 멘션 목록
  final List<ParsedMention> mentions;

  /// "나" 포함 여부
  final bool includesOwner;

  /// 궁합 모드 여부 (2명 멘션)
  bool get isCompatibilityMode => mentions.length == 2 || (includesOwner && mentions.length == 1);

  /// 유효한 궁합인지 (정확히 2명)
  bool get isValidCompatibility {
    if (includesOwner) {
      return mentions.length == 1; // 나 + 1명
    }
    return mentions.length == 2; // 2명
  }

  /// 첫 번째 상대방 프로필 ID (target_profile_id용)
  String? get targetProfileId {
    // 나가 아닌 첫 번째 멘션의 프로필 ID
    final nonOwnerMention = mentions.where((m) => !m.isOwner).firstOrNull;
    return nonOwnerMention?.profileId;
  }

  /// 모든 참가자 프로필 ID (나 포함)
  List<String> get participantIds {
    return mentions
        .where((m) => m.profileId != null)
        .map((m) => m.profileId!)
        .toList();
  }

  const MentionParseResult({
    required this.mentions,
    required this.includesOwner,
  });

  static const empty = MentionParseResult(mentions: [], includesOwner: false);
}

/// 파싱된 단일 멘션
class ParsedMention {
  /// 카테고리 (나, 가족, 친구, 연인, 직장, 기타)
  final String category;

  /// 이름
  final String name;

  /// 프로필 ID (매칭된 경우)
  final String? profileId;

  /// "나" 여부
  final bool isOwner;

  /// 매칭 성공 여부
  bool get isMatched => profileId != null;

  const ParsedMention({
    required this.category,
    required this.name,
    this.profileId,
    this.isOwner = false,
  });

  @override
  String toString() => '@$category/$name (profileId: $profileId, isOwner: $isOwner)';
}

/// 첫 번째 멘션 파싱 결과 (기준 인물 파악용)
class FirstMentionResult {
  /// 카테고리 (나, 가족, 친구 등)
  final String? category;

  /// 이름
  final String? name;

  /// "나" 카테고리인지
  bool get isOwnerCategory => category == '나';

  /// 멘션이 존재하는지
  bool get hasMention => category != null && name != null;

  const FirstMentionResult({this.category, this.name});

  static const empty = FirstMentionResult();
}

/// 멘션 파서
///
/// ## 사용법
/// ```dart
/// final parser = MentionParser(
///   ownerProfileId: '나의-프로필-ID',
///   ownerName: '신선우',
///   relations: [인연 목록],
/// );
///
/// final result = parser.parse('@나/신선우 @친구/박재현 2026년 궁합');
/// print(result.isValidCompatibility); // true
/// print(result.targetProfileId); // 박재현의 프로필 ID
/// ```
///
/// ## Phase 56: 2단계 파싱 지원
/// 연속 궁합 채팅에서 `@나/박재현 @친구/김동현` 같은 멘션 처리:
/// 1. extractFirstMention()으로 "박재현"이 기준 인물임을 파악
/// 2. 박재현의 관계 목록 재조회
/// 3. 재조회된 관계로 새 MentionParser 생성 후 parse()
class MentionParser {
  /// "나"의 프로필 ID
  final String? ownerProfileId;

  /// "나"의 이름
  final String? ownerName;

  /// 인연 목록 (프로필 ID 매칭용)
  final List<ProfileRelationModel> relations;

  /// 카테고리 매핑 (한글 → relation_type prefix)
  static const categoryMapping = {
    '나': 'owner',
    '가족': 'family',
    '연인': 'romantic',
    '친구': 'friend',
    '직장': 'work',
    '기타': 'other',
  };

  MentionParser({
    required this.ownerProfileId,
    required this.ownerName,
    required this.relations,
  });

  /// 멘션 패턴: @카테고리/이름
  static final _mentionPattern = RegExp(r'@([^\s/]+)/([^\s@]+)');

  /// Phase 56: 첫 번째 멘션 추출 (기준 인물 파악용)
  ///
  /// `@나/박재현 @친구/김동현`에서 `@나/박재현` 추출
  /// → 기준 인물이 "박재현"임을 파악
  static FirstMentionResult extractFirstMention(String text) {
    final match = _mentionPattern.firstMatch(text);
    if (match == null) {
      return FirstMentionResult.empty;
    }

    return FirstMentionResult(
      category: match.group(1),
      name: match.group(2),
    );
  }

  /// Phase 56: 이름으로 관계 목록에서 프로필 ID 찾기
  ///
  /// `@나/박재현`에서 박재현의 프로필 ID를 사용자의 관계 목록에서 검색
  String? findProfileIdByName(String name) {
    for (final relation in relations) {
      final displayName = relation.displayName ?? relation.toProfile?.displayName ?? '';
      if (displayName == name || displayName.contains(name) || name.contains(displayName)) {
        if (kDebugMode) {
          print('[MentionParser] 이름으로 프로필 ID 찾기: $name → ${relation.toProfileId}');
        }
        return relation.toProfileId;
      }
    }
    if (kDebugMode) {
      print('[MentionParser] 이름으로 프로필 ID 찾기 실패: $name');
    }
    return null;
  }

  /// 텍스트에서 멘션 파싱
  MentionParseResult parse(String text) {
    final matches = _mentionPattern.allMatches(text);
    if (matches.isEmpty) {
      return MentionParseResult.empty;
    }

    final mentions = <ParsedMention>[];
    bool includesOwner = false;

    for (final match in matches) {
      final category = match.group(1) ?? '';
      final name = match.group(2) ?? '';

      if (kDebugMode) {
        print('[MentionParser] 멘션 발견: @$category/$name');
      }

      // "나" 멘션인 경우
      if (category == '나') {
        includesOwner = true;
        mentions.add(ParsedMention(
          category: category,
          name: name,
          profileId: ownerProfileId,
          isOwner: true,
        ));
        if (kDebugMode) {
          print('[MentionParser] → "나" 매칭: profileId=$ownerProfileId');
        }
        continue;
      }

      // 인연에서 매칭
      final profileId = _findProfileId(category, name);
      mentions.add(ParsedMention(
        category: category,
        name: name,
        profileId: profileId,
        isOwner: false,
      ));

      if (kDebugMode) {
        print('[MentionParser] → 인연 매칭: profileId=$profileId');
      }
    }

    return MentionParseResult(
      mentions: mentions,
      includesOwner: includesOwner,
    );
  }

  /// 카테고리와 이름으로 프로필 ID 찾기
  String? _findProfileId(String category, String name) {
    // 카테고리를 relation_type prefix로 변환
    final relationTypePrefix = categoryMapping[category];
    if (relationTypePrefix == null) {
      if (kDebugMode) {
        print('[MentionParser] 알 수 없는 카테고리: $category');
      }
      return null;
    }

    // 이름과 카테고리로 매칭
    for (final relation in relations) {
      final displayName = relation.displayName ?? '';
      final relationType = relation.relationType;

      // 이름 매칭 (정확히 일치 또는 포함)
      final nameMatches = displayName == name || displayName.contains(name) || name.contains(displayName);

      // 카테고리 매칭
      final categoryMatches = relationType.startsWith(relationTypePrefix) ||
          _categoryMatchesRelationType(category, relationType);

      if (nameMatches && categoryMatches) {
        return relation.toProfileId;
      }
    }

    // 이름만으로 매칭 시도 (카테고리 무시)
    for (final relation in relations) {
      final displayName = relation.displayName ?? '';
      if (displayName == name) {
        if (kDebugMode) {
          print('[MentionParser] 이름만으로 매칭: $name → ${relation.toProfileId}');
        }
        return relation.toProfileId;
      }
    }

    if (kDebugMode) {
      print('[MentionParser] 매칭 실패: @$category/$name');
    }
    return null;
  }

  /// 카테고리와 relation_type 매칭 확인
  bool _categoryMatchesRelationType(String category, String relationType) {
    switch (category) {
      case '가족':
        return relationType.startsWith('family');
      case '연인':
        return relationType.startsWith('romantic');
      case '친구':
        return relationType.startsWith('friend');
      case '직장':
        return relationType.startsWith('work');
      case '기타':
        return relationType == 'other' || relationType.startsWith('other')
            || relationType == 'business_partner' || relationType == 'mentor';
      default:
        return false;
    }
  }
}
