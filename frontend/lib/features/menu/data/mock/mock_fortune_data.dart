import 'package:flutter/material.dart';

/// Mock data for fortune-telling app
class MockFortuneData {
  // Today's overall fortune score (0-100)
  static int todayScore = 78;

  // Fortune category scores
  static Map<String, int> categoryScores = {
    'love': 85,
    'money': 72,
    'health': 90,
    'career': 68,
    'study': 75,
  };

  // Five elements balance
  static Map<String, double> fiveElements = {
    'wood': 0.8,
    'fire': 0.6,
    'earth': 0.4,
    'metal': 0.7,
    'water': 0.5,
  };

  // Detailed Saju data (Four Pillars) - 시주, 일주, 월주, 년주 순서
  static List<Map<String, dynamic>> sajuPillarsDetailed = [
    {
      'label': '생시',
      'heavenly': {'char': '己', 'korean': '기', 'element': 'earth', 'yinyang': '-'},
      'earthly': {'char': '亥', 'korean': '해', 'element': 'water', 'yinyang': '+'},
      'tenGod1': '편인',
      'tenGod2': '상관',
      'jijanggan': '무갑임',
      'twelveState': '목욕',
      'twelveStar': '망신살',
    },
    {
      'label': '생일',
      'heavenly': {'char': '辛', 'korean': '신', 'element': 'metal', 'yinyang': '-'},
      'earthly': {'char': '酉', 'korean': '유', 'element': 'metal', 'yinyang': '-'},
      'tenGod1': '비견',
      'tenGod2': '비견',
      'jijanggan': '경신',
      'twelveState': '건록',
      'twelveStar': '년살',
    },
    {
      'label': '생월',
      'heavenly': {'char': '戊', 'korean': '무', 'element': 'earth', 'yinyang': '+'},
      'earthly': {'char': '寅', 'korean': '인', 'element': 'wood', 'yinyang': '+'},
      'tenGod1': '정인',
      'tenGod2': '정재',
      'jijanggan': '무병갑',
      'twelveState': '태',
      'twelveStar': '역마살',
    },
    {
      'label': '생년',
      'heavenly': {'char': '庚', 'korean': '경', 'element': 'metal', 'yinyang': '+'},
      'earthly': {'char': '辰', 'korean': '진', 'element': 'earth', 'yinyang': '+'},
      'tenGod1': '겁재',
      'tenGod2': '정인',
      'jijanggan': '을계무',
      'twelveState': '묘',
      'twelveStar': '천살',
    },
  ];

  // Legacy saju pillars (for compatibility)
  static List<Map<String, String>> sajuPillars = [
    {'name': '년주', 'heavenly': '갑', 'earthly': '진', 'meaning': '청룡', 'element': 'wood'},
    {'name': '월주', 'heavenly': '을', 'earthly': '사', 'meaning': '뱀띠', 'element': 'fire'},
    {'name': '일주', 'heavenly': '병', 'earthly': '오', 'meaning': '말띠', 'element': 'fire'},
    {'name': '시주', 'heavenly': '정', 'earthly': '미', 'meaning': '양띠', 'element': 'earth'},
  ];

  // Daily advice items
  static List<Map<String, dynamic>> dailyAdvice = [
    {'icon': Icons.access_time_outlined, 'title': '길한 시간', 'value': '오전 9-11시'},
    {'icon': Icons.palette_outlined, 'title': '행운의 색', 'value': '파란색'},
    {'icon': Icons.explore_outlined, 'title': '행운의 방향', 'value': '동쪽'},
    {'icon': Icons.tag_outlined, 'title': '행운의 숫자', 'value': '3, 7, 12'},
  ];

  // Today's message
  static String todayMessage =
      "오늘은 새로운 시작에 좋은 날입니다. 적극적으로 행동하면 좋은 결과를 얻을 수 있어요.";

  // Category details
  static Map<String, Map<String, dynamic>> categoryDetails = {
    'love': {'name': '연애운', 'icon': Icons.favorite_outline},
    'money': {'name': '재물운', 'icon': Icons.payments_outlined},
    'health': {'name': '건강운', 'icon': Icons.favorite_border},
    'career': {'name': '직업운', 'icon': Icons.work_outline},
    'study': {'name': '학업운', 'icon': Icons.school_outlined},
  };

  // Element colors (오행 색상)
  static Color getElementColor(String element) {
    switch (element) {
      case 'wood':
        return const Color(0xFF4ADE80); // green
      case 'fire':
        return const Color(0xFFF87171); // red
      case 'earth':
        return const Color(0xFFFBBF24); // yellow/amber
      case 'metal':
        return const Color(0xFFE5E7EB); // white/gray
      case 'water':
        return const Color(0xFF60A5FA); // blue
      default:
        return const Color(0xFFA1A1AA); // zinc-400
    }
  }

  // Yin/Yang symbol
  static String getYinYangSymbol(String yinyang) {
    return yinyang == '+' ? '+' : '-';
  }

  // Element name in Korean
  static String getElementKorean(String element) {
    switch (element) {
      case 'wood':
        return '목';
      case 'fire':
        return '화';
      case 'earth':
        return '토';
      case 'metal':
        return '금';
      case 'water':
        return '수';
      default:
        return '';
    }
  }
}
