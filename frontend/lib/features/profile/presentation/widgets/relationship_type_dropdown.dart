import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/relationship_type.dart';
import '../../data/relation_schema.dart';
import '../providers/profile_provider.dart';

/// 관계 유형 드롭다운 — 세분류 (RelationshipAddScreen과 동일)
///
/// ProfileRelationType (19종)을 카테고리별로 그룹핑하여 표시
/// 선택 시 ProfileRelationType → RelationshipType 대분류 매핑하여 폼에 저장
class RelationshipTypeDropdown extends ConsumerStatefulWidget {
  const RelationshipTypeDropdown({super.key});

  @override
  ConsumerState<RelationshipTypeDropdown> createState() =>
      _RelationshipTypeDropdownState();
}

class _RelationshipTypeDropdownState
    extends ConsumerState<RelationshipTypeDropdown> {
  ProfileRelationType _selectedDetailType = ProfileRelationType.friendGeneral;

  @override
  void initState() {
    super.initState();
    // 기존 폼 상태에서 초기값 매핑 + "나" 중복 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(profileFormProvider);
      _selectedDetailType = _mapFromRelationshipType(formState.relationType);
      // 폼 기본값이 "나"이면 → "친구(일반)"으로 강제 변경 (나 중복 생성 방지)
      // 이 드롭다운이 표시되는 경우는 항상 "관계인" 프로필 생성이므로 me일 수 없음
      if (formState.relationType == RelationshipType.me) {
        ref.read(profileFormProvider.notifier)
            .updateRelationType(RelationshipType.friend);
        setState(() {
          _selectedDetailType = ProfileRelationType.friendGeneral;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.relationType'.tr(),
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.textMuted.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProfileRelationType>(
              value: _selectedDetailType,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              style: TextStyle(color: theme.textPrimary, fontSize: 16),
              items: _buildItems(theme),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDetailType = value);
                  // 세분류 → 대분류 매핑하여 폼에 저장
                  final broadType = _mapToRelationshipType(value);
                  ref.read(profileFormProvider.notifier)
                      .updateRelationType(broadType);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<ProfileRelationType>> _buildItems(
      AppThemeExtension theme) {
    final categories = {
      'profile.categoryFamily'.tr(): ProfileRelationType.familyTypes,
      'profile.categoryLover'.tr(): ProfileRelationType.romanticTypes,
      'profile.categoryFriend'.tr(): ProfileRelationType.friendTypes,
      'profile.categoryWork'.tr(): ProfileRelationType.workTypes,
      'profile.categoryOther'.tr(): ProfileRelationType.otherTypes,
    };

    final items = <DropdownMenuItem<ProfileRelationType>>[];

    for (final entry in categories.entries) {
      // 카테고리 헤더 (선택 불가)
      items.add(
        DropdownMenuItem<ProfileRelationType>(
          enabled: false,
          child: Text(
            '── ${entry.key} ──',
            style: TextStyle(
              color: theme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );

      for (final type in entry.value) {
        items.add(
          DropdownMenuItem<ProfileRelationType>(
            value: type,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                type.displayName,
                style: TextStyle(color: theme.textPrimary),
              ),
            ),
          ),
        );
      }
    }

    return items;
  }

  /// ProfileRelationType → RelationshipType 대분류 매핑
  RelationshipType _mapToRelationshipType(ProfileRelationType detail) {
    final category = detail.categoryLabel;
    return switch (category) {
      'family' => RelationshipType.family,
      'romantic' => RelationshipType.lover,
      'friend' => RelationshipType.friend,
      'work' => RelationshipType.work,
      _ => RelationshipType.other,
    };
  }

  /// RelationshipType → ProfileRelationType 기본값 매핑
  ProfileRelationType _mapFromRelationshipType(RelationshipType broad) {
    return switch (broad) {
      RelationshipType.me => ProfileRelationType.other,
      RelationshipType.family => ProfileRelationType.familyOther,
      RelationshipType.friend => ProfileRelationType.friendGeneral,
      RelationshipType.lover => ProfileRelationType.romanticPartner,
      RelationshipType.work => ProfileRelationType.workColleague,
      RelationshipType.other => ProfileRelationType.other,
      RelationshipType.admin => ProfileRelationType.other,
    };
  }
}
