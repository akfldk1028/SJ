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
    // 3. 기본값
    else {
      targetId = fallbackTargetProfileId;
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
      print('[MentionSendHandler] Phase 57: isThirdPartyMode=$isThirdPartyMode, isExcludeOwnerMode=$isExcludeOwnerMode, hasOwnerMention=$hasOwnerMention, mentionCount=${allMentions.length}');
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
        participantIds = foundIds.take(2).toList();
        targetId = participantIds.first;
        includesOwner = false;
        if (kDebugMode) {
          print('[MentionSendHandler] Phase 57: third-party compatibility - participantIds=$participantIds');
        }
      } else {
        if (kDebugMode) {
          print('[MentionSendHandler] Phase 57: third-party mode but failed to find 2 (found=${foundIds.length})');
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
}
