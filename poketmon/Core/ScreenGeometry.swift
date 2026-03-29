//
//  ScreenGeometry.swift
//  poketmon
//
//  멀티 모니터 좌표 계산 — 모든 화면의 합집합(union) 및 dead zone 보정
//

import AppKit

final class ScreenGeometry {

    static let shared = ScreenGeometry()

    /// 모든 모니터의 합집합 (윈도우 크기용)
    private(set) var unionFrame: CGRect = .zero

    /// 개별 모니터 frame 배열 (글로벌 좌표)
    private(set) var screenFrames: [CGRect] = []

    /// 개별 모니터 이름 배열 (screenFrames와 동일 순서)
    private(set) var screenNames: [String] = []

    /// 특정 모니터로 이동 제한 (nil이면 모든 모니터 사용)
    var restrictedScreenName: String? = nil

    /// 제한 모니터 또는 전체 모니터 frame 배열
    private var activeScreenFrames: [CGRect] {
        if let name = restrictedScreenName,
           let idx = screenNames.firstIndex(of: name),
           idx < screenFrames.count {
            return [screenFrames[idx]]
        }
        return screenFrames
    }

    /// 주 모니터 높이 (renderSize 계산용)
    var primaryScreenHeight: CGFloat {
        screenFrames.first?.height ?? 1080
    }

    /// 변경 콜백 (AppDelegate에서 윈도우 리사이즈용)
    var onScreenChange: (() -> Void)?

    private init() {
        recalculate()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.recalculate()
            self.onScreenChange?()
        }
    }

    // MARK: - 재계산

    /// NSScreen.screens에서 geometry 재계산
    func recalculate() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        screenFrames = screens.map { $0.frame }
        screenNames = screens.map { $0.localizedName }
        unionFrame = screenFrames.dropFirst().reduce(screenFrames[0]) { $0.union($1) }
    }

    // MARK: - 좌표 판정

    /// 해당 점이 실제 모니터 위에 있는지 확인
    func isOnScreen(_ point: CGPoint, margin: CGFloat = 0) -> Bool {
        activeScreenFrames.contains { frame in
            frame.insetBy(dx: margin, dy: margin).contains(point)
        }
    }

    /// dead zone에 빠진 점을 가장 가까운 모니터 안쪽으로 보정
    func clampToNearestScreen(_ point: CGPoint, margin: CGFloat = 0) -> CGPoint {
        let frames = activeScreenFrames
        guard !frames.isEmpty else { return point }

        var bestPoint = point
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for frame in frames {
            let inset = frame.insetBy(dx: margin, dy: margin)
            guard inset.width > 0, inset.height > 0 else { continue }

            // 프레임 안쪽 가장 가까운 점
            let clampedX = min(max(point.x, inset.minX), inset.maxX)
            let clampedY = min(max(point.y, inset.minY), inset.maxY)
            let candidate = CGPoint(x: clampedX, y: clampedY)

            let dx = candidate.x - point.x
            let dy = candidate.y - point.y
            let dist = dx * dx + dy * dy

            if dist < bestDistance {
                bestDistance = dist
                bestPoint = candidate
            }
        }

        return bestPoint
    }

    /// 스프라이트가 화면 밖으로 나가지 않도록 위치를 union frame 내로 clamp
    /// position: 스프라이트 중심, halfWidth: 너비/2, height: 전체 높이, walkHalfHeight: walk 높이/2 (발 기준)
    func clampSpritePosition(_ position: CGPoint, halfWidth: CGFloat, height: CGFloat, walkHalfHeight: CGFloat) -> (position: CGPoint, bounced: Bool) {
        let bounds = unionFrame
        var pos = position
        var bounced = false

        if pos.x < bounds.minX + halfWidth {
            pos.x = bounds.minX + halfWidth
            bounced = true
        } else if pos.x > bounds.maxX - halfWidth {
            pos.x = bounds.maxX - halfWidth
            bounced = true
        }

        if pos.y < bounds.minY + walkHalfHeight {
            pos.y = bounds.minY + walkHalfHeight
            bounced = true
        } else if pos.y > bounds.maxY - height + walkHalfHeight {
            pos.y = bounds.maxY - height + walkHalfHeight
            bounced = true
        }

        return (pos, bounced)
    }

    /// 실제 모니터 위의 랜덤 목표점 생성
    func randomTarget(margin: CGFloat = 40) -> CGPoint {
        let frames = activeScreenFrames
        guard !frames.isEmpty else { return .zero }

        // 랜덤 모니터 선택 (제한 시 해당 모니터만)
        let frame = frames.randomElement()!
        let inset = frame.insetBy(dx: margin, dy: margin)

        guard inset.width > 0, inset.height > 0 else {
            return CGPoint(x: frame.midX, y: frame.midY)
        }

        return CGPoint(
            x: CGFloat.random(in: inset.minX...inset.maxX),
            y: CGFloat.random(in: inset.minY...inset.maxY)
        )
    }
}
