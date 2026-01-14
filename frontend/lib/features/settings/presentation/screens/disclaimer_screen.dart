import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 면책 안내 화면 - shadcn_ui 기반
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  static const String _content = '''
면책 안내

중요 공지

사담 서비스에서 제공하는 모든 사주 분석, 운세 정보, AI 상담 내용은 오락 및 참고 목적으로만 제공됩니다.

1. 본 서비스의 결과를 근거로 한 어떠한 결정에 대해서도 책임지지 않습니다.

2. 건강, 재정, 법률, 직업 등 중요한 결정을 내리기 전에 반드시 해당 분야의 전문가와 상담하시기 바랍니다.

3. 사주, 운세 분석은 과학적으로 검증된 방법이 아니며, 결과의 정확성을 보장하지 않습니다.

4. AI가 생성한 답변은 일반적인 정보 제공 목적이며, 전문적인 조언으로 간주되어서는 안 됩니다.

5. 본 서비스 이용으로 인해 발생하는 직접적, 간접적 손해에 대해 책임지지 않습니다.

서비스를 이용함으로써 위 내용에 동의하신 것으로 간주됩니다.
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
                        color: theme.colorScheme.primary.withOpacity(0.1),
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
