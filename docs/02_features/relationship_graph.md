# 관계 그래프 (Relationship Graph) 기능 명세

> 사주 프로필들을 노드-엣지 그래프로 시각화하는 기능

---

## 1. 개요

### 1.1 목적
- 기존 리스트 형태가 아닌 **그래프 형태**로 관계 시각화
- "나" 중심으로 가족/친구/연인 등 연결된 사람들을 한눈에 파악
- React Flow 스타일의 노드 기반 UI

### 1.2 핵심 차별점
| 기존 사주 앱 | 만톡 관계 그래프 |
|-------------|-----------------|
| 나만의 사주 정보 | 나 + 주변 사람들 사주 |
| 리스트 형태 | 노드 그래프 형태 |
| 단순 나열 | 관계 시각화 |

---

## 2. 패키지 선택

### 2.1 선택: graphview ^1.5.1
- **pub.dev**: https://pub.dev/packages/graphview
- **GitHub**: https://github.com/nabil6391/graphview
- **최근 업데이트**: 2025-10-17

### 2.2 선택 이유
| 기준 | graphview | vyuh_node_flow |
|------|-----------|----------------|
| Family Tree 지원 | ✅ 최적화 | ❌ 일반 플로우 |
| 안정성 | ✅ v1.5.1 | ⚠️ v0.7.2 |
| 알고리즘 | 8가지 | 1가지 |
| 학습 곡선 | 낮음 | 높음 |

### 2.3 지원 알고리즘
1. **BuchheimWalkerTree** ← 사용 예정 (깔끔한 트리)
2. Tidier Tree
3. Directed Graph (FruchtermanReingold)
4. Layered Graph (Sugiyama)
5. Balloon Layout
6. Circular Layout
7. Radial Tree Layout
8. Mindmap Layout

---

## 3. 위젯 트리 설계

### 3.1 전체 구조
```
RelationshipScreen (메인 화면)
├── AppBar
│   ├── Title: "인연 관계도"
│   ├── ViewModeToggle (리스트 ↔ 그래프)
│   ├── SearchButton
│   └── AddProfileButton
│
├── Body (ViewMode에 따라 전환)
│   │
│   ├── [ListView Mode] RelationshipListView
│   │   └── (기존 RelationshipListScreen 내용)
│   │
│   └── [GraphView Mode] RelationshipGraphView
│       ├── InteractiveViewer (줌/패닝 제어)
│       │   └── GraphView.builder
│       │       ├── Controller: GraphController
│       │       ├── Algorithm: BuchheimWalkerConfiguration
│       │       └── Builder: (Node node) => NodeWidget
│       │
│       └── GraphControls (우측 하단)
│           ├── ZoomInButton
│           ├── ZoomOutButton
│           └── FitToScreenButton
│
└── BottomSheet (노드 탭 시 표시)
    └── ProfileQuickViewSheet
        ├── Avatar + Name
        ├── BirthInfo
        ├── RelationType Badge
        └── ActionButtons (채팅, 편집, 삭제)
```

### 3.2 그래프 구조
```
           ┌─────────┐
           │   나    │ ← MeNodeWidget (Root, 핑크 테두리)
           │  (Me)   │
           └────┬────┘
                │
    ┌───────────┼───────────┐
    │           │           │
┌───┴───┐  ┌───┴───┐  ┌───┴───┐
│ 가족  │  │ 친구  │  │ 연인  │ ← RelationshipGroupNode
└───┬───┘  └───┬───┘  └───┬───┘
    │          │          │
┌───┴───┐  ┌───┴───┐  ┌───┴───┐
│ 엄마  │  │ 철수  │  │ 영희  │ ← ProfileNodeWidget
│ 아빠  │  │ 민수  │  └───────┘
└───────┘  └───────┘
```

---

## 4. 노드 위젯 설계

### 4.1 MeNodeWidget (나 - Root 노드)
```dart
class MeNodeWidget extends StatelessWidget {
  const MeNodeWidget({super.key, required this.profile, required this.onTap});

  final SajuProfile profile;
  final VoidCallback onTap;

  // 크기: 80x80
  // 스타일: 핑크 테두리 (#FF69B4), 큰 아바타, 그림자
}
```

**디자인:**
```
┌──────────────────┐
│    ┌────────┐    │
│    │ Avatar │    │  ← 48x48
│    │   나   │    │
│    └────────┘    │
│      홍길동      │
│    1990.05.20    │
└──────────────────┘
     핑크 테두리
```

### 4.2 RelationshipGroupNode (관계 그룹 노드)
```dart
class RelationshipGroupNode extends StatelessWidget {
  const RelationshipGroupNode({
    super.key,
    required this.type,
    required this.count,
    required this.onTap,
  });

  final RelationshipType type;
  final int count;
  final VoidCallback onTap;

  // 크기: 60x40
  // 스타일: 관계 유형별 색상, 라운드 박스
}
```

**관계 유형별 색상:**
| 유형 | 색상 | Hex |
|------|------|-----|
| family | 빨강 계열 | #FF6B6B |
| friend | 청록 계열 | #4ECDC4 |
| lover | 핑크 | #FF69B4 |
| work | 파랑 | #45B7D1 |
| other | 회색 | #95A5A6 |

### 4.3 ProfileNodeWidget (개별 프로필 노드)
```dart
class ProfileNodeWidget extends StatelessWidget {
  const ProfileNodeWidget({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final SajuProfile profile;
  final VoidCallback onTap;

  // 크기: 100x60
}
```

**디자인:**
```
┌─────────────────────┐
│ [👤]  홍길동        │
│       1990.05.20    │
└─────────────────────┘
```

---

## 5. 파일 구조

```
features/profile/
├── presentation/
│   ├── screens/
│   │   ├── relationship_list_screen.dart     (기존)
│   │   └── relationship_screen.dart          (신규 - 메인 통합)
│   │
│   ├── widgets/
│   │   ├── relationship_category_section.dart (기존)
│   │   │
│   │   └── relationship_graph/                (신규 폴더)
│   │       ├── relationship_graph_view.dart   # GraphView 래퍼
│   │       ├── me_node_widget.dart            # 나 노드 위젯
│   │       ├── profile_node_widget.dart       # 프로필 노드 위젯
│   │       ├── relationship_group_node.dart   # 그룹 노드 위젯
│   │       ├── graph_controls.dart            # 줌/패닝 컨트롤
│   │       ├── graph_edge_painter.dart        # 엣지(선) 커스텀
│   │       └── profile_quick_view_sheet.dart  # 바텀시트
│   │
│   └── providers/
│       ├── profile_provider.dart              (기존)
│       └── relationship_graph_provider.dart   (신규)
```

---

## 6. Provider 설계

### 6.1 relationship_graph_provider.dart
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:graphview/GraphView.dart';

part 'relationship_graph_provider.g.dart';

/// 뷰 모드 (리스트/그래프)
enum ViewModeType { list, graph }

@riverpod
class ViewMode extends _$ViewMode {
  @override
  ViewModeType build() => ViewModeType.graph; // 기본값: 그래프

  void toggle() {
    state = state == ViewModeType.list
        ? ViewModeType.graph
        : ViewModeType.list;
  }

  void setMode(ViewModeType mode) => state = mode;
}

/// 선택된 노드 (바텀시트 표시용)
@riverpod
class SelectedProfile extends _$SelectedProfile {
  @override
  SajuProfile? build() => null;

  void select(SajuProfile profile) => state = profile;
  void clear() => state = null;
}

/// 프로필 목록 → Graph 변환
@riverpod
Graph relationshipGraph(Ref ref) {
  final profiles = ref.watch(allProfilesProvider).valueOrNull ?? [];
  return _buildGraphFromProfiles(profiles);
}

Graph _buildGraphFromProfiles(List<SajuProfile> profiles) {
  final graph = Graph();

  // 1. "나" 프로필 찾기 (없으면 가상 노드)
  final meProfile = profiles.firstWhereOrNull(
    (p) => p.relationType == RelationshipType.me
  );

  final meNode = Node.Id(meProfile?.id ?? 'me_placeholder');
  graph.addNode(meNode);

  // 2. 관계 유형별 그룹화
  final groupedProfiles = <RelationshipType, List<SajuProfile>>{};
  for (final profile in profiles) {
    if (profile.relationType == RelationshipType.me) continue;
    groupedProfiles
        .putIfAbsent(profile.relationType, () => [])
        .add(profile);
  }

  // 3. 그룹 노드 + 개별 노드 추가
  for (final entry in groupedProfiles.entries) {
    final groupNode = Node.Id('group_${entry.key.name}');
    graph.addEdge(meNode, groupNode);

    for (final profile in entry.value) {
      final profileNode = Node.Id(profile.id);
      graph.addEdge(groupNode, profileNode);
    }
  }

  return graph;
}

/// Graph Algorithm 설정
@riverpod
BuchheimWalkerConfiguration graphAlgorithm(Ref ref) {
  return BuchheimWalkerConfiguration()
    ..siblingSeparation = 50
    ..levelSeparation = 80
    ..subtreeSeparation = 80
    ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
}
```

---

## 7. 인터랙션

### 7.1 노드 탭
1. 노드 탭 → `selectedProfileProvider` 업데이트
2. 바텀시트 표시 (`ProfileQuickViewSheet`)
3. 액션 버튼: 채팅 시작, 프로필 편집, 삭제

### 7.2 줌/패닝
- `InteractiveViewer`로 감싸서 핀치 줌, 드래그 패닝 지원
- 우측 하단 컨트롤 버튼 (줌인, 줌아웃, 전체보기)

### 7.3 뷰 전환
- AppBar의 토글 버튼으로 리스트 ↔ 그래프 전환
- 애니메이션 효과 (fade 또는 slide)

---

## 8. 구현 체크리스트

### 8.1 의존성 추가
- [ ] `pubspec.yaml`에 `graphview: ^1.5.1` 추가
- [ ] `flutter pub get` 실행

### 8.2 Provider 구현
- [ ] `relationship_graph_provider.dart` 생성
- [ ] `ViewMode` Provider
- [ ] `SelectedProfile` Provider
- [ ] `relationshipGraph` Provider
- [ ] `dart run build_runner build`

### 8.3 위젯 구현
- [ ] `relationship_screen.dart` (메인 통합 화면)
- [ ] `relationship_graph_view.dart` (GraphView 래퍼)
- [ ] `me_node_widget.dart`
- [ ] `profile_node_widget.dart`
- [ ] `relationship_group_node.dart`
- [ ] `graph_controls.dart`
- [ ] `profile_quick_view_sheet.dart`

### 8.4 라우팅
- [ ] `routes.dart`에 `/relationships` 추가
- [ ] `app_router.dart`에 라우트 등록

### 8.5 Widget Tree Guard 검증
- [ ] const 생성자 적용
- [ ] 100줄 이하 위젯
- [ ] RepaintBoundary 적용
- [ ] setState 범위 최소화

---

## 9. 참고 자료

- [graphview pub.dev](https://pub.dev/packages/graphview)
- [graphview GitHub](https://github.com/nabil6391/graphview)
- [Flutter Gems - Tree View](https://fluttergems.dev/tree-view/)
- [React Flow](https://reactflow.dev) (디자인 참고)
