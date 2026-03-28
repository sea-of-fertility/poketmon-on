//
//  PetView.swift
//  poketmon
//
//  투명 윈도우의 콘텐츠 뷰 — 포켓몬 스프라이트 렌더링 + 클릭 통과
//  PetManager.shared에서 위치/프레임 정보를 가져와 렌더링
//  각 모니터마다 독립 PetView가 존재하며, 포켓몬이 해당 모니터 위에 있을 때만 렌더링
//

import AppKit

final class PetView: NSView {

    /// 이 뷰가 담당하는 모니터의 글로벌 frame
    var screenFrame: CGRect = .zero

    /// 드래그 중 여부 (드래그 중에는 ignoresMouseEvents 유지)
    private var isDragging = false

    /// 렌더링 크기 (주 모니터 높이의 약 6%)
    private var renderSize: CGFloat {
        return ScreenGeometry.shared.primaryScreenHeight * 0.06
    }

    /// 포켓몬 스프라이트 영역 (글로벌 좌표 → 이 윈도우의 로컬 좌표 변환)
    private var petRect: CGRect {
        let size = renderSize
        let pos = PetManager.shared.stateMachine.position
        return CGRect(
            x: (pos.x - screenFrame.origin.x) - size / 2,
            y: (pos.y - screenFrame.origin.y) - size / 2,
            width: size,
            height: size
        )
    }

    // MARK: - 초기화

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupRendering()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRendering()
    }

    private func setupRendering() {
        DispatchQueue.main.async { [weak self] in
            self?.window?.ignoresMouseEvents = true
        }

        // 30fps 뷰 갱신 + 마우스 위치 체크
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
            self?.updateMousePassthrough()
        }
    }

    // MARK: - 마우스 통과 제어

    private func updateMousePassthrough() {
        guard let window = self.window else { return }
        let pos = PetManager.shared.stateMachine.position
        // 포켓몬이 이 모니터 위에 없으면 항상 클릭 통과
        guard screenFrame.contains(pos) else {
            window.ignoresMouseEvents = true
            return
        }
        let screenLocation = NSEvent.mouseLocation
        let windowLocation = window.convertPoint(fromScreen: screenLocation)
        let isOverPet = petRect.contains(windowLocation)
        window.ignoresMouseEvents = !isOverPet && !isDragging
    }

    // MARK: - 렌더링

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()

        let pos = PetManager.shared.stateMachine.position
        let size = renderSize

        // 포켓몬이 이 모니터 근처에 없으면 그리지 않음
        let expandedFrame = screenFrame.insetBy(dx: -size, dy: -size)
        guard expandedFrame.contains(pos) else { return }

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let animator = PetManager.shared.spriteAnimator
        let rect = petRect

        // nearest-neighbor 보간 (픽셀아트)
        context.interpolationQuality = .none

        // Shadow 렌더링
        if let shadow = animator.currentShadowFrame {
            let shadowWidth = rect.width * 0.8
            let shadowRect = CGRect(
                x: rect.midX - shadowWidth / 2,
                y: rect.minY - size * 0.05,
                width: shadowWidth,
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
        // Phase 4에서 클릭/드래그 인터랙션 구현 예정
    }

    override func mouseDragged(with event: NSEvent) {
        isDragging = true
        // Phase 4에서 드래그 이동 구현 예정
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        // Phase 4에서 드래그 종료 처리 예정
    }
}
