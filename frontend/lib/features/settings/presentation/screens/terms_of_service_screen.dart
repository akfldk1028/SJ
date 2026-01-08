import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 이용약관 화면 - shadcn_ui 기반
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const String _content = '''
만톡 서비스 이용약관

제1조 (목적)
본 약관은 만톡(이하 "서비스")의 이용 조건 및 절차에 관한 사항을 규정함을 목적으로 합니다.

제2조 (서비스 내용)
1. 본 서비스는 AI 기반 사주 상담 서비스입니다.
2. 사주 분석 결과는 참고용 정보이며, 전문적인 상담을 대체하지 않습니다.

제3조 (이용자 의무)
1. 이용자는 본인의 정확한 생년월일 정보를 입력해야 합니다.
2. 서비스를 부정한 목적으로 사용해서는 안 됩니다.

제4조 (서비스 제공의 제한)
운영상, 기술상 필요한 경우 서비스 제공을 일시적으로 중단할 수 있습니다.

제5조 (면책사항)
1. 서비스에서 제공하는 정보는 오락 및 참고 목적입니다.
2. 중요한 결정은 반드시 해당 분야 전문가와 상담하시기 바랍니다.
''';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
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
              _content,
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
