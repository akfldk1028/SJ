import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 이용약관 화면
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.06),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          theme,
                          title: '제1조 (목적)',
                          content:
                              '이 약관은 만톡(이하 "회사")이 제공하는 AI 사주 상담 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.',
                        ),
                        _buildSection(
                          theme,
                          title: '제2조 (용어의 정의)',
                          content: '''1. "서비스"란 회사가 제공하는 AI 기반 사주 상담, 운세 정보 제공 등의 서비스를 말합니다.
2. "이용자"란 이 약관에 따라 회사가 제공하는 서비스를 이용하는 회원 및 비회원을 말합니다.
3. "회원"이란 회사에 개인정보를 제공하여 회원등록을 한 자로서 서비스를 계속적으로 이용할 수 있는 자를 말합니다.''',
                        ),
                        _buildSection(
                          theme,
                          title: '제3조 (약관의 효력)',
                          content:
                              '1. 이 약관은 서비스 화면에 게시하거나 기타의 방법으로 이용자에게 공지함으로써 효력이 발생합니다.\n2. 회사는 필요한 경우 관련 법령을 위배하지 않는 범위 내에서 이 약관을 변경할 수 있습니다.',
                        ),
                        _buildSection(
                          theme,
                          title: '제4조 (서비스의 내용)',
                          content: '''1. AI 기반 사주팔자 분석 서비스
2. 오늘의 운세 제공 서비스
3. 궁합 분석 서비스
4. 기타 회사가 정하는 서비스''',
                        ),
                        _buildSection(
                          theme,
                          title: '제5조 (서비스 이용)',
                          content:
                              '1. 서비스의 이용은 연중무휴 24시간을 원칙으로 합니다.\n2. 회사는 시스템 점검, 장애 발생 등의 사유로 서비스 이용을 일시 중지할 수 있습니다.',
                        ),
                        _buildSection(
                          theme,
                          title: '제6조 (이용자의 의무)',
                          content: '''1. 이용자는 서비스 이용 시 다음 각 호의 행위를 하여서는 안 됩니다.
  - 타인의 정보 도용
  - 서비스 운영을 방해하는 행위
  - 법령에 위반되는 행위
2. 이용자는 이 약관 및 관계 법령에서 규정한 사항을 준수하여야 합니다.''',
                        ),
                        _buildSection(
                          theme,
                          title: '제7조 (면책조항)',
                          content:
                              '1. 회사는 사주 상담 결과에 대해 어떠한 법적 책임도 지지 않습니다.\n2. 서비스에서 제공하는 정보는 참고용이며, 중요한 의사결정은 전문가와 상담하시기 바랍니다.\n3. 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우 책임이 면제됩니다.',
                        ),
                        _buildSection(
                          theme,
                          title: '제8조 (개인정보보호)',
                          content:
                              '회사는 이용자의 개인정보를 관련 법령이 정하는 바에 따라 보호하며, 개인정보의 보호 및 사용에 대해서는 개인정보처리방침에 따릅니다.',
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            '시행일: 2024년 1월 1일',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '이용약관',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSection(
    AppThemeExtension theme, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
