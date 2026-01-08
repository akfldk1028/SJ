import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../providers/saju_chart_provider.dart';
import '../widgets/saju_detail_tabs.dart';

/// 사주 상세 분석 페이지 - 전체 화면으로 탭 컨텐츠 표시
/// ShellRoute 내에서 네비게이션 바가 자동으로 표시됨
class SajuDetailScreen extends ConsumerWidget {
  const SajuDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final sajuAnalysisAsync = ref.watch(currentSajuAnalysisProvider);

    return MysticBackground(
      child: Column(
        children: [
          // 커스텀 앱바
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      '사주 상세 분석',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 밸런스를 위한 빈 공간
                ],
              ),
            ),
          ),
          // 본문
          Expanded(
            child: sajuAnalysisAsync.when(
              data: (analysis) {
                if (analysis == null) {
                  return Center(
                    child: Text(
                      '분석 정보를 불러올 수 없습니다.',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  );
                }

                return const SajuDetailTabs(isFullPage: true);
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '오류가 발생했습니다:\n$err',
                    style: TextStyle(color: theme.fireColor ?? Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
