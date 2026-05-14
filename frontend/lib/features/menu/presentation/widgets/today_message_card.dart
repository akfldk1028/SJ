import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../AI/jina/personas/zodiac/zodiac_identity.dart';
import '../../../../AI/jina/personas/zodiac/zodiac_image_service.dart';
import '../../../../AI/jina/personas/zodiac/zodiac_resolver.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/daily_fortune_provider.dart';

/// Today message card - AI 데이터 연동 + 수호동물 캐릭터
class TodayMessageCard extends ConsumerWidget {
  const TodayMessageCard({super.key});

  static const _shadowLight = Color.fromRGBO(0, 0, 0, 0.06);
  static const _shadowDark = Color.fromRGBO(0, 0, 0, 0.3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    final affirmation = ref.watch(
      dailyFortuneProvider.select((asyncValue) {
        return asyncValue.whenData((data) => data?.affirmation);
      }),
    );

    // 활성 프로필에서 zodiac identity 계산
    final profileAsync = ref.watch(activeProfileProvider);
    ZodiacIdentity? zodiacIdentity;
    if (profileAsync.hasValue && profileAsync.value != null) {
      try {
        // 음력/진태양시/자시까지 보정한 일주(Day Pillar) 기반 매칭
        zodiacIdentity = ZodiacResolver.fromProfile(
          profileAsync.value!,
          localeCode: context.locale.languageCode,
        );
      } catch (_) {}
    }

    return affirmation.when(
      skipLoadingOnRefresh: true,
      loading: () => _buildLoadingCard(context, theme, zodiacIdentity),
      error: (_, __) => _buildCard(context, theme, 'menu.cannotLoadMessage'.tr(), zodiacIdentity),
      data: (message) {
        if (message == null) {
          return _buildLoadingCard(context, theme, zodiacIdentity);
        }
        return _buildCard(context, theme, message, zodiacIdentity);
      },
    );
  }

  Widget _buildZodiacAvatar(double size, ZodiacIdentity? identity) {
    if (identity == null) {
      return Icon(
        Icons.lightbulb_outline_rounded,
        color: Colors.amber,
        size: size * 0.55,
      );
    }

    final imageUrl = ZodiacImageService.getImageUrl(identity);
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size, height: size,
          fit: BoxFit.contain,
          placeholder: (_, __) => Text(
            identity.animalEmoji,
            style: TextStyle(fontSize: size * 0.5),
          ),
          errorWidget: (_, __, ___) => Text(
            identity.animalEmoji,
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      );
    }

    return Text(
      identity.animalEmoji,
      style: TextStyle(fontSize: size * 0.5),
    );
  }

  Widget _buildLoadingCard(BuildContext context, AppThemeExtension theme, ZodiacIdentity? identity) {
    final scale = context.scaleFactor;
    final avatarSize = (44 * scale).clamp(40.0, 56.0);
    final titleSize = context.scaledFont(12);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.scaledPadding(20)),
      child: Container(
        padding: EdgeInsets.all(context.scaledPadding(20)),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.isDark ? _shadowDark : _shadowLight,
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildZodiacAvatar(avatarSize, identity),
                SizedBox(width: context.scaledPadding(12)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.scaledPadding(10),
                    vertical: context.scaledPadding(4),
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'menu.todayMessage'.tr(),
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.scaledPadding(16)),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(width: context.scaledPadding(12)),
                Text(
                  'menu.aiPreparingMessage'.tr(),
                  style: TextStyle(
                    fontSize: context.scaledFont(14),
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppThemeExtension theme, String message, ZodiacIdentity? identity) {
    final scale = context.scaleFactor;
    final avatarSize = (44 * scale).clamp(40.0, 56.0);
    final titleSize = context.scaledFont(12);
    final messageSize = context.scaledFont(15);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.scaledPadding(20)),
      child: Container(
        padding: EdgeInsets.all(context.scaledPadding(20)),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.isDark ? _shadowDark : _shadowLight,
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildZodiacAvatar(avatarSize, identity),
                SizedBox(width: context.scaledPadding(12)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.scaledPadding(10),
                    vertical: context.scaledPadding(4),
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'menu.todayMessage'.tr(),
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.scaledPadding(16)),
            Text(
              message,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: messageSize,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
