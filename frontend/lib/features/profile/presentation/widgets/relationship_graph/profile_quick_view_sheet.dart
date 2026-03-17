import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/gender.dart';
import '../../../domain/entities/relationship_type.dart';

/// 프로필 빠른 보기 바텀시트
///
/// 그래프에서 노드 탭 시 표시되는 프로필 상세 정보
class ProfileQuickViewSheet extends StatelessWidget {
  const ProfileQuickViewSheet({
    super.key,
    required this.profile,
    this.onChatPressed,
    this.onEditPressed,
    this.onDeletePressed,
  });

  final SajuProfile profile;
  final VoidCallback? onChatPressed;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Profile header
          _buildProfileHeader(context),

          const SizedBox(height: 20),

          // Profile info
          _buildProfileInfo(context),

          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(context),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _getRelationColor().withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName.substring(0, 1)
                  : '?',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: _getRelationColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name and relation type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRelationColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  profile.relationType.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getRelationColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            icon: Icons.cake_outlined,
            label: 'profile.birthDate'.tr(),
            value: '${profile.birthDateFormatted} (${profile.calendarTypeLabel})',
          ),
          const Divider(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.access_time_outlined,
            label: 'profile.birthTime'.tr(),
            value: profile.birthTimeUnknown
                ? 'profile.birthTimeUnknown'.tr()
                : (profile.birthTimeFormatted ?? 'profile.notEntered'.tr()),
          ),
          const Divider(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.person_outline,
            label: 'common.gender'.tr(),
            value: profile.gender == Gender.male ? 'common.genderMale'.tr() : 'common.genderFemale'.tr(),
          ),
          const Divider(height: 16),
          _buildInfoRow(
            context,
            icon: Icons.location_on_outlined,
            label: 'profile.birthPlace'.tr(),
            value: '${profile.birthCity} (${profile.timeCorrectionLabel})',
          ),
          if (profile.memo != null && profile.memo!.isNotEmpty) ...[
            const Divider(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.note_outlined,
              label: 'profile.memo'.tr(),
              value: profile.memo!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Chat button
        Expanded(
          child: ShadButton(
            onPressed: onChatPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 8),
                Text('profile.sajuConsult'.tr()),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Edit button
        ShadButton.outline(
          onPressed: onEditPressed,
          child: const Icon(Icons.edit_outlined, size: 18),
        ),
        const SizedBox(width: 8),

        // Delete button
        ShadButton.outline(
          onPressed: onDeletePressed,
          child: Icon(
            Icons.delete_outline,
            size: 18,
            color: Colors.red[400],
          ),
        ),
      ],
    );
  }

  Color _getRelationColor() {
    final type = profile.relationType;
    if (type == RelationshipType.me) return const Color(0xFFFF69B4);
    if (type == RelationshipType.family) return const Color(0xFFFF6B6B);
    if (type == RelationshipType.friend) return const Color(0xFF4ECDC4);
    if (type == RelationshipType.lover) return const Color(0xFFFF69B4);
    if (type == RelationshipType.work) return const Color(0xFF45B7D1);
    return const Color(0xFF95A5A6); // other
  }
}

/// 바텀시트 표시 헬퍼 함수
void showProfileQuickView(
  BuildContext context, {
  required SajuProfile profile,
  VoidCallback? onChatPressed,
  VoidCallback? onEditPressed,
  VoidCallback? onDeletePressed,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProfileQuickViewSheet(
      profile: profile,
      onChatPressed: onChatPressed,
      onEditPressed: onEditPressed,
      onDeletePressed: onDeletePressed,
    ),
  );
}
