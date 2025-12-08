import 'package:flutter/material.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/relationship_type.dart';

class RelationshipCategorySection extends StatelessWidget {
  final RelationshipType type;
  final List<SajuProfile> profiles;
  final VoidCallback? onAddPressed;
  final Function(SajuProfile) onProfileTap;

  const RelationshipCategorySection({
    super.key,
    required this.type,
    required this.profiles,
    this.onAddPressed,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty && type != RelationshipType.me) {
      return const SizedBox.shrink(); // Hide empty sections except 'Me'
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${type.label} ${profiles.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (onAddPressed != null)
                GestureDetector(
                  onTap: onAddPressed,
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        if (profiles.isEmpty && type == RelationshipType.me)
          _buildEmptyMe(context)
        else
          ...profiles.map((profile) => _buildProfileItem(context, profile)),
      ],
    );
  }

  Widget _buildEmptyMe(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '나의 프로필을 등록해주세요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, SajuProfile profile) {
    return InkWell(
      onTap: () => onProfileTap(profile),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profile.displayName.substring(0, 1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.birthDateFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
            // Memo or Action
            if (profile.memo != null && profile.memo!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  profile.memo!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
