/// # 궁합 해석기
///
/// ## 개요
/// 두 사람의 일주(일간/일지)를 기반으로 개인화된 궁합 해석을 생성합니다.
/// 단순한 합충형해파 설명이 아닌, "내 일간이 X라서 Y와 이런 관계" 형태의 해석.
///
/// ## 사용 예시
/// ```dart
/// final interpreter = CompatibilityInterpreter(
///   myDayGan: '갑(甲)',
///   myDayJi: '자(子)',
///   targetDayGan: '기(己)',
///   targetDayJi: '축(丑)',
/// );
/// final interpretation = interpreter.generateInterpretation();
/// ```

/// 일간 오행 정보
class DayGanInfo {
  final String korean;      // 갑
  final String hanja;       // 甲
  final String oheng;       // 木
  final String ohengKorean; // 목
  final bool isYang;        // true = 양, false = 음
  final String nature;      // 성격 특성

  const DayGanInfo({
    required this.korean,
    required this.hanja,
    required this.oheng,
    required this.ohengKorean,
    required this.isYang,
    required this.nature,
  });

  String get fullName => '$korean($hanja)';
  String get ohengFull => '$ohengKorean($oheng)';
  String get yinYang => isYang ? '양(陽)' : '음(陰)';
}

/// 일지 정보
class DayJiInfo {
  final String korean;      // 자
  final String hanja;       // 子
  final String oheng;       // 水
  final String ohengKorean; // 수
  final String animal;      // 쥐
  final String nature;      // 성격 특성

  const DayJiInfo({
    required this.korean,
    required this.hanja,
    required this.oheng,
    required this.ohengKorean,
    required this.animal,
    required this.nature,
  });

  String get fullName => '$korean($hanja)';
  String get ohengFull => '$ohengKorean($oheng)';
}

/// 천간 데이터
const Map<String, DayGanInfo> _ganData = {
  '갑': DayGanInfo(
    korean: '갑', hanja: '甲', oheng: '木', ohengKorean: '목', isYang: true,
    nature: '진취적이고 리더십이 강하며 새로운 시작을 좋아합니다',
  ),
  '을': DayGanInfo(
    korean: '을', hanja: '乙', oheng: '木', ohengKorean: '목', isYang: false,
    nature: '유연하고 적응력이 뛰어나며 섬세한 감성을 지녔습니다',
  ),
  '병': DayGanInfo(
    korean: '병', hanja: '丙', oheng: '火', ohengKorean: '화', isYang: true,
    nature: '열정적이고 밝으며 사람들을 이끄는 카리스마가 있습니다',
  ),
  '정': DayGanInfo(
    korean: '정', hanja: '丁', oheng: '火', ohengKorean: '화', isYang: false,
    nature: '따뜻하고 섬세하며 내면의 빛으로 주변을 밝힙니다',
  ),
  '무': DayGanInfo(
    korean: '무', hanja: '戊', oheng: '土', ohengKorean: '토', isYang: true,
    nature: '믿음직하고 중후하며 안정감을 줍니다',
  ),
  '기': DayGanInfo(
    korean: '기', hanja: '己', oheng: '土', ohengKorean: '토', isYang: false,
    nature: '포용력이 있고 실용적이며 세심하게 배려합니다',
  ),
  '경': DayGanInfo(
    korean: '경', hanja: '庚', oheng: '金', ohengKorean: '금', isYang: true,
    nature: '결단력 있고 의리가 강하며 정의감이 있습니다',
  ),
  '신': DayGanInfo(
    korean: '신', hanja: '辛', oheng: '金', ohengKorean: '금', isYang: false,
    nature: '섬세하고 예리하며 완벽을 추구합니다',
  ),
  '임': DayGanInfo(
    korean: '임', hanja: '壬', oheng: '水', ohengKorean: '수', isYang: true,
    nature: '지혜롭고 포용력이 넓으며 큰 그림을 봅니다',
  ),
  '계': DayGanInfo(
    korean: '계', hanja: '癸', oheng: '水', ohengKorean: '수', isYang: false,
    nature: '총명하고 직관적이며 깊은 통찰력을 지녔습니다',
  ),
};

/// 지지 데이터
const Map<String, DayJiInfo> _jiData = {
  '자': DayJiInfo(
    korean: '자', hanja: '子', oheng: '水', ohengKorean: '수', animal: '쥐',
    nature: '영리하고 적응력이 뛰어나며 사교적입니다',
  ),
  '축': DayJiInfo(
    korean: '축', hanja: '丑', oheng: '土', ohengKorean: '토', animal: '소',
    nature: '성실하고 인내심이 강하며 묵묵히 노력합니다',
  ),
  '인': DayJiInfo(
    korean: '인', hanja: '寅', oheng: '木', ohengKorean: '목', animal: '호랑이',
    nature: '용감하고 리더십이 있으며 도전을 즐깁니다',
  ),
  '묘': DayJiInfo(
    korean: '묘', hanja: '卯', oheng: '木', ohengKorean: '목', animal: '토끼',
    nature: '온화하고 예술적 감각이 있으며 평화를 추구합니다',
  ),
  '진': DayJiInfo(
    korean: '진', hanja: '辰', oheng: '土', ohengKorean: '토', animal: '용',
    nature: '야망이 크고 자신감이 넘치며 변화를 이끕니다',
  ),
  '사': DayJiInfo(
    korean: '사', hanja: '巳', oheng: '火', ohengKorean: '화', animal: '뱀',
    nature: '지혜롭고 신중하며 깊은 사고력을 지녔습니다',
  ),
  '오': DayJiInfo(
    korean: '오', hanja: '午', oheng: '火', ohengKorean: '화', animal: '말',
    nature: '활발하고 열정적이며 자유를 사랑합니다',
  ),
  '미': DayJiInfo(
    korean: '미', hanja: '未', oheng: '土', ohengKorean: '토', animal: '양',
    nature: '온순하고 예술적이며 배려심이 깊습니다',
  ),
  '신': DayJiInfo(
    korean: '신', hanja: '申', oheng: '金', ohengKorean: '금', animal: '원숭이',
    nature: '재치 있고 다재다능하며 문제 해결력이 뛰어납니다',
  ),
  '유': DayJiInfo(
    korean: '유', hanja: '酉', oheng: '金', ohengKorean: '금', animal: '닭',
    nature: '꼼꼼하고 계획적이며 자기 관리에 철저합니다',
  ),
  '술': DayJiInfo(
    korean: '술', hanja: '戌', oheng: '土', ohengKorean: '토', animal: '개',
    nature: '충직하고 정의감이 강하며 책임감이 있습니다',
  ),
  '해': DayJiInfo(
    korean: '해', hanja: '亥', oheng: '水', ohengKorean: '수', animal: '돼지',
    nature: '낙천적이고 관대하며 진실된 마음을 지녔습니다',
  ),
};

/// 천간합 해석
const Map<String, String> _ganHapInterpretations = {
  '갑기': '갑목(甲木)과 기토(己土)가 만나 土로 변합니다. 진취적인 당신이 포용력 있는 상대를 만나 안정감을 얻습니다. 새로운 시작과 실용적 지원이 조화를 이루는 최고의 파트너십입니다.',
  '을경': '을목(乙木)과 경금(庚金)이 만나 金으로 변합니다. 유연한 당신과 결단력 있는 상대가 만나 서로의 부족함을 채웁니다. 부드러움과 강함이 조화된 의리 있는 관계입니다.',
  '병신': '병화(丙火)와 신금(辛金)이 만나 水로 변합니다. 열정적인 당신과 섬세한 상대가 만나 창의적 시너지를 만듭니다. 밝은 에너지와 예리함이 결합된 관계입니다.',
  '정임': '정화(丁火)와 임수(壬水)가 만나 木으로 변합니다. 따뜻한 당신과 지혜로운 상대가 만나 성장을 이끕니다. 섬세한 빛과 깊은 물이 생명을 키우는 관계입니다.',
  '무계': '무토(戊土)와 계수(癸水)가 만나 火로 변합니다. 믿음직한 당신과 총명한 상대가 만나 열정을 피웁니다. 겉으로는 담담하지만 내면이 깊은 유대입니다.',
};

/// 오행 상생 관계 해석
const Map<String, String> _ohengSangsaeng = {
  '木火': '목(木)이 화(火)를 생합니다. 당신의 성장 에너지가 상대의 열정에 불을 붙입니다.',
  '火土': '화(火)가 토(土)를 생합니다. 당신의 열정이 상대에게 안정과 신뢰를 줍니다.',
  '土金': '토(土)가 금(金)을 생합니다. 당신의 포용력이 상대의 결단력을 키웁니다.',
  '金水': '금(金)이 수(水)를 생합니다. 당신의 결단력이 상대의 지혜를 깊게 합니다.',
  '水木': '수(水)가 목(木)을 생합니다. 당신의 지혜가 상대의 성장을 돕습니다.',
};

/// 오행 상극 관계 해석
const Map<String, String> _ohengSanggeuk = {
  '木土': '목(木)이 토(土)를 극합니다. 당신의 진취적 기질이 상대의 안정을 흔들 수 있습니다. 서로의 페이스를 존중하세요.',
  '土水': '토(土)가 수(水)를 극합니다. 당신의 고집이 상대의 유연함을 막을 수 있습니다. 열린 마음이 필요합니다.',
  '水火': '수(水)가 화(火)를 극합니다. 당신의 냉철함이 상대의 열정을 꺾을 수 있습니다. 감정적 공감이 중요합니다.',
  '火金': '화(火)가 금(金)을 극합니다. 당신의 열정이 상대를 지치게 할 수 있습니다. 쉬어가는 여유가 필요합니다.',
  '金木': '금(金)이 목(木)을 극합니다. 당신의 날카로움이 상대에게 상처가 될 수 있습니다. 부드러운 표현을 연습하세요.',
};

/// 궁합 해석기
class CompatibilityInterpreter {
  final String? myDayGan;    // 내 일간 (예: "갑(甲)")
  final String? myDayJi;     // 내 일지 (예: "자(子)")
  final String? targetDayGan; // 상대 일간
  final String? targetDayJi;  // 상대 일지
  final Map<String, dynamic>? pairHapchung; // 두 사람 간 합충형해파

  CompatibilityInterpreter({
    this.myDayGan,
    this.myDayJi,
    this.targetDayGan,
    this.targetDayJi,
    this.pairHapchung,
  });

  /// 한글(한자) 형식에서 한글만 추출: "갑(甲)" → "갑"
  String _extractKorean(String? value) {
    if (value == null || value.isEmpty) return '';
    return value.split('(').first.trim();
  }

  /// 내 일간 정보
  DayGanInfo? get myGanInfo => _ganData[_extractKorean(myDayGan)];

  /// 상대 일간 정보
  DayGanInfo? get targetGanInfo => _ganData[_extractKorean(targetDayGan)];

  /// 내 일지 정보
  DayJiInfo? get myJiInfo => _jiData[_extractKorean(myDayJi)];

  /// 상대 일지 정보
  DayJiInfo? get targetJiInfo => _jiData[_extractKorean(targetDayJi)];

  /// 일주 요약 해석 생성
  CompatibilityInterpretation generateInterpretation() {
    final myGan = myGanInfo;
    final targetGan = targetGanInfo;
    final myJi = myJiInfo;
    final targetJi = targetJiInfo;

    // 일간 소개
    String myGanIntro = '';
    String targetGanIntro = '';
    if (myGan != null) {
      myGanIntro = '당신의 일간은 ${myGan.fullName} ${myGan.ohengFull}입니다. ${myGan.nature}.';
    }
    if (targetGan != null) {
      targetGanIntro = '상대의 일간은 ${targetGan.fullName} ${targetGan.ohengFull}입니다. ${targetGan.nature}.';
    }

    // 천간합 확인
    String? ganHapAnalysis;
    if (myGan != null && targetGan != null) {
      final hapKey1 = '${myGan.korean}${targetGan.korean}';
      final hapKey2 = '${targetGan.korean}${myGan.korean}';
      ganHapAnalysis = _ganHapInterpretations[hapKey1] ?? _ganHapInterpretations[hapKey2];
    }

    // 오행 상생상극 분석
    String? ohengAnalysis;
    if (myGan != null && targetGan != null) {
      final myOheng = myGan.oheng;
      final targetOheng = targetGan.oheng;

      if (myOheng == targetOheng) {
        ohengAnalysis = '둘 다 ${myGan.ohengFull} 오행으로 동질감이 있습니다. 서로를 잘 이해하지만, 비슷한 단점도 공유할 수 있습니다.';
      } else {
        // 상생 체크
        final sangsaengKey = '$myOheng$targetOheng';
        final sangsaengKeyReverse = '$targetOheng$myOheng';
        ohengAnalysis = _ohengSangsaeng[sangsaengKey] ?? _ohengSangsaeng[sangsaengKeyReverse];

        // 상극 체크
        if (ohengAnalysis == null) {
          final sanggeukKey = '$myOheng$targetOheng';
          final sanggeukKeyReverse = '$targetOheng$myOheng';
          ohengAnalysis = _ohengSanggeuk[sanggeukKey] ?? _ohengSanggeuk[sanggeukKeyReverse];
        }
      }
    }

    // 일지 분석
    String? jiAnalysis;
    if (myJi != null && targetJi != null) {
      jiAnalysis = '당신의 일지 ${myJi.fullName}(${myJi.animal})과 상대의 일지 ${targetJi.fullName}(${targetJi.animal})의 관계입니다.';
    }

    // 종합 조언
    String advice = _generateAdvice(myGan, targetGan, ganHapAnalysis != null);

    return CompatibilityInterpretation(
      myDayGanIntro: myGanIntro,
      targetDayGanIntro: targetGanIntro,
      ganHapAnalysis: ganHapAnalysis,
      ohengAnalysis: ohengAnalysis,
      jiAnalysis: jiAnalysis,
      advice: advice,
    );
  }

  /// 조언 생성
  String _generateAdvice(DayGanInfo? myGan, DayGanInfo? targetGan, bool hasGanHap) {
    if (hasGanHap) {
      return '천간합이 있어 서로에게 끌리는 인연입니다. 자연스럽게 마음이 통하니 그 흐름을 믿으세요.';
    }

    if (myGan == null || targetGan == null) {
      return '서로를 이해하고 존중하는 마음이 좋은 관계의 기본입니다.';
    }

    // 음양 조화
    if (myGan.isYang != targetGan.isYang) {
      return '음양이 조화를 이루는 관계입니다. 서로 다른 점이 오히려 매력이 됩니다. 차이를 인정하고 존중하세요.';
    } else {
      return '음양이 같아 서로 비슷한 면이 많습니다. 공감대는 쉽게 형성되지만, 때로는 양보가 필요합니다.';
    }
  }
}

/// 궁합 해석 결과
class CompatibilityInterpretation {
  final String myDayGanIntro;      // 내 일간 소개
  final String targetDayGanIntro;  // 상대 일간 소개
  final String? ganHapAnalysis;    // 천간합 분석 (있을 경우)
  final String? ohengAnalysis;     // 오행 상생상극 분석
  final String? jiAnalysis;        // 일지 분석
  final String advice;             // 종합 조언

  const CompatibilityInterpretation({
    required this.myDayGanIntro,
    required this.targetDayGanIntro,
    this.ganHapAnalysis,
    this.ohengAnalysis,
    this.jiAnalysis,
    required this.advice,
  });

  /// 모든 해석이 있는지 확인
  bool get hasContent => myDayGanIntro.isNotEmpty || targetDayGanIntro.isNotEmpty;
}
