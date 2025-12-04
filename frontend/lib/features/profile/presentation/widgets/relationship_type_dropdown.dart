import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/entities/relationship_type.dart';
import '../providers/profile_provider.dart';

class RelationshipTypeDropdown extends ConsumerWidget {
  const RelationshipTypeDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationType = ref.watch(profileFormProvider.select((s) => s.relationType));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '관계',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        ShadSelect<RelationshipType>(
          placeholder: const Text('관계를 선택하세요'),
          initialValue: relationType,
          options: RelationshipType.values.map((type) {
            return ShadOption(
              value: type,
              child: Text(type.label),
            );
          }).toList(),
          selectedOptionBuilder: (context, value) => Text(value.label),
          onChanged: (value) {
            if (value != null) {
              ref.read(profileFormProvider.notifier).updateRelationType(value);
            }
          },
        ),
      ],
    );
  }
}
