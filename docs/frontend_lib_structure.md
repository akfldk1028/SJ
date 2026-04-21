# frontend/lib 폴더 구조

> 2026-03-24 기준 | 총 Dart 파일 약 370개

```
frontend/lib/
├── main.dart                              # 앱 진입점
├── app.dart                               # MaterialApp 설정
├── test_edge_function.dart                # Edge Function 테스트
│
├── AI/                                    # AI 모듈 (GPT-5.2 + Gemini 3.0)
│   ├── ai.dart                            # barrel export
│   ├── base/                              # (빈 폴더 or 기반 클래스)
│   ├── core/                              # AI 공통 설정/유틸
│   │   ├── ai_cache.dart
│   │   ├── ai_config.dart
│   │   ├── ai_constants.dart
│   │   ├── ai_logger.dart
│   │   ├── ai_simple_logger.dart
│   │   ├── base_provider.dart
│   │   ├── file_logger.dart
│   │   ├── file_logger_stub.dart
│   │   └── file_logger_web.dart
│   ├── common/                            # JH_AI + Jina 공동 모듈
│   │   ├── data/
│   │   │   ├── ai_context.dart
│   │   │   ├── ai_data_provider.dart
│   │   │   ├── ai_data_provider.g.dart
│   │   │   └── data.dart
│   │   ├── pipelines/
│   │   │   ├── base_pipeline.dart
│   │   │   └── saju_pipeline.dart
│   │   ├── prompts/
│   │   │   └── saju_prompts.dart
│   │   └── providers/
│   │       ├── google/
│   │       │   └── gemini_provider.dart
│   │       ├── image/
│   │       │   ├── dalle_provider.dart
│   │       │   └── imagen_provider.dart
│   │       └── openai/
│   │           └── gpt_provider.dart
│   ├── data/                              # AI 데이터 쿼리
│   │   ├── mutations.dart
│   │   └── queries.dart
│   ├── fortune/                           # 운세 프롬프트 & 서비스
│   │   ├── fortune_coordinator.dart
│   │   ├── common/
│   │   │   ├── fortune_input_data.dart
│   │   │   ├── fortune_state.dart
│   │   │   ├── korea_date_utils.dart
│   │   │   ├── locale_utils.dart
│   │   │   ├── prompt_template.dart
│   │   │   └── saju_analyses_queries.dart
│   │   ├── daily/
│   │   │   ├── daily_mutations.dart
│   │   │   ├── daily_prompt.dart
│   │   │   ├── daily_queries.dart
│   │   │   └── daily_service.dart
│   │   ├── lifetime/
│   │   │   ├── lifetime_phase1_prompt.dart
│   │   │   ├── lifetime_phase2_prompt.dart
│   │   │   ├── lifetime_phase3_prompt.dart
│   │   │   ├── lifetime_phase4_prompt.dart
│   │   │   ├── lifetime_prompt.dart
│   │   │   ├── lifetime_queries.dart
│   │   │   ├── lifetime_unified_prompt.dart
│   │   │   └── lifetime_unified_schema.dart
│   │   ├── monthly/
│   │   │   ├── monthly_mutations.dart
│   │   │   ├── monthly_prompt.dart
│   │   │   ├── monthly_queries.dart
│   │   │   └── monthly_service.dart
│   │   ├── yearly_2025/
│   │   │   ├── yearly_2025_mutations.dart
│   │   │   ├── yearly_2025_prompt.dart
│   │   │   ├── yearly_2025_queries.dart
│   │   │   └── yearly_2025_service.dart
│   │   └── yearly_2026/
│   │       ├── yearly_2026_mutations.dart
│   │       ├── yearly_2026_prompt.dart
│   │       ├── yearly_2026_queries.dart
│   │       └── yearly_2026_service.dart
│   ├── jh/                                # JH_AI 전용 (사주 분석)
│   │   ├── jh.dart
│   │   ├── analysis/
│   │   │   ├── earthly_relations.dart
│   │   │   ├── four_pillars_parser.dart
│   │   │   ├── geokguk_analyzer.dart
│   │   │   ├── heavenly_relations.dart
│   │   │   ├── hidden_stems_analyzer.dart
│   │   │   ├── ohaeng_analyzer.dart
│   │   │   ├── spirits_analyzer.dart
│   │   │   ├── ten_gods_analyzer.dart
│   │   │   ├── twelve_stages_analyzer.dart
│   │   │   └── yongshin_analyzer.dart
│   │   └── providers/
│   │       ├── jh_analysis_provider.dart
│   │       └── jh_analysis_provider.g.dart
│   ├── jina/                              # Jina 전용 (AI 대화)
│   │   ├── jina.dart
│   │   ├── chat/
│   │   │   ├── emoji_injector.dart
│   │   │   ├── response_generator.dart
│   │   │   └── tone_adjuster.dart
│   │   ├── context/
│   │   │   ├── chat_history_manager.dart
│   │   │   └── context_builder.dart
│   │   ├── image/
│   │   │   ├── nanabanan_provider.dart
│   │   │   └── saju_illustration_prompt.dart
│   │   ├── personas/                      # 채팅 페르소나 (MBTI 기반)
│   │   │   ├── _TEMPLATE.dart
│   │   │   ├── persona_base.dart
│   │   │   ├── persona_registry.dart
│   │   │   ├── persona_selector.dart
│   │   │   ├── baby_monk.dart
│   │   │   ├── base_nf.dart
│   │   │   ├── base_nt.dart
│   │   │   ├── base_sf.dart
│   │   │   ├── base_st.dart
│   │   │   ├── cute_friend.dart
│   │   │   ├── detail_book.dart
│   │   │   ├── friendly_sister.dart
│   │   │   ├── grandma.dart
│   │   │   ├── newbie_shaman.dart
│   │   │   ├── saeongjima.dart
│   │   │   ├── scenario_writer.dart
│   │   │   ├── test_negative_persona.dart
│   │   │   └── wise_scholar.dart
│   │   └── providers/
│   │       ├── jina_chat_provider.dart
│   │       └── jina_chat_provider.g.dart
│   └── services/                          # AI 통합 서비스
│       ├── ai_api_service.dart
│       ├── compatibility_analysis_service.dart
│       ├── compatibility_calculator.dart
│       └── saju_analysis_service.dart
│
├── ad/                                    # 광고 시스템
│   ├── ad.dart                            # barrel export
│   ├── ad_config.dart
│   ├── ad_network_resolver.dart
│   ├── ad_service.dart                    # 오케스트레이터
│   ├── ad_strategy.dart
│   ├── ad_tracking_service.dart
│   ├── feature_unlock_service.dart
│   ├── region_detector.dart
│   ├── token_reward_service.dart
│   ├── DK/                                # DK 전용 작업 폴더
│   ├── adapters/                          # 멀티 네트워크 어댑터
│   │   ├── ad_network_adapter.dart        # 인터페이스
│   │   ├── adfit_adapter.dart
│   │   ├── admob_adapter.dart
│   │   ├── unity_ads_adapter.dart
│   │   ├── unity_ads_config.dart
│   │   ├── vungle_adapter.dart
│   │   └── vungle_config.dart
│   ├── adfit/                             # AdFit (배너/네이티브)
│   │   ├── adfit_banner_ad_widget.dart
│   │   ├── adfit_config.dart
│   │   ├── adfit_native_ad_widget.dart
│   │   └── adfit_service.dart
│   ├── data/
│   │   ├── ad_data.dart
│   │   └── queries/
│   │       └── ad_queries.dart
│   ├── providers/
│   │   ├── ad_provider.dart
│   │   └── ad_provider.g.dart
│   └── widgets/                           # 광고 UI 위젯
│       ├── banner_ad_widget.dart
│       ├── card_native_ad_widget.dart
│       ├── chat_ad_factory.dart
│       ├── inline_ad_widget.dart
│       └── native_ad_widget.dart
│
├── animation/
│   └── saju_loading_animation.dart
│
├── core/                                  # 앱 전역 공통
│   ├── config/
│   │   └── admin_config.dart
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_sizes.dart
│   │   └── app_strings.dart
│   ├── data/
│   │   ├── base_query.dart
│   │   ├── data.dart
│   │   └── query_result.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── auth_provider.g.dart
│   │   ├── repository_providers.dart
│   │   └── repository_providers.g.dart
│   ├── repositories/
│   │   ├── chat_repository.dart
│   │   ├── saju_analysis_repository.dart
│   │   └── saju_profile_repository.dart
│   ├── services/
│   │   ├── ai_chat_service.dart
│   │   ├── ai_summary_service.dart
│   │   ├── app_update_service.dart
│   │   ├── auth_service.dart
│   │   ├── error_logging_service.dart
│   │   ├── intent_classifier_service.dart
│   │   ├── posthog_service.dart
│   │   ├── prompt_loader.dart
│   │   ├── quota_service.dart
│   │   └── supabase_service.dart
│   ├── supabase/
│   │   └── generated/                     # Supadart 자동 생성
│   │       ├── supadart_exports.dart
│   │       ├── supadart_header.dart
│   │       ├── ai_summaries.dart
│   │       ├── chat_messages.dart
│   │       ├── chat_sessions.dart
│   │       ├── compatibility_analyses.dart
│   │       ├── saju_analyses.dart
│   │       ├── saju_profiles.dart
│   │       └── user_daily_token_usage.dart
│   ├── theme/
│   │   ├── app_fonts.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_theme.dart
│   │   ├── theme_provider.dart
│   │   └── theme_provider.g.dart
│   ├── utils/
│   │   ├── responsive_utils.dart
│   │   └── suggested_questions_parser.dart
│   └── widgets/
│       ├── main_bottom_nav.dart
│       ├── main_shell.dart
│       ├── mystic_background.dart
│       └── illustrations/
│           ├── illustrations.dart
│           ├── floating_elements.dart
│           ├── fortune_teller_illustration.dart
│           ├── lotus_illustration.dart
│           ├── mystic_moon_illustration.dart
│           └── yin_yang_illustration.dart
│
├── features/                              # 기능별 모듈 (MVVM)
│   │
│   ├── calendar/                          # 캘린더
│   │   ├── domain/models/
│   │   │   └── calendar_event.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── calendar_event_provider.dart
│   │       │   └── calendar_event_provider.g.dart
│   │       ├── screens/
│   │       │   └── calendar_screen.dart
│   │       └── widgets/
│   │           ├── add_event_bottom_sheet.dart
│   │           └── event_list_widget.dart
│   │
│   ├── compatibility/                     # 궁합
│   │   ├── data/
│   │   │   ├── compatibility_interpreter.dart
│   │   │   ├── compatibility_mutations.dart
│   │   │   ├── compatibility_queries.dart
│   │   │   ├── compatibility_schema.dart
│   │   │   ├── data.dart
│   │   │   ├── hapchung_explanations.dart
│   │   │   └── models/
│   │   │       ├── compatibility_analysis_model.dart
│   │   │       ├── compatibility_analysis_model.freezed.dart
│   │   │       └── compatibility_analysis_model.g.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── compatibility_provider.dart
│   │       │   └── compatibility_provider.g.dart
│   │       ├── screens/
│   │       │   ├── compatibility_detail_screen.dart
│   │       │   ├── compatibility_list_screen.dart
│   │       │   └── compatibility_screen.dart
│   │       └── widgets/
│   │           └── compatibility_card.dart
│   │
│   ├── daily_fortune/                     # 오늘의 운세
│   │   └── presentation/screens/
│   │       ├── category_fortune_detail_screen.dart
│   │       └── daily_fortune_detail_screen.dart
│   │
│   ├── history/                           # 히스토리
│   │   └── presentation/screens/
│   │       └── history_screen.dart
│   │
│   ├── home/                              # 홈
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── home_screen.dart
│   │       │   └── main_scaffold.dart
│   │       └── widgets/
│   │           └── daily_fortune_card.dart
│   │
│   ├── menu/                              # 메뉴 (메인 화면)
│   │   ├── domain/models/
│   │   │   └── menu_item.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── daily_analysis_step_provider.dart
│   │       │   ├── daily_fortune_provider.dart
│   │       │   └── daily_fortune_provider.g.dart
│   │       ├── screens/
│   │       │   └── menu_screen.dart
│   │       └── widgets/
│   │           ├── ai_chat_cta_card.dart
│   │           ├── bottom_nav_bar.dart
│   │           ├── compatibility_promo_card.dart
│   │           ├── daily_advice_section.dart
│   │           ├── fortune_category_list.dart
│   │           ├── fortune_summary_card.dart
│   │           ├── header_view.dart
│   │           ├── menu_app_bar.dart
│   │           ├── menu_card.dart
│   │           ├── menu_grid.dart
│   │           ├── section_header.dart
│   │           └── today_message_card.dart
│   │
│   ├── monthly_fortune/                   # 월별 운세
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── monthly_fortune_provider.dart
│   │       │   └── monthly_fortune_provider.g.dart
│   │       └── screens/
│   │           └── monthly_fortune_screen.dart
│   │
│   ├── new_year_fortune/                  # 2026 신년 운세
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── new_year_fortune_provider.dart
│   │       │   └── new_year_fortune_provider.g.dart
│   │       └── screens/
│   │           └── new_year_fortune_screen.dart
│   │
│   ├── onboarding/                        # 온보딩
│   │   └── presentation/screens/
│   │       └── onboarding_screen.dart
│   │
│   ├── profile/                           # 사주 프로필 입력 (P0)
│   │   ├── data/
│   │   │   ├── data.dart
│   │   │   ├── mutations.dart
│   │   │   ├── queries.dart
│   │   │   ├── relation_mutations.dart
│   │   │   ├── relation_queries.dart
│   │   │   ├── relation_refresh_state.dart
│   │   │   ├── relation_saju_helper.dart
│   │   │   ├── relation_schema.dart
│   │   │   ├── schema.dart
│   │   │   ├── datasources/
│   │   │   │   └── profile_local_datasource.dart
│   │   │   ├── mock/
│   │   │   │   └── mock_profiles.dart
│   │   │   ├── models/
│   │   │   │   ├── profile_relation_model.dart
│   │   │   │   ├── profile_relation_model.freezed.dart
│   │   │   │   ├── profile_relation_model.g.dart
│   │   │   │   ├── saju_profile_model.dart
│   │   │   │   ├── saju_profile_model.freezed.dart
│   │   │   │   └── saju_profile_model.g.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── gender.dart
│   │   │   │   ├── relationship_type.dart
│   │   │   │   ├── saju_profile.dart
│   │   │   │   └── saju_profile.freezed.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── profile_provider.dart
│   │       │   ├── profile_provider.g.dart
│   │       │   ├── relation_provider.dart
│   │       │   ├── relation_provider.g.dart
│   │       │   ├── relationship_graph_provider.dart
│   │       │   └── relationship_graph_provider.g.dart
│   │       ├── screens/
│   │       │   ├── profile_edit_screen.dart
│   │       │   ├── profile_select_screen.dart
│   │       │   ├── relationship_add_screen.dart
│   │       │   ├── relationship_list_screen.dart
│   │       │   └── relationship_screen.dart
│   │       └── widgets/
│   │           ├── birth_date_input_widget.dart
│   │           ├── birth_date_picker.dart
│   │           ├── birth_time_input_widget.dart
│   │           ├── birth_time_options.dart
│   │           ├── birth_time_picker.dart
│   │           ├── calendar_type_dropdown.dart
│   │           ├── city_search_field.dart
│   │           ├── gender_selector.dart
│   │           ├── gender_toggle_buttons.dart
│   │           ├── lunar_options.dart
│   │           ├── profile_action_buttons.dart
│   │           ├── profile_name_input.dart
│   │           ├── relation_category_section.dart
│   │           ├── relationship_category_section.dart
│   │           ├── relationship_type_dropdown.dart
│   │           ├── time_correction_banner.dart
│   │           └── relationship_graph/
│   │               ├── graph_controls.dart
│   │               ├── me_node_widget.dart
│   │               ├── orthogonal_edge_renderer.dart
│   │               ├── profile_node_widget.dart
│   │               ├── profile_quick_view_sheet.dart
│   │               ├── relationship_graph_view.dart
│   │               ├── relationship_group_node.dart
│   │               ├── saju_quick_view_sheet.dart
│   │               └── straight_edge_renderer.dart
│   │
│   ├── saju_chart/                        # 만세력 사주 차트
│   │   ├── saju_chart.dart                # barrel export
│   │   ├── example_usage.dart
│   │   ├── data/
│   │   │   ├── mutations.dart
│   │   │   ├── queries.dart
│   │   │   ├── schema.dart
│   │   │   ├── constants/               # 만세력 상수 데이터
│   │   │   │   ├── cheongan_jiji.dart
│   │   │   │   ├── cheongan_jiji_i18n.dart
│   │   │   │   ├── dst_periods.dart
│   │   │   │   ├── gapja_60.dart
│   │   │   │   ├── gongmang_table.dart
│   │   │   │   ├── hapchung_relations.dart
│   │   │   │   ├── jijanggan_table.dart
│   │   │   │   ├── sipsin_relations.dart
│   │   │   │   ├── solar_term_calculator.dart
│   │   │   │   ├── solar_term_table.dart
│   │   │   │   ├── solar_term_table_extended.dart
│   │   │   │   ├── twelve_sinsal.dart
│   │   │   │   ├── twelve_unsung.dart
│   │   │   │   └── lunar_data/           # 음력 변환 테이블
│   │   │   │       ├── lunar_table.dart
│   │   │   │       ├── lunar_table_1900_1949.dart
│   │   │   │       ├── lunar_table_1950_1999.dart
│   │   │   │       ├── lunar_table_2000_2050.dart
│   │   │   │       ├── lunar_table_2051_2100.dart
│   │   │   │       └── lunar_year_data.dart
│   │   │   ├── models/
│   │   │   │   ├── cheongan_model.dart
│   │   │   │   ├── jiji_model.dart
│   │   │   │   ├── oheng_model.dart
│   │   │   │   ├── pillar_model.dart
│   │   │   │   ├── rule_models.dart
│   │   │   │   ├── saju_analysis_db_model.dart
│   │   │   │   ├── saju_analysis_model.dart
│   │   │   │   └── saju_chart_model.dart
│   │   │   └── repositories/
│   │   │       ├── rule_repository_impl.dart
│   │   │       └── saju_analysis_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── compiled_rules.dart
│   │   │   │   ├── daeun.dart
│   │   │   │   ├── day_strength.dart
│   │   │   │   ├── gyeokguk.dart
│   │   │   │   ├── lunar_date.dart
│   │   │   │   ├── lunar_validation.dart
│   │   │   │   ├── pillar.dart
│   │   │   │   ├── rule.dart
│   │   │   │   ├── rule_condition.dart
│   │   │   │   ├── saju_analysis.dart
│   │   │   │   ├── saju_chart.dart
│   │   │   │   ├── saju_context.dart
│   │   │   │   ├── sinsal.dart
│   │   │   │   ├── solar_term.dart
│   │   │   │   └── yongsin.dart
│   │   │   ├── repositories/
│   │   │   │   └── rule_repository.dart
│   │   │   └── services/               # 만세력 계산 서비스
│   │   │       ├── daeun_service.dart
│   │   │       ├── day_strength_service.dart
│   │   │       ├── dst_service.dart
│   │   │       ├── gilseong_service.dart
│   │   │       ├── gongmang_service.dart
│   │   │       ├── gyeokguk_service.dart
│   │   │       ├── hapchung_service.dart
│   │   │       ├── jasi_service.dart
│   │   │       ├── jijanggan_service.dart
│   │   │       ├── lunar_solar_converter.dart
│   │   │       ├── rule_engine.dart
│   │   │       ├── rule_validator.dart
│   │   │       ├── saju_analysis_service.dart
│   │   │       ├── saju_calculation_service.dart
│   │   │       ├── sinsal_service.dart
│   │   │       ├── solar_term_service.dart
│   │   │       ├── true_solar_time_service.dart
│   │   │       ├── twelve_sinsal_service.dart
│   │   │       ├── unsung_service.dart
│   │   │       └── yongsin_service.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── saju_analysis_repository_provider.dart
│   │       │   ├── saju_analysis_repository_provider.g.dart
│   │       │   ├── saju_chart_provider.dart
│   │       │   └── saju_chart_provider.g.dart
│   │       ├── screens/
│   │       │   ├── saju_chart_screen.dart
│   │       │   ├── saju_detail_screen.dart
│   │       │   └── saju_graph_screen.dart
│   │       └── widgets/
│   │           ├── day_strength_display.dart
│   │           ├── fortune_display.dart
│   │           ├── gilseong_display.dart
│   │           ├── gongmang_display.dart
│   │           ├── hapchung_tab.dart
│   │           ├── jijanggan_display.dart
│   │           ├── oheng_analysis_display.dart
│   │           ├── oheng_explanation_sheet.dart
│   │           ├── personalized_oheng_widget.dart
│   │           ├── pillar_column_widget.dart
│   │           ├── pillar_display.dart
│   │           ├── possteller_style_table.dart
│   │           ├── saju_detail_sheet.dart
│   │           ├── saju_detail_tabs.dart
│   │           ├── saju_info_header.dart
│   │           ├── saju_mini_card.dart
│   │           ├── sinsal_display.dart
│   │           ├── sipsung_display.dart
│   │           └── unsung_display.dart
│   │
│   ├── saju_chat/                         # AI 사주 챗봇 (P0 핵심)
│   │   ├── docs/                          # 내부 문서
│   │   ├── data/
│   │   │   ├── mutations.dart
│   │   │   ├── queries.dart
│   │   │   ├── schema.dart
│   │   │   ├── datasources/
│   │   │   │   ├── ai_pipeline_manager.dart
│   │   │   │   ├── chat_local_datasource.dart
│   │   │   │   ├── chat_session_local_datasource.dart
│   │   │   │   ├── gemini_edge_datasource.dart
│   │   │   │   ├── gemini_rest_datasource.dart
│   │   │   │   ├── openai_datasource.dart
│   │   │   │   ├── openai_edge_datasource.dart
│   │   │   │   └── saju_chat_edge_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── chat_message_model.dart
│   │   │   │   ├── chat_message_model.freezed.dart
│   │   │   │   ├── chat_message_model.g.dart
│   │   │   │   ├── chat_session_model.dart
│   │   │   │   ├── chat_session_model.freezed.dart
│   │   │   │   ├── chat_session_model.g.dart
│   │   │   │   ├── conversational_ad_model.dart
│   │   │   │   ├── conversational_ad_model.freezed.dart
│   │   │   │   └── conversational_ad_model.g.dart
│   │   │   ├── repositories/
│   │   │   │   ├── chat_repository_impl.dart
│   │   │   │   └── chat_session_repository_impl.dart
│   │   │   └── services/
│   │   │       ├── ad_trigger_service.dart
│   │   │       ├── ai_summary_prompt_builder.dart
│   │   │       ├── chat_realtime_service.dart
│   │   │       ├── compatibility_data_loader.dart
│   │   │       ├── conversation_window_manager.dart
│   │   │       ├── message_queue_service.dart
│   │   │       ├── participant_resolver.dart
│   │   │       ├── session_restore_service.dart
│   │   │       ├── sse_stream_client.dart
│   │   │       ├── system_prompt_builder.dart
│   │   │       └── token_counter.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── ad_chat_message.dart
│   │   │   │   ├── chat_message.dart
│   │   │   │   └── chat_session.dart
│   │   │   ├── models/
│   │   │   │   ├── ad_persona_prompt.dart
│   │   │   │   ├── ai_persona.dart
│   │   │   │   ├── base_character.dart
│   │   │   │   ├── base_persona.dart
│   │   │   │   ├── chat_persona.dart
│   │   │   │   ├── chat_type.dart
│   │   │   │   ├── compatibility_context.dart
│   │   │   │   ├── multi_compatibility_context.dart
│   │   │   │   └── special_character.dart
│   │   │   ├── repositories/
│   │   │   │   ├── chat_repository.dart
│   │   │   │   └── chat_session_repository.dart
│   │   │   └── services/
│   │   │       └── mention_parser.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── chat_persona_provider.dart
│   │       │   ├── chat_persona_provider.g.dart
│   │       │   ├── chat_provider.dart
│   │       │   ├── chat_provider.g.dart
│   │       │   ├── chat_session_provider.dart
│   │       │   ├── chat_session_provider.g.dart
│   │       │   ├── conversational_ad_provider.dart
│   │       │   └── conversational_ad_provider.g.dart
│   │       ├── screens/
│   │       │   └── saju_chat_shell.dart
│   │       └── widgets/
│   │           ├── ad_native_bubble.dart
│   │           ├── ad_transition_bubble.dart
│   │           ├── chat_app_bar.dart
│   │           ├── chat_bubble.dart
│   │           ├── chat_desktop_layout.dart
│   │           ├── chat_input_field.dart
│   │           ├── chat_message_list.dart
│   │           ├── chat_mobile_layout.dart
│   │           ├── conversational_ad_widget.dart
│   │           ├── deep_analysis_loading_banner.dart
│   │           ├── disclaimer_banner.dart
│   │           ├── error_banner.dart
│   │           ├── mention_send_handler.dart
│   │           ├── message_bubble.dart
│   │           ├── persona_avatar.dart
│   │           ├── persona_horizontal_selector.dart
│   │           ├── relation_selector_sheet.dart
│   │           ├── send_button.dart
│   │           ├── streaming_message_bubble.dart
│   │           ├── suggested_questions.dart
│   │           ├── thinking_bubble.dart
│   │           ├── token_depleted_banner.dart
│   │           ├── typing_indicator.dart
│   │           ├── chat_history_sidebar/
│   │           │   ├── chat_history_sidebar.dart
│   │           │   ├── chat_history_sidebar_widgets.dart
│   │           │   ├── persona_selector_grid.dart
│   │           │   ├── session_group_header.dart
│   │           │   ├── session_list.dart
│   │           │   ├── session_list_tile.dart
│   │           │   ├── sidebar_footer.dart
│   │           │   └── sidebar_header.dart
│   │           ├── persona_selector/
│   │           │   ├── mbti_axis_selector.dart
│   │           │   ├── persona_horizontal_list.dart
│   │           │   ├── persona_selector.dart
│   │           │   └── persona_selector_sheet.dart
│   │           └── persona_selector_sheet.dart
│   │
│   ├── settings/                          # 설정
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── disclaimer_screen.dart
│   │       │   ├── icon_generator_screen.dart
│   │       │   ├── notification_settings_screen.dart
│   │       │   ├── privacy_policy_screen.dart
│   │       │   ├── profile_management_screen.dart
│   │       │   ├── settings_screen.dart
│   │       │   └── terms_of_service_screen.dart
│   │       └── widgets/
│   │           └── legal_notice_dialog.dart
│   │
│   ├── splash/                            # 스플래시
│   │   ├── data/
│   │   │   ├── data.dart
│   │   │   ├── mutations.dart
│   │   │   ├── queries.dart
│   │   │   └── schema.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── splash_provider.dart
│   │       │   └── splash_provider.g.dart
│   │       └── screens/
│   │           └── splash_screen.dart
│   │
│   ├── traditional_saju/                  # 평생운세
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── lifetime_fortune_provider.dart
│   │       │   └── lifetime_fortune_provider.g.dart
│   │       └── screens/
│   │           ├── lifetime_fortune_screen.dart
│   │           └── traditional_saju_screen.dart
│   │
│   └── yearly_2025_fortune/               # 2025 연간 운세
│       └── presentation/
│           ├── providers/
│           │   ├── yearly_2025_fortune_provider.dart
│           │   └── yearly_2025_fortune_provider.g.dart
│           ├── screens/
│           │   └── yearly_2025_fortune_screen.dart
│           └── widgets/
│               (빈 폴더)
│
├── i18n/                                  # 다국어 리소스 (17개 언어)
│   ├── multi_file_asset_loader.dart       # 다중 JSON 로더
│   ├── ar/                                # 아랍어
│   ├── de/                                # 독일어
│   ├── en/                                # 영어
│   ├── es/                                # 스페인어
│   ├── fr/                                # 프랑스어
│   ├── hi/                                # 힌디어
│   ├── id/                                # 인도네시아어
│   ├── it/                                # 이탈리아어
│   ├── ja/                                # 일본어
│   ├── ko/                                # 한국어
│   ├── ms/                                # 말레이어
│   ├── my/                                # 미얀마어
│   ├── pt/                                # 포르투갈어
│   ├── ru/                                # 러시아어
│   ├── th/                                # 태국어
│   ├── vi/                                # 베트남어
│   └── zh/                                # 중국어
│
├── purchase/                              # 인앱 결제 (RevenueCat)
│   ├── purchase.dart                      # barrel export
│   ├── purchase_config.dart
│   ├── purchase_service.dart
│   ├── data/
│   │   ├── purchase_data.dart
│   │   ├── mutations/
│   │   │   └── purchase_mutations.dart
│   │   └── queries/
│   │       └── purchase_queries.dart
│   ├── providers/
│   │   ├── purchase_provider.dart
│   │   └── purchase_provider.g.dart
│   └── widgets/
│       ├── paywall_screen.dart
│       ├── premium_badge_widget.dart
│       ├── restore_button_widget.dart
│       └── subscription_manage_screen.dart
│
├── router/                                # go_router 라우팅
│   ├── app_router.dart
│   ├── app_router.g.dart
│   └── routes.dart
│
├── shared/                                # 공통 위젯/유틸
│   ├── utils/
│   │   └── text_formatter.dart
│   └── widgets/
│       ├── fortune_category_chip_section.dart
│       ├── fortune_keyword_badge.dart
│       ├── fortune_monthly_chip_section.dart
│       ├── fortune_monthly_step_section.dart
│       ├── fortune_score_gauge.dart
│       ├── fortune_section_card.dart
│       ├── fortune_shimmer_loading.dart
│       ├── fortune_title_header.dart
│       ├── fortune_weekly_chip_section.dart
│       ├── fortune_year_info_card.dart
│       └── quota_exceeded_dialog.dart
│
└── sql/                                   # SQL 쿼리 (JH_BE 담당)
```
