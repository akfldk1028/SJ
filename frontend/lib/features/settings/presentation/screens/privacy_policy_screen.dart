import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 개인정보처리방침 화면
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                        _buildIntro(theme),
                        _buildSection(
                          theme,
                          title: '1. 수집하는 개인정보 항목',
                          content: '''만톡은 서비스 제공을 위해 다음의 개인정보를 수집합니다.

[필수 수집 항목]
• 이름 (닉네임)
• 생년월일
• 출생시간
• 성별
• 양/음력 구분

[선택 수집 항목]
• 이메일 주소
• 프로필 이미지

[자동 수집 항목]
• 서비스 이용 기록
• 접속 로그
• 기기 정보''',
                        ),
                        _buildSection(
                          theme,
                          title: '2. 개인정보의 수집 및 이용 목적',
                          content: '''수집된 개인정보는 다음의 목적으로 이용됩니다.

• 사주 분석 및 운세 서비스 제공
• 맞춤형 상담 서비스 제공
• 회원 관리 및 서비스 이용에 따른 본인 확인
• 서비스 개선 및 신규 서비스 개발
• 이벤트 및 프로모션 안내 (동의 시)''',
                        ),
                        _buildSection(
                          theme,
                          title: '3. 개인정보의 보유 및 이용 기간',
                          content: '''이용자의 개인정보는 원칙적으로 개인정보 수집 및 이용 목적이 달성되면 지체 없이 파기합니다.

• 회원 탈퇴 시: 즉시 파기
• 관계 법령에 의한 보존 필요 시: 해당 기간 동안 보관

[관계 법령에 의한 정보 보유]
• 계약 또는 청약철회 등에 관한 기록: 5년
• 소비자 불만 또는 분쟁처리에 관한 기록: 3년
• 접속에 관한 기록: 3개월''',
                        ),
                        _buildSection(
                          theme,
                          title: '4. 개인정보의 제3자 제공',
                          content:
                              '만톡은 이용자의 개인정보를 원칙적으로 외부에 제공하지 않습니다. 다만, 아래의 경우에는 예외로 합니다.\n\n• 이용자가 사전에 동의한 경우\n• 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우',
                        ),
                        _buildSection(
                          theme,
                          title: '5. 개인정보의 파기 절차 및 방법',
                          content: '''[파기 절차]
이용자가 회원 탈퇴를 요청하거나 개인정보 수집 목적이 달성된 경우, 내부 방침 및 관련 법령에 따라 일정 기간 저장 후 파기합니다.

[파기 방법]
• 전자적 파일 형태: 복구 불가능한 방법으로 영구 삭제
• 종이 문서: 분쇄기로 분쇄하거나 소각''',
                        ),
                        _buildSection(
                          theme,
                          title: '6. 이용자의 권리와 행사 방법',
                          content: '''이용자는 언제든지 다음의 권리를 행사할 수 있습니다.

• 개인정보 열람 요구
• 오류 등이 있을 경우 정정 요구
• 삭제 요구
• 처리 정지 요구

권리 행사는 앱 내 설정 메뉴 또는 고객센터를 통해 가능합니다.''',
                        ),
                        _buildSection(
                          theme,
                          title: '7. 개인정보 보호책임자',
                          content: '''만톡은 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 이용자의 불만 처리 및 피해 구제를 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.

[개인정보 보호책임자]
• 담당부서: 개인정보보호팀
• 이메일: privacy@mantok.com''',
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
            '개인정보처리방침',
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

  Widget _buildIntro(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        '만톡(이하 "회사")은 이용자의 개인정보를 중요시하며, 「개인정보 보호법」을 준수하고 있습니다. 회사는 개인정보처리방침을 통하여 이용자의 개인정보가 어떠한 용도와 방식으로 이용되고 있으며, 개인정보보호를 위해 어떠한 조치가 취해지고 있는지 알려드립니다.',
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: theme.textSecondary,
        ),
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
