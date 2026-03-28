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
            let oldUnion = self.unionFrame
            let oldCount = self.screenFrames.count
            self.recalculate()
            print("[ScreenGeo] 모니터 변경 감지 — 모니터 수: \(oldCount) → \(self.screenFrames.count)")
            print("[ScreenGeo] unionFrame: \(oldUnion) → \(self.unionFrame)")
            for (i, frame) in self.screenFrames.enumerated() {
                print("[ScreenGeo]   screen[\(i)]: \(frame)")
            }
            self.onScreenChange?()
        }
    }

    // MARK: - 재계산

    /// NSScreen.screens에서 geometry 재계산
    func recalculate() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        screenFrames = screens.map { $0.frame }
        unionFrame = screenFrames.dropFirst().reduce(screenFrames[0]) { $0.union($1) }
    }

    // MARK: - 좌표 판정

    /// 해당 점이 실제 모니터 위에 있는지 확인
    func isOnScreen(_ point: CGPoint, margin: CGFloat = 0) -> Bool {
        screenFrames.contains { frame in
            frame.insetBy(dx: margin, dy: margin).contains(point)
        }
    }

    /// dead zone에 빠진 점을 가장 가까운 모니터 안쪽으로 보정
    func clampToNearestScreen(_ point: CGPoint, margin: CGFloat = 0) -> CGPoint {
        guard !screenFrames.isEmpty else { return point }

        var bestPoint = point
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for frame in screenFrames {
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

    /// 실제 모니터 위의 랜덤 목표점 생성
    func randomTarget(margin: CGFloat = 40) -> CGPoint {
        guard !screenFrames.isEmpty else { return .zero }

        // 랜덤 모니터 선택
        let frame = screenFrames.randomElement()!
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
