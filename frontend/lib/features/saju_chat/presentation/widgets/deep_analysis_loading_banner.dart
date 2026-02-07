/// GPT-5.2 상세 분석 로딩 배너
///
/// 첫 프로필 분석 시 ~2분 소요되므로 사용자에게 진행 상황을 안내합니다.
/// - 합충형파해, 십성, 신살 등 정밀 분석 진행
/// - 한 번 저장되면 이후에는 빠르게 로드됨
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DeepAnalysisLoadingBanner extends StatelessWidget {
  const DeepAnalysisLoadingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: appTheme.primaryColor.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 로딩 스피너
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(appTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          // 안내 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'saju_chat.deepAnalysisTitle'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: appTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'saju_chat.deepAnalysisSubtitle'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: appTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
