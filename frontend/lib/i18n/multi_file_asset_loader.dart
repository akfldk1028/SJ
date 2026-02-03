import 'dart:convert';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

/// 여러 JSON 파일을 locale 폴더에서 로드하여 병합하는 AssetLoader.
///
/// 폴더 구조: lib/i18n/{locale}/{feature}.json
/// 키 접근: '{feature}.{key}'.tr()
/// 예: 'common.appName'.tr(), 'splash.loading'.tr()
class MultiFileAssetLoader extends AssetLoader {
  /// 로드할 JSON 파일명 목록 (확장자 제외)
  static const List<String> _fileNames = [
    'common',
    'splash',
    'onboarding',
    'profile',
    'saju_chat',
    'saju_chart',
    'menu',
    'settings',
    'compatibility',
    'daily_fortune',
    'monthly_fortune',
    'new_year_fortune',
    'calendar',
    'purchase',
  ];

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final merged = <String, dynamic>{};

    for (final fileName in _fileNames) {
      try {
        final jsonStr = await rootBundle.loadString(
          '$path/${locale.languageCode}/$fileName.json',
        );
        final Map<String, dynamic> data = json.decode(jsonStr);
        // feature 이름을 prefix로 사용
        merged[fileName] = data;
      } catch (_) {
        // 파일이 없으면 건너뜀
      }
    }

    return merged;
  }
}
