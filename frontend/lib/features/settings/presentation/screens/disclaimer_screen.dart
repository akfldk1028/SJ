import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 면책 안내 화면 - shadcn_ui 기반
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  // 사업자 정보
  static const String _companyName = '어뮤니티';
  static const String _email = 'clickaround8@gmail.com';

  static const String _content = '''
면책 안내

■ 중요 공지

$_companyName(이하 "회사")가 제공하는 사담 서비스에서 제공하는 모든 사주 분석, 운세 정보, AI 상담 내용은 오락 및 참고 목적으로만 제공됩니다.


1. 서비스의 성격

본 서비스는 전통 명리학을 기반으로 한 AI 엔터테인먼트 서비스입니다. 제공되는 정보는 과학적으로 검증된 것이 아니며, 어떠한 예측이나 결과도 보장하지 않습니다.


2. 책임의 제한

• 본 서비스의 결과를 근거로 한 어떠한 결정에 대해서도 회사는 책임지지 않습니다.

• 서비스 이용으로 인해 발생하는 직접적, 간접적, 부수적, 결과적 손해에 대해 책임지지 않습니다.

• AI가 생성한 모든 답변은 일반적인 정보 제공 목적이며, 전문적인 조언으로 간주되어서는 안 됩니다.


3. 전문가 상담 권고

다음 사항에 대해서는 반드시 해당 분야 전문가와 상담하시기 바랍니다:

• 건강 및 의료 관련 결정
• 재정 및 투자 관련 결정
• 법률 관련 결정
• 직업 및 진로 관련 결정
• 대인관계 및 결혼 관련 중요 결정


4. 정보의 정확성

사주, 운세 분석 결과의 정확성을 보장하지 않습니다. 만세력 계산은 일반적으로 알려진 방법을 따르나, 학파나 해석 방법에 따라 다를 수 있습니다.


5. 동의

서비스를 이용함으로써 위 내용에 동의하신 것으로 간주됩니다.


■ 문의

서비스 관련 문의: $_email
''';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('면책 안내'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 주요 안내 카드
              ShadCard(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.info,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '사주 상담은 참고용입니다',
                      style: theme.textTheme.h4,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '중요한 인생의 결정은 반드시\n전문가와 상담하시기 바랍니다.',
                      style: theme.textTheme.p.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 상세 내용 카드
              ShadCard(
                child: Text(
                  _content,
                  style: theme.textTheme.p.copyWith(
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
