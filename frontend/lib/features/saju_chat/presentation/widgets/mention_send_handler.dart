import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/mention_parser.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/providers/relation_provider.dart';
import '../../../profile/data/models/profile_relation_model.dart';
import 'relation_selector_sheet.dart';

/// 멘션 파싱 결과를 담는 데이터 클래스
class MentionSendParams {
  final String? targetProfileId;
  final List<String>? participantIds;
  final bool includesOwner;

  const MentionSendParams({
    this.targetProfileId,
    this.participantIds,
    this.includesOwner = true,
  });
}

/// 두 ChatInputField.onSend 콜백의 공통 멘션 파싱 로직
///
/// "no session" 상태와 "active session" 상태에서 동일하게 사용되는
/// 멘션 파싱/targetProfileId/participantIds 결정 로직을 통합합니다.
class MentionSendHandler {
  /// 텍스트에서 멘션을 파싱하여 targetProfileId, participantIds, includesOwner를 결정
  ///
  /// [text]: 사용자 입력 텍스트
  /// [ref]: Riverpod ref (WidgetRef)
  /// [pendingCompatibilitySelection]: UI에서 선택한 궁합 데이터
  /// [pendingTargetProfileId]: UI에서 선택한 단일 멘션 targetProfileId
  /// [fallbackTargetProfileId]: 세션/위젯에서 온 기본 targetProfileId
  static Future<MentionSendParams> resolveMentionParams({
    required String text,
    required WidgetRef ref,
    CompatibilitySelection? pendingCompatibilitySelection,
    String? pendingTargetProfileId,
    String? fallbackTargetProfileId,
  }) async {
    // 멘션 패턴 감지: @카테고리/이름
    final mentionPattern = RegExp(r'@[^\s/]+/[^\s]+');
    final hasMention = mentionPattern.hasMatch(text);

    // targetProfileId 및 participantIds 결정
    String? targetId;
    List<String>? participantIds;
    bool includesOwner = true; // 기본값: "나 포함"

    // 1. UI 선택으로 pendingCompatibilitySelection이 있으면 우선 사용
    if (pendingCompatibilitySelection != null) {
      final selection = pendingCompatibilitySelection;
      targetId = selection.targetProfileId;
      participantIds = selection.participantIds;
      includesOwner = selection.includesOwner;
      if (kDebugMode) {
        print('[MentionSendHandler] UI 선택 궁합 모드: participantIds=$participantIds, targetId=$targetId, includesOwner=$includesOwner');
      }
    }
    // 2. UI 선택 없이 직접 타이핑한 멘션이 있으면 파싱
    else if (hasMention) {
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile != null) {
        final result = await _parseMentionsFromText(
          text: text,
          ref: ref,
          activeProfileId: activeProfile.id,
          activeProfileDisplayName: activeProfile.displayName,
          pendingTargetProfileId: pendingTargetProfileId,
          fallbackTargetProfileId: fallbackTargetProfileId,
        );
        targetId = result.targetProfileId;
        participantIds = result.participantIds;
        includesOwner = result.includesOwner;
      }
    }
    // 3. @멘션 없어도 인연 이름이 텍스트에 있으면 자동 매칭 (v13.0)
    else {
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile != null) {
        final matched = await _matchRelationNamesInText(
          text: text,
          ref: ref,
          activeProfileId: activeProfile.id,
        );
        if (matched != null) {
          targetId = matched.targetProfileId;
          participantIds = matched.participantIds;
          includesOwner = matched.includesOwner;
        } else {
          targetId = fallbackTargetProfileId;
        }
      } else {
        targetId = fallbackTargetProfileId;
      }
    }

    return MentionSendParams(
      targetProfileId: targetId,
      participantIds: participantIds,
      includesOwner: includesOwner,
    );
  }

  /// 멘션 텍스트를 파싱하여 targetProfileId, participantIds, includesOwner를 결정
  ///
  /// Phase 56-57: 향상된 멘션 파싱 로직
  /// - "[나 제외]" 패턴 또는 두 멘션 모두 "나"가 아닌 경우 감지
  /// - 2단계 파싱: 첫 번째 멘션으로 기준 인물 파악 후 관계 재조회
  ///
  /// Phase 58: 캐시 무효화 추가
  /// - 대화 도중 인연 등록 후 멘션 시 캐시된 관계 목록 문제 해결
  /// - 멘션 파싱 전 relationListProvider 캐시 무효화
  static Future<MentionSendParams> _parseMentionsFromText({
    required String text,
    required WidgetRef ref,
    required String activeProfileId,
    required String activeProfileDisplayName,
    String? pendingTargetProfileId,
    String? fallbackTargetProfileId,
  }) async {
    String? targetId;
    List<String>? participantIds;
    bool includesOwner = true;

    // ═══════════════════════════════════════════════════════════════════════════
    // Phase 58: 관계 목록 캐시 무효화 (대화 도중 인연 등록 후 멘션 시 필수)
    // - 채팅 화면에서 인연 등록 화면으로 갔다가 돌아오면 캐시가 stale
    // - 멘션 파싱 전 무효화하여 최신 관계 목록 사용
    // ═══════════════════════════════════════════════════════════════════════════
    ref.invalidate(relationListProvider(activeProfileId));
    if (kDebugMode) {
      print('[MentionSendHandler] Phase 58: relationListProvider 캐시 무효화 완료');
    }

    // Phase 56-57: 향상된 멘션 파싱 로직
    // "[나 제외]" 패턴 또는 두 멘션 모두 "나"가 아닌 경우 감지
    final isExcludeOwnerMode = text.contains('[나 제외]') || text.contains('나 제외');

    // 모든 멘션 추출
    final allMentions = RegExp(r'@([^\s/]+)/([^\s@]+)').allMatches(text).toList();
    final hasOwnerMention = allMentions.any((m) => m.group(1) == '나');

    // "나 제외" 모드: 두 멘션 모두 "나"가 아니거나, 명시적으로 [나 제외] 포함
    final isThirdPartyMode = isExcludeOwnerMode ||
        (allMentions.length >= 2 && !hasOwnerMention);

    if (kDebugMode) {
      print('[MentionSendHandler] Phase 58: isThirdPartyMode=$isThirdPartyMode, isExcludeOwnerMode=$isExcludeOwnerMode, hasOwnerMention=$hasOwnerMention, mentionCount=${allMentions.length}');
    }

    if (isThirdPartyMode && allMentions.length >= 2) {
      // "나 제외" 모드: 두 사람 모두 관계 목록에서 ID 찾기
      final relations = await ref.read(relationListProvider(activeProfileId).future);

      final List<String> foundIds = [];
      for (final match in allMentions) {
        final category = match.group(1) ?? '';
        final name = match.group(2) ?? '';

        // 이름으로 관계에서 프로필 ID 찾기
        String? profileId;
        for (final relation in relations) {
          final displayName = relation.displayName ?? relation.toProfile?.displayName ?? '';
          if (displayName == name || displayName.contains(name) || name.contains(displayName)) {
            profileId = relation.toProfileId;
            break;
          }
        }

        if (profileId != null) {
          foundIds.add(profileId);
          if (kDebugMode) {
            print('[MentionSendHandler] Phase 57: @$category/$name -> profileId=$profileId');
          }
        } else {
          if (kDebugMode) {
            print('[MentionSendHandler] Phase 57: @$category/$name -> not found');
          }
        }
      }

      if (foundIds.length >= 2) {
        // Phase 59: 3명 이상 참가자 지원 (.take(2) 제거)
        // 모든 참가자 ID를 전달하여 additionalParticipants로 처리
        participantIds = foundIds;
        targetId = participantIds.first;
        includesOwner = false;
        if (kDebugMode) {
          print('[MentionSendHandler] Phase 59: third-party compatibility - participantIds=$participantIds (${foundIds.length}명)');
        }
      } else {
        if (kDebugMode) {
          print('[MentionSendHandler] Phase 59: third-party mode but failed to find 2+ (found=${foundIds.length})');
        }
      }
    } else {
      // 기존 로직: "나 포함" 모드 또는 단일 멘션
      // Phase 56: 2단계 파싱 로직
      // 1단계: 첫 번째 멘션 추출하여 "기준 인물" 파악
      final firstMention = MentionParser.extractFirstMention(text);

      String ownerProfileId = activeProfileId;
      String ownerName = activeProfileDisplayName;
      List<ProfileRelationModel> relations = await ref.read(relationListProvider(activeProfileId).future);

      // 2단계: @나/XXX 형태이고 XXX가 로그인 사용자와 다르면
      // -> XXX의 관계 목록으로 재조회
      if (firstMention.isOwnerCategory &&
          firstMention.name != null &&
          firstMention.name != activeProfileDisplayName) {
        if (kDebugMode) {
          print('[MentionSendHandler] Phase 56: base person change detected - ${firstMention.name}');
        }

        // 로그인 사용자의 관계 목록에서 기준 인물 프로필 ID 찾기
        final tempParser = MentionParser(
          ownerProfileId: activeProfileId,
          ownerName: activeProfileDisplayName,
          relations: relations,
        );
        final baseProfileId = tempParser.findProfileIdByName(firstMention.name!);

        if (baseProfileId != null) {
          // 기준 인물의 관계 목록 재조회
          final baseRelations = await ref.read(relationListProvider(baseProfileId).future);

          if (kDebugMode) {
            print('[MentionSendHandler] Phase 56: base person relations reload - ${firstMention.name} (${baseRelations.length})');
          }

          // 기준 인물 정보로 교체
          ownerProfileId = baseProfileId;
          ownerName = firstMention.name!;
          relations = baseRelations;
        } else {
          if (kDebugMode) {
            print('[MentionSendHandler] Phase 56: base person profile ID not found - ${firstMention.name}');
          }
        }
      }

      // 멘션 파싱 (기준 인물 기준)
      final parser = MentionParser(
        ownerProfileId: ownerProfileId,
        ownerName: ownerName,
        relations: relations,
      );
      final parseResult = parser.parse(text);

      if (kDebugMode) {
        print('[MentionSendHandler] mention parse result: mentions=${parseResult.mentions.length}, targetId=${parseResult.targetProfileId}, includesOwner=${parseResult.includesOwner}');
        print('[MentionSendHandler] participantIds: ${parseResult.participantIds}');
      }

      // 파싱된 targetProfileId 및 participantIds 사용
      targetId = parseResult.targetProfileId;
      participantIds = parseResult.participantIds;
      includesOwner = parseResult.includesOwner;
    }

    // 파싱 실패 시 UI 선택된 값 또는 세션 값 사용
    if (targetId == null) {
      targetId = pendingTargetProfileId ?? fallbackTargetProfileId;
      if (kDebugMode) {
        print('[MentionSendHandler] parse failed, using fallback: $targetId');
      }
    }

    return MentionSendParams(
      targetProfileId: targetId,
      participantIds: participantIds,
      includesOwner: includesOwner,
    );
  }

  /// 텍스트에 멘션 패턴(@카테고리/이름)이 포함되어 있는지 확인
  static bool hasMention(String text) {
    return RegExp(r'@[^\s/]+/[^\s]+').hasMatch(text);
  }

  /// v13.0: @멘션 없이 자연어에서 인연 이름 자동 매칭
  ///
  /// "언니와 형님 궁합 봐줘" → 인연 목록에서 "언니", "형님" 매칭
  /// - 2명 이상 매칭: 제3자 궁합 모드 (includesOwner=false)
  /// - 1명 매칭: 나+상대 모드 (includesOwner=true)
  /// - 0명: null 반환 (fallback)
  ///
  /// 오탐 방지: display_name 2글자 이상만 매칭
  static Future<MentionSendParams?> _matchRelationNamesInText({
    required String text,
    required WidgetRef ref,
    required String activeProfileId,
  }) async {
    try {
      final relations = await ref.read(relationListProvider(activeProfileId).future);
      if (relations.isEmpty) return null;

      // 인연 이름 → profileId 매칭 (긴 이름부터 검색하여 부분 매칭 오탐 방지)
      final candidates = <({String name, String profileId})>[];
      for (final relation in relations) {
        final name = relation.displayName ?? relation.toProfile?.displayName ?? '';
        final pid = relation.toProfileId;
        if (name.length >= 2 && pid != null && text.contains(name)) {
          candidates.add((name: name, profileId: pid));
        }
      }

      if (candidates.isEmpty) return null;

      // 중복 profileId 제거 (동일인 다른 이름)
      final seen = <String>{};
      final uniqueIds = <String>[];
      for (final c in candidates) {
        if (seen.add(c.profileId)) {
          uniqueIds.add(c.profileId);
        }
      }

      if (uniqueIds.length >= 2) {
        // 2명 이상: 제3자 궁합 (언니와 형님)
        if (kDebugMode) {
          print('[MentionSendHandler] v13.0 자연어 매칭: ${candidates.map((c) => c.name).join(", ")} (${uniqueIds.length}명, 제3자 모드)');
        }
        return MentionSendParams(
          targetProfileId: uniqueIds.first,
          participantIds: uniqueIds,
          includesOwner: false,
        );
      } else if (uniqueIds.length == 1) {
        // 1명: 나+상대
        if (kDebugMode) {
          print('[MentionSendHandler] v13.0 자연어 매칭: ${candidates.first.name} (단일, 나+상대 모드)');
        }
        return MentionSendParams(
          targetProfileId: uniqueIds.first,
          participantIds: uniqueIds,
          includesOwner: true,
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[MentionSendHandler] v13.0 자연어 매칭 오류: $e');
      }
      return null;
    }
  }
}
