//
//  poketmonApp.swift
//  poketmon
//
//  SwiftUI + AppKit 하이브리드 앱 진입점
//  MenuBarExtra (메뉴바 전용) + AppDelegate (투명 윈도우 관리)
//

import SwiftUI

@main
struct poketmonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// 몬스터볼 메뉴바 아이콘 (16×16 Template)
    private static let pokeballImage: NSImage = {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            let lineWidth: CGFloat = 1.5
            let inset: CGFloat = 1.5
            let circleRect = rect.insetBy(dx: inset, dy: inset)
            let center = CGPoint(x: rect.midX, y: rect.midY)

            ctx.setFillColor(NSColor.black.cgColor)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineWidth(lineWidth)

            // 상단 반원 채우기
            ctx.saveGState()
            ctx.clip(to: CGRect(x: 0, y: center.y, width: rect.width, height: rect.height / 2))
            ctx.fillEllipse(in: circleRect)
            ctx.restoreGState()

            // 전체 원 윤곽
            ctx.strokeEllipse(in: circleRect)

            // 중앙 가로선
            ctx.move(to: CGPoint(x: circleRect.minX, y: center.y))
            ctx.addLine(to: CGPoint(x: circleRect.maxX, y: center.y))
            ctx.strokePath()

            // 중앙 버튼 (투명 원 + 윤곽)
            let btnR: CGFloat = 2.5
            let btnRect = CGRect(x: center.x - btnR, y: center.y - btnR,
                                 width: btnR * 2, height: btnR * 2)
            ctx.setBlendMode(.clear)
            ctx.fillEllipse(in: btnRect.insetBy(dx: -1, dy: -1))
            ctx.setBlendMode(.normal)
            ctx.strokeEllipse(in: btnRect)

            return true
        }
        image.isTemplate = true
        return image
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdownView()
        } label: {
            Image(nsImage: Self.pokeballImage)
        }
        .menuBarExtraStyle(.window)
    }
}
