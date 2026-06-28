/// # 월별 간지 계산기 (오호둔법 기반)
///
/// 연도 무관하게 12개월 전체 간지/오행을 정확히 계산.
/// 기존 monthly_prompt.dart의 2025/2026 하드코딩 + 인덱스 misalignment 버그 수정.
///
/// ## 알고리즘
/// - 년간: (year - 4) % 10  → 0=갑 ... 9=계
/// - 오호둔(五虎遁): 년간 → 정월(인월) 첫 천간
///   - 갑/기 → 병, 을/경 → 무, 병/신 → 경, 정/임 → 임, 무/계 → 갑
/// - 12개월 천간: 인월부터 +1씩 순환 (mod 10)
/// - 12개월 지지: 寅 卯 辰 巳 午 未 申 酉 戌 亥 子 丑 (고정)
///
/// ## 절기 기준
/// 사주력은 24절기로 월이 바뀝니다. 본 계산기는 양력 날짜를 받아
/// 가장 최근 지나간 절기 기준으로 사주년/사주월을 결정합니다.
/// 절기 일자는 ±1일 오차 가능 (정밀도가 필요하면 천문연구원 만세력 참조).

class MonthlyGanjiCalculator {
  // 천간/지지 (한글, 한자, 오행)
  static const _stems = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
  static const _stemsHanja = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  static const _stemElement = ['목', '목', '화', '화', '토', '토', '금', '금', '수', '수'];

  // 12개월 지지 (인월=1부터 축월=12까지)
  static const _branches = ['인', '묘', '진', '사', '오', '미', '신', '유', '술', '해', '자', '축'];
  static const _branchesHanja = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];
  static const _branchElement = ['목', '목', '토', '화', '화', '토', '금', '금', '토', '수', '수', '토'];

  // 오호둔: 년간 index → 인월 첫 천간 index
  // 갑(0)/기(5) → 병(2)
  // 을(1)/경(6) → 무(4)
  // 병(2)/신(7) → 경(6)
  // 정(3)/임(8) → 임(8)
  // 무(4)/계(9) → 갑(0)
  static const _ohHoDun = [2, 4, 6, 8, 0, 2, 4, 6, 8, 0];

  // 절기 대략 일자 [Gregorian month, day] (입춘부터 순서대로)
  // 입춘→인월(사주1), 경칩→묘월(2), ... 소한→축월(12)
  static const _solarTerms = [
    [2, 4],   // 입춘 → 인월
    [3, 6],   // 경칩 → 묘월
    [4, 5],   // 청명 → 진월
    [5, 5],   // 입하 → 사월
    [6, 6],   // 망종 → 오월
    [7, 7],   // 소서 → 미월
    [8, 8],   // 입추 → 신월
    [9, 8],   // 백로 → 유월
    [10, 8],  // 한로 → 술월
    [11, 7],  // 입동 → 해월
    [12, 7],  // 대설 → 자월
    [1, 6],   // 소한 → 축월
  ];

  /// 년간 index (0=갑, 1=을, ..., 9=계)
  static int yearStemIndex(int year) => (year - 4) % 10;

  /// 년지 index (0=자, 1=축, ..., 11=해)
  static int yearBranchIndex(int year) => (year - 4) % 12;

  /// 년 간지 한글 (예: "병오")
  static String yearGanji(int year) {
    final s = yearStemIndex(year);
    final b = yearBranchIndex(year);
    // 년지 순서: 자(0), 축(1), 인(2), 묘(3), 진(4), 사(5), 오(6), 미(7), 신(8), 유(9), 술(10), 해(11)
    const yearBranches = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];
    return '${_stems[s]}${yearBranches[b]}';
  }

  /// 사주년 결정 (입춘 전이면 전년도)
  static int getSajuYear(DateTime date) {
    if (date.month < 2) return date.year - 1;
    if (date.month == 2 && date.day < 4) return date.year - 1;
    return date.year;
  }

  /// 사주월 index (1=인월, 12=축월) — 양력 날짜 기준 절기로 결정
  ///
  /// 사주월은 양력 N월의 절기 시작일을 기준으로 전환:
  /// - 절기 전 (해당 월 1~ 절기 전날) → 전 사주월 유지
  /// - 절기 후 (해당 월 절기일~말일) → 새 사주월 시작
  ///
  /// 예시 (m=3, 경칩 3/6):
  /// - 3/1~3/5 → saju 1 (인월) 유지
  /// - 3/6~3/31 → saju 2 (묘월) 시작
  ///
  /// 절기 일자는 ±1일 오차. 정밀도가 필요하면 만세력 API 사용.
  static int getSajuMonthIndex(DateTime date) {
    final m = date.month;
    final d = date.day;

    // 1월 (전년도 사주의 마지막 두 달):
    // - 1/1~1/5 (소한 전) → saju 11 (자월, 전년도 사주의 11번째 달)
    // - 1/6~1/31 (소한 후) → saju 12 (축월)
    if (m == 1) return d < 6 ? 11 : 12;

    // 2월 (사주년 전환):
    // - 2/1~2/3 (입춘 전) → saju 12 (전년도 축월)
    // - 2/4~2/28(29) (입춘 후) → saju 1 (당해 인월)
    if (m == 2) return d < 4 ? 12 : 1;

    // 3~12월: 각 월의 절기 일자 기준
    // _solarTerms[m-2]는 해당 양력월의 절기 (m=3 → index 1 = 경칩)
    final term = _solarTerms[m - 2];
    if (d < term[1]) {
      // 절기 전 → 전 사주월 유지 (m=3이면 saju 1=인월)
      return m - 2;
    }
    // 절기 후 → 새 사주월 시작 (m=3이면 saju 2=묘월, m=5이면 saju 4=사월, m=12면 saju 11=자월)
    return m - 1;
  }

  /// 12개월 전체 간지/오행 테이블 (key: 사주월 1~12)
  ///
  /// [sajuYear] 사주년 (입춘 기준, 예: 2026)
  static Map<int, MonthGanji> getTwelveMonths(int sajuYear) {
    final yearStemIdx = yearStemIndex(sajuYear);
    final firstStemIdx = _ohHoDun[yearStemIdx];

    final result = <int, MonthGanji>{};
    for (int i = 0; i < 12; i++) {
      final stemIdx = (firstStemIdx + i) % 10;
      result[i + 1] = MonthGanji(
        sajuMonth: i + 1,
        stem: _stems[stemIdx],
        stemHanja: _stemsHanja[stemIdx],
        stemElement: _stemElement[stemIdx],
        branch: _branches[i],
        branchHanja: _branchesHanja[i],
        branchElement: _branchElement[i],
      );
    }
    return result;
  }

  /// 특정 양력 날짜 기준 현재 사주월 간지
  static MonthGanji getCurrentMonthGanji(DateTime date) {
    final sajuYear = getSajuYear(date);
    final sajuMonth = getSajuMonthIndex(date);
    return getTwelveMonths(sajuYear)[sajuMonth]!;
  }

  /// 양력 월(1~12) → 사주월 매핑 + 간지 (UI 호환용)
  ///
  /// 양력 월의 "대부분"을 차지하는 사주월 사용.
  /// - 양력 1월 → 전년도 사주의 축월(12) — 소한(1/6) 후가 대부분, 입춘 전이라 전년도 사주년
  /// - 양력 2월 → 당해 사주의 인월(1) — 입춘(2/4) 후가 대부분
  /// - 양력 5월 → 당해 사주의 사월(4) — 입하(5/5) 후가 대부분
  /// - 양력 12월 → 당해 사주의 자월(11) — 대설(12/7) 후가 대부분
  ///
  /// [sajuYearOrCalendarYear] 양력년(혹은 사주년). 양력 2월~12월은 동일,
  /// 양력 1월은 전년도 사주년이 적용되므로 내부에서 (year - 1) 사용.
  static MonthGanji getByGregorianMonth(int gregorianMonth, int sajuYearOrCalendarYear) {
    if (gregorianMonth == 1) {
      // 양력 1월 = 전년도 사주의 축월(12)
      return getTwelveMonths(sajuYearOrCalendarYear - 1)[12]!;
    }
    // 양력 2~12월 = 당해 사주의 (gregorianMonth - 1)월
    return getTwelveMonths(sajuYearOrCalendarYear)[gregorianMonth - 1]!;
  }
}

/// 월간지 데이터 클래스
class MonthGanji {
  /// 사주월 (1=인월, 2=묘월, ..., 12=축월)
  final int sajuMonth;

  /// 천간 (한글 1자)
  final String stem;

  /// 천간 (한자 1자)
  final String stemHanja;

  /// 천간 오행 (목/화/토/금/수)
  final String stemElement;

  /// 지지 (한글 1자)
  final String branch;

  /// 지지 (한자 1자)
  final String branchHanja;

  /// 지지 오행 (목/화/토/금/수)
  final String branchElement;

  const MonthGanji({
    required this.sajuMonth,
    required this.stem,
    required this.stemHanja,
    required this.stemElement,
    required this.branch,
    required this.branchHanja,
    required this.branchElement,
  });

  /// 한글 간지 (예: "계사")
  String get pillar => '$stem$branch';

  /// 한자 간지 (예: "癸巳")
  String get pillarHanja => '$stemHanja$branchHanja';

  /// 표시용 (예: "계사(癸巳)")
  String get displayName => '$pillar($pillarHanja)';

  /// 사주월 한글 이름 (예: "사월")
  String get sajuMonthName => '$branch월';

  Map<String, String> toMap() => {
        'sajuMonth': '$sajuMonth',
        'pillar': pillar,
        'pillarHanja': pillarHanja,
        'stem': stem,
        'stemHanja': stemHanja,
        'stemElement': stemElement,
        'branch': branch,
        'branchHanja': branchHanja,
        'branchElement': branchElement,
      };
}
