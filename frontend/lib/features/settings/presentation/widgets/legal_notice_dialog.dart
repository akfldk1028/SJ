import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/app_strings.dart';

/// 법적 고지 다이얼로그 타입
enum LegalNoticeType {
  terms,
  privacy,
  disclaimer,
}

/// 법적 고지 다이얼로그
class LegalNoticeDialog extends StatelessWidget {
  const LegalNoticeDialog({
    super.key,
    required this.type,
  });

  final LegalNoticeType type;

  String get _title {
    switch (type) {
      case LegalNoticeType.terms:
        return AppStrings.settingsTerms;
      case LegalNoticeType.privacy:
        return AppStrings.settingsPrivacy;
      case LegalNoticeType.disclaimer:
        return AppStrings.settingsDisclaimer;
    }
  }

  String get _content {
    switch (type) {
      case LegalNoticeType.terms:
        return _termsContent;
      case LegalNoticeType.privacy:
        return _privacyContent;
      case LegalNoticeType.disclaimer:
        return _disclaimerContent;
    }
  }

  static const String _termsContent = '''
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

  static const String _privacyContent = '''
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

  static const String _disclaimerContent = '''
면책 안내

중요 공지

만톡 서비스에서 제공하는 모든 사주 분석, 운세 정보, AI 상담 내용은 오락 및 참고 목적으로만 제공됩니다.

1. 본 서비스의 결과를 근거로 한 어떠한 결정에 대해서도 책임지지 않습니다.

2. 건강, 재정, 법률, 직업 등 중요한 결정을 내리기 전에 반드시 해당 분야의 전문가와 상담하시기 바랍니다.

3. 사주, 운세 분석은 과학적으로 검증된 방법이 아니며, 결과의 정확성을 보장하지 않습니다.

4. AI가 생성한 답변은 일반적인 정보 제공 목적이며, 전문적인 조언으로 간주되어서는 안 됩니다.

5. 본 서비스 이용으로 인해 발생하는 직접적, 간접적 손해에 대해 책임지지 않습니다.

서비스를 이용함으로써 위 내용에 동의하신 것으로 간주됩니다.
''';

  static void show(BuildContext context, LegalNoticeType type) {
    showShadDialog(
      context: context,
      builder: (context) => LegalNoticeDialog(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadDialog(
      title: Text(_title),
      description: const Text(''),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.buttonConfirm),
        ),
      ],
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Text(
            _content,
            style: theme.textTheme.small,
          ),
        ),
      ),
    );
  }
}
