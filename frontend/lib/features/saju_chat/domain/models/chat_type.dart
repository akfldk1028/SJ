import 'package:easy_localization/easy_localization.dart';

/// 채팅 타입 enum
enum ChatType {
  dailyFortune,
  newYearFortune,
  sajuAnalysis,
  compatibility,
  general;

  /// 문자열에서 ChatType 변환
  static ChatType fromString(String? value) {
    switch (value) {
      case 'dailyFortune':
        return ChatType.dailyFortune;
      case 'newYearFortune':
        return ChatType.newYearFortune;
      case 'sajuAnalysis':
        return ChatType.sajuAnalysis;
      case 'compatibility':
        return ChatType.compatibility;
      default:
        return ChatType.general;
    }
  }

  /// 채팅 타입별 타이틀
  String get title {
    switch (this) {
      case ChatType.dailyFortune:
        return 'saju_chat.chatType_dailyFortune'.tr();
      case ChatType.newYearFortune:
        return 'saju_chat.chatType_newYearFortune'.tr();
      case ChatType.sajuAnalysis:
        return 'saju_chat.chatType_sajuAnalysis'.tr();
      case ChatType.compatibility:
        return 'saju_chat.chatType_compatibility'.tr();
      case ChatType.general:
        return 'saju_chat.chatType_general'.tr();
    }
  }

  /// 채팅 타입별 환영 메시지
  String get welcomeMessage {
    switch (this) {
      case ChatType.dailyFortune:
        return '안녕하세요! 오늘의 운세를 봐드릴게요. 🌟\n\n'
            '생년월일을 알려주시면 더 정확한 운세를 알려드릴 수 있어요.\n'
            '또는 바로 궁금한 점을 물어보셔도 됩니다!';
      case ChatType.newYearFortune:
        return '안녕하세요! 신년운세를 봐드릴게요. 🎊\n\n'
            '새해의 운세와 월별 운세를 분석해 드리겠습니다.\n'
            '생년월일을 알려주시면 시작할게요!';
      case ChatType.sajuAnalysis:
        return '안녕하세요! 사주팔자 분석을 도와드릴게요. ✨\n\n'
            '정확한 분석을 위해 다음 정보를 알려주세요:\n'
            '• 생년월일 (양력/음력)\n'
            '• 태어난 시간 (모르시면 괜찮아요)';
      case ChatType.compatibility:
        return '안녕하세요! 궁합을 봐드릴게요. 💕\n\n'
            '본인과 상대방의 생년월일을 알려주시면\n'
            '두 분의 궁합을 분석해 드리겠습니다.';
      case ChatType.general:
        return '안녕하세요! 사담 AI입니다. 🔮\n\n'
            '사주, 운세, 궁합 등 궁금한 것을 물어보세요!';
    }
  }

  /// 채팅 타입별 입력 힌트
  String get inputHint {
    switch (this) {
      case ChatType.dailyFortune:
        return 'saju_chat.chatType_dailyFortuneHint'.tr();
      case ChatType.newYearFortune:
        return 'saju_chat.chatType_newYearFortuneHint'.tr();
      case ChatType.sajuAnalysis:
        return 'saju_chat.chatType_sajuAnalysisHint'.tr();
      case ChatType.compatibility:
        return 'saju_chat.chatType_compatibilityHint'.tr();
      case ChatType.general:
        return 'saju_chat.chatType_generalHint'.tr();
    }
  }
}
