//
//  PetView.swift
//  poketmon
//
//  투명 윈도우의 콘텐츠 뷰 — 포켓몬 스프라이트 렌더링 + 클릭 통과
//  Phase 2: Anim + Shadow 프레임을 nearest-neighbor로 그리기
//
//  클릭 통과 방식: 기본 ignoresMouseEvents = true (다른 앱으로 클릭 통과)
//  마우스가 포켓몬 위에 올라가면 false로 전환하여 이벤트 수신
//

import AppKit

final class PetView: NSView {

    // MARK: - 스프라이트 상태

    private let animator = SpriteAnimator()

    /// 포켓몬 위치 (좌하단 기준 — macOS 좌표계)
    private(set) var petPosition: CGPoint = .zero

    /// 렌더링 크기 (화면 높이의 약 6%)
    private var renderSize: CGFloat {
        guard let screen = NSScreen.main else { return 64 }
        return screen.frame.height * 0.06
    }

    /// 포켓몬 스프라이트 영역
    private var petRect: CGRect {
        let size = renderSize
        return CGRect(
            x: petPosition.x - size / 2,
            y: petPosition.y - size / 2,
            width: size,
            height: size
        )
    }

    // MARK: - 초기화

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupPet()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPet()
    }

    private func setupPet() {
        // 화면 중앙 하단 1/3 지점에 배치
        petPosition = CGPoint(
            x: bounds.midX,
            y: bounds.height * 0.3
        )

        // 피카츄 로드 + Idle 애니메이션 시작
        animator.load(pokemonID: 25)

        // 기본: 클릭 통과 (다른 앱으로 이벤트 전달)
        window?.ignoresMouseEvents = true

        // 30fps 뷰 갱신 + 마우스 위치 체크
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
            self?.updateMousePassthrough()
        }
    }

    // MARK: - 마우스 통과 제어

    /// 마우스가 포켓몬 위에 있으면 이벤트 수신, 아니면 클릭 통과
    private func updateMousePassthrough() {
        guard let window = self.window else { return }

        // 현재 마우스 위치 (스크린 좌표 → 윈도우 좌표)
        let screenLocation = NSEvent.mouseLocation
        let windowLocation = window.convertPoint(fromScreen: screenLocation)

        let isOverPet = petRect.contains(windowLocation)
        window.ignoresMouseEvents = !isOverPet
    }

    // MARK: - 렌더링

    override func draw(_ dirtyRect: NSRect) {
        // 투명 배경
        NSColor.clear.set()
        dirtyRect.fill()

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // nearest-neighbor 보간 (픽셀아트)
        context.interpolationQuality = .none

        let size = renderSize
        let rect = petRect

        // Shadow 렌더링 (Anim 아래에)
        if let shadow = animator.currentShadowFrame {
            let shadowRect = CGRect(
                x: rect.midX - size * 0.35,
                y: rect.minY - size * 0.05,
                width: size * 0.7,
                height: size * 0.15
            )
            context.draw(shadow, in: shadowRect)
        }

        // Anim 렌더링
        if let frame = animator.currentFrame {
            context.draw(frame, in: rect)
        }
    }

    // MARK: - 마우스 이벤트

    override func mouseDown(with event: NSEvent) {
        // super 호출 안 함 → makeKeyWindow 방지
        // Phase 4에서 클릭/드래그 인터랙션 구현 예정
    }
}
