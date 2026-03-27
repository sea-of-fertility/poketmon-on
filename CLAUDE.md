# PokePet - macOS 데스크톱 펫

Gen 1-5 포켓몬(649종) 스프라이트를 활용한 macOS 데스크톱 펫 앱.
PMDCollab SpriteCollab의 8방향 스프라이트 시트 사용.

## 빌드
- Xcode 프로젝트: `poketmon.xcodeproj`
- 타겟: macOS 15.5+
- 언어: Swift

## 아키텍처
- SwiftUI + AppKit 하이브리드 (투명 윈도우는 AppKit, 설정/선택기 UI는 SwiftUI)
- 메뉴바: MenuBarExtra + .window 스타일 (커스텀 SwiftUI 드롭다운)
- Dock 숨김 (LSUIElement = true), 메뉴바 전용 앱
- 게임 루프: DispatchSourceTimer
- 스프라이트는 앱 번들에 포함 (~15MB)
- portrait 이미지: 포켓몬 선택기에서 초상화 표시용 (PMDCollab portrait/{ID}/Normal.png)

## 프로젝트 구조
```
poketmon/
  App/            — 앱 진입점 (AppDelegate)
  Models/         — AnimDataParser, SpriteSheet, SpriteAnimator, PokemonDataManager
  Views/          — SwiftUI 뷰 (선택기, 설정 패널)
  ViewModels/     — ObservableObject VM
  Services/       — SettingsManager 등
  Core/           — 상태 머신, 이동 로직
  Resources/      — Sprites/{ID}/, pokemon_data.json
```

## 스프라이트 시스템
- 소스: PMDCollab/SpriteCollab (GitHub)
- 포켓몬당 파일: AnimData.xml + {Walk,Idle,Sleep,Eat,Hop,Hurt}-{Anim,Shadow}.png
- AnimData.xml로 프레임 크기/수/Duration 파싱 → CGImage.cropping으로 프레임 추출
- 8방향 (Row 0~7: Down, DownRight, Right, UpRight, Up, UpLeft, Left, DownLeft)

## 결정 사항
- 화면 가장자리에서 반사 기능 제거
- 다른 윈도우 위에서만 이동 기능 제거 (Accessibility API 권한 부담)
- Run 상태는 별도 모션 없이 Walk 애니메이션 속도 증가로 처리

## 개발 계획
8단계 순차 개발. 상세 내용은 @plan.md 참고.
현재: Phase 1 준비 중 (디렉토리 구조 생성 완료, mockup 고도화 진행 중)

## 참고 문서
- @plan.md — 전체 개발 계획 (Phase 1~8)
- @SCREEN_SPEC.md — 화면별 상세 스펙
- @SPRITE_INTEGRATION_PLAN.md — 스프라이트 구조/파싱/다운로드 상세
- @pokemon_data.json — 649종 포켓몬 데이터 (id, name, gen, types)
- @ui-mockup.html — UI 목업 (브라우저에서 열어 확인, portrait 이미지 포함)

## 코딩 규칙
- 주석/커밋 메시지: 한국어
- Swift 표준 네이밍 (camelCase 변수, PascalCase 타입)
- 픽셀아트 렌더링 시 nearest-neighbor 보간 사용
