# 포켓몬 데스크톱 펫 - 개발 계획

> 각 단계는 이전 단계의 결과물에 의존한다. 순서대로 진행.
> 코드 구현 세부사항은 SCREEN_SPEC.md, SPRITE_INTEGRATION_PLAN.md 참고.

---

## Phase 1. 프로젝트 기반 & 스프라이트 시스템
모든 시각적 작업의 토대. 스프라이트 다운로드 → 파싱 → 프레임 추출 → 애니메이션 재생까지.

### Step 1-1. 스프라이트 다운로드
- `download_sprites.sh` 실행 → `./poketmon/Resources/Sprites/{ID:04d}/`에 633종 저장
- 포켓몬당 7파일 (AnimData.xml + 3종 Anim.png + 3종 Shadow.png)
- 다운로드 후 Xcode 프로젝트에 리소스 등록 (Sprites 폴더 + pokemon_data.json)

> **🔶 확인 필요**: 스프라이트를 앱 번들에 전부 포함할지 (앱 용량 12~15MB 증가), 아니면 첫 실행 시 다운로드 방식으로 갈지?

### Step 1-2. AnimData.xml 파서
- `poketmon/Models/AnimDataParser.swift`
- Foundation XMLParser로 각 애니메이션의 프레임 크기, 프레임 수, Duration 배열 추출
- XML 구조는 SPRITE_INTEGRATION_PLAN.md 섹션 3 참고

### Step 1-3. 스프라이트 프레임 추출기
- `poketmon/Models/SpriteSheet.swift`
- 스프라이트 시트 PNG에서 CGImage.cropping으로 개별 프레임 추출
- 8방향 × N프레임 = 2차원 배열로 반환
- 8방향 Direction enum도 이 파일 또는 별도 파일에 정의
- 추출 공식은 SPRITE_INTEGRATION_PLAN.md 섹션 3 참고

### Step 1-4. SpriteAnimator
- `poketmon/Models/SpriteAnimator.swift`
- AnimDataParser + SpriteSheet를 결합하여 애니메이션 재생
- 포켓몬 ID를 받아 로드 → 애니메이션 종류("Walk"/"Idle"/"Sleep") 전환 → 방향 전환 → 현재 프레임 이미지 제공
- Duration 기반 타이머로 프레임 자동 순환
- ObservableObject로 구현하여 UI 바인딩 대비

> **🔶 확인 필요**: Shadow PNG도 렌더링에 사용할지? 사용한다면 Anim과 Shadow를 겹쳐 그리는 로직 추가 필요.

### Step 1-5. PokemonDataManager
- `poketmon/Models/PokemonDataManager.swift`
- pokemon_data.json을 Codable로 디코딩하여 포켓몬 목록 제공
- 누락 16종은 스프라이트 폴더 존재 여부로 판별하여 사용 불가 표시

### Phase 1 생성 파일
- `poketmon/Models/AnimDataParser.swift`
- `poketmon/Models/SpriteSheet.swift` (Direction enum 포함)
- `poketmon/Models/SpriteAnimator.swift`
- `poketmon/Models/PokemonDataManager.swift`

---

## Phase 2. 투명 윈도우 & 포켓몬 렌더링
borderless 투명 NSWindow 생성, 포켓몬 스프라이트를 화면 위에 표시.
hitTest 오버라이드로 클릭 통과 구현. 앱 구조를 SwiftUI → AppKit 하이브리드로 전환.

> **🔶 확인 필요**: 앱 구조를 순수 AppKit(NSApplicationDelegate)으로 갈지, SwiftUI + NSViewRepresentable 하이브리드로 갈지?

---

## Phase 3. 상태 머신 & 이동 로직
6개 상태(Idle, Walk, Run, Sleep, Reaction, Dragged) 전환 구현.
8방향 랜덤 이동, 화면 경계 반사, 전환 타이밍 로직.
상태 전환 규칙은 SCREEN_SPEC.md "포켓몬 상태 (State Machine)" 섹션 참고.

---

## Phase 4. 마우스 인터랙션
좌클릭(Reaction), 드래그(Dragged), 우클릭(컨텍스트 메뉴), 더블클릭(선택기) 처리.
입력별 동작은 SCREEN_SPEC.md "인터랙션" 테이블 참고.

---

## Phase 5. 메뉴바 & 컨텍스트 메뉴
NSStatusItem 메뉴바 아이콘 + 드롭다운 메뉴 구현.
우클릭 NSMenu 컨텍스트 메뉴 구현. 상태 제어(일시정지, 재우기, 뛰게 하기).
항목 구성은 SCREEN_SPEC.md 화면 2, 3 참고. UI 디자인은 ui-mockup.html 참고.

> **🔶 확인 필요**: 메뉴바 드롭다운을 네이티브 NSMenu로 할지, NSPopover 커스텀 UI로 할지? (ui-mockup.html은 커스텀 스타일로 디자인되어 있음)

---

## Phase 6. 포켓몬 선택기
NSPanel 기반 선택 윈도우. 검색바, 세대 탭(Gen 1~5), 타입 필터 칩(18종).
포켓몬 그리드 표시, 선택 시 데스크톱 펫 교체.
필터 조합 로직과 레이아웃은 SCREEN_SPEC.md 화면 4 참고. UI 디자인은 ui-mockup.html 참고.

> **🔶 확인 필요**: 선택기 UI를 SwiftUI로 구현할지, AppKit(NSCollectionView)으로 구현할지?

---

## Phase 7. 설정 패널
NSPanel 기반 설정 윈도우. 크기/투명도/표시위치, 이동속도/활동빈도/수면시간, 시스템 설정.
UserDefaults 저장 & 실시간 반영.
설정 항목과 범위는 SCREEN_SPEC.md 화면 5 참고. UI 디자인은 ui-mockup.html 참고.

---

## Phase 8. 마무리 & 폴리시
로그인 시 자동 실행, 성능 최적화, 엣지 케이스 처리, 최종 테스트.
