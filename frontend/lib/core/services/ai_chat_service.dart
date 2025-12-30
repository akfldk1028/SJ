import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'quota_service.dart';
import '../../features/saju_chart/domain/entities/saju_analysis.dart';
import '../../features/saju_chart/data/constants/sipsin_relations.dart';

/// AI 채팅 서비스 - Supabase Edge Function 호출
///
/// saju-chat Edge Function을 통해 Gemini AI와 대화
class AiChatService {
  static const String _functionName = 'saju-chat';

  /// AI에게 메시지 전송
  ///
  /// [messages] - 대화 히스토리 [{role: 'user'|'assistant', content: '...'}]
  /// [sajuAnalysis] - 사주 분석 데이터
  /// [profileName] - 프로필 이름
  /// [birthDate] - 생년월일 (YYYY-MM-DD)
  /// [chatType] - 상담 유형 (general, compatibility, yearly, monthly, career, love, health, wealth)
  /// [targetProfile] - 궁합 분석 시 상대방 정보
  /// [contextSummary] - 이전 대화 요약
  static Future<AiChatResult> sendMessage({
    required List<Map<String, String>> messages,
    SajuAnalysis? sajuAnalysis,
    String? profileName,
    String? birthDate,
    String chatType = 'general',
    TargetProfile? targetProfile,
    String? contextSummary,
  }) async {
    try {
      final client = SupabaseService.client;
      if (client == null) {
        return AiChatResult.failure('Supabase not initialized');
      }

      // 요청 바디 구성
      final body = <String, dynamic>{
        'messages': messages,
        if (profileName != null) 'profileName': profileName,
        if (birthDate != null) 'birthDate': birthDate,
        'chatType': chatType,
        if (contextSummary != null) 'contextSummary': contextSummary,
      };

      // 사주 분석 데이터 변환
      if (sajuAnalysis != null) {
        body['sajuAnalysis'] = _convertSajuAnalysis(sajuAnalysis);
      }

      // 궁합 대상 정보
      if (targetProfile != null) {
        body['targetProfile'] = targetProfile.toJson();
      }

      if (kDebugMode) {
        print('[AiChatService] Edge Function 호출: $_functionName');
        print('[AiChatService] 메시지 수: ${messages.length}');
      }

      // 오프라인 모드 체크
      if (client == null) {
        return AiChatResult.failure('Supabase not initialized. Please check your connection.');
      }

      // Edge Function 호출
      final response = await client.functions.invoke(
        _functionName,
        body: body,
      );

      // QUOTA_EXCEEDED 처리 (HTTP 429)
      if (response.status == 429) {
        final errorData = response.data as Map<String, dynamic>?;
        final quotaInfo = QuotaService.parseQuotaExceededResponse(errorData);
        if (kDebugMode) {
          print('[AiChatService] QUOTA_EXCEEDED: $quotaInfo');
        }
        return AiChatResult.quotaExceeded(
          message: quotaInfo?.message ?? '오늘 토큰 사용량을 초과했습니다.',
          tokensUsed: quotaInfo?.tokensUsed ?? 0,
          quotaLimit: quotaInfo?.quotaLimit ?? QuotaService.dailyQuota,
        );
      }

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] ?? 'Unknown error';
        if (kDebugMode) {
          print('[AiChatService] Error: $errorMessage');
        }
        return AiChatResult.failure(errorMessage);
      }

      final data = response.data as Map<String, dynamic>;

      // 차단된 응답
      if (data['blocked'] == true) {
        return AiChatResult.blocked(
          data['response'] ?? '죄송합니다. 해당 질문에 답변드리기 어렵습니다.',
        );
      }

      // 토큰 사용량
      AiChatUsage? usage;
      if (data['usage'] != null) {
        final usageData = data['usage'] as Map<String, dynamic>;
        usage = AiChatUsage(
          promptTokens: usageData['promptTokens'] ?? 0,
          responseTokens: usageData['responseTokens'] ?? 0,
          totalTokens: usageData['totalTokens'] ?? 0,
        );
      }

      if (kDebugMode) {
        print('[AiChatService] 응답 수신 완료');
        if (usage != null) {
          print('[AiChatService] 토큰: ${usage.totalTokens}');
        }
      }

      return AiChatResult.success(
        response: data['response'] ?? '',
        usage: usage,
        model: data['model'],
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AiChatService] Exception: $e');
      }
      return AiChatResult.failure(e.toString());
    }
  }

  /// SajuAnalysis 엔티티를 Edge Function 형식으로 변환
  static Map<String, dynamic> _convertSajuAnalysis(SajuAnalysis analysis) {
    final chart = analysis.chart;
    final oheng = analysis.ohengDistribution;
    final yongsin = analysis.yongsin;
    final sipsinInfo = analysis.sipsinInfo;
    final daeun = analysis.daeun;

    return {
      'saju': {
        'year': {
          'gan': chart.yearPillar.gan,
          'ji': chart.yearPillar.ji,
          'ganHanja': chart.yearPillar.ganHanja,
          'jiHanja': chart.yearPillar.jiHanja,
        },
        'month': {
          'gan': chart.monthPillar.gan,
          'ji': chart.monthPillar.ji,
          'ganHanja': chart.monthPillar.ganHanja,
          'jiHanja': chart.monthPillar.jiHanja,
        },
        'day': {
          'gan': chart.dayPillar.gan,
          'ji': chart.dayPillar.ji,
          'ganHanja': chart.dayPillar.ganHanja,
          'jiHanja': chart.dayPillar.jiHanja,
        },
        'hour': chart.hourPillar != null
            ? {
                'gan': chart.hourPillar!.gan,
                'ji': chart.hourPillar!.ji,
                'ganHanja': chart.hourPillar!.ganHanja,
                'jiHanja': chart.hourPillar!.jiHanja,
              }
            : {
                'gan': '?',
                'ji': '?',
              },
      },
      'oheng': {
        'wood': oheng.mok,
        'fire': oheng.hwa,
        'earth': oheng.to,
        'metal': oheng.geum,
        'water': oheng.su,
      },
      'yongsin': {
        'yongsin': _ohengToString(yongsin.yongsin),
        'huisin': _ohengToString(yongsin.heesin),
        'gisin': _ohengToString(yongsin.gisin),
        'gusin': _ohengToString(yongsin.gusin),
      },
      'sipsin': {
        'yearGan': sipsinInfo.yearGanSipsin.korean,
        'monthGan': sipsinInfo.monthGanSipsin.korean,
        if (sipsinInfo.hourGanSipsin != null)
          'hourGan': sipsinInfo.hourGanSipsin!.korean,
        'yearJi': sipsinInfo.yearJiSipsin.korean,
        'monthJi': sipsinInfo.monthJiSipsin.korean,
        'dayJi': sipsinInfo.dayJiSipsin.korean,
        if (sipsinInfo.hourJiSipsin != null)
          'hourJi': sipsinInfo.hourJiSipsin!.korean,
      },
      if (daeun != null && daeun.daeUnList.isNotEmpty)
        'daeun': daeun.daeUnList
            .map((d) => {
                  'age': d.startAge,
                  'gan': d.pillar.gan,
                  'ji': d.pillar.ji,
                })
            .toList(),
      if (analysis.currentSeun != null)
        'currentDaeun': {
          'age': analysis.currentSeun!.age,
          'gan': analysis.currentSeun!.pillar.gan,
          'ji': analysis.currentSeun!.pillar.ji,
        },
    };
  }

  /// 오행 enum을 문자열로 변환
  static String _ohengToString(Oheng oheng) {
    switch (oheng) {
      case Oheng.mok:
        return '목(木)';
      case Oheng.hwa:
        return '화(火)';
      case Oheng.to:
        return '토(土)';
      case Oheng.geum:
        return '금(金)';
      case Oheng.su:
        return '수(水)';
    }
  }
}

/// AI 응답 결과
class AiChatResult {
  final String response;
  final bool blocked;
  final bool quotaExceeded;
  final int? tokensUsed;
  final int? quotaLimit;
  final AiChatUsage? usage;
  final String? model;
  final String? error;

  AiChatResult._({
    required this.response,
    this.blocked = false,
    this.quotaExceeded = false,
    this.tokensUsed,
    this.quotaLimit,
    this.usage,
    this.model,
    this.error,
  });

  /// 성공 응답 생성
  factory AiChatResult.success({
    required String response,
    AiChatUsage? usage,
    String? model,
  }) {
    return AiChatResult._(
      response: response,
      usage: usage,
      model: model,
    );
  }

  /// 차단 응답 생성
  factory AiChatResult.blocked(String message) {
    return AiChatResult._(
      response: message,
      blocked: true,
    );
  }

  /// 에러 응답 생성
  factory AiChatResult.failure(String error) {
    return AiChatResult._(
      response: '',
      error: error,
    );
  }

  /// Quota 초과 응답 생성
  factory AiChatResult.quotaExceeded({
    required String message,
    int? tokensUsed,
    int? quotaLimit,
  }) {
    return AiChatResult._(
      response: message,
      quotaExceeded: true,
      tokensUsed: tokensUsed,
      quotaLimit: quotaLimit,
    );
  }

  bool get isSuccess => error == null && !blocked && !quotaExceeded;

  /// Quota 초과로 광고 시청이 필요한지
  bool get needsAdWatch => quotaExceeded;
}

/// AI 토큰 사용량
class AiChatUsage {
  final int promptTokens;
  final int responseTokens;
  final int totalTokens;

  AiChatUsage({
    required this.promptTokens,
    required this.responseTokens,
    required this.totalTokens,
  });
}

/// 궁합 분석 대상 프로필
class TargetProfile {
  final String name;
  final String birthDate;
  final SajuAnalysis? sajuAnalysis;
  final String? relationType;

  TargetProfile({
    required this.name,
    required this.birthDate,
    this.sajuAnalysis,
    this.relationType,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'birthDate': birthDate,
      if (relationType != null) 'relationType': relationType,
    };

    if (sajuAnalysis != null) {
      json['sajuAnalysis'] = AiChatService._convertSajuAnalysis(sajuAnalysis!);
    }

    return json;
  }
}
