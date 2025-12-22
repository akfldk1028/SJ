/// 페르소나 선택 로직
/// 담당: Jina

import 'persona_base.dart';
import 'friendly_sister.dart';
import 'wise_scholar.dart';
import 'cute_friend.dart';

// TODO: 구현 예정
// - [ ] 유저 선호도 기반 선택
// - [ ] 상황별 자동 전환
// - [ ] 선호도 저장

enum PersonaType {
  friendlySister, // 기본값
  wiseScholar,
  cuteFriend,
}

class PersonaSelector {
  static PersonaBase getPersona(PersonaType type) {
    switch (type) {
      case PersonaType.friendlySister:
        return FriendlySisterPersona();
      case PersonaType.wiseScholar:
        return WiseScholarPersona();
      case PersonaType.cuteFriend:
        return CuteFriendPersona();
    }
  }

  static PersonaBase get defaultPersona => FriendlySisterPersona();
}
