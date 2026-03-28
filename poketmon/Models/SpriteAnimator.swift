//
//  SpriteAnimator.swift
//  poketmon
//
//  AnimDataParser + SpriteSheet를 결합하여 애니메이션 재생
//  포켓몬 ID를 받아 로드 → 애니메이션 전환 → 방향 전환 → 현재 프레임 제공
//  Duration 배열 기반 가변 타이머로 프레임 순환
//

import AppKit
import Observation

// MARK: - 애니메이션 종류

/// 앱에서 사용하는 6종 애니메이션
enum AnimationType: String, CaseIterable {
    case walk  = "Walk"
    case idle  = "Idle"
    case sleep = "Sleep"
    case eat   = "Eat"
    case hop   = "Hop"
    case hurt  = "Hurt"
}

// MARK: - SpriteAnimator

@Observable
final class SpriteAnimator {

    // MARK: 외부 접근 프로퍼티

    /// 현재 표시할 Anim 프레임
    private(set) var currentFrame: CGImage?

    /// 현재 표시할 Shadow 프레임
    private(set) var currentShadowFrame: CGImage?

    /// 현재 애니메이션 종류
    private(set) var currentAnimation: AnimationType = .idle

    /// 현재 방향
    private(set) var currentDirection: Direction = .down

    /// 사용 가능한 Reaction 애니메이션 목록
    private(set) var availableReactions: [AnimationType] = []

    /// 현재 로드된 포켓몬 ID (0 = 미로드)
    private(set) var loadedPokemonID: Int = 0

    /// 현재 애니메이션의 프레임 크기
    var currentFrameSize: CGSize {
        guard let loaded = loadedAnimations[currentAnimation] else { return .zero }
        return CGSize(width: loaded.animData.frameWidth, height: loaded.animData.frameHeight)
    }

    /// Walk 애니메이션의 프레임 크기 (렌더링 기준선)
    var walkFrameSize: CGSize {
        guard let loaded = loadedAnimations[.walk] else { return currentFrameSize }
        return CGSize(width: loaded.animData.frameWidth, height: loaded.animData.frameHeight)
    }

    /// Walk 대비 현재 애니메이션의 렌더링 스케일 (최소 1.0 — Walk보다 작으면 Walk 크기 유지)
    var renderScale: CGFloat {
        let walk = walkFrameSize
        let current = currentFrameSize
        guard walk.width > 0, walk.height > 0 else { return 1.0 }
        return max(1.0, max(current.width / walk.width, current.height / walk.height))
    }

    /// 프레임 재생 속도 배율 (Run 상태: 1.5)
    var speedMultiplier: Double = 1.0 {
        didSet {
            guard !isPaused else { return }
            restartTimer()
        }
    }

    // MARK: 내부 상태

    /// 로드된 애니메이션 데이터
    private struct LoadedAnimation {
        let animSheet: SpriteSheet
        let shadowSheet: SpriteSheet?
        let animData: AnimationData
    }

    private var loadedAnimations: [AnimationType: LoadedAnimation] = [:]
    private var currentFrameIndex: Int = 0
    private var frameTimer: DispatchWorkItem?
    private var isPaused: Bool = false

    // 1회 재생 (Reaction용)
    private var isOneShot = false
    private var oneShotCompletion: (() -> Void)?

    // MARK: - 포켓몬 로드

    /// 포켓몬 ID로 모든 애니메이션 로드
    func load(pokemonID: Int) {
        stopTimer()
        loadedAnimations.removeAll()
        isOneShot = false
        oneShotCompletion = nil

        guard let animData = AnimDataParser.parse(pokemonID: pokemonID) else { return }

        loadedPokemonID = pokemonID

        let reactionTypes: Set<AnimationType> = [.eat, .hop, .hurt]
        var reactions: [AnimationType] = []

        for animType in AnimationType.allCases {
            guard let data = animData.animation(named: animType.rawValue) else { continue }

            let animFileName = "\(animType.rawValue)-Anim.png"
            guard let animImage = SpriteSheet.loadImage(pokemonID: pokemonID, fileName: animFileName),
                  let animSheet = SpriteSheet.extract(from: animImage, animData: data)
            else { continue }

            let shadowFileName = "\(animType.rawValue)-Shadow.png"
            let shadowImage = SpriteSheet.loadImage(pokemonID: pokemonID, fileName: shadowFileName)
            let shadowSheet = shadowImage.flatMap { SpriteSheet.extract(from: $0, animData: data) }

            loadedAnimations[animType] = LoadedAnimation(
                animSheet: animSheet,
                shadowSheet: shadowSheet,
                animData: data
            )

            if reactionTypes.contains(animType) {
                reactions.append(animType)
            }
        }

        availableReactions = reactions
        currentDirection = .down
        switchAnimation(to: .idle)
    }

    // MARK: - 애니메이션 전환

    /// 애니메이션 종류 전환 (반복 재생)
    func switchAnimation(to type: AnimationType) {
        guard loadedAnimations[type] != nil else { return }
        isOneShot = false
        oneShotCompletion = nil
        currentAnimation = type
        currentFrameIndex = 0
        updateFrame()
        restartTimer()
    }

    /// Reaction 애니메이션 1회 재생 후 완료 콜백
    func playOnce(_ type: AnimationType, completion: @escaping () -> Void) {
        guard loadedAnimations[type] != nil else {
            completion()
            return
        }
        currentAnimation = type
        currentFrameIndex = 0
        isOneShot = true
        oneShotCompletion = completion
        updateFrame()
        restartTimer()
    }

    /// 방향 전환
    func setDirection(_ direction: Direction) {
        guard currentDirection != direction else { return }
        currentDirection = direction
        updateFrame()
    }

    // MARK: - 일시정지

    func pause() {
        isPaused = true
        stopTimer()
    }

    func resume() {
        isPaused = false
        restartTimer()
    }

    // MARK: - 프레임 타이머 (가변 Duration)

    private func restartTimer() {
        stopTimer()
        guard !isPaused else { return }
        scheduleNextFrame()
    }

    private func stopTimer() {
        frameTimer?.cancel()
        frameTimer = nil
    }

    private func scheduleNextFrame() {
        guard let loaded = loadedAnimations[currentAnimation] else { return }
        let durations = loaded.animData.durationsInSeconds
        guard !durations.isEmpty else { return }

        // 현재 프레임의 표시 시간 (speedMultiplier 적용)
        let delay = durations[currentFrameIndex % durations.count] / max(speedMultiplier, 0.1)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, !self.isPaused else { return }

            let frameCount = loaded.animData.frameCount
            let nextIndex = (self.currentFrameIndex + 1) % frameCount

            // 1회 재생 완료 체크
            if self.isOneShot && nextIndex == 0 {
                self.isOneShot = false
                let completion = self.oneShotCompletion
                self.oneShotCompletion = nil
                completion?()
                return
            }

            self.currentFrameIndex = nextIndex
            self.updateFrame()
            self.scheduleNextFrame()
        }

        frameTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func updateFrame() {
        guard let loaded = loadedAnimations[currentAnimation] else {
            currentFrame = nil
            currentShadowFrame = nil
            return
        }

        let frameIndex = currentFrameIndex % loaded.animData.frameCount
        currentFrame = loaded.animSheet.frame(direction: currentDirection, index: frameIndex)
        currentShadowFrame = loaded.shadowSheet?.frame(direction: currentDirection, index: frameIndex)
    }
}
