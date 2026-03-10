/// AdMob + AdFit Module
/// 광고 관련 모듈 exports
library;

// Config
export 'ad_config.dart';
export 'ad_strategy.dart';

// Network
export 'ad_network_resolver.dart';
export 'region_detector.dart';

// Data Layer (Supabase queries/mutations)
export 'data/ad_data.dart';

// Service
export 'ad_service.dart';
export 'ad_tracking_service.dart';
export 'feature_unlock_service.dart';

// AdFit
export 'adfit/adfit_config.dart';
export 'adfit/adfit_service.dart';
export 'adfit/adfit_native_ad_widget.dart';

// Providers
export 'providers/ad_provider.dart';

// Widgets
export 'widgets/banner_ad_widget.dart';
export 'widgets/card_native_ad_widget.dart';
export 'widgets/inline_ad_widget.dart';
export 'widgets/native_ad_widget.dart';
export 'widgets/chat_ad_factory.dart';
