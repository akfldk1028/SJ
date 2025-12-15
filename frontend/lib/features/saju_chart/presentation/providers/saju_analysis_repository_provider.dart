import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/constants/cheongan_jiji.dart';
import '../../data/constants/sipsin_relations.dart';
import '../../data/constants/twelve_unsung.dart';
import '../../data/constants/twelve_sinsal.dart';
import '../../data/models/saju_analysis_db_model.dart';
import '../../data/repositories/saju_analysis_repository.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/entities/saju_analysis.dart';
import '../../domain/entities/daeun.dart';
import '../../domain/entities/pillar.dart';
import '../../domain/services/unsung_service.dart';
import '../../domain/services/twelve_sinsal_service.dart';
import '../../domain/services/daeun_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'saju_analysis_repository_provider.g.dart';

/// 사주 분석 Repository Provider
@riverpod
SajuAnalysisRepository sajuAnalysisRepository(Ref ref) {
  return SajuAnalysisRepository();
}

/// 현재 프로필의 사주 분석 DB 데이터 Provider
@riverpod
class CurrentSajuAnalysisDb extends _$CurrentSajuAnalysisDb {
  @override
  Future<SajuAnalysisDbModel?> build() async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final repository = ref.read(sajuAnalysisRepositoryProvider);
    return repository.getByProfileId(activeProfile.id);
  }

  /// 사주 분석 결과 저장
  Future<SajuAnalysisDbModel?> saveAnalysis({
    required SajuChart chart,
    Map<String, dynamic>? ohengDistribution,
    Map<String, dynamic>? dayStrength,
    Map<String, dynamic>? yongsin,
    Map<String, dynamic>? gyeokguk,
    Map<String, dynamic>? sipsinInfo,
    Map<String, dynamic>? jijangganInfo,
  }) async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final repository = ref.read(sajuAnalysisRepositoryProvider);

    // 기존 데이터 확인
    final existing = await repository.getByProfileId(activeProfile.id);

    final model = SajuAnalysisDbModel.fromSajuChart(
      id: existing?.id ?? _generateUuid(),
      profileId: activeProfile.id,
      chart: chart,
      ohengDistribution: ohengDistribution,
      dayStrength: dayStrength,
      yongsin: yongsin,
      gyeokguk: gyeokguk,
      sipsinInfo: sipsinInfo,
      jijangganInfo: jijangganInfo,
    );

    final saved = await repository.save(model);

    // 상태 갱신
    ref.invalidateSelf();

    return saved;
  }

  /// 현재 분석 결과 삭제
  Future<void> deleteAnalysis() async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) return;

    final repository = ref.read(sajuAnalysisRepositoryProvider);
    await repository.deleteByProfileId(activeProfile.id);

    ref.invalidateSelf();
  }

  /// UUID 생성
  String _generateUuid() {
    return const Uuid().v4();
  }

  /// SajuAnalysis 결과를 자동 저장
  ///
  /// 프로필 저장 후 호출하거나, 사주 분석 결과가 변경될 때 호출
  Future<SajuAnalysisDbModel?> saveFromAnalysis(SajuAnalysis analysis) async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final repository = ref.read(sajuAnalysisRepositoryProvider);

    // 기존 데이터 확인
    final existing = await repository.getByProfileId(activeProfile.id);

    // OhengDistribution을 Map으로 변환 (한글(한자) 형식)
    final ohengMap = {
      '목(木)': analysis.ohengDistribution.mok,
      '화(火)': analysis.ohengDistribution.hwa,
      '토(土)': analysis.ohengDistribution.to,
      '금(金)': analysis.ohengDistribution.geum,
      '수(水)': analysis.ohengDistribution.su,
    };

    // DayStrength를 Map으로 변환 (한글(한자) 형식)
    final dayStrengthMap = {
      'isStrong': analysis.dayStrength.isStrong,
      'score': analysis.dayStrength.score,
      'level': '${analysis.dayStrength.level.korean}(${analysis.dayStrength.level.hanja})',
      'monthScore': analysis.dayStrength.monthScore,
      'bigeopScore': analysis.dayStrength.bigeopScore,
      'inseongScore': analysis.dayStrength.inseongScore,
      'exhaustionScore': analysis.dayStrength.exhaustionScore,
    };

    // YongSin을 Map으로 변환 (한글(한자) 형식)
    // 용신/희신/기신/구신/한신은 오행(Oheng) enum
    final yongsinMap = {
      'yongsin': '${analysis.yongsin.yongsin.korean}(${analysis.yongsin.yongsin.hanja})',
      'heesin': '${analysis.yongsin.heesin.korean}(${analysis.yongsin.heesin.hanja})',
      'gisin': '${analysis.yongsin.gisin.korean}(${analysis.yongsin.gisin.hanja})',
      'gusin': '${analysis.yongsin.gusin.korean}(${analysis.yongsin.gusin.hanja})',
      'hansin': '${analysis.yongsin.hansin.korean}(${analysis.yongsin.hansin.hanja})',
      'reason': analysis.yongsin.reason,
      'method': '${analysis.yongsin.method.korean}(${analysis.yongsin.method.hanja})',
    };

    // GyeokGuk을 Map으로 변환 (한글(한자) 형식)
    final gyeokgukMap = {
      'name': '${analysis.gyeokguk.gyeokguk.korean}(${analysis.gyeokguk.gyeokguk.hanja})',
      'strength': analysis.gyeokguk.strength,
      'isSpecial': analysis.gyeokguk.isSpecial,
      'reason': analysis.gyeokguk.reason,
    };

    // SipsinInfo를 Map으로 변환 (한글(한자) 형식)
    String formatSipsin(SipSin sipsin) =>
        '${sipsin.korean}(${sipsin.hanja})';

    final sipsinMap = {
      'yearGan': formatSipsin(analysis.sipsinInfo.yearGanSipsin),
      'monthGan': formatSipsin(analysis.sipsinInfo.monthGanSipsin),
      'hourGan': analysis.sipsinInfo.hourGanSipsin != null
          ? formatSipsin(analysis.sipsinInfo.hourGanSipsin!)
          : null,
      'yearJi': formatSipsin(analysis.sipsinInfo.yearJiSipsin),
      'monthJi': formatSipsin(analysis.sipsinInfo.monthJiSipsin),
      'dayJi': formatSipsin(analysis.sipsinInfo.dayJiSipsin),
      'hourJi': analysis.sipsinInfo.hourJiSipsin != null
          ? formatSipsin(analysis.sipsinInfo.hourJiSipsin!)
          : null,
    };

    // JiJangGanInfo를 Map으로 변환 (한글(한자) 형식)
    // 천간(gan)은 cheonganHanja로, 십신(sipsin)은 SipSin enum의 hanja로 변환
    String formatGan(String gan) {
      final hanja = cheonganHanja[gan];
      return hanja != null ? '$gan($hanja)' : gan;
    }

    final jijangganMap = {
      'yearJi': analysis.jijangganInfo.yearJi
          .map((e) => {
                'gan': formatGan(e.gan),
                'sipsin': formatSipsin(e.sipsin),
                'type': e.type
              })
          .toList(),
      'monthJi': analysis.jijangganInfo.monthJi
          .map((e) => {
                'gan': formatGan(e.gan),
                'sipsin': formatSipsin(e.sipsin),
                'type': e.type
              })
          .toList(),
      'dayJi': analysis.jijangganInfo.dayJi
          .map((e) => {
                'gan': formatGan(e.gan),
                'sipsin': formatSipsin(e.sipsin),
                'type': e.type
              })
          .toList(),
      'hourJi': analysis.jijangganInfo.hourJi
          .map((e) => {
                'gan': formatGan(e.gan),
                'sipsin': formatSipsin(e.sipsin),
                'type': e.type
              })
          .toList(),
    };

    // 신살 목록을 Map으로 변환 (한글(한자) 형식)
    final sinsalListMap = analysis.sinsalList.map((result) {
      return {
        'name': '${result.sinsal.korean}(${result.sinsal.hanja})',
        'type': result.sinsal.type.korean,
        'description': result.description,
        'location': result.location,
        'relatedJi': result.relatedJi,
      };
    }).toList();

    // 12운성 분석
    final unsungResult = UnsungService.analyzeFromChart(analysis.chart);
    String formatUnsung(TwelveUnsung unsung) =>
        '${unsung.korean}(${unsung.hanja})';

    final twelveUnsungList = [
      {
        'pillar': '년주',
        'jiji': unsungResult.yearUnsung.jiji,
        'unsung': formatUnsung(unsungResult.yearUnsung.unsung),
        'strength': unsungResult.yearUnsung.strength,
        'fortuneType': unsungResult.yearUnsung.fortuneType,
      },
      {
        'pillar': '월주',
        'jiji': unsungResult.monthUnsung.jiji,
        'unsung': formatUnsung(unsungResult.monthUnsung.unsung),
        'strength': unsungResult.monthUnsung.strength,
        'fortuneType': unsungResult.monthUnsung.fortuneType,
      },
      {
        'pillar': '일주',
        'jiji': unsungResult.dayUnsung.jiji,
        'unsung': formatUnsung(unsungResult.dayUnsung.unsung),
        'strength': unsungResult.dayUnsung.strength,
        'fortuneType': unsungResult.dayUnsung.fortuneType,
      },
      if (unsungResult.hourUnsung != null)
        {
          'pillar': '시주',
          'jiji': unsungResult.hourUnsung!.jiji,
          'unsung': formatUnsung(unsungResult.hourUnsung!.unsung),
          'strength': unsungResult.hourUnsung!.strength,
          'fortuneType': unsungResult.hourUnsung!.fortuneType,
        },
    ];

    // 12신살 분석
    final twelveSinsalResult =
        TwelveSinsalService.analyzeFromChart(analysis.chart);
    String formatTwelveSinsal(TwelveSinsal sinsal) =>
        '${sinsal.korean}(${sinsal.hanja})';

    final twelveSinsalList = [
      {
        'pillar': '년지',
        'jiji': twelveSinsalResult.yearResult.jiji,
        'sinsal': formatTwelveSinsal(twelveSinsalResult.yearResult.sinsal),
        'fortuneType': twelveSinsalResult.yearResult.fortuneType,
      },
      {
        'pillar': '월지',
        'jiji': twelveSinsalResult.monthResult.jiji,
        'sinsal': formatTwelveSinsal(twelveSinsalResult.monthResult.sinsal),
        'fortuneType': twelveSinsalResult.monthResult.fortuneType,
      },
      {
        'pillar': '일지',
        'jiji': twelveSinsalResult.dayResult.jiji,
        'sinsal': formatTwelveSinsal(twelveSinsalResult.dayResult.sinsal),
        'fortuneType': twelveSinsalResult.dayResult.fortuneType,
      },
      if (twelveSinsalResult.hourResult != null)
        {
          'pillar': '시지',
          'jiji': twelveSinsalResult.hourResult!.jiji,
          'sinsal': formatTwelveSinsal(twelveSinsalResult.hourResult!.sinsal),
          'fortuneType': twelveSinsalResult.hourResult!.fortuneType,
        },
    ];

    // 대운 계산
    final daeunService = DaeUnService();
    final daeunResult = daeunService.calculate(
      chart: analysis.chart,
      gender: activeProfile.gender == '남' ? Gender.male : Gender.female,
      birthDateTime: analysis.chart.birthDateTime,
    );

    String formatPillar(Pillar pillar) {
      final ganHanja = cheonganHanja[pillar.gan] ?? '';
      final jiHanja = jijiHanja[pillar.ji] ?? '';
      return '${pillar.gan}($ganHanja)${pillar.ji}($jiHanja)';
    }

    final daeunMap = {
      'startAge': daeunResult.startAge,
      'isForward': daeunResult.isForward,
      'list': daeunResult.daeUnList.map((daeun) {
        return {
          'pillar': formatPillar(daeun.pillar),
          'startAge': daeun.startAge,
          'endAge': daeun.endAge,
          'order': daeun.order,
        };
      }).toList(),
    };

    // 현재 세운 계산
    final currentYear = DateTime.now().year;
    final birthYear = analysis.chart.birthDateTime.year;
    final currentSeunData = daeunService.calculateSeUn(currentYear, birthYear);

    final currentSeunMap = {
      'year': currentSeunData.year,
      'age': currentSeunData.age,
      'pillar': formatPillar(currentSeunData.pillar),
    };

    final model = SajuAnalysisDbModel.fromSajuChart(
      id: existing?.id ?? _generateUuid(),
      profileId: activeProfile.id,
      chart: analysis.chart,
      ohengDistribution: ohengMap,
      dayStrength: dayStrengthMap,
      yongsin: yongsinMap,
      gyeokguk: gyeokgukMap,
      sipsinInfo: sipsinMap,
      jijangganInfo: jijangganMap,
      sinsalList: sinsalListMap,
      daeun: daeunMap,
      currentSeun: currentSeunMap,
      twelveUnsung: twelveUnsungList,
      twelveSinsal: twelveSinsalList,
    );

    final saved = await repository.save(model);

    // 상태 갱신
    ref.invalidateSelf();

    return saved;
  }
}

/// 오프라인 데이터 동기화 Provider
@riverpod
class SajuAnalysisSync extends _$SajuAnalysisSync {
  @override
  Future<SyncResult?> build() async {
    // 앱 시작 시 자동 동기화 수행
    final repository = ref.read(sajuAnalysisRepositoryProvider);
    return repository.syncPendingData();
  }

  /// 수동 동기화
  Future<SyncResult> sync() async {
    final repository = ref.read(sajuAnalysisRepositoryProvider);
    final result = await repository.syncPendingData();
    ref.invalidateSelf();
    return result;
  }

  /// 원격 데이터 가져오기
  Future<int> pullFromRemote() async {
    final repository = ref.read(sajuAnalysisRepositoryProvider);
    final count = await repository.pullFromRemote();
    ref.invalidateSelf();
    return count;
  }
}

/// 모든 사주 분석 목록 Provider (로컬)
@riverpod
List<SajuAnalysisDbModel> allSajuAnalyses(Ref ref) {
  final repository = ref.watch(sajuAnalysisRepositoryProvider);
  return repository.getAllLocal();
}
