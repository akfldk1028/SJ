import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/saju_analysis_db_model.dart';
import '../../data/repositories/saju_analysis_repository.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/entities/saju_analysis.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'saju_chart_provider.dart';

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

    // OhengDistribution을 Map으로 변환
    final ohengMap = {
      '목': analysis.ohengDistribution.mok,
      '화': analysis.ohengDistribution.hwa,
      '토': analysis.ohengDistribution.to,
      '금': analysis.ohengDistribution.geum,
      '수': analysis.ohengDistribution.su,
    };

    // DayStrength를 Map으로 변환
    final dayStrengthMap = {
      'isStrong': analysis.dayStrength.isStrong,
      'score': analysis.dayStrength.score,
      'level': analysis.dayStrength.level.korean,
      'monthScore': analysis.dayStrength.monthScore,
      'bigeopScore': analysis.dayStrength.bigeopScore,
      'inseongScore': analysis.dayStrength.inseongScore,
      'exhaustionScore': analysis.dayStrength.exhaustionScore,
    };

    // YongSin을 Map으로 변환
    final yongsinMap = {
      'yongsin': analysis.yongsin.yongsin.name,
      'heesin': analysis.yongsin.heesin.name,
      'gisin': analysis.yongsin.gisin.name,
      'gusin': analysis.yongsin.gusin.name,
      'hansin': analysis.yongsin.hansin.name,
      'reason': analysis.yongsin.reason,
      'method': analysis.yongsin.method.korean,
    };

    // GyeokGuk을 Map으로 변환
    final gyeokgukMap = {
      'name': analysis.gyeokguk.gyeokguk.korean,
      'hanja': analysis.gyeokguk.gyeokguk.hanja,
      'strength': analysis.gyeokguk.strength,
      'isSpecial': analysis.gyeokguk.isSpecial,
      'reason': analysis.gyeokguk.reason,
    };

    // SipsinInfo를 Map으로 변환
    final sipsinMap = {
      'yearGan': analysis.sipsinInfo.yearGanSipsin.name,
      'monthGan': analysis.sipsinInfo.monthGanSipsin.name,
      'hourGan': analysis.sipsinInfo.hourGanSipsin?.name,
      'yearJi': analysis.sipsinInfo.yearJiSipsin.name,
      'monthJi': analysis.sipsinInfo.monthJiSipsin.name,
      'dayJi': analysis.sipsinInfo.dayJiSipsin.name,
      'hourJi': analysis.sipsinInfo.hourJiSipsin?.name,
    };

    // JiJangGanInfo를 Map으로 변환
    final jijangganMap = {
      'yearJi': analysis.jijangganInfo.yearJi
          .map((e) => {'gan': e.gan, 'sipsin': e.sipsin.name, 'type': e.type})
          .toList(),
      'monthJi': analysis.jijangganInfo.monthJi
          .map((e) => {'gan': e.gan, 'sipsin': e.sipsin.name, 'type': e.type})
          .toList(),
      'dayJi': analysis.jijangganInfo.dayJi
          .map((e) => {'gan': e.gan, 'sipsin': e.sipsin.name, 'type': e.type})
          .toList(),
      'hourJi': analysis.jijangganInfo.hourJi
          .map((e) => {'gan': e.gan, 'sipsin': e.sipsin.name, 'type': e.type})
          .toList(),
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
