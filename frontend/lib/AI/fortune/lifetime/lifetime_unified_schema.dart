/// # 통합 JSON Schema (Structured Outputs)
///
/// ## 개요
/// Phase 1~4의 모든 필드를 합친 strict json_schema 정의.
/// OpenAI Structured Outputs (strict: true) 모드에서 100% valid JSON 보장.
///
/// ## 요구사항 (OpenAI strict mode)
/// - 모든 object에 additionalProperties: false
/// - 모든 property가 required에 포함
/// - 최상위 type: "json_schema"
///
/// ## 사용처
/// - ai_api_service.dart callOpenAI()의 responseFormat 파라미터

/// 평생사주 통합 분석용 json_schema response_format
///
/// Phase 1 (Foundation): mySajuIntro, my_saju_characters, wonGuk_analysis,
///   sipsung_analysis, hapchung_analysis, personality, lucky_elements
/// Phase 2 (Fortune): wealth, career, business, love, marriage
/// Phase 3 (Special): sinsal_gilseong, health, daeun_detail
/// Phase 4 (Synthesis): summary, life_cycles, peak_years, modern_interpretation
Map<String, dynamic> get sajuBaseUnifiedResponseFormat => {
  'type': 'json_schema',
  'json_schema': {
    'name': 'saju_base_unified',
    'strict': true,
    'schema': _unifiedSchema,
  },
};

Map<String, dynamic> get _unifiedSchema => {
  'type': 'object',
  'properties': {
    // ═══════════════════════════════════════════════════════════════
    // Phase 1: Foundation
    // ═══════════════════════════════════════════════════════════════
    'mySajuIntro': {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
        'ilju': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['title', 'ilju', 'reading'],
      'additionalProperties': false,
    },
    'my_saju_characters': {
      'type': 'object',
      'properties': {
        'description': {'type': 'string'},
        'year_gan': _sajuCharacterGan,
        'year_ji': _sajuCharacterJi,
        'month_gan': _sajuCharacterGan,
        'month_ji': _sajuCharacterJiSeason,
        'day_gan': _sajuCharacterGan,
        'day_ji': _sajuCharacterJi,
        'hour_gan': _sajuCharacterGan,
        'hour_ji': _sajuCharacterJi,
        'overall_reading': {'type': 'string'},
      },
      'required': [
        'description', 'year_gan', 'year_ji', 'month_gan', 'month_ji',
        'day_gan', 'day_ji', 'hour_gan', 'hour_ji', 'overall_reading',
      ],
      'additionalProperties': false,
    },
    'wonGuk_analysis': {
      'type': 'object',
      'properties': {
        'day_master': {'type': 'string'},
        'oheng_balance': {'type': 'string'},
        'singang_singak': {'type': 'string'},
        'gyeokguk': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['day_master', 'oheng_balance', 'singang_singak', 'gyeokguk', 'reading'],
      'additionalProperties': false,
    },
    'sipsung_analysis': {
      'type': 'object',
      'properties': {
        'dominant_sipsung': {'type': 'array', 'items': {'type': 'string'}},
        'weak_sipsung': {'type': 'array', 'items': {'type': 'string'}},
        'key_interactions': {'type': 'string'},
        'life_implications': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['dominant_sipsung', 'weak_sipsung', 'key_interactions', 'life_implications', 'reading'],
      'additionalProperties': false,
    },
    'hapchung_analysis': {
      'type': 'object',
      'properties': {
        'major_haps': {'type': 'array', 'items': {'type': 'string'}},
        'major_chungs': {'type': 'array', 'items': {'type': 'string'}},
        'other_interactions': {'type': 'string'},
        'overall_impact': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['major_haps', 'major_chungs', 'other_interactions', 'overall_impact', 'reading'],
      'additionalProperties': false,
    },
    'personality': {
      'type': 'object',
      'properties': {
        'core_traits': {'type': 'array', 'items': {'type': 'string'}},
        'strengths': {'type': 'array', 'items': {'type': 'string'}},
        'weaknesses': {'type': 'array', 'items': {'type': 'string'}},
        'social_style': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['core_traits', 'strengths', 'weaknesses', 'social_style', 'reading'],
      'additionalProperties': false,
    },
    'lucky_elements': {
      'type': 'object',
      'properties': {
        'colors': {'type': 'array', 'items': {'type': 'string'}},
        'directions': {'type': 'array', 'items': {'type': 'string'}},
        'numbers': {'type': 'array', 'items': {'type': 'integer'}},
        'seasons': {'type': 'string'},
        'partner_elements': {'type': 'array', 'items': {'type': 'string'}},
      },
      'required': ['colors', 'directions', 'numbers', 'seasons', 'partner_elements'],
      'additionalProperties': false,
    },
    // ═══════════════════════════════════════════════════════════════
    // Phase 2: Fortune
    // ═══════════════════════════════════════════════════════════════
    'wealth': {
      'type': 'object',
      'properties': {
        'overall_tendency': {'type': 'string'},
        'earning_style': {'type': 'string'},
        'spending_tendency': {'type': 'string'},
        'investment_aptitude': {'type': 'string'},
        'wealth_timing': {'type': 'string'},
        'cautions': {'type': 'array', 'items': {'type': 'string'}},
        'advice': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['overall_tendency', 'earning_style', 'spending_tendency', 'investment_aptitude', 'wealth_timing', 'cautions', 'advice', 'reading'],
      'additionalProperties': false,
    },
    'career': {
      'type': 'object',
      'properties': {
        'suitable_fields': {'type': 'array', 'items': {'type': 'string'}},
        'unsuitable_fields': {'type': 'array', 'items': {'type': 'string'}},
        'work_style': {'type': 'string'},
        'leadership_potential': {'type': 'string'},
        'career_timing': {'type': 'string'},
        'advice': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['suitable_fields', 'unsuitable_fields', 'work_style', 'leadership_potential', 'career_timing', 'advice', 'reading'],
      'additionalProperties': false,
    },
    'business': {
      'type': 'object',
      'properties': {
        'entrepreneurship_aptitude': {'type': 'string'},
        'suitable_business_types': {'type': 'array', 'items': {'type': 'string'}},
        'business_partner_traits': {'type': 'string'},
        'cautions': {'type': 'array', 'items': {'type': 'string'}},
        'success_factors': {'type': 'array', 'items': {'type': 'string'}},
        'advice': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['entrepreneurship_aptitude', 'suitable_business_types', 'business_partner_traits', 'cautions', 'success_factors', 'advice', 'reading'],
      'additionalProperties': false,
    },
    'love': {
      'type': 'object',
      'properties': {
        'attraction_style': {'type': 'string'},
        'dating_pattern': {'type': 'string'},
        'romantic_strengths': {'type': 'array', 'items': {'type': 'string'}},
        'romantic_weaknesses': {'type': 'array', 'items': {'type': 'string'}},
        'ideal_partner_traits': {'type': 'array', 'items': {'type': 'string'}},
        'love_timing': {'type': 'string'},
        'advice': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['attraction_style', 'dating_pattern', 'romantic_strengths', 'romantic_weaknesses', 'ideal_partner_traits', 'love_timing', 'advice', 'reading'],
      'additionalProperties': false,
    },
    'marriage': {
      'type': 'object',
      'properties': {
        'spouse_palace_analysis': {'type': 'string'},
        'marriage_timing': {'type': 'string'},
        'spouse_characteristics': {'type': 'string'},
        'married_life_tendency': {'type': 'string'},
        'cautions': {'type': 'array', 'items': {'type': 'string'}},
        'advice': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['spouse_palace_analysis', 'marriage_timing', 'spouse_characteristics', 'married_life_tendency', 'cautions', 'advice', 'reading'],
      'additionalProperties': false,
    },
    // ═══════════════════════════════════════════════════════════════
    // Phase 3: Special
    // ═══════════════════════════════════════════════════════════════
    'sinsal_gilseong': {
      'type': 'object',
      'properties': {
        'major_gilseong': {'type': 'array', 'items': {'type': 'string'}},
        'major_sinsal': {'type': 'array', 'items': {'type': 'string'}},
        'practical_implications': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['major_gilseong', 'major_sinsal', 'practical_implications', 'reading'],
      'additionalProperties': false,
    },
    'health': {
      'type': 'object',
      'properties': {
        'vulnerable_organs': {'type': 'array', 'items': {'type': 'string'}},
        'potential_issues': {'type': 'array', 'items': {'type': 'string'}},
        'mental_health': {'type': 'string'},
        'lifestyle_advice': {'type': 'array', 'items': {'type': 'string'}},
        'caution_periods': {'type': 'string'},
        'reading': {'type': 'string'},
      },
      'required': ['vulnerable_organs', 'potential_issues', 'mental_health', 'lifestyle_advice', 'caution_periods', 'reading'],
      'additionalProperties': false,
    },
    'daeun_detail': {
      'type': 'object',
      'properties': {
        'intro': {'type': 'string'},
        'cycles': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'order': {'type': 'integer'},
              'pillar': {'type': 'string'},
              'age_range': {'type': 'string'},
              'main_theme': {'type': 'string'},
              'fortune_level': {'type': 'string'},
              'reading': {'type': 'string'},
              'opportunities': {'type': 'array', 'items': {'type': 'string'}},
              'challenges': {'type': 'array', 'items': {'type': 'string'}},
            },
            'required': ['order', 'pillar', 'age_range', 'main_theme', 'fortune_level', 'reading', 'opportunities', 'challenges'],
            'additionalProperties': false,
          },
        },
        'best_daeun': {
          'type': 'object',
          'properties': {
            'period': {'type': 'string'},
            'why': {'type': 'string'},
          },
          'required': ['period', 'why'],
          'additionalProperties': false,
        },
        'worst_daeun': {
          'type': 'object',
          'properties': {
            'period': {'type': 'string'},
            'why': {'type': 'string'},
          },
          'required': ['period', 'why'],
          'additionalProperties': false,
        },
      },
      'required': ['intro', 'cycles', 'best_daeun', 'worst_daeun'],
      'additionalProperties': false,
    },
    // ═══════════════════════════════════════════════════════════════
    // Phase 4: Synthesis
    // ═══════════════════════════════════════════════════════════════
    'summary': {'type': 'string'},
    'life_cycles': {
      'type': 'object',
      'properties': {
        'youth': {'type': 'string'},
        'middle_age': {'type': 'string'},
        'later_years': {'type': 'string'},
        'key_years': {'type': 'array', 'items': {'type': 'string'}},
      },
      'required': ['youth', 'middle_age', 'later_years', 'key_years'],
      'additionalProperties': false,
    },
    'peak_years': {
      'type': 'object',
      'properties': {
        'period': {'type': 'string'},
        'age_range': {'type': 'array', 'items': {'type': 'integer'}},
        'why': {'type': 'string'},
        'what_to_prepare': {'type': 'string'},
        'what_to_do': {'type': 'string'},
        'cautions': {'type': 'string'},
      },
      'required': ['period', 'age_range', 'why', 'what_to_prepare', 'what_to_do', 'cautions'],
      'additionalProperties': false,
    },
    'modern_interpretation': {
      'type': 'object',
      'properties': {
        'dominant_elements': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'element': {'type': 'string'},
              'traditional': {'type': 'string'},
              'modern': {'type': 'string'},
              'advice': {'type': 'string'},
            },
            'required': ['element', 'traditional', 'modern', 'advice'],
            'additionalProperties': false,
          },
        },
        'career_in_ai_era': {
          'type': 'object',
          'properties': {
            'traditional_path': {'type': 'string'},
            'modern_opportunities': {'type': 'array', 'items': {'type': 'string'}},
            'digital_strengths': {'type': 'string'},
          },
          'required': ['traditional_path', 'modern_opportunities', 'digital_strengths'],
          'additionalProperties': false,
        },
        'wealth_in_ai_era': {
          'type': 'object',
          'properties': {
            'traditional_view': {'type': 'string'},
            'modern_opportunities': {'type': 'array', 'items': {'type': 'string'}},
            'risk_factors': {'type': 'string'},
          },
          'required': ['traditional_view', 'modern_opportunities', 'risk_factors'],
          'additionalProperties': false,
        },
        'relationships_in_ai_era': {
          'type': 'object',
          'properties': {
            'traditional_view': {'type': 'string'},
            'modern_networking': {'type': 'string'},
            'collaboration_style': {'type': 'string'},
          },
          'required': ['traditional_view', 'modern_networking', 'collaboration_style'],
          'additionalProperties': false,
        },
      },
      'required': ['dominant_elements', 'career_in_ai_era', 'wealth_in_ai_era', 'relationships_in_ai_era'],
      'additionalProperties': false,
    },
  },
  'required': [
    // Phase 1
    'mySajuIntro', 'my_saju_characters', 'wonGuk_analysis',
    'sipsung_analysis', 'hapchung_analysis', 'personality', 'lucky_elements',
    // Phase 2
    'wealth', 'career', 'business', 'love', 'marriage',
    // Phase 3
    'sinsal_gilseong', 'health', 'daeun_detail',
    // Phase 4
    'summary', 'life_cycles', 'peak_years', 'modern_interpretation',
  ],
  'additionalProperties': false,
};

// ═══════════════════════════════════════════════════════════════════════════
// 재사용 서브 스키마 (사주팔자 글자 정보)
// ═══════════════════════════════════════════════════════════════════════════

/// 천간 글자 (animal 없음)
Map<String, dynamic> get _sajuCharacterGan => {
  'type': 'object',
  'properties': {
    'character': {'type': 'string'},
    'reading': {'type': 'string'},
    'oheng': {'type': 'string'},
    'yin_yang': {'type': 'string'},
    'meaning': {'type': 'string'},
  },
  'required': ['character', 'reading', 'oheng', 'yin_yang', 'meaning'],
  'additionalProperties': false,
};

/// 지지 글자 (animal 포함)
Map<String, dynamic> get _sajuCharacterJi => {
  'type': 'object',
  'properties': {
    'character': {'type': 'string'},
    'reading': {'type': 'string'},
    'animal': {'type': 'string'},
    'oheng': {'type': 'string'},
    'yin_yang': {'type': 'string'},
    'meaning': {'type': 'string'},
  },
  'required': ['character', 'reading', 'animal', 'oheng', 'yin_yang', 'meaning'],
  'additionalProperties': false,
};

/// 월지 글자 (season 포함)
Map<String, dynamic> get _sajuCharacterJiSeason => {
  'type': 'object',
  'properties': {
    'character': {'type': 'string'},
    'reading': {'type': 'string'},
    'season': {'type': 'string'},
    'oheng': {'type': 'string'},
    'yin_yang': {'type': 'string'},
    'meaning': {'type': 'string'},
  },
  'required': ['character', 'reading', 'season', 'oheng', 'yin_yang', 'meaning'],
  'additionalProperties': false,
};
