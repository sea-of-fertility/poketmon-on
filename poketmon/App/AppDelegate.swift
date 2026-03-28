//
//  AppDelegate.swift
//  poketmon
//
//  투명 NSWindow 생성 및 관리
//  Phase 2: borderless 투명 윈도우에 포켓몬 스프라이트 표시
//

import AppKit

// MARK: - 투명 오버레이 전용 윈도우

/// key/main window가 되지 않는 투명 윈도우
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func makeKey() {}
    override func makeKeyAndOrderFront(_ sender: Any?) { orderFront(sender) }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var overlayWindow: NSWindow?
    private var petView: PetView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupOverlayWindow()

        // 앱 활성화 시 OverlayWindow가 key window가 되지 않도록 방지
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - 투명 윈도우 설정

    private func setupOverlayWindow() {
        guard let screen = NSScreen.main else { return }

        // borderless 투명 윈도우 — 전체 화면 크기
        let window = OverlayWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false

        // 포켓몬 렌더링 뷰
        let petView = PetView(frame: screen.frame)
        window.contentView = petView
        self.petView = petView

        window.orderFront(nil)
        overlayWindow = window
    }
}
