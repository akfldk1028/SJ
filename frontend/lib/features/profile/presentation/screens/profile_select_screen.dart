import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/saju_profile.dart';
import '../providers/profile_provider.dart';

/// 프로필 선택 화면
///
/// 등록된 프로필 목록에서 활성 프로필을 선택
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 100줄 이하 위젯으로 분리
class ProfileSelectScreen extends ConsumerWidget {
  const ProfileSelectScreen({super.key});

  // 캐싱된 색상 상수
  static const _bgGradientStart = Color(0xFF1A1A2E);
  static const _bgGradientEnd = Color(0xFF16213E);
  static const _emptyTextColor = Color.fromRGBO(255, 255, 255, 0.6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileListAsync = ref.watch(profileListProvider);

    return Scaffold(
      backgroundColor: _bgGradientStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgGradientStart, _bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _AppBar(),
              Expanded(
                child: profileListAsync.when(
                  data: (profiles) => profiles.isEmpty
                      ? const _EmptyState()
                      : _ProfileList(profiles: profiles),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      '프로필 로딩 실패: $e',
                      style: const TextStyle(color: _emptyTextColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/profile/edit'),
        backgroundColor: const Color(0xFF7E57C2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// 앱바 위젯
class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          ),
          const Expanded(
            child: Text(
              '프로필 선택',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 빈 상태 위젯
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 64,
            color: ProfileSelectScreen._emptyTextColor,
          ),
          SizedBox(height: 16),
          Text(
            '등록된 프로필이 없습니다',
            style: TextStyle(
              color: ProfileSelectScreen._emptyTextColor,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 프로필을 추가하세요',
            style: TextStyle(
              color: ProfileSelectScreen._emptyTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// 프로필 목록 위젯
class _ProfileList extends StatelessWidget {
  final List<SajuProfile> profiles;

  const _ProfileList({required this.profiles});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      itemBuilder: (context, index) => _ProfileCard(
        profile: profiles[index],
        isLast: index == profiles.length - 1,
      ),
    );
  }
}

/// 프로필 카드 위젯
class _ProfileCard extends ConsumerWidget {
  static const _cardBg = Color.fromRGBO(255, 255, 255, 0.08);
  static const _borderColor = Color.fromRGBO(255, 255, 255, 0.15);
  static const _activeBorderColor = Color(0xFF7E57C2);

  final SajuProfile profile;
  final bool isLast;

  const _ProfileCard({
    required this.profile,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSelect(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: profile.isActive ? _activeBorderColor : _borderColor,
                width: profile.isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _ProfileAvatar(profile: profile),
                const SizedBox(width: 16),
                Expanded(child: _ProfileInfo(profile: profile)),
                if (profile.isActive)
                  const Icon(
                    Icons.check_circle,
                    color: _activeBorderColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSelect(BuildContext context, WidgetRef ref) async {
    if (profile.isActive) {
      // 이미 활성화된 프로필이면 그냥 닫기
      context.pop();
      return;
    }

    // 활성 프로필 변경
    await ref.read(profileListProvider.notifier).setActiveProfile(profile.id);
    if (context.mounted) {
      context.pop();
    }
  }
}

/// 프로필 아바타 위젯
class _ProfileAvatar extends StatelessWidget {
  static const _avatarBg = Color.fromRGBO(126, 87, 194, 0.3);

  final SajuProfile profile;

  const _ProfileAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _avatarBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          profile.displayName.isNotEmpty ? profile.displayName[0] : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 프로필 정보 위젯
class _ProfileInfo extends StatelessWidget {
  static const _subtitleColor = Color.fromRGBO(255, 255, 255, 0.7);

  final SajuProfile profile;

  const _ProfileInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              profile.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _ProfileCard._borderColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                profile.relationType.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${profile.birthDateFormatted} (${profile.calendarTypeLabel})',
          style: const TextStyle(
            color: _subtitleColor,
            fontSize: 13,
          ),
        ),
        if (profile.birthTimeFormatted != null)
          Text(
            '${profile.birthTimeFormatted} 출생',
            style: const TextStyle(
              color: _subtitleColor,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
