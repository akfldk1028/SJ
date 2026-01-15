/// 대화형 네이티브 광고 버블
///
/// 채팅 메시지처럼 보이는 네이티브 광고 위젯
/// Provider에서 로드된 광고를 표시
/// 위젯 트리 최적화: const 생성자, 100줄 이하
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/conversational_ad_model.dart';

/// 모바일 플랫폼 체크
bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// 대화형 네이티브 광고 버블
///
/// Provider에서 로드한 NativeAd를 전달받아 표시
/// 채팅 버블 스타일로 자연스럽게 노출
class AdNativeBubble extends StatelessWidget {
  /// 로드된 네이티브 광고
  final NativeAd? nativeAd;

  /// 광고 로드 상태
  final AdLoadState loadState;

  /// 광고 닫기 콜백
  final VoidCallback? onDismiss;

  /// 페르소나 이모지
  final String personaEmoji;

  const AdNativeBubble({
    super.key,
    this.nativeAd,
    this.loadState = AdLoadState.idle,
    this.onDismiss,
    this.personaEmoji = '📢',
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    // Web에서는 간단한 placeholder 표시
    if (!_isMobile) {
      return _buildWebPlaceholder(context, theme);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 광고 아바타
          _buildAdAvatar(theme),
          const SizedBox(width: 8),
          // 광고 버블
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 광고 라벨
                _buildAdLabel(theme),
                const SizedBox(height: 4),
                // 광고 컨텐츠
                _buildAdContent(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdAvatar(AppThemeExtension theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha:0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          personaEmoji,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAdLabel(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha:0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 10,
            color: Color(0xFFD4AF37),
          ),
          const SizedBox(width: 3),
          Text(
            '후원자 소개',
            style: TextStyle(
              fontSize: 10,
              color: theme.isDark ? const Color(0xFFD4AF37) : const Color(0xFFB8962E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdContent(BuildContext context, AppThemeExtension theme) {
    // 로딩 중
    if (loadState == AdLoadState.loading) {
      return _buildLoadingState(theme);
    }

    // 로드 실패
    if (loadState == AdLoadState.failed || nativeAd == null) {
      return _buildErrorState(theme);
    }

    // 광고 표시
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120,
        maxHeight: 280,
      ),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha:0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: nativeAd!),
    );
  }

  Widget _buildLoadingState(AppThemeExtension theme) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFD4AF37),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha:0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(
          color: theme.textSecondary.withValues(alpha:0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '광고를 불러오지 못했습니다',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          if (onDismiss != null)
            TextButton(
              onPressed: onDismiss,
              child: Text(
                '닫기',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebPlaceholder(BuildContext context, AppThemeExtension theme) {
    if (kDebugMode) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.textSecondary.withValues(alpha:0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.desktop_mac, color: theme.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '[Web] 광고는 모바일에서만 표시됩니다',
                style: TextStyle(color: theme.textSecondary, fontSize: 12),
              ),
            ),
            if (onDismiss != null)
              TextButton(
                onPressed: onDismiss,
                child: const Text('확인'),
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
