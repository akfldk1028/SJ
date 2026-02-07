import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../AI/services/saju_analysis_service.dart';
import '../../saju_chart/domain/entities/daeun.dart' as daeun_entities;
import '../../saju_chart/domain/services/jasi_service.dart'; // JasiMode
import '../../saju_chart/presentation/providers/saju_chart_provider.dart'
    hide sajuAnalysisService; // sajuCalculationServiceProvider, sajuAnalysisServiceProvider
import '../../saju_chart/presentation/providers/saju_analysis_repository_provider.dart'; // currentSajuAnalysisDbProvider

/// 인연 프로필 사주 분석 헬퍼
///
/// CREATE/EDIT 시 동일한 사주 분석 로직을 재사용
class RelationSajuHelper {
  /// 사주 분석 수행 및 저장
  ///
  /// [ref] - WidgetRef for provider access
  /// [profileId] - 분석할 프로필 ID
  /// [displayName] - 프로필 이름 (로깅용)
  /// [birthDate] - 생년월일
  /// [birthTimeMinutes] - 출생 시간 (분 단위, null이면 시간 모름)
  /// [birthTimeUnknown] - 출생 시간 모름 여부
  /// [birthCity] - 출생 도시
  /// [isLunar] - 음력 여부
  /// [isLeapMonth] - 윤달 여부
  /// [useYaJasi] - 야자시 사용 여부
  /// [genderName] - 성별 ('male' or 'female')
  /// [triggerGptAnalysis] - GPT 분석 트리거 여부
  ///
  /// Returns: saju_analyses ID (성공 시) or null (실패 시)
  static Future<String?> analyzeSajuProfile({
    required WidgetRef ref,
    required String profileId,
    required String displayName,
    required DateTime birthDate,
    int? birthTimeMinutes,
    bool birthTimeUnknown = false,
    required String birthCity,
    bool isLunar = false,
    bool isLeapMonth = false,
    bool useYaJasi = true,
    required String genderName,
    bool triggerGptAnalysis = true,
  }) async {
    debugPrint('🔮 [RelationSajuHelper] 사주 분석 시작: $displayName ($profileId)');

    String? analysisId;

    try {
      // 1. 사주 차트 계산 (만세력)
      debugPrint('   Step 1: 만세력 계산');
      final calculationService = ref.read(sajuCalculationServiceProvider);

      DateTime birthDateTime;
      if (birthTimeUnknown || birthTimeMinutes == null) {
        birthDateTime = DateTime(
          birthDate.year,
          birthDate.month,
          birthDate.day,
          12, 0,
        );
      } else {
        final hours = birthTimeMinutes ~/ 60;
        final minutes = birthTimeMinutes % 60;
        birthDateTime = DateTime(
          birthDate.year,
          birthDate.month,
          birthDate.day,
          hours, minutes,
        );
      }

      final chart = calculationService.calculate(
        birthDateTime: birthDateTime,
        birthCity: birthCity,
        isLunarCalendar: isLunar,
        isLeapMonth: isLeapMonth,
        birthTimeUnknown: birthTimeUnknown,
        jasiMode: useYaJasi ? JasiMode.yaJasi : JasiMode.joJasi,
      );
      debugPrint('   ✅ 만세력: ${chart.yearPillar.fullName} ${chart.monthPillar.fullName} ${chart.dayPillar.fullName} ${chart.hourPillar?.fullName ?? "시주없음"}');

      // 2. 사주 분석 계산 (대운, 십신 등)
      debugPrint('   Step 2: 사주 분석 계산');
      final analysisService = ref.read(sajuAnalysisServiceProvider);
      final daeunGender = genderName == 'female'
          ? daeun_entities.Gender.female
          : daeun_entities.Gender.male;

      final analysis = analysisService.analyze(
        chart: chart,
        gender: daeunGender,
        currentYear: DateTime.now().year,
      );
      debugPrint('   ✅ 사주 분석 계산 완료');

      // 3. DB에 저장 (saju_analyses 테이블)
      debugPrint('   Step 3: saju_analyses DB 저장');
      final dbNotifier = ref.read(currentSajuAnalysisDbProvider.notifier);
      final savedAnalysis = await dbNotifier.saveFromAnalysisWithProfileId(profileId, analysis);
      analysisId = savedAnalysis?.id;
      debugPrint('   ✅ saju_analyses 저장 완료: $analysisId');

      // 4. GPT-5.2 분석 트리거 (백그라운드)
      if (triggerGptAnalysis) {
        debugPrint('   Step 4: GPT 분석 트리거 (백그라운드)');
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          sajuAnalysisService.analyzeOnProfileSave(
            userId: user.id,
            profileId: profileId,
            runInBackground: true,
            locale: 'ko',
            onComplete: (result) {
              debugPrint('✅ [RelationSajuHelper] GPT 분석 완료: $displayName');
              debugPrint('   - 평생운세: ${result.sajuBase?.success ?? false}');
              debugPrint('   - 오늘운세: ${result.dailyFortune?.success ?? false}');
            },
          );
          debugPrint('   ✅ GPT 분석 백그라운드 시작됨');
        } else {
          debugPrint('   ⚠️ GPT 분석 스킵: 로그인 정보 없음');
        }
      }
    } catch (e) {
      debugPrint('   ⚠️ 사주 분석 실패 (무시됨): $e');
      // 분석 실패해도 프로필 저장은 계속 진행되므로 null 반환
    }

    debugPrint('🔮 [RelationSajuHelper] 사주 분석 완료: analysisId=$analysisId');
    return analysisId;
  }
}
