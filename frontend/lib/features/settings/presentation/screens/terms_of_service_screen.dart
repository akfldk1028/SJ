import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 이용약관 화면 - shadcn_ui 기반
///
/// 2025년 전자상거래법 및 정보통신망법 준수
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  // 사업자 정보
  static const String _companyName = '어뮤니티';
  static const String _ceoName = '김동현';
  static const String _businessNumber = '626-40-00870';
  static const String _address = '서울특별시 은평구 통일로 742, 304호(불광동, 한화생명 불광동사옥 2동)';
  static const String _email = 'clickaround8@gmail.com';
  static const String _serviceName = '사담';
  static const String _effectiveDate = '2026년 1월 23일';

  static const String _content = '''
$_serviceName 서비스 이용약관


제1조 (목적)

이 약관은 $_companyName(이하 "회사")가 제공하는 $_serviceName 서비스(이하 "서비스")의 이용조건 및 절차, 회사와 이용자의 권리, 의무, 책임사항 및 기타 필요한 사항을 규정함을 목적으로 합니다.


제2조 (정의)

1. "서비스"란 회사가 제공하는 AI 기반 사주 상담 서비스를 말합니다.
2. "이용자"란 본 약관에 따라 회사가 제공하는 서비스를 이용하는 자를 말합니다.
3. "프로필"이란 서비스 이용을 위해 이용자가 입력하는 생년월일, 출생시간, 성별 등의 정보를 말합니다.


제3조 (약관의 효력 및 변경)

1. 본 약관은 서비스 화면에 게시하거나 기타의 방법으로 이용자에게 공지함으로써 효력이 발생합니다.
2. 회사는 필요한 경우 관련법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있습니다.
3. 약관이 변경되는 경우 회사는 변경 사항을 시행일자 7일 전부터 앱 내 공지합니다.
4. 이용자가 변경된 약관에 동의하지 않는 경우 서비스 이용을 중단하고 탈퇴할 수 있습니다.


제4조 (서비스의 제공)

1. 회사는 다음과 같은 서비스를 제공합니다.
   - 생년월일, 출생시간 기반 만세력 계산
   - AI 사주 분석 및 상담 서비스
   - 사주 프로필 관리 기능

2. 서비스는 연중무휴, 1일 24시간 제공함을 원칙으로 합니다. 단, 시스템 점검 등의 필요가 있는 경우 예외로 합니다.


제5조 (서비스 이용료)

1. 기본 서비스는 무료로 제공됩니다.
2. 일부 프리미엄 기능에 대해서는 별도의 이용료가 부과될 수 있으며, 이 경우 사전에 안내합니다.
3. 광고 시청을 통해 무료로 이용할 수 있는 기능이 있습니다.


제6조 (이용자의 의무)

1. 이용자는 정확한 정보를 입력해야 합니다.
2. 이용자는 다음 행위를 해서는 안 됩니다.
   - 타인의 정보를 도용하는 행위
   - 서비스의 운영을 방해하는 행위
   - 서비스를 이용하여 법령 또는 공서양속에 위배되는 행위
   - 서비스 내용을 무단으로 복제, 배포하는 행위
   - 기타 관계법령에 위배되는 행위


제7조 (서비스 이용의 제한 및 중지)

1. 회사는 다음의 경우 서비스 이용을 제한하거나 중지할 수 있습니다.
   - 시스템 정기점검, 증설 및 교체를 위해 필요한 경우
   - 기간통신사업자가 전기통신 서비스를 중지한 경우
   - 천재지변, 국가비상사태 등 불가항력적 사유가 있는 경우
   - 이용자가 본 약관을 위반한 경우

2. 회사는 서비스 중지 시 사전에 공지합니다. 단, 불가피한 경우 사후에 공지할 수 있습니다.


제8조 (면책사항)

1. 서비스에서 제공하는 사주 분석, 운세 정보, AI 상담 내용은 오락 및 참고 목적으로만 제공됩니다.
2. 사주, 운세 분석은 과학적으로 검증된 방법이 아니며, 결과의 정확성을 보장하지 않습니다.
3. 이용자가 서비스를 통해 얻은 정보를 기반으로 내린 결정에 대해 회사는 책임을 지지 않습니다.
4. 건강, 재정, 법률, 직업 등 중요한 결정은 반드시 해당 분야 전문가와 상담하시기 바랍니다.
5. 천재지변, 전쟁, 기간통신사업자의 서비스 중지 등 불가항력적 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.


제9조 (개인정보 보호)

회사는 이용자의 개인정보를 「개인정보 보호법」 등 관계법령이 정하는 바에 따라 보호하며, 개인정보 처리에 관한 사항은 개인정보처리방침에 따릅니다.


제10조 (지식재산권)

1. 서비스에 포함된 콘텐츠, 디자인, 소프트웨어 등에 대한 지식재산권은 회사에 귀속됩니다.
2. 이용자는 서비스를 이용함으로써 얻은 정보를 회사의 사전 승낙 없이 복제, 전송, 출판, 배포, 방송 등 기타 방법으로 이용하거나 제3자에게 이용하게 할 수 없습니다.


제11조 (분쟁해결)

1. 회사는 이용자가 제기하는 정당한 의견이나 불만을 반영하고 그 피해를 보상 처리하기 위한 절차를 마련합니다.
2. 서비스 이용과 관련하여 분쟁이 발생한 경우 회사와 이용자는 성실히 협의하여 해결합니다.
3. 본 약관에 관한 분쟁은 대한민국 법률에 따라 규율되며, 회사의 본사 소재지를 관할하는 법원을 관할 법원으로 합니다.


제12조 (사업자 정보)

■ 상호: $_companyName
■ 대표: $_ceoName
■ 사업자등록번호: $_businessNumber
■ 주소: $_address
■ 이메일: $_email


부칙

본 약관은 $_effectiveDate부터 시행됩니다.
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
