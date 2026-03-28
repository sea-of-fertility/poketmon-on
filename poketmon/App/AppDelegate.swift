//
//  AppDelegate.swift
//  poketmon
//
//  투명 NSWindow 생성 및 관리
//  모니터별 독립 윈도우로 멀티 모니터 지원
//

import AppKit

// MARK: - 투명 오버레이 전용 윈도우

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func makeKey() {}
    override func makeKeyAndOrderFront(_ sender: Any?) { orderFront(sender) }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var overlayWindows: [NSWindow] = []
    private var petViews: [PetView] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        _ = PetManager.shared
        setupOverlayWindows()
        setupScreenChangeHandler()
    }

    // MARK: - 모니터별 투명 윈도우 생성

    private func setupOverlayWindows() {
        // 기존 윈도우 정리
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        petViews.removeAll()

        let geo = ScreenGeometry.shared

        for screenFrame in geo.screenFrames {
            let window = OverlayWindow(
                contentRect: screenFrame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )

            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.hidesOnDeactivate = false
            window.ignoresMouseEvents = true

            let viewFrame = CGRect(origin: .zero, size: screenFrame.size)
            let petView = PetView(frame: viewFrame)
            petView.screenFrame = screenFrame
            window.contentView = petView

            window.orderFront(nil)

            overlayWindows.append(window)
            petViews.append(petView)
        }
    }

    // MARK: - 모니터 변경 감지

    private func setupScreenChangeHandler() {
        ScreenGeometry.shared.onScreenChange = { [weak self] in
            self?.setupOverlayWindows()
            PetManager.shared.relocateIfOffScreen()
        }
    }
}
