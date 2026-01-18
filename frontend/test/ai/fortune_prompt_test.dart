/// # Fortune Prompt Test
///
/// 예시 데이터로 운세 프롬프트 테스트
///
/// 실행:
/// ```bash
/// cd frontend
/// dart test/ai/fortune_prompt_test.dart
/// ```

import '../../lib/AI/fortune/common/fortune_input_data.dart';
import '../../lib/AI/fortune/yearly_2026/yearly_2026_prompt.dart';
import '../../lib/AI/fortune/monthly/monthly_prompt.dart';
import '../../lib/AI/fortune/yearly_2025/yearly_2025_prompt.dart';

void main() {
  print('=' * 80);
  print('Fortune Prompt Test - 스토리텔링 v3.0');
  print('=' * 80);
  print('');

  // 예시 데이터 생성
  final testData = _createTestData();

  print('📋 테스트 데이터:');
  print('  이름: ${testData.profileName}');
  print('  생년월일: ${testData.birthDate}');
  print('  성별: ${testData.genderKorean}');
  print('  용신: ${testData.yongsinElement}');
  print('  일간: ${testData.dayGan}');
  print('  일지: ${testData.dayJi}');
  print('');

  // 1. 2026 신년운세 프롬프트
  _test2026Prompt(testData);

  // 2. 월운 프롬프트
  _testMonthlyPrompt(testData);

  // 3. 2025 회고 프롬프트
  _test2025Prompt(testData);
}

/// 테스트용 예시 데이터 생성
FortuneInputData _createTestData() {
  // 예시: 1990년 3월 15일 오전 7시 남성
  // 사주: 경오(庚午)년 기묘(己卯)월 무진(戊辰)일 을묘(乙卯)시

  return FortuneInputData.fromSajuBase(
    profileName: '김민수',
    birthDate: '1990-03-15',
    birthTime: '07:00',
    gender: 'M',

    // saju_base content (AI 분석 결과)
    sajuBaseContent: {
      'personality': '''
성격적으로 무토(戊土) 일간으로 태어나셨어요. 무토는 산과 같은 기운을 가진 큰 흙으로,
듬직하고 안정감 있으며 신뢰를 주는 성격입니다. 묵묵히 자신의 길을 가는 인내심이 있고,
한번 마음먹은 일은 끝까지 해내는 끈기가 있습니다.
''',
      'career': '''
직업적으로는 안정적인 환경에서 능력을 발휘하시는 타입입니다.
금융, 부동산, 교육 분야에서 두각을 나타낼 수 있으며,
조직 내에서 중심 역할을 맡게 되는 경우가 많습니다.
''',
      'wealth': '''
재물운은 꾸준히 쌓아가는 타입입니다. 큰 투기보다는 안정적인 저축과 투자가 어울립니다.
40대 이후 재물운이 크게 상승하며, 부동산 관련 수익을 볼 가능성이 높습니다.
''',
      'love': '''
애정운에서는 따뜻하고 포용력 있는 배우자를 만나게 됩니다.
결혼 후 가정을 중시하며, 자녀운도 좋은 편입니다.
다만 감정 표현이 서툰 편이라 의식적으로 표현하려는 노력이 필요합니다.
''',
      'health': '''
건강에서는 소화기와 피부 쪽을 주의해야 합니다.
규칙적인 식사와 적절한 운동으로 건강을 유지하시면 장수하실 상입니다.
특히 스트레스 관리가 중요합니다.
''',
    },

    // saju_analyses (만세력 계산 결과)
    sajuAnalyses: {
      // 천간/지지
      'year_gan': '庚',  // 경
      'year_ji': '午',   // 오
      'month_gan': '己', // 기
      'month_ji': '卯',  // 묘
      'day_gan': '戊',   // 무 (일간)
      'day_ji': '辰',    // 진 (일지)
      'hour_gan': '乙',  // 을
      'hour_ji': '卯',   // 묘

      // 용신/기신
      'yongsin': {
        'yongsin': '금(金)',
        'huisin': '수(水)',
        'gisin': '화(火)',
        'gusin': '목(木)',
      },

      // 일간 강약
      'day_strength': {
        'score': 65,
        'type': '신강',
        'reason': '월령 卯木이 일간 戊土를 극하나, 년지 午火와 일지 辰土가 일간을 생조하여 신강함',
      },

      // 합충형파해
      'hapchung': {
        '辰卯': '진묘해(辰卯害) - 일지와 월지가 해(害)를 이룸',
      },

      // 대운 (현재)
      'daeun': {
        'current': '임신(壬申)',
        'start_age': 33,
        'end_age': 42,
        'description': '수(水)와 금(金) 기운이 들어오는 대운으로, 희신과 용신이 함께 작용',
      },
    },

    targetYear: 2026,
    targetMonth: 1,
  );
}

/// 2026 신년운세 프롬프트 테스트
void _test2026Prompt(FortuneInputData data) {
  print('━' * 80);
  print('🐍 2026 병오(丙午)년 신년운세 프롬프트');
  print('━' * 80);
  print('');

  final prompt = Yearly2026Prompt(inputData: data);

  print('📌 System Prompt (일부):');
  print('-' * 40);
  final systemLines = prompt.systemPrompt.split('\n').take(30).join('\n');
  print(systemLines);
  print('... (이하 생략)');
  print('');

  print('📌 User Prompt:');
  print('-' * 40);
  print(prompt.buildUserPrompt());
  print('');
}

/// 월운 프롬프트 테스트
void _testMonthlyPrompt(FortuneInputData data) {
  print('━' * 80);
  print('📅 2026년 1월 월운 프롬프트');
  print('━' * 80);
  print('');

  final prompt = MonthlyPrompt(inputData: data);

  print('📌 System Prompt (일부):');
  print('-' * 40);
  final systemLines = prompt.systemPrompt.split('\n').take(30).join('\n');
  print(systemLines);
  print('... (이하 생략)');
  print('');

  print('📌 User Prompt:');
  print('-' * 40);
  print(prompt.buildUserPrompt());
  print('');
}

/// 2025 회고 프롬프트 테스트
void _test2025Prompt(FortuneInputData data) {
  print('━' * 80);
  print('📖 2025 을사(乙巳)년 회고 프롬프트');
  print('━' * 80);
  print('');

  final prompt = Yearly2025Prompt(inputData: data);

  print('📌 System Prompt (일부):');
  print('-' * 40);
  final systemLines = prompt.systemPrompt.split('\n').take(30).join('\n');
  print(systemLines);
  print('... (이하 생략)');
  print('');

  print('📌 User Prompt:');
  print('-' * 40);
  print(prompt.buildUserPrompt());
  print('');
}
