import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Google Play In-App Update 서비스
///
/// Android에서만 동작. iOS는 App Store 정책상 In-App Update 미지원.
/// - Immediate: 전체 화면 강제 업데이트 (critical fix)
/// - Flexible: 백그라운드 다운로드 후 사용자가 설치
class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  AppUpdateInfo? _updateInfo;

  /// 업데이트 확인 및 실행
  ///
  /// [forceImmediate] true이면 무조건 즉시 업데이트 (큰 버그 수정 시)
  Future<void> checkForUpdate({bool forceImmediate = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      _updateInfo = await InAppUpdate.checkForUpdate();

      if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        if (forceImmediate &&
            (_updateInfo?.immediateUpdateAllowed ?? false)) {
          await _performImmediateUpdate();
        } else if (_updateInfo?.flexibleUpdateAllowed ?? false) {
          await _performFlexibleUpdate();
        } else if (_updateInfo?.immediateUpdateAllowed ?? false) {
          await _performImmediateUpdate();
        }
      }
    } catch (e) {
      debugPrint('[AppUpdate] 업데이트 확인 실패: $e');
    }
  }

  /// 즉시 업데이트 (전체 화면, 앱 사용 불가)
  Future<void> _performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('[AppUpdate] 즉시 업데이트 실패: $e');
    }
  }

  /// 유연한 업데이트 (백그라운드 다운로드)
  Future<void> _performFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      // 다운로드 완료 후 설치
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('[AppUpdate] 유연한 업데이트 실패: $e');
    }
  }
}
