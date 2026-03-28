# PokePet - macOS 데스크톱 펫

Gen 1~5 포켓몬(649종)이 바탕화면 위를 자유롭게 돌아다니는 macOS 데스크톱 펫 앱.
PMDCollab SpriteCollab의 8방향 스프라이트 시트를 사용합니다.

## 주요 기능

- **649종 포켓몬** — Gen 1~5 전체. 8방향 애니메이션 (Walk, Idle, Sleep, Eat, Hop, Hurt)
- **6가지 상태** — 대기, 걷기, 달리기, 수면, 반응, 드래그
- **포켓몬 선택기** — 세대 탭, 타입 필터, 검색으로 포켓몬 교체 (페이드 전환)
- **설정 패널** — 크기, 투명도, 표시 위치, 이동 속도, 활동 빈도, 수면 시간
- **멀티 모니터** — 모니터별 독립 윈도우, 모니터 간 자유 이동
- **마우스 인터랙션** — 클릭(반응), 드래그(이동), 우클릭(메뉴), 더블클릭(선택기)
- **메뉴바 앱** — Dock 숨김, 메뉴바 아이콘으로 제어

## 빌드

- **Xcode 프로젝트**: `poketmon.xcodeproj`
- **타겟**: macOS 15.5+
- **언어**: Swift
- **외부 의존성 없음**

## 프로젝트 구조

```
Sprites/              스프라이트 (포켓몬당 AnimData.xml + Anim/Shadow PNG)
poketmon/
  App/                앱 진입점 (AppDelegate)
  Models/             AnimDataParser, SpriteSheet, SpriteAnimator, PokemonDataManager
  Views/              PetView, PokemonSelectorView, SettingsView, MenuBarDropdownView
  Services/           SettingsManager (UserDefaults)
  Core/               PetManager, PetStateMachine, GameLoop, ScreenGeometry
  Resources/          pokemon_data.json, Portraits/
```

## 아키텍처

SwiftUI + AppKit 하이브리드. 투명 윈도우는 AppKit, 설정/선택기 UI는 SwiftUI.

```
PetManager.shared (@Observable 싱글턴)
  ├─ spriteAnimator      프레임 제공, 애니메이션 전환
  ├─ stateMachine        6개 상태 전환, 위치/방향
  ├─ gameLoop            DispatchSourceTimer (30fps)
  ├─ settingsManager     UserDefaults 저장/로드
  └─ pokemonDataManager  649종 포켓몬 목록
```

## 스프라이트 출처

[PMDCollab SpriteCollab](https://github.com/PMDCollab/SpriteCollab) - 8방향 스프라이트 시트
