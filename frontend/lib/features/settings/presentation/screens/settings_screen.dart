import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// 설정 화면 (Placeholder)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text(AppStrings.settingsProfile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 프로필 관리 화면 이동
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text(AppStrings.settingsNotification),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 알림 설정
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text(AppStrings.settingsTerms),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 이용약관
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text(AppStrings.settingsPrivacy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 개인정보처리방침
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text(AppStrings.settingsDisclaimer),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 면책 안내
            },
          ),
        ],
      ),
    );
  }
}
