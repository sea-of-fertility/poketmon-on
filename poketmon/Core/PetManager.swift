//
//  PetManager.swift
//  poketmon
//
//  중앙 관리자 싱글턴 — 모든 하위 컴포넌트 소유
//  SwiftUI/AppKit 어디서든 PetManager.shared로 접근
//

import AppKit
import Observation

@Observable
final class PetManager {

    // MARK: - 싱글턴

    static let shared = PetManager()

    // MARK: - 하위 컴포넌트

    let spriteAnimator = SpriteAnimator()
    let stateMachine = PetStateMachine()
    let gameLoop = GameLoop()
    let pokemonDataManager = PokemonDataManager()

    // MARK: - 상태

    /// 현재 포켓몬 ID
    private(set) var currentPokemonID: Int = 25

    /// 일시정지 여부
    private(set) var isPaused = false

    // MARK: - 초기화

    private init() {
        setupGameLoop()
        loadPokemon(id: 25)
    }

    // MARK: - 포켓몬 로드

    /// 포켓몬 교체
    func loadPokemon(id: Int) {
        currentPokemonID = id
        spriteAnimator.load(pokemonID: id)
        stateMachine.transition(to: .idle)

        // 초기 위치 설정 (주 모니터 중앙 하단 1/3)
        let primaryFrame = ScreenGeometry.shared.screenFrames.first ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
        stateMachine.position = CGPoint(
            x: primaryFrame.midX,
            y: primaryFrame.minY + primaryFrame.height * 0.3
        )
    }

    // MARK: - 게임 루프 연결

    private func setupGameLoop() {
        gameLoop.onUpdate = { [weak self] in
            self?.tick()
        }
        gameLoop.start()
    }

    /// 디버그: 포켓몬이 어느 모니터 위에 있는지 추적
    private var lastScreenIndex: Int = -1

    /// 매 프레임 호출
    private func tick() {
        let geo = ScreenGeometry.shared
        let screenBounds = geo.unionFrame
        let pos = stateMachine.position

        // 모니터 전환 감지
        let currentScreenIndex = geo.screenFrames.firstIndex { $0.contains(pos) } ?? -1
        if currentScreenIndex != lastScreenIndex {
            print("[DEBUG] 모니터 전환: screen[\(lastScreenIndex)] → screen[\(currentScreenIndex)]")
            print("[DEBUG]   위치: \(pos)")
            print("[DEBUG]   unionFrame: \(screenBounds)")
            print("[DEBUG]   screenFrames: \(geo.screenFrames)")
            if currentScreenIndex == -1 {
                print("[DEBUG]   ⚠️ 포켓몬이 어떤 모니터에도 속하지 않음!")
            }
            lastScreenIndex = currentScreenIndex
        }

        // 상태 머신 업데이트 — 전환 필요 시 애니메이션 변경
        if let newAnim = stateMachine.update(screenBounds: screenBounds) {
            spriteAnimator.switchAnimation(to: newAnim)

            // Run 상태면 속도 배율 1.5, 아니면 1.0
            spriteAnimator.speedMultiplier = (stateMachine.currentState == .run) ? 1.5 : 1.0
        }

        // 방향 동기화
        spriteAnimator.setDirection(stateMachine.currentDirection)
    }

    // MARK: - 외부 제어

    /// 일시정지 토글
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            gameLoop.pause()
            spriteAnimator.pause()
        } else {
            gameLoop.resume()
            spriteAnimator.resume()
        }
    }

    /// 강제 Sleep
    func sleep() {
        stateMachine.sleep()
        spriteAnimator.switchAnimation(to: .sleep)
    }

    /// 깨우기
    func wake() {
        stateMachine.wake()
        spriteAnimator.switchAnimation(to: .idle)
    }

    /// 강제 Run (10초)
    func run() {
        stateMachine.run()
        spriteAnimator.switchAnimation(to: .walk)
        spriteAnimator.speedMultiplier = 1.5
    }

    /// 모니터 해제 시 포켓몬이 화면 밖에 있으면 가장 가까운 모니터로 이동
    func relocateIfOffScreen() {
        let geo = ScreenGeometry.shared
        let pos = stateMachine.position
        if !geo.isOnScreen(pos, margin: 20) {
            stateMachine.position = geo.clampToNearestScreen(pos, margin: 40)
        }
    }

    /// 클릭 반응
    func react() {
        let previousState = stateMachine.currentState
        stateMachine.react()

        if previousState == .sleep {
            spriteAnimator.switchAnimation(to: .idle)
        } else if stateMachine.currentState == .reaction {
            // 사용 가능한 Reaction 애니메이션 중 랜덤 선택
            if let reactionAnim = spriteAnimator.availableReactions.randomElement() {
                spriteAnimator.playOnce(reactionAnim) { [weak self] in
                    self?.stateMachine.reactionFinished()
                    self?.spriteAnimator.switchAnimation(to: .idle)
                }
            } else {
                // Reaction 애니메이션 없으면 바로 Idle
                stateMachine.reactionFinished()
                spriteAnimator.switchAnimation(to: .idle)
            }
        }
    }
}
