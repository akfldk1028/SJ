import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';
import '../../data/models/compatibility_analysis_model.dart';
import '../providers/compatibility_provider.dart';
import '../widgets/compatibility_card.dart';

/// 궁합 분석 목록 화면
///
/// 특정 프로필의 모든 궁합 분석 결과 표시
class CompatibilityListScreen extends ConsumerWidget {
  final String profileId;

  const CompatibilityListScreen({
    super.key,
    required this.profileId,
  });

  static const _primaryColor = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final analysesAsync = ref.watch(compatibilityAnalysisListProvider(profileId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'compatibility.list_title'.tr(),
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.textPrimary),
            onPressed: () {
              ref.invalidate(compatibilityAnalysisListProvider(profileId));
            },
          ),
        ],
      ),
      body: MysticBackground(
        child: SafeArea(
          child: analysesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildError(theme, error.toString()),
            data: (analyses) => analyses.isEmpty
                ? _buildEmpty(theme)
                : _buildList(context, ref, theme, analyses),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppThemeExtension theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              'compatibility.error_occurred'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: theme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 40,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'compatibility.empty_title'.tr(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'compatibility.empty_desc'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: theme.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AppThemeExtension theme,
    List<CompatibilityAnalysisModel> analyses,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final analysis = analyses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(analysis.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.red),
            ),
            confirmDismiss: (direction) => _confirmDelete(context, theme),
            onDismissed: (direction) {
              _deleteAnalysis(context, ref, analysis.id);
            },
            child: CompatibilityCard(
              analysis: analysis,
              showDetails: true,
              onTap: () => _navigateToDetail(context, analysis.id),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(
      BuildContext context, AppThemeExtension theme) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'compatibility.delete_title'.tr(),
              style: TextStyle(color: theme.textPrimary),
            ),
            content: Text(
              'compatibility.delete_confirm'.tr(),
              style: TextStyle(color: theme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('common.buttonCancel'.tr(), style: TextStyle(color: theme.textMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _deleteAnalysis(BuildContext context, WidgetRef ref, String analysisId) {
    ref.read(compatibilityNotifierProvider.notifier).delete(
          analysisId: analysisId,
          profileId: profileId,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('compatibility.deleted_snackbar'.tr())),
    );
  }

  void _navigateToDetail(BuildContext context, String analysisId) {
    context.push('${Routes.compatibilityDetail}?analysisId=$analysisId');
  }
}
