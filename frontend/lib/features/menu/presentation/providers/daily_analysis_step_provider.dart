import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 일일 운세 분석 단계
enum DailyAnalysisStep {
  idle,           // 대기
  checkingCache,  // 캐시 확인 중
  callingApi,     // Gemini API 호출 중
  saving,         // DB 저장 중
  completed,      // 완료
  error,          // 에러
}

extension DailyAnalysisStepX on DailyAnalysisStep {
  /// 0.0 ~ 1.0 진행률
  double get progress => switch (this) {
    DailyAnalysisStep.idle => 0.0,
    DailyAnalysisStep.checkingCache => 0.2,
    DailyAnalysisStep.callingApi => 0.5,
    DailyAnalysisStep.saving => 0.8,
    DailyAnalysisStep.completed => 1.0,
    DailyAnalysisStep.error => 0.0,
  };

  /// UI 표시 텍스트 (한국어 fallback)
  String get label => switch (this) {
    DailyAnalysisStep.idle => '분석 준비 중...',
    DailyAnalysisStep.checkingCache => '사주 데이터 확인 중...',
    DailyAnalysisStep.callingApi => 'AI 운세 분석 중...',
    DailyAnalysisStep.saving => '결과 저장 중...',
    DailyAnalysisStep.completed => '분석 완료!',
    DailyAnalysisStep.error => '탭하면 다시 시도합니다',
  };

  /// i18n 키 (UI에서 .tr() 호출용)
  String get labelKey => switch (this) {
    DailyAnalysisStep.idle => 'menu.analysisIdle',
    DailyAnalysisStep.checkingCache => 'menu.analysisChecking',
    DailyAnalysisStep.callingApi => 'menu.aiAnalyzing',
    DailyAnalysisStep.saving => 'menu.analysisSaving',
    DailyAnalysisStep.completed => 'menu.analysisCompleted',
    DailyAnalysisStep.error => 'menu.analysisError',
  };
}

/// 일일 운세 분석 단계 추적 (전역 싱글톤)
final dailyAnalysisStepProvider = StateProvider<DailyAnalysisStep>(
  (ref) => DailyAnalysisStep.idle,
);
