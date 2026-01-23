/// # 2026 신년운세 서비스
///
/// ## 개요
/// 2026 신년운세 분석 오케스트레이션
/// 캐시 확인 → API 호출 → 저장
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2026/yearly_2026_service.dart`

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../../services/ai_api_service.dart';
import '../common/fortune_input_data.dart';
import 'yearly_2026_mutations.dart';
import 'yearly_2026_prompt.dart';
import 'yearly_2026_queries.dart';

/// 2026 신년운세 분석 결과
class Yearly2026Result {
  final bool success;
  final Map<String, dynamic>? content;
  final String? errorMessage;
  final bool fromCache;
  final int? promptTokens;
  final int? completionTokens;
  final double? totalCost;

  const Yearly2026Result({
    required this.success,
    this.content,
    this.errorMessage,
    this.fromCache = false,
    this.promptTokens,
    this.completionTokens,
    this.totalCost,
  });

  factory Yearly2026Result.fromCache(Map<String, dynamic> content) {
    return Yearly2026Result(
      success: true,
      content: content,
      fromCache: true,
    );
  }

  factory Yearly2026Result.error(String message) {
    return Yearly2026Result(
      success: false,
      errorMessage: message,
    );
  }
}

/// 2026 신년운세 서비스
class Yearly2026Service {
  final SupabaseClient _supabase;
  final AIApiService _aiApiService;

  late final Yearly2026Queries _queries;
  late final Yearly2026Mutations _mutations;

  Yearly2026Service({
    required SupabaseClient supabase,
    required AIApiService aiApiService,
  })  : _supabase = supabase,
        _aiApiService = aiApiService {
    _queries = Yearly2026Queries(_supabase);
    _mutations = Yearly2026Mutations(_supabase);
  }

  /// 2026 신년운세 분석 실행
  ///
  /// ## 플로우
  /// 1. 캐시 확인 → 있으면 반환
  /// 2. 프롬프트 생성
  /// 3. GPT-5-mini API 호출
  /// 4. 결과 저장
  /// 5. 결과 반환
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [inputData] 입력 데이터 (saju_base 포함)
  /// [forceRefresh] 캐시 무시하고 재분석
  Future<Yearly2026Result> analyze({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    bool forceRefresh = false,
  }) async {
    print('[Yearly2026Service] 🚀 분석 시작: profileId=$profileId');

    try {
      // 1. 캐시 확인 (forceRefresh가 아닐 때)
      if (!forceRefresh) {
        final cachedContent = await _queries.getContent(profileId);
        if (cachedContent != null) {
          print('[Yearly2026Service] 📦 캐시에서 반환');
          return Yearly2026Result.fromCache(cachedContent);
        }
      }

      // 2. 프롬프트 생성
      print('[Yearly2026Service] 📝 프롬프트 생성');
      final prompt = Yearly2026Prompt(inputData: inputData);

      // 3. GPT-5-mini API 호출
      print('[Yearly2026Service] 🤖 API 호출 시작...');
      final apiResponse = await _aiApiService.chat(
        model: prompt.modelName,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(),
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        userId: userId,
      );
      print('[Yearly2026Service] 📡 API 응답: success=${apiResponse.success}');

      if (!apiResponse.success) {
        print('[Yearly2026Service] ❌ API 실패: ${apiResponse.errorMessage}');
        return Yearly2026Result.error(
          apiResponse.errorMessage ?? 'API 호출 실패',
        );
      }

      // 4. 응답 파싱
      print('[Yearly2026Service] 🔍 응답 파싱 시작');
      final content = _parseResponse(apiResponse.content ?? '');
      if (content == null) {
        print('[Yearly2026Service] ❌ 파싱 실패');
        return Yearly2026Result.error('응답 파싱 실패');
      }
      print('[Yearly2026Service] ✅ 파싱 성공');

      // 5. 비용 계산
      final totalCost = OpenAIPricing.calculateCost(
        model: prompt.modelName,
        promptTokens: apiResponse.promptTokens ?? 0,
        completionTokens: apiResponse.completionTokens ?? 0,
      );
      print('[Yearly2026Service] 💰 비용: \$$totalCost');

      // 6. 결과 저장 (전체 프롬프트 포함)
      print('[Yearly2026Service] 💾 DB 저장 시작...');
      await _mutations.save(
        userId: userId,
        profileId: profileId,
        content: content,
        modelName: prompt.modelName,
        promptTokens: apiResponse.promptTokens ?? 0,
        completionTokens: apiResponse.completionTokens ?? 0,
        totalCost: totalCost,
        inputData: inputData,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(),
      );
      print('[Yearly2026Service] ✅ DB 저장 완료!');

      // 7. 결과 반환
      return Yearly2026Result(
        success: true,
        content: content,
        fromCache: false,
        promptTokens: apiResponse.promptTokens,
        completionTokens: apiResponse.completionTokens,
        totalCost: totalCost,
      );
    } catch (e) {
      print('[Yearly2026Service] ❌ 에러: $e');
      return Yearly2026Result.error(e.toString());
    }
  }

  /// 캐시 확인만 (분석 없이)
  Future<Map<String, dynamic>?> getCached(String profileId) {
    return _queries.getContent(profileId);
  }

  /// 캐시 존재 여부 확인
  Future<bool> hasCached(String profileId) {
    return _queries.exists(profileId);
  }

  /// 캐시 무효화
  Future<void> invalidateCache(String profileId) {
    return _mutations.invalidate(profileId);
  }

  /// API 응답 파싱 + 구조 검증
  Map<String, dynamic>? _parseResponse(String response) {
    try {
      // JSON 블록 추출 시도
      String jsonStr = response;

      // ```json ... ``` 형식 처리
      final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(response);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(1) ?? response;
      } else {
        // { ... } 형식만 추출
        final braceMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (braceMatch != null) {
          jsonStr = braceMatch.group(0) ?? response;
        }
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 🔒 v3.1: 2026 신년운세 구조 검증 (monthly fortune 혼동 방지!)
      if (!_validateYearly2026Structure(parsed)) {
        print('[Yearly2026Service] ❌ 응답 구조가 2026 신년운세 포맷이 아님!');
        print('[Yearly2026Service] 받은 키: ${parsed.keys.toList()}');
        return null;
      }

      return parsed;
    } catch (e) {
      print('[Yearly2026Service] ❌ JSON 파싱 에러: $e');
      return null;
    }
  }

  /// 2026 신년운세 구조 검증
  /// - 필수 키: year=2026, lucky, overview, categories
  /// - 금지 키: months, currentMonth, current (이건 monthly fortune 포맷!)
  bool _validateYearly2026Structure(Map<String, dynamic> json) {
    // 필수 키 확인
    final requiredKeys = ['year', 'lucky', 'overview', 'categories'];
    for (final key in requiredKeys) {
      if (!json.containsKey(key)) {
        print('[Yearly2026Service] ⚠️ 필수 키 없음: $key');
        return false;
      }
    }

    // year 값 확인 (2026이어야 함)
    final year = json['year'];
    if (year != 2026) {
      print('[Yearly2026Service] ⚠️ year가 2026이 아님: $year');
      return false;
    }

    // monthly fortune 구조 감지 (이건 잘못된 응답!)
    final monthlyKeys = ['months', 'currentMonth', 'current'];
    for (final key in monthlyKeys) {
      if (json.containsKey(key)) {
        print('[Yearly2026Service] ⚠️ monthly fortune 키 감지: $key');
        return false;
      }
    }

    return true;
  }
}
