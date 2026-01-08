import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 개인정보처리방침 화면 - shadcn_ui 기반
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _content = '''
개인정보처리방침

1. 수집하는 개인정보 항목
- 필수: 생년월일, 출생시간, 성별
- 선택: 이름, 출생지

2. 개인정보의 수집 및 이용목적
- 사주 분석 서비스 제공
- 서비스 개선 및 통계 분석

3. 개인정보의 보유 및 이용기간
- 서비스 이용 기간 동안 보관
- 회원 탈퇴 시 즉시 삭제

4. 개인정보의 파기
- 앱 삭제 시 기기에 저장된 모든 데이터가 삭제됩니다.

5. 개인정보 보호책임자
- 문의: support@mantok.app

6. 개인정보 처리방침 변경
- 본 방침은 시행일로부터 적용됩니다.
- 변경 시 앱 내 공지를 통해 안내합니다.
''';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
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
