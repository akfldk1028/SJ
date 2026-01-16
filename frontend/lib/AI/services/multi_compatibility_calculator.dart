/// # 다중 궁합 계산기 (Multi-Compatibility Calculator)
///
/// ## 개요
/// 2~4명의 사주 데이터를 기반으로 다중 궁합을 계산합니다.
/// 기존 2명 궁합(`compatibility_calculator.dart`)을 확장하여 3~4명 그룹 궁합을 지원합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/services/multi_compatibility_calculator.dart`
///
/// ## Phase 50 신규 기능
/// - 3~4명 다중 궁합 분석
/// - "나 제외" (includes_owner=false) 지원
/// - 모든 조합 분석 (nC2 조합)
/// - 그룹 전체 조화도 계산
///
/// ## 계산 요소 (기존과 동일)
/// - 천간합 (5가지): 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
/// - 지지 육합 (6가지): 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합화
/// - 지지 삼합/반합 (4가지): 인오술합화, 해묘미합목, 사유축합금, 신자진합수
/// - 지지 방합 (4가지): 인묘진합목, 사오미합화, 신유술합금, 해자축합수
/// - 지지 충 (6가지): 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
/// - 지지 형: 삼형살(인사신, 축술미), 자묘형, 자형
/// - 지지 해 (6가지): 술유해, 신해해, 미자해, 축오해, 인사해, 묘진해
/// - 지지 파 (6가지): 유자파, 축진파, 인해파, 묘오파, 신사파, 술미파
/// - 원진 (6가지): 자미, 축오, 인사, 묘진, 신해, 유술
///
/// ## 다중 궁합 특수 요소
/// - 삼합 완성 (3명 지지가 삼합 완성 시 보너스)
/// - 방합 완성 (3명 지지가 방합 완성 시 보너스)
/// - 그룹 오행 균형 분석

import 'compatibility_calculator.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 다중 궁합 결과 모델
// ═══════════════════════════════════════════════════════════════════════════

/// 1:1 페어 궁합 결과
class PairCompatibility {
  /// 참가자 1 ID
  final String participant1Id;

  /// 참가자 1 이름
  final String participant1Name;

  /// 참가자 2 ID
  final String participant2Id;

  /// 참가자 2 이름
  final String participant2Name;

  /// 페어 점수 (0-100)
  final int score;

  /// 합충형해파 분석 결과
  final HapchungAnalysis hapchungDetails;

  /// 강점
  final List<String> strengths;

  /// 도전과제
  final List<String> challenges;

  /// 일간합 여부
  final bool hasDayGanHap;

  /// 일지합 여부
  final bool hasDayJiHap;

  /// 일지충 여부
  final bool hasDayJiChung;

  const PairCompatibility({
    required this.participant1Id,
    required this.participant1Name,
    required this.participant2Id,
    required this.participant2Name,
    required this.score,
    required this.hapchungDetails,
    required this.strengths,
    required this.challenges,
    this.hasDayGanHap = false,
    this.hasDayJiHap = false,
    this.hasDayJiChung = false,
  });

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'participant1_id': participant1Id,
        'participant1_name': participant1Name,
        'participant2_id': participant2Id,
        'participant2_name': participant2Name,
        'score': score,
        'hapchung_details': hapchungDetails.toJson(),
        'strengths': strengths,
        'challenges': challenges,
        'has_day_gan_hap': hasDayGanHap,
        'has_day_ji_hap': hasDayJiHap,
        'has_day_ji_chung': hasDayJiChung,
      };
}

/// 그룹 특수 합 결과 (삼합/방합 완성)
class GroupHarmony {
  /// 합 유형 (samhap, banghap)
  final String type;

  /// 합 이름 (예: "인오술합화")
  final String name;

  /// 한자 표기
  final String hanja;

  /// 결과 오행
  final String resultOheng;

  /// 참여한 참가자 ID 목록
  final List<String> participantIds;

  /// 참여한 참가자 이름 목록
  final List<String> participantNames;

  /// 해당 지지 위치 (년지, 월지 등)
  final List<String> positions;

  const GroupHarmony({
    required this.type,
    required this.name,
    required this.hanja,
    required this.resultOheng,
    required this.participantIds,
    required this.participantNames,
    required this.positions,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'hanja': hanja,
        'result_oheng': resultOheng,
        'participant_ids': participantIds,
        'participant_names': participantNames,
        'positions': positions,
      };
}

/// 그룹 오행 분포
class GroupOhengDistribution {
  final int mok; // 목(木)
  final int hwa; // 화(火)
  final int to; // 토(土)
  final int geum; // 금(金)
  final int su; // 수(水)

  const GroupOhengDistribution({
    required this.mok,
    required this.hwa,
    required this.to,
    required this.geum,
    required this.su,
  });

  /// 총합
  int get total => mok + hwa + to + geum + su;

  /// 균형도 (0-100, 100이 완벽 균형)
  int get balanceScore {
    if (total == 0) return 0;
    final avg = total / 5;
    final variance = [mok, hwa, to, geum, su]
        .map((v) => (v - avg) * (v - avg))
        .reduce((a, b) => a + b);
    final stdDev = (variance / 5).sqrt();
    // 표준편차가 작을수록 균형 잡힘
    final normalizedStdDev = (stdDev / avg).clamp(0.0, 2.0);
    return ((1 - normalizedStdDev / 2) * 100).round();
  }

  /// 부족한 오행
  List<String> get weakElements {
    final threshold = total / 10; // 10% 미만이면 부족
    final weak = <String>[];
    if (mok < threshold) weak.add('목(木)');
    if (hwa < threshold) weak.add('화(火)');
    if (to < threshold) weak.add('토(土)');
    if (geum < threshold) weak.add('금(金)');
    if (su < threshold) weak.add('수(水)');
    return weak;
  }

  /// 과다한 오행
  List<String> get strongElements {
    final threshold = total / 3; // 33% 이상이면 과다
    final strong = <String>[];
    if (mok > threshold) strong.add('목(木)');
    if (hwa > threshold) strong.add('화(火)');
    if (to > threshold) strong.add('토(土)');
    if (geum > threshold) strong.add('금(金)');
    if (su > threshold) strong.add('수(水)');
    return strong;
  }

  Map<String, dynamic> toJson() => {
        'mok': mok,
        'hwa': hwa,
        'to': to,
        'geum': geum,
        'su': su,
        'balance_score': balanceScore,
        'weak_elements': weakElements,
        'strong_elements': strongElements,
      };
}

/// 다중 궁합 계산 결과
class MultiCompatibilityResult {
  /// 전체 점수 (0-100)
  final int overallScore;

  /// 참가자 수
  final int participantCount;

  /// "나" 포함 여부
  final bool includesOwner;

  /// "나"의 프로필 ID (includesOwner=true인 경우)
  final String? ownerProfileId;

  /// 참가자 ID 목록
  final List<String> participantIds;

  /// 참가자 이름 목록
  final List<String> participantNames;

  /// 모든 1:1 페어 궁합
  final List<PairCompatibility> pairCompatibilities;

  /// 그룹 특수 합 (삼합/방합 완성)
  final List<GroupHarmony> groupHarmonies;

  /// 그룹 오행 분포
  final GroupOhengDistribution groupOhengDistribution;

  /// 그룹 강점
  final List<String> groupStrengths;

  /// 그룹 도전과제
  final List<String> groupChallenges;

  /// 전체 요약
  final String summary;

  /// 관계 유형별 점수
  final Map<String, int> categoryScores;

  const MultiCompatibilityResult({
    required this.overallScore,
    required this.participantCount,
    required this.includesOwner,
    this.ownerProfileId,
    required this.participantIds,
    required this.participantNames,
    required this.pairCompatibilities,
    required this.groupHarmonies,
    required this.groupOhengDistribution,
    required this.groupStrengths,
    required this.groupChallenges,
    required this.summary,
    required this.categoryScores,
  });

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'overall_score': overallScore,
        'participant_count': participantCount,
        'includes_owner': includesOwner,
        'owner_profile_id': ownerProfileId,
        'participant_ids': participantIds,
        'participant_names': participantNames,
        'pair_compatibilities': pairCompatibilities.map((p) => p.toJson()).toList(),
        'group_harmonies': groupHarmonies.map((h) => h.toJson()).toList(),
        'group_oheng_distribution': groupOhengDistribution.toJson(),
        'group_strengths': groupStrengths,
        'group_challenges': groupChallenges,
        'summary': summary,
        'category_scores': categoryScores,
      };

  /// 최고 궁합 페어
  PairCompatibility? get bestPair {
    if (pairCompatibilities.isEmpty) return null;
    return pairCompatibilities.reduce((a, b) => a.score > b.score ? a : b);
  }

  /// 최저 궁합 페어
  PairCompatibility? get worstPair {
    if (pairCompatibilities.isEmpty) return null;
    return pairCompatibilities.reduce((a, b) => a.score < b.score ? a : b);
  }

  /// 평균 페어 점수
  double get averagePairScore {
    if (pairCompatibilities.isEmpty) return 0;
    final total = pairCompatibilities.fold<int>(0, (sum, p) => sum + p.score);
    return total / pairCompatibilities.length;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 참가자 사주 데이터
// ═══════════════════════════════════════════════════════════════════════════

/// 참가자 사주 데이터
class ParticipantSaju {
  /// 프로필 ID
  final String id;

  /// 표시 이름
  final String name;

  /// 사주 데이터 (saju_analyses 형식)
  final Map<String, dynamic> sajuData;

  const ParticipantSaju({
    required this.id,
    required this.name,
    required this.sajuData,
  });

  /// 년간
  Cheongan? get yearGan => Cheongan.fromKoreanHanja(sajuData['year_gan'] as String?);

  /// 년지
  Jiji? get yearJi => Jiji.fromKoreanHanja(sajuData['year_ji'] as String?);

  /// 월간
  Cheongan? get monthGan => Cheongan.fromKoreanHanja(sajuData['month_gan'] as String?);

  /// 월지
  Jiji? get monthJi => Jiji.fromKoreanHanja(sajuData['month_ji'] as String?);

  /// 일간
  Cheongan? get dayGan => Cheongan.fromKoreanHanja(sajuData['day_gan'] as String?);

  /// 일지
  Jiji? get dayJi => Jiji.fromKoreanHanja(sajuData['day_ji'] as String?);

  /// 시간
  Cheongan? get hourGan => Cheongan.fromKoreanHanja(sajuData['hour_gan'] as String?);

  /// 시지
  Jiji? get hourJi => Jiji.fromKoreanHanja(sajuData['hour_ji'] as String?);

  /// 모든 천간 목록
  List<Cheongan?> get allGans => [yearGan, monthGan, dayGan, hourGan];

  /// 모든 지지 목록
  List<Jiji?> get allJis => [yearJi, monthJi, dayJi, hourJi];

  /// 사주 문자열 (디버깅용)
  String get sajuString {
    final year = '${yearGan?.korean ?? '?'}${yearJi?.korean ?? '?'}';
    final month = '${monthGan?.korean ?? '?'}${monthJi?.korean ?? '?'}';
    final day = '${dayGan?.korean ?? '?'}${dayJi?.korean ?? '?'}';
    final hour = '${hourGan?.korean ?? '?'}${hourJi?.korean ?? '?'}';
    return '$year $month $day $hour';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 다중 궁합 계산기
// ═══════════════════════════════════════════════════════════════════════════

/// 다중 궁합 계산기
///
/// 2~4명의 참가자 사주를 받아 그룹 궁합을 계산합니다.
class MultiCompatibilityCalculator {
  /// 기존 2명 궁합 계산기 (재사용)
  final CompatibilityCalculator _pairCalculator = CompatibilityCalculator();

  /// 다중 궁합 계산
  ///
  /// ## 파라미터
  /// - `participants`: 참가자 사주 데이터 목록 (2~4명)
  /// - `relationType`: 관계 유형
  /// - `includesOwner`: "나" 포함 여부
  /// - `ownerProfileId`: "나"의 프로필 ID (includesOwner=true인 경우)
  ///
  /// ## 반환
  /// `MultiCompatibilityResult` - 다중 궁합 분석 결과
  MultiCompatibilityResult calculate({
    required List<ParticipantSaju> participants,
    required String relationType,
    required bool includesOwner,
    String? ownerProfileId,
  }) {
    print('[MultiCompatibilityCalculator] 다중 궁합 계산 시작');
    print('  - 참가자 수: ${participants.length}명');
    print('  - 나 포함: $includesOwner');
    print('  - 관계 유형: $relationType');

    // 참가자 정보 출력
    for (final p in participants) {
      print('  - ${p.name}: ${p.sajuString}');
    }

    // 1. 모든 1:1 페어 궁합 계산
    final pairCompatibilities = _calculateAllPairs(participants, relationType);
    print('  - 페어 궁합 계산 완료: ${pairCompatibilities.length}개');

    // 2. 그룹 특수 합 분석 (삼합/방합 완성)
    final groupHarmonies = _analyzeGroupHarmonies(participants);
    print('  - 그룹 특수 합: ${groupHarmonies.length}개');

    // 3. 그룹 오행 분포 계산
    final groupOheng = _calculateGroupOheng(participants);
    print('  - 그룹 오행 균형도: ${groupOheng.balanceScore}점');

    // 4. 전체 점수 계산
    final overallScore = _calculateOverallScore(
      pairCompatibilities: pairCompatibilities,
      groupHarmonies: groupHarmonies,
      groupOheng: groupOheng,
      relationType: relationType,
    );

    // 5. 그룹 강점/도전과제 추출
    final groupStrengths = _extractGroupStrengths(
      pairCompatibilities,
      groupHarmonies,
      groupOheng,
    );
    final groupChallenges = _extractGroupChallenges(
      pairCompatibilities,
      groupHarmonies,
      groupOheng,
    );

    // 6. 요약 생성
    final summary = _generateSummary(
      overallScore: overallScore,
      participantCount: participants.length,
      includesOwner: includesOwner,
      relationType: relationType,
      pairCompatibilities: pairCompatibilities,
    );

    // 7. 카테고리별 점수
    final categoryScores = _calculateCategoryScores(
      pairCompatibilities: pairCompatibilities,
      groupHarmonies: groupHarmonies,
      groupOheng: groupOheng,
    );

    print('[MultiCompatibilityCalculator] 다중 궁합 계산 완료: $overallScore점');

    return MultiCompatibilityResult(
      overallScore: overallScore,
      participantCount: participants.length,
      includesOwner: includesOwner,
      ownerProfileId: ownerProfileId,
      participantIds: participants.map((p) => p.id).toList(),
      participantNames: participants.map((p) => p.name).toList(),
      pairCompatibilities: pairCompatibilities,
      groupHarmonies: groupHarmonies,
      groupOhengDistribution: groupOheng,
      groupStrengths: groupStrengths,
      groupChallenges: groupChallenges,
      summary: summary,
      categoryScores: categoryScores,
    );
  }

  /// 모든 1:1 페어 궁합 계산 (nC2 조합)
  List<PairCompatibility> _calculateAllPairs(
    List<ParticipantSaju> participants,
    String relationType,
  ) {
    final pairs = <PairCompatibility>[];

    for (int i = 0; i < participants.length; i++) {
      for (int j = i + 1; j < participants.length; j++) {
        final p1 = participants[i];
        final p2 = participants[j];

        // 기존 2명 궁합 계산기 사용
        final result = _pairCalculator.calculate(
          mySaju: p1.sajuData,
          targetSaju: p2.sajuData,
          relationType: relationType,
        );

        // 일간합, 일지합, 일지충 확인
        final hasDayGanHap = p1.dayGan != null &&
            p2.dayGan != null &&
            CheonganHap.checkHapName(p1.dayGan!, p2.dayGan!) != null;

        final hasDayJiHap = p1.dayJi != null &&
            p2.dayJi != null &&
            JijiYukhap.checkHapName(p1.dayJi!, p2.dayJi!) != null;

        final hasDayJiChung = p1.dayJi != null &&
            p2.dayJi != null &&
            JijiChung.checkChung(p1.dayJi!, p2.dayJi!) != null;

        pairs.add(PairCompatibility(
          participant1Id: p1.id,
          participant1Name: p1.name,
          participant2Id: p2.id,
          participant2Name: p2.name,
          score: result.overallScore,
          hapchungDetails: result.hapchungDetails,
          strengths: result.strengths,
          challenges: result.challenges,
          hasDayGanHap: hasDayGanHap,
          hasDayJiHap: hasDayJiHap,
          hasDayJiChung: hasDayJiChung,
        ));
      }
    }

    return pairs;
  }

  /// 그룹 특수 합 분석 (삼합/방합 완성)
  ///
  /// 3명 이상일 때 지지가 삼합이나 방합을 완성하는지 확인
  List<GroupHarmony> _analyzeGroupHarmonies(List<ParticipantSaju> participants) {
    final harmonies = <GroupHarmony>[];

    if (participants.length < 3) return harmonies;

    // 모든 3명 조합에 대해 삼합/방합 체크
    for (int i = 0; i < participants.length; i++) {
      for (int j = i + 1; j < participants.length; j++) {
        for (int k = j + 1; k < participants.length; k++) {
          final p1 = participants[i];
          final p2 = participants[j];
          final p3 = participants[k];

          // 각 위치(년지, 월지, 일지, 시지)에서 삼합/방합 체크
          final positions = ['년지', '월지', '일지', '시지'];
          final jijisLists = [
            [p1.yearJi, p2.yearJi, p3.yearJi],
            [p1.monthJi, p2.monthJi, p3.monthJi],
            [p1.dayJi, p2.dayJi, p3.dayJi],
            [p1.hourJi, p2.hourJi, p3.hourJi],
          ];

          for (int pos = 0; pos < 4; pos++) {
            final jijis = jijisLists[pos];
            if (jijis.any((j) => j == null)) continue;

            final jijiSet = jijis.map((j) => j!.korean).toSet();
            if (jijiSet.length < 3) continue; // 중복된 지지 있으면 스킵

            // 삼합 체크
            final samhapResult = JijiSamhap.checkSamhap(jijis[0]!, jijis[1]!, jijis[2]!);
            if (samhapResult != null) {
              harmonies.add(GroupHarmony(
                type: 'samhap',
                name: samhapResult.$1,
                hanja: _getHanja(samhapResult.$1),
                resultOheng: samhapResult.$2.korean,
                participantIds: [p1.id, p2.id, p3.id],
                participantNames: [p1.name, p2.name, p3.name],
                positions: [positions[pos], positions[pos], positions[pos]],
              ));
            }

            // 방합 체크 (3명의 지지가 방합을 이루는지)
            final banghapResult = _checkBanghap(jijis[0]!, jijis[1]!, jijis[2]!);
            if (banghapResult != null) {
              harmonies.add(GroupHarmony(
                type: 'banghap',
                name: banghapResult.$1,
                hanja: _getHanja(banghapResult.$1),
                resultOheng: banghapResult.$2.korean,
                participantIds: [p1.id, p2.id, p3.id],
                participantNames: [p1.name, p2.name, p3.name],
                positions: [positions[pos], positions[pos], positions[pos]],
              ));
            }
          }

          // 크로스 위치에서도 삼합/방합 체크 (예: A의 년지 + B의 월지 + C의 일지)
          harmonies.addAll(_analyzeCrossPositionHarmonies(p1, p2, p3));
        }
      }
    }

    return harmonies;
  }

  /// 크로스 위치 삼합/방합 분석
  List<GroupHarmony> _analyzeCrossPositionHarmonies(
    ParticipantSaju p1,
    ParticipantSaju p2,
    ParticipantSaju p3,
  ) {
    final harmonies = <GroupHarmony>[];
    final positions = ['년지', '월지', '일지', '시지'];

    // 각 참가자의 모든 지지 조합 체크
    final p1Jijis = [p1.yearJi, p1.monthJi, p1.dayJi, p1.hourJi];
    final p2Jijis = [p2.yearJi, p2.monthJi, p2.dayJi, p2.hourJi];
    final p3Jijis = [p3.yearJi, p3.monthJi, p3.dayJi, p3.hourJi];

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        for (int k = 0; k < 4; k++) {
          final j1 = p1Jijis[i];
          final j2 = p2Jijis[j];
          final j3 = p3Jijis[k];

          if (j1 == null || j2 == null || j3 == null) continue;

          // 삼합 체크
          final samhapResult = JijiSamhap.checkSamhap(j1, j2, j3);
          if (samhapResult != null) {
            harmonies.add(GroupHarmony(
              type: 'samhap_cross',
              name: '${samhapResult.$1} (크로스)',
              hanja: _getHanja(samhapResult.$1),
              resultOheng: samhapResult.$2.korean,
              participantIds: [p1.id, p2.id, p3.id],
              participantNames: [p1.name, p2.name, p3.name],
              positions: [positions[i], positions[j], positions[k]],
            ));
          }
        }
      }
    }

    return harmonies;
  }

  /// 방합 체크 (3개 지지)
  (String, Oheng)? _checkBanghap(Jiji a, Jiji b, Jiji c) {
    final triple = {a, b, c};

    // 방합 조합
    const banghapSets = {
      // 인묘진합목
      'in_,myo,jin': ('인묘진합목', Oheng.wood),
      // 사오미합화
      'sa,o,mi': ('사오미합화', Oheng.fire),
      // 신유술합금
      'sin_,yu,sul': ('신유술합금', Oheng.metal),
      // 해자축합수
      'hae,ja,chuk': ('해자축합수', Oheng.water),
    };

    final tripleNames = triple.map((j) => j.name).toSet();

    for (final entry in banghapSets.entries) {
      final banghapJijis = entry.key.split(',').toSet();
      if (tripleNames.containsAll(banghapJijis) && banghapJijis.containsAll(tripleNames)) {
        return entry.value;
      }
    }

    return null;
  }

  /// 그룹 오행 분포 계산
  GroupOhengDistribution _calculateGroupOheng(List<ParticipantSaju> participants) {
    int mok = 0, hwa = 0, to = 0, geum = 0, su = 0;

    for (final p in participants) {
      // 천간 오행
      for (final gan in p.allGans) {
        if (gan == null) continue;
        switch (gan.oheng) {
          case '木':
            mok++;
            break;
          case '火':
            hwa++;
            break;
          case '土':
            to++;
            break;
          case '金':
            geum++;
            break;
          case '水':
            su++;
            break;
        }
      }

      // 지지 오행
      for (final ji in p.allJis) {
        if (ji == null) continue;
        switch (ji.oheng) {
          case '木':
            mok++;
            break;
          case '火':
            hwa++;
            break;
          case '土':
            to++;
            break;
          case '金':
            geum++;
            break;
          case '水':
            su++;
            break;
        }
      }
    }

    return GroupOhengDistribution(
      mok: mok,
      hwa: hwa,
      to: to,
      geum: geum,
      su: su,
    );
  }

  /// 전체 점수 계산
  int _calculateOverallScore({
    required List<PairCompatibility> pairCompatibilities,
    required List<GroupHarmony> groupHarmonies,
    required GroupOhengDistribution groupOheng,
    required String relationType,
  }) {
    if (pairCompatibilities.isEmpty) return 50;

    // 1. 페어 점수 평균 (70% 가중치)
    final avgPairScore =
        pairCompatibilities.fold<int>(0, (sum, p) => sum + p.score) / pairCompatibilities.length;

    // 2. 그룹 특수 합 보너스 (최대 15점)
    int harmonyBonus = 0;
    for (final harmony in groupHarmonies) {
      if (harmony.type == 'samhap') {
        harmonyBonus += 8; // 삼합 완성
      } else if (harmony.type == 'banghap') {
        harmonyBonus += 6; // 방합 완성
      } else if (harmony.type == 'samhap_cross') {
        harmonyBonus += 4; // 크로스 삼합
      }
    }
    harmonyBonus = harmonyBonus.clamp(0, 15);

    // 3. 오행 균형 점수 (10% 가중치)
    final ohengScore = groupOheng.balanceScore * 0.1;

    // 4. 관계 유형별 가중치
    double relationWeight = 1.0;
    if (relationType.startsWith('family_')) {
      relationWeight = 1.1; // 가족 궁합은 조금 관대
    } else if (relationType.startsWith('work_')) {
      relationWeight = 0.95; // 업무 궁합은 더 관대
    }

    // 5. 최종 점수 계산
    final rawScore = (avgPairScore * 0.7 + harmonyBonus + ohengScore) * relationWeight;

    return rawScore.round().clamp(15, 95);
  }

  /// 카테고리별 점수 계산
  Map<String, int> _calculateCategoryScores({
    required List<PairCompatibility> pairCompatibilities,
    required List<GroupHarmony> groupHarmonies,
    required GroupOhengDistribution groupOheng,
  }) {
    // 페어 점수 평균
    final avgScore = pairCompatibilities.isEmpty
        ? 50.0
        : pairCompatibilities.fold<int>(0, (sum, p) => sum + p.score) /
            pairCompatibilities.length;

    // 합이 많은 페어 비율
    final hapRatio =
        pairCompatibilities.where((p) => p.hapchungDetails.hap.isNotEmpty).length /
            (pairCompatibilities.isEmpty ? 1 : pairCompatibilities.length);

    // 충이 있는 페어 비율
    final chungRatio =
        pairCompatibilities.where((p) => p.hapchungDetails.chung.isNotEmpty).length /
            (pairCompatibilities.isEmpty ? 1 : pairCompatibilities.length);

    return {
      'harmony': (50 + avgScore * 0.3 + hapRatio * 20 - chungRatio * 15).round().clamp(10, 100),
      'emotional': (avgScore + groupOheng.balanceScore * 0.1).round().clamp(10, 100),
      'stability':
          (60 - chungRatio * 30 + groupHarmonies.length * 5).round().clamp(10, 100),
      'synergy': (50 + groupHarmonies.length * 10 + groupOheng.balanceScore * 0.2)
          .round()
          .clamp(10, 100),
    };
  }

  /// 그룹 강점 추출
  List<String> _extractGroupStrengths(
    List<PairCompatibility> pairs,
    List<GroupHarmony> harmonies,
    GroupOhengDistribution oheng,
  ) {
    final strengths = <String>[];

    // 그룹 특수 합
    if (harmonies.isNotEmpty) {
      final samhapCount = harmonies.where((h) => h.type.contains('samhap')).length;
      final banghapCount = harmonies.where((h) => h.type == 'banghap').length;

      if (samhapCount > 0) {
        strengths.add('삼합 완성: 그룹 전체의 ${ harmonies.first.resultOheng} 기운이 강화됨');
      }
      if (banghapCount > 0) {
        strengths.add('방합 완성: 같은 계절/방위의 에너지로 조화로움');
      }
    }

    // 페어 궁합 분석
    final highScorePairs = pairs.where((p) => p.score >= 70).toList();
    if (highScorePairs.length == pairs.length && pairs.isNotEmpty) {
      strengths.add('모든 관계가 좋음: 그룹 전체의 조화가 뛰어남');
    } else if (highScorePairs.length >= pairs.length * 0.7) {
      strengths.add('대부분의 관계가 좋음: 전반적으로 잘 맞는 그룹');
    }

    // 일간합이 있는 페어
    final dayGanHapPairs = pairs.where((p) => p.hasDayGanHap).toList();
    if (dayGanHapPairs.isNotEmpty) {
      strengths.add('일간합 관계: ${dayGanHapPairs.map((p) => "${p.participant1Name}↔${p.participant2Name}").join(", ")}');
    }

    // 오행 균형
    if (oheng.balanceScore >= 70) {
      strengths.add('오행 균형: 그룹 전체의 오행이 조화롭게 분포');
    }

    // 부족한 오행 없음
    if (oheng.weakElements.isEmpty) {
      strengths.add('오행 완비: 모든 오행이 골고루 있어 상호보완');
    }

    return strengths.isEmpty ? ['그룹이 함께 발전할 수 있는 잠재력'] : strengths;
  }

  /// 그룹 도전과제 추출
  List<String> _extractGroupChallenges(
    List<PairCompatibility> pairs,
    List<GroupHarmony> harmonies,
    GroupOhengDistribution oheng,
  ) {
    final challenges = <String>[];

    // 낮은 점수 페어
    final lowScorePairs = pairs.where((p) => p.score < 50).toList();
    if (lowScorePairs.isNotEmpty) {
      for (final pair in lowScorePairs.take(2)) {
        challenges.add('${pair.participant1Name}↔${pair.participant2Name}: 서로 이해와 배려 필요');
      }
    }

    // 충이 있는 페어
    final chungPairs = pairs.where((p) => p.hapchungDetails.chung.isNotEmpty).toList();
    if (chungPairs.isNotEmpty) {
      challenges.add('충 관계 주의: ${chungPairs.map((p) => "${p.participant1Name}↔${p.participant2Name}").join(", ")}');
    }

    // 원진이 있는 페어
    final wonjinPairs = pairs.where((p) => p.hapchungDetails.wonjin.isNotEmpty).toList();
    if (wonjinPairs.isNotEmpty) {
      challenges.add('원진 관계: 오해가 생기기 쉬우니 소통을 자주');
    }

    // 오행 불균형
    if (oheng.weakElements.isNotEmpty) {
      challenges.add('부족한 오행: ${oheng.weakElements.join(", ")} - 해당 기운 보완 필요');
    }
    if (oheng.strongElements.length > 1) {
      challenges.add('과다한 오행: ${oheng.strongElements.join(", ")} - 기운 분산 필요');
    }

    return challenges.isEmpty ? ['특별한 주의사항 없음'] : challenges;
  }

  /// 요약 생성
  String _generateSummary({
    required int overallScore,
    required int participantCount,
    required bool includesOwner,
    required String relationType,
    required List<PairCompatibility> pairCompatibilities,
  }) {
    final groupName = includesOwner ? '우리 그룹' : '이 그룹';
    final countText = '$participantCount명';

    String relationName;
    if (relationType.startsWith('family_')) {
      relationName = '가족';
    } else if (relationType.startsWith('friend_')) {
      relationName = '친구';
    } else if (relationType.startsWith('work_')) {
      relationName = '업무 파트너';
    } else {
      relationName = '인연';
    }

    if (overallScore >= 80) {
      return '$groupName $countText의 $relationName 궁합이 매우 좋습니다. 서로 시너지를 내며 함께 발전할 수 있는 조합입니다.';
    } else if (overallScore >= 65) {
      return '$groupName $countText의 $relationName 궁합이 좋습니다. 대체로 잘 맞으며 서로 보완하는 관계입니다.';
    } else if (overallScore >= 50) {
      return '$groupName $countText의 $relationName 궁합은 보통입니다. 서로의 다름을 인정하고 노력하면 좋은 관계가 됩니다.';
    } else if (overallScore >= 35) {
      return '$groupName $countText의 $relationName 궁합은 노력이 필요합니다. 이해와 배려로 극복할 수 있습니다.';
    } else {
      return '$groupName $countText의 $relationName 궁합은 도전적입니다. 인내심을 갖고 소통하며 성장의 기회로 삼으세요.';
    }
  }

  /// 한자 변환 헬퍼
  String _getHanja(String name) {
    const hanjaMap = {
      '인오술합화': '寅午戌合火',
      '해묘미합목': '亥卯未合木',
      '사유축합금': '巳酉丑合金',
      '신자진합수': '申子辰合水',
      '인묘진합목': '寅卯辰合木',
      '사오미합화': '巳午未合火',
      '신유술합금': '申酉戌合金',
      '해자축합수': '亥子丑合水',
    };
    return hanjaMap[name] ?? '';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 헬퍼 확장
// ═══════════════════════════════════════════════════════════════════════════

/// num 확장 (sqrt)
extension NumExtension on num {
  double sqrt() => this < 0 ? 0 : this.toDouble().sqrt();
}

/// double 확장 (sqrt)
extension DoubleExtension on double {
  double sqrt() {
    if (this < 0) return 0;
    // Newton-Raphson method
    double guess = this / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + this / guess) / 2;
    }
    return guess;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 전역 인스턴스
// ═══════════════════════════════════════════════════════════════════════════

/// 전역 다중 궁합 계산기 인스턴스
final multiCompatibilityCalculator = MultiCompatibilityCalculator();
