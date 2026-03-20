import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 개인정보처리방침 화면 - shadcn_ui 기반
///
/// 2025년 개인정보보호법 및 작성지침 준수
/// 참고: https://www.privacy.go.kr
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.privacy'.tr()),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ShadCard(
            child: Text(
              'settings.privacyContent'.tr(),
              style: theme.textTheme.p.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
