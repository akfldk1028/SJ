import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_theme.dart';

part 'theme_provider.g.dart';

/// 테마 설정 저장 키
const String _themeBoxName = 'theme_settings';
const String _themeTypeKey = 'selected_theme';

/// 테마 Provider - 사용자 선택 테마 관리
@riverpod
class AppThemeNotifier extends _$AppThemeNotifier {
  late Box<String> _box;

  @override
  AppThemeType build() {
    _initHive();
    return _loadSavedTheme();
  }

  /// Hive 박스 초기화
  Future<void> _initHive() async {
    if (!Hive.isBoxOpen(_themeBoxName)) {
      _box = await Hive.openBox<String>(_themeBoxName);
    } else {
      _box = Hive.box<String>(_themeBoxName);
    }
  }

  /// 저장된 테마 불러오기
  AppThemeType _loadSavedTheme() {
    try {
      if (Hive.isBoxOpen(_themeBoxName)) {
        final box = Hive.box<String>(_themeBoxName);
        final savedTheme = box.get(_themeTypeKey);
        if (savedTheme != null) {
          return AppThemeType.values.firstWhere(
            (type) => type.name == savedTheme,
            orElse: () => AppThemeType.defaultLight,
          );
        }
      }
    } catch (e) {
      debugPrint('테마 로드 오류: $e');
    }
    return AppThemeType.defaultLight;
  }

  /// 테마 변경
  Future<void> setTheme(AppThemeType themeType) async {
    state = themeType;
    await _saveTheme(themeType);
  }

  /// 테마 저장
  Future<void> _saveTheme(AppThemeType themeType) async {
    try {
      if (!Hive.isBoxOpen(_themeBoxName)) {
        await Hive.openBox<String>(_themeBoxName);
      }
      final box = Hive.box<String>(_themeBoxName);
      await box.put(_themeTypeKey, themeType.name);
    } catch (e) {
      debugPrint('테마 저장 오류: $e');
    }
  }

  /// 다음 테마로 순환 (빠른 전환용)
  Future<void> cycleTheme() async {
    final currentIndex = AppThemeType.values.indexOf(state);
    final nextIndex = (currentIndex + 1) % AppThemeType.values.length;
    await setTheme(AppThemeType.values[nextIndex]);
  }
}

/// 현재 테마 데이터 Provider
@riverpod
ThemeData currentThemeData(CurrentThemeDataRef ref) {
  final themeType = ref.watch(appThemeNotifierProvider);
  return AppTheme.getTheme(themeType);
}

/// 현재 테마 확장 데이터 Provider
@riverpod
AppThemeExtension currentThemeExtension(CurrentThemeExtensionRef ref) {
  final themeType = ref.watch(appThemeNotifierProvider);
  return AppTheme.getExtension(themeType);
}

/// 다크 모드 여부 Provider
@riverpod
bool isDarkMode(IsDarkModeRef ref) {
  final themeType = ref.watch(appThemeNotifierProvider);
  return AppTheme.getExtension(themeType).isDark;
}
