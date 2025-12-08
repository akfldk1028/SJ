/// 사주팔자 계산 Feature
/// 만세력 계산 로직 및 사주 차트 생성
/// 포스텔러 수준의 상세 분석 제공
library;

// =============================================================================
// Constants (상수 데이터)
// =============================================================================
export 'data/constants/cheongan_jiji.dart';
export 'data/constants/gapja_60.dart';
export 'data/constants/solar_term_table.dart';
export 'data/constants/dst_periods.dart';
export 'data/constants/jijanggan_table.dart';
export 'data/constants/sipsin_relations.dart';
export 'data/constants/lunar_data/lunar_table.dart';

// =============================================================================
// Domain Entities (엔티티)
// =============================================================================
export 'domain/entities/pillar.dart';
export 'domain/entities/saju_chart.dart';
export 'domain/entities/lunar_date.dart';
export 'domain/entities/solar_term.dart';
export 'domain/entities/day_strength.dart';
export 'domain/entities/gyeokguk.dart';
export 'domain/entities/sinsal.dart';
export 'domain/entities/yongsin.dart';
export 'domain/entities/daeun.dart';
export 'domain/entities/saju_analysis.dart';

// =============================================================================
// Domain Services (서비스)
// =============================================================================
// 기본 계산 서비스
export 'domain/services/lunar_solar_converter.dart';
export 'domain/services/solar_term_service.dart';
export 'domain/services/true_solar_time_service.dart';
export 'domain/services/dst_service.dart';
export 'domain/services/jasi_service.dart';
export 'domain/services/saju_calculation_service.dart';

// 분석 서비스 (신규)
export 'domain/services/day_strength_service.dart';
export 'domain/services/gyeokguk_service.dart';
export 'domain/services/sinsal_service.dart';
export 'domain/services/yongsin_service.dart';
export 'domain/services/daeun_service.dart';
export 'domain/services/saju_analysis_service.dart';

// =============================================================================
// Data Models (데이터 모델)
// =============================================================================
export 'data/models/pillar_model.dart';
export 'data/models/saju_chart_model.dart';
