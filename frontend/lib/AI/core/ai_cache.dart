/// AI 응답 캐시
/// 동일 요청 중복 호출 방지
class AICache {
  static final AICache _instance = AICache._();
  factory AICache() => _instance;
  AICache._();

  final Map<String, _CacheEntry> _cache = {};

  /// 캐시 TTL (기본 5분)
  Duration ttl = const Duration(minutes: 5);

  /// 캐시에서 가져오기
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T;
  }

  /// 캐시에 저장
  void set(String key, dynamic value, {Duration? customTtl}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(customTtl ?? ttl),
    );
  }

  /// 캐시 키 생성 (해시)
  String createKey(String provider, String prompt, [Map<String, dynamic>? params]) {
    final buffer = StringBuffer('$provider:$prompt');
    if (params != null) {
      buffer.write(':${params.hashCode}');
    }
    return buffer.toString().hashCode.toString();
  }

  /// 특정 키 삭제
  void remove(String key) => _cache.remove(key);

  /// 전체 캐시 클리어
  void clear() => _cache.clear();

  /// 만료된 캐시 정리
  void cleanup() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// 캐시 상태
  int get size => _cache.length;
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
