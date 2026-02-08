# ad/ - AdMob Advertising Module

> **Owner**: DK
> **Package**: google_mobile_ads ^6.0.0

## Folder Structure

```
frontend/lib/ad/
+-- ad.dart                    # Module barrel exports
+-- ad_config.dart             # Ad unit IDs (test + production). AdMode toggle.
+-- ad_service.dart            # Ad loading/display service (singleton)
+-- ad_strategy.dart           # Business monetization settings
+-- ad_tracking_service.dart   # Central ad event tracking to Supabase
+-- feature_unlock_service.dart # Feature gating via ad views
+-- providers/                 # Riverpod ad state providers
+-- widgets/                   # Ad display widgets (banner, etc.)
+-- data/                      # Ad data layer
+-- DK/                        # DK private (do not modify)
```

## Key Files

| File | Purpose |
|------|---------|
| `ad_tracking_service.dart` | Central ad event tracking. `trackRewarded()` increments `rewarded_tokens_earned`. `trackNativeImpression()` increments `native_impressions`. `trackNativeClick()` increments `native_clicks`. All use `increment_ad_counter` RPC. |
| `ad_config.dart` | Ad unit IDs for Android/iOS, both test and production. `AdMode` enum controls which IDs are active. |
| `ad_strategy.dart` | Ad timing/frequency settings. `inlineAdMessageInterval=3`, `interstitialDailyLimit`, `interstitialCooldownSeconds=60`. Chat ad type selection (`nativeMedium`, `inlineBanner`, `nativeCompact`). |
| `ad_service.dart` | Singleton for loading and showing ads (banner, interstitial, rewarded). |

## Ad Types

| Type | Trigger | eCPM Range |
|------|---------|------------|
| Banner | Persistent bottom bar | $0.5-2 |
| Native (chat bubble) | Every 3 messages in chat | $3-15 |
| Interstitial | Session transitions | $2-10 |
| Rewarded | Token depletion (100%) | $10-50 |

## Token Reward System

| Trigger | Reward | Tracking Column |
|---------|--------|-----------------|
| Rewarded ad complete | 3000 tokens | `rewarded_tokens_earned` |
| Native ad click | 7000~10000 tokens | `native_tokens_earned` (via `add_native_bonus_tokens` RPC) |
| Native ad impression | count only | `native_impressions` (count only) |

## DB Columns (user_daily_token_usage)

| Column | Status | Description |
|--------|--------|-------------|
| `rewarded_tokens_earned` | Implemented | Tokens from rewarded ads |
| `native_tokens_earned` | Implemented | Tokens from native ad clicks |
| `bonus_tokens_earned` | Not implemented | Reserved for events/attendance |

## Test vs Production

Set in `ad_config.dart`:
```dart
const AdMode currentAdMode = AdMode.test; // Switch to AdMode.production before release
```

## Connections

- **Chat integration**: `features/saju_chat/presentation/widgets/conversational_ad_widget.dart` triggers ads
- **Chat provider**: `chat_provider.addBonusTokens()` receives reward amounts
- **Ad trigger**: `features/saju_chat/data/services/ad_trigger_service.dart` decides when to show ads
- **Supabase**: `increment_ad_counter` RPC, `user_daily_token_usage` table
