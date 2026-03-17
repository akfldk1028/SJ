/// 지역 감지 유틸리티
/// 한국/해외 분기 판단
library;

import 'dart:io' show Platform;

class RegionDetector {
  RegionDetector._();

  /// 한국 로케일 여부 (ko_KR, ko 등)
  static bool get isKorea => Platform.localeName.startsWith('ko');
}
